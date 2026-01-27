//
//  typoApp.swift
//  typo
//
//  Created by content manager on 23/01/26.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox
import Combine
import CoreText

@main
struct typoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

// Puntero global para el callback de Carbon
var globalAppDelegate: AppDelegate?

// Custom NSPanel that can become key window and is draggable
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        // Allow the panel to be moved by dragging its background
        self.isMovableByWindowBackground = true
    }
}

// Manager para compartir el texto capturado
class CapturedTextManager: ObservableObject {
    static let shared = CapturedTextManager()
    @Published var capturedText: String = ""
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popoverWindow: NSWindow?
    var settingsWindow: NSWindow?
    var onboardingWindow: NSWindow?
    var eventMonitor: Any?
    var localEventMonitor: Any?
    var hotKeyRef: EventHotKeyRef?
    var actionHotKeyRefs: [EventHotKeyRef?] = []
    var pendingAction: Action?
    var cancellables = Set<AnyCancellable>()
    var previousActiveApp: NSRunningApplication?
    var menuBarMenuController = MenuBarMenuWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        globalAppDelegate = self
        registerCustomFonts()

        // Register for URL scheme handling
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Check if onboarding is needed
        if !OnboardingManager.shared.hasCompletedOnboarding {
            showOnboarding()
        } else {
            setupApp()
        }
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else { return }

        // Handle OAuth callback
        if url.scheme == "textab" && url.host == "auth" {
            Task {
                do {
                    try await AuthManager.shared.handleOAuthCallback(url: url)
                    await MainActor.run {
                        self.openSettings()
                        NotificationCenter.default.post(name: NSNotification.Name("OAuthLoginSuccess"), object: nil)
                    }
                } catch {
                    await MainActor.run {
                        AuthManager.shared.errorMessage = error.localizedDescription
                        self.openSettings()
                    }
                }
            }
        }

