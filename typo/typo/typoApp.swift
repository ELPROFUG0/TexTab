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

// Manager para compartir el texto capturado
class CapturedTextManager: ObservableObject {
    static let shared = CapturedTextManager()
    @Published var capturedText: String = ""
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popoverWindow: NSWindow?
    var settingsWindow: NSWindow?
    var eventMonitor: Any?
    var localEventMonitor: Any?
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        globalAppDelegate = self
        registerCustomFonts()
        setupMenuBar()
        setupGlobalHotkey()
        setupLocalEscapeMonitor()

        // Ocultar del dock (solo menu bar)
        NSApp.setActivationPolicy(.accessory)
    }

    func registerCustomFonts() {
        // Debug: Print bundle path
        print("Bundle path: \(Bundle.main.bundlePath)")

        // Try to find the font in different locations
        // Register both Nunito Bold and ExtraBold
        let fontFiles = ["Nunito-Bold", "Nunito-ExtraBold"]

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
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Typo")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            // Click derecho: mostrar menú
            let menu = NSMenu()

            let openItem = NSMenuItem(title: "Open Typo", action: #selector(showPopover), keyEquivalent: "")
            openItem.target = self
            menu.addItem(openItem)

            let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)

            menu.addItem(NSMenuItem.separator())

            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)

            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Click izquierdo: abrir popup
            togglePopover()
        }
    }

    func setupGlobalHotkey() {
        // Usar Carbon API para registrar hotkey global (más confiable)
        // Cmd + Shift + T (keyCode 17 = T)
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5459504F) // "TYPO"
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        // Instalar el handler
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            globalAppDelegate?.showPopover()
            return noErr
        }, 1, &eventType, nil, nil)

        // Registrar Cmd + Shift + T
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(17) // T key

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        print("Hotkey registered: Cmd + Shift + T")
    }

    @objc func togglePopover() {
        if popoverWindow?.isVisible == true {
            hidePopover()
        } else {
            showPopover()
        }
    }

    @objc func showPopover() {
        // Capturar texto seleccionado antes de mostrar el popup
        captureSelectedText()

        // Recrear la ventana para que tome el nuevo texto
        popoverWindow = nil
        createPopoverWindow()

        // Posicionar cerca del cursor o centro de pantalla
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 340
            let windowHeight: CGFloat = 420
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

    func createPopoverWindow() {
        let contentView = PopoverView(onClose: { [weak self] in
            self?.hidePopover()
        }, onOpenSettings: { [weak self] in
            self?.hidePopover()
            self?.openSettings()
        })

        popoverWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        popoverWindow?.isOpaque = false
        popoverWindow?.backgroundColor = .clear
        popoverWindow?.level = .floating
        popoverWindow?.contentView = NSHostingView(rootView: contentView)
        popoverWindow?.hasShadow = true
    }

    @objc func openSettings() {
        // Crear nueva ventana siempre para evitar problemas de memoria
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 540),
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

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
