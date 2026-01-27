//
//  MenuBarMenuView.swift
//  typo
//
//  Created by content manager on 27/01/26.
//

import SwiftUI
import AppKit

struct MenuBarMenuView: View {
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("appTheme") private var appThemeString: String = "System"
    @State private var isVisible = false
    @State private var hoveredItem: String? = nil

    var onOpenTexTab: () -> Void
    var onSettings: () -> Void
    var onQuit: () -> Void
    var onDismiss: () -> Void

    var isDarkMode: Bool {
        switch appThemeString {
        case "Light": return false
        case "Dark": return true
        default: return systemColorScheme == .dark
        }
    }

    var backgroundColor: Color {
        isDarkMode
            ? Color(NSColor.windowBackgroundColor)
            : Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            // Menu items
            VStack(spacing: 2) {
                MenuBarMenuItemWithAsset(
                    assetName: "MenuBarIcon",
                    title: "Open TexTab",
                    isHovered: hoveredItem == "open",
                    isDarkMode: isDarkMode,
                    delay: 0.05
                ) {
                    onOpenTexTab()
                }
                .onHover { hovering in
                    hoveredItem = hovering ? "open" : nil
                }

                MenuBarMenuItem(
                    icon: "gearshape",
                    title: "Settings",
                    isHovered: hoveredItem == "settings",
                    isDarkMode: isDarkMode,
                    delay: 0.1
                ) {
                    onSettings()
                }
                .onHover { hovering in
                    hoveredItem = hovering ? "settings" : nil
                }

                // Separator
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.2).delay(0.15), value: isVisible)

                MenuBarMenuItem(
                    icon: "power",
                    title: "Quit",
                    isHovered: hoveredItem == "quit",
                    isDarkMode: isDarkMode,
                    isDestructive: true,
                    delay: 0.15
                ) {
                    onQuit()
                }
                .onHover { hovering in
                    hoveredItem = hovering ? "quit" : nil
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .frame(width: 170)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        )
        .scaleEffect(isVisible ? 1 : 0.8, anchor: .top)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isVisible = true
            }
        }
    }

    func dismiss() {
        withAnimation(.easeIn(duration: 0.15)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onDismiss()
        }
    }
}

struct MenuBarMenuItem: View {
    let icon: String
    let title: String
    let isHovered: Bool
    let isDarkMode: Bool
    var isDestructive: Bool = false
    let delay: Double
    let action: () -> Void

    @State private var isVisible = false

    var textColor: Color {
        if isDestructive && isHovered {
            return .white
        }
        return isDarkMode ? .white : Color(white: 0.15)
    }

    var iconColor: Color {
        if isDestructive && isHovered {
            return .white
        }
        return isDarkMode ? Color(white: 0.7) : Color(white: 0.4)
    }

    var hoverBackground: Color {
        if isDestructive {
            return Color.red.opacity(0.85)
        }
        return isDarkMode
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.06)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? hoverBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(y: isVisible ? 0 : -8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// Menu item with asset image instead of SF Symbol
struct MenuBarMenuItemWithAsset: View {
    let assetName: String
    let title: String
    let isHovered: Bool
    let isDarkMode: Bool
    var isDestructive: Bool = false
    let delay: Double
    let action: () -> Void

    @State private var isVisible = false

    var textColor: Color {
        if isDestructive && isHovered {
            return .white
        }
        return isDarkMode ? .white : Color(white: 0.15)
    }

    var iconColor: Color {
        if isDestructive && isHovered {
            return .white
        }
        return isDarkMode ? Color(white: 0.7) : Color(white: 0.4)
    }

    var hoverBackground: Color {
        if isDestructive {
            return Color.red.opacity(0.85)
        }
        return isDarkMode
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.06)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(assetName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(iconColor)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? hoverBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(y: isVisible ? 0 : -8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// Window controller for the menu
class MenuBarMenuWindowController: NSObject {
    private var menuWindow: NSWindow?
    private var eventMonitor: Any?

    func showMenu(relativeTo statusItem: NSStatusItem, onOpenTexTab: @escaping () -> Void, onSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        guard let button = statusItem.button else { return }

        // Close existing menu if any
        closeMenu()

        // Get button frame in screen coordinates
        guard let buttonWindow = button.window else { return }
        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)

        // Create the menu view
        let menuView = MenuBarMenuView(
            onOpenTexTab: { [weak self] in
                self?.closeMenu()
                onOpenTexTab()
            },
            onSettings: { [weak self] in
                self?.closeMenu()
                onSettings()
            },
            onQuit: { [weak self] in
                self?.closeMenu()
                onQuit()
            },
            onDismiss: { [weak self] in
                self?.closeMenu()
            }
        )

        let hostingView = NSHostingView(rootView: menuView)
        hostingView.setFrameSize(hostingView.fittingSize)

        // Create borderless window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: hostingView.fittingSize.width, height: hostingView.fittingSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = false // We handle shadow in SwiftUI

        // Position below the status item, centered
        let menuX = buttonFrameOnScreen.midX - (hostingView.fittingSize.width / 2)
        let menuY = buttonFrameOnScreen.minY - hostingView.fittingSize.height - 4
        window.setFrameOrigin(NSPoint(x: menuX, y: menuY))

        window.orderFront(nil)
        menuWindow = window

        // Monitor for clicks outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closeMenu()
        }

        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let menuWindow = self?.menuWindow,
               !NSPointInRect(NSEvent.mouseLocation, menuWindow.frame) {
                self?.closeMenu()
            }
            return event
        }
    }

    func closeMenu() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        menuWindow?.orderOut(nil)
        menuWindow = nil
    }

    var isMenuVisible: Bool {
        menuWindow != nil
    }
}