        // Handle payment success callback
        if url.scheme == "textab" && url.host == "payment" && url.path == "/success" {
            Task {
                // Retry a few times with delay to wait for webhook to update database
                for attempt in 1...5 {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000) // 1s, 2s, 3s, 4s, 5s
                    await AuthManager.shared.refreshSubscription()
                    if AuthManager.shared.isPro {
                        break
                    }
                }
                await MainActor.run {
                    self.openSettings()
                    NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                }
            }
        }
    }

    func setupApp() {
        setupMenuBar()
        setupGlobalHotkey()
        setupActionHotkeys()
        setupLocalEscapeMonitor()
        setupColorPickerResultObserver()

        // Ocultar del dock (solo menu bar)
        NSApp.setActivationPolicy(.accessory)

        // Observar cambios en las acciones para re-registrar hotkeys
        ActionsStore.shared.$actions
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.setupActionHotkeys()
            }
            .store(in: &cancellables)

        // Observar cambios en el shortcut principal
        ActionsStore.shared.$mainShortcut
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                if let ref = self?.hotKeyRef {
                    UnregisterEventHotKey(ref)
                }
                self?.setupGlobalHotkey()
            }
            .store(in: &cancellables)
    }

    func showOnboarding() {
        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.setupApp()
        })

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()

        // Hide minimize and zoom buttons, keep only close button
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false

        onboardingWindow = window
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupColorPickerResultObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowColorPickerResult"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let result = notification.userInfo?["result"] as? String,
                  let action = notification.userInfo?["action"] as? Action else {
                return
            }

            // Store the result and show popup with it
            self?.showColorPickerResult(result: result, action: action)
        }

        // Listen for chat open/close to suspend/restore click-outside monitor
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChatOpened"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Suspend click-outside monitor when chat is open
            if let monitor = self?.eventMonitor {
                NSEvent.removeMonitor(monitor)
                self?.eventMonitor = nil
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChatClosed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Restore click-outside monitor when chat is closed
            self?.eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hidePopover()
            }
        }
    }

    func showColorPickerResult(result: String, action: Action) {
        // Create a special popup to show the color result
        popoverWindow = nil

        let contentView = ColorPickerResultView(
            result: result,
            action: action,
            onClose: { [weak self] in
                self?.hidePopover()
            }
        )

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 380),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.contentView = NSHostingView(rootView: contentView)
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false

        // Position center of screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 380
            let windowHeight: CGFloat = 380
            let x = (screenRect.width - windowWidth) / 2 + screenRect.minX
            let y = (screenRect.height - windowHeight) / 2 + screenRect.minY
            panel.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        popoverWindow = panel
        popoverWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Close on click outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePopover()
        }
    }

    func registerCustomFonts() {
        // Debug: Print bundle path
        print("Bundle path: \(Bundle.main.bundlePath)")

        // Try to find the font in different locations
        // Register Nunito Bold, ExtraBold, and Black
        let fontFiles = ["Nunito-Bold", "Nunito-ExtraBold", "Nunito-Black"]

        for fontFile in fontFiles {
            let possiblePaths = [
                Bundle.main.url(forResource: fontFile, withExtension: "ttf", subdirectory: "Fonts"),
                Bundle.main.url(forResource: fontFile, withExtension: "ttf"),
                Bundle.main.resourceURL?.appendingPathComponent("Fonts/\(fontFile).ttf")
            ]

            for path in possiblePaths {
                if let fontURL = path {
                    print("Trying font at: \(fontURL.path)")
                    if FileManager.default.fileExists(atPath: fontURL.path) {
                        var error: Unmanaged<CFError>?
                        let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
                        print("Font registration success for \(fontFile): \(success)")
                        if let error = error?.takeRetainedValue() {
                            print("Font registration error: \(error)")
                        }
                        break
                    }
                }
            }
        }

        // List all available fonts to debug
        let fontFamilies = NSFontManager.shared.availableFontFamilies
        let nunitoFonts = fontFamilies.filter { $0.lowercased().contains("nunito") }
        print("Available Nunito fonts: \(nunitoFonts)")
    }

    func setupLocalEscapeMonitor() {
        // Monitor local para ESC dentro de la app
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // 53 = Escape
                self?.hidePopover()
                return nil // Consume el evento
            }
            return event
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let catIcon = NSImage(named: "MenuBarIcon") {
                catIcon.isTemplate = true
                button.image = catIcon
            } else {
                button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "TexTab")
            }
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        // Mostrar menú personalizado animado (para clic izquierdo y derecho)
        if menuBarMenuController.isMenuVisible {
            menuBarMenuController.closeMenu()
        } else {
            guard let statusItem = statusItem else { return }
            menuBarMenuController.showMenu(
                relativeTo: statusItem,
                onOpenTexTab: { [weak self] in
                    self?.showPopover()
                },
                onSettings: { [weak self] in
                    self?.openSettings()
                },
                onQuit: { [weak self] in
                    self?.quitApp()
                }
            )
        }
    }

    func setupGlobalHotkey() {
        let store = ActionsStore.shared
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5459504F) // "TYPO"
        hotKeyID.id = 1

        let modifiers = store.mainCarbonModifiers
        guard let keyCode = keyCodeForCharacter(store.mainShortcut.uppercased()) else { return }

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        print("Hotkey registered: \(store.mainShortcutModifiers.joined()) + \(store.mainShortcut)")
    }

    func setupActionHotkeys() {
        // Desregistrar hotkeys anteriores
        for hotKeyRef in actionHotKeyRefs {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        actionHotKeyRefs.removeAll()

        let actions = ActionsStore.shared.actions

        for (index, action) in actions.enumerated() {
            guard !action.shortcut.isEmpty,
                  let keyCode = keyCodeForCharacter(action.shortcut.uppercased()) else {
                continue
            }

            let modifiers = action.carbonModifiers

            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x5459504F) // "TYPO"
            hotKeyID.id = UInt32(index + 100) // IDs 100+ para acciones

            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

            if status == noErr {
                actionHotKeyRefs.append(hotKeyRef)
                print("Action hotkey registered: \(action.shortcutModifiers.joined()) + \(action.shortcut) for '\(action.name)'")
            }
        }

        // Instalar handler global para hotkeys de acciones
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            if hotKeyID.id == 1 {
                // Main popup hotkey
                globalAppDelegate?.pendingAction = nil
                globalAppDelegate?.showPopover()
            } else if hotKeyID.id >= 100 {
                // Action hotkey
                let actionIndex = Int(hotKeyID.id - 100)
                let actions = ActionsStore.shared.actions
                if actionIndex < actions.count {
                    globalAppDelegate?.pendingAction = actions[actionIndex]
                    globalAppDelegate?.showPopoverWithAction()
                }
            }

            return noErr
        }, 1, &eventType, nil, nil)
    }

    func keyCodeForCharacter(_ char: String) -> UInt32? {
        let keyMap: [String: UInt32] = [
            "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7,
            "C": 8, "V": 9, "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15,
            "Y": 16, "T": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
            "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
            "]": 30, "O": 31, "U": 32, "[": 33, "I": 34, "P": 35, "L": 37,
            "J": 38, "'": 39, "K": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
            "N": 45, "M": 46, ".": 47
        ]
        return keyMap[char]
    }

    func showPopoverWithAction() {
        // Guardar la app activa antes de mostrar el popup
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        // Capturar texto seleccionado antes de mostrar el popup
        captureSelectedText()

        // Recrear la ventana con la acción pendiente
        popoverWindow = nil
        createPopoverWindow(withAction: pendingAction)

        // Posicionar cerca del cursor o centro de pantalla - ventana más grande para acciones
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 560
            let windowHeight: CGFloat = 600
            let x = (screenRect.width - windowWidth) / 2 + screenRect.minX
            let y = (screenRect.height - windowHeight) / 2 + screenRect.minY

            popoverWindow?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        popoverWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Cerrar al hacer click fuera
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePopover()
        }

        pendingAction = nil
    }

    @objc func togglePopover() {
        if popoverWindow?.isVisible == true {
            hidePopover()
        } else {
            showPopover()
        }
    }

    @objc func showPopover() {
        // Guardar la app activa antes de mostrar el popup
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        // Capturar texto seleccionado antes de mostrar el popup
        captureSelectedText()

        // Recrear la ventana para que tome el nuevo texto
        popoverWindow = nil
        createPopoverWindow()

        // Posicionar cerca del cursor o centro de pantalla
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 320
            let windowHeight: CGFloat = 460
            let x = (screenRect.width - windowWidth) / 2 + screenRect.minX
            let y = (screenRect.height - windowHeight) / 2 + screenRect.minY

            popoverWindow?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        popoverWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Cerrar al hacer click fuera
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePopover()
        }
    }

    func captureSelectedText() {
        // Guardar el contenido actual del clipboard
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        // Simular Cmd+C para copiar el texto seleccionado
        let source = CGEventSource(stateID: .combinedSessionState)

        // Key down C con Cmd
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C
        cDown?.flags = .maskCommand

        // Key up C
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand

        // Ejecutar
        cDown?.post(tap: .cgSessionEventTap)
        cUp?.post(tap: .cgSessionEventTap)

        // Esperar un poco para que el sistema procese la copia
        usleep(100000) // 100ms

        // Guardar el texto capturado
        CapturedTextManager.shared.capturedText = pasteboard.string(forType: .string) ?? ""

        // Si no se copió nada nuevo, mantener lo que había (podría ser que no había selección)
        if CapturedTextManager.shared.capturedText.isEmpty {
            CapturedTextManager.shared.capturedText = oldContents ?? ""
        }
    }

    func hidePopover() {
        popoverWindow?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func hidePopoverAndRestoreFocus() {
        popoverWindow?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        // Restaurar el foco a la app anterior
        if let previousApp = previousActiveApp {
            previousApp.activate()
        }
    }

    func performPasteInPreviousApp() {
        // Cerrar el popup
        popoverWindow?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        // Restaurar el foco a la app anterior y pegar
        if let previousApp = previousActiveApp {
            previousApp.activate()

            // Esperar a que la app anterior tenga el foco
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Verificar permisos de accesibilidad
                guard AXIsProcessTrusted() else {
                    print("Accessibility permissions not granted")
                    return
                }

                // Simular Cmd+V para pegar
                let source = CGEventSource(stateID: .hidSystemState)

                if let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
                    vDown.flags = .maskCommand
                    vDown.post(tap: .cghidEventTap)
                }

                usleep(10000) // 10ms

                if let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                    vUp.flags = .maskCommand
                    vUp.post(tap: .cghidEventTap)
                }
            }
        }
    }

    func createPopoverWindow(withAction action: Action? = nil) {
        let contentView = PopoverView(onClose: { [weak self] in
            self?.hidePopover()
        }, onOpenSettings: { [weak self] in
            self?.hidePopover()
            self?.openSettings()
        }, initialAction: action)

        // Tamaño más grande para acciones directas
        let width: CGFloat = action != nil ? 560 : 320
        let height: CGFloat = action != nil ? 600 : 460

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.contentView = NSHostingView(rootView: contentView)
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false

        popoverWindow = panel
    }

    @objc func openSettings() {
        // Crear nueva ventana siempre para evitar problemas de memoria
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func suspendHotkeys() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        for ref in actionHotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        actionHotKeyRefs.removeAll()
    }

    func resumeHotkeys() {
        setupGlobalHotkey()
        setupActionHotkeys()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
