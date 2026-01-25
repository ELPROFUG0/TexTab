//
//  ShortcutStep.swift
//  typo
//

import SwiftUI
import AppKit

struct ShortcutStep: View {
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var recordedKeys: [String] = []
    @State private var isRecording = false
    @State private var savedShortcutKeys: [String] = ["\u{2318}", "\u{21E7}", "T"] // Default: Command + Shift + T
    @State private var eventMonitor: Any?

    private let brandOrange = Color(hex: "ff7300")

    var body: some View {
        HStack(spacing: 0) {
            // Left side - White form
            ZStack(alignment: .trailing) {
                Color.white

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 40)

                    Text("Shortcut")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1a1a1a"))

                    Spacer()
                        .frame(height: 10)

                    Text("Set your keyboard shortcut to\nsummon TexTab from anywhere.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(3)

                    Spacer()
                        .frame(height: 40)

                    // Shortcut recorder with tooltip
                    VStack(spacing: 0) {
                        // Tooltip appears above when recording
                        if isRecording {
                            OnboardingShortcutTooltip(recordedKeys: recordedKeys)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                                    removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                                ))
                                .padding(.bottom, 8)
                        }

                        // Shortcut display box
                        Button(action: {
                            startRecording()
                        }) {
                            HStack(spacing: 8) {
                                if savedShortcutKeys.isEmpty {
                                    Text("Click to record shortcut...")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "999999"))
                                } else {
                                    ForEach(savedShortcutKeys, id: \.self) { key in
                                        OnboardingShortcutKey(text: key)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(hex: "f8f8f8"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .foregroundColor(Color(hex: "c0c0c0"))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recordedKeys)

                    Spacer()
                        .frame(height: 16)

                    Text("Click the box above to record a new\nshortcut. You can change this anytime in\nthe settings.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "999999"))
                        .lineSpacing(2)

                    Spacer()

                    // Next button
                    Button(action: {
                        saveShortcut()
                        onNext()
                    }) {
                        Text("Next")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                ZStack {
                                    // Bottom shadow layer (3D effect) - darker orange
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "cc5c00"))
                                        .offset(y: 5)

                                    // Main button
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(brandOrange)
                                }
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 32)
                .padding(.trailing, 24)

                // Wavy edge
                WavyEdgeOrange()
                    .frame(width: 22)
                    .offset(x: 10)
            }
            .frame(width: 340)

            // Right side - Orange with keyboard image
            ZStack {
                brandOrange

                VStack(spacing: 20) {
                    Spacer()

                    // Keyboard image
                    Image("keyboard")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 380)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                    // Animated hint tooltip
                    KeyboardHintTooltip()

                    Spacer()
                }
                .padding(30)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            loadCurrentShortcut()
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func loadCurrentShortcut() {
        let savedKeys = UserDefaults.standard.stringArray(forKey: "typo_shortcut_keys") ?? ["\u{2318}", "\u{21E7}", "T"]
        savedShortcutKeys = savedKeys
    }

    private func saveShortcut() {
        UserDefaults.standard.set(savedShortcutKeys, forKey: "typo_shortcut_keys")
    }

    private func startRecording() {
        stopRecording() // Clean up any existing monitor
        isRecording = true
        recordedKeys = []

        // Use local monitor for key events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }

            let modifiers = event.modifierFlags

            // Build current modifier keys array
            var currentModifiers: [String] = []
            if modifiers.contains(.control) { currentModifiers.append("^") }
            if modifiers.contains(.option) { currentModifiers.append("\u{2325}") }
            if modifiers.contains(.shift) { currentModifiers.append("\u{21E7}") }
            if modifiers.contains(.command) { currentModifiers.append("\u{2318}") }

            if event.type == .flagsChanged {
                // Update recorded keys to show current modifiers in real-time
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    self.recordedKeys = currentModifiers
                }
                return event
            }

            if event.type == .keyDown {
                // Must have Command or Option to complete
                let hasCommand = modifiers.contains(.command)
                let hasOption = modifiers.contains(.option)

                if !hasCommand && !hasOption {
                    // Ignore keys without Command or Option
                    return event
                }

                // Add the final key
                let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
                if !key.isEmpty && key.count == 1 {
                    var finalKeys = currentModifiers
                    finalKeys.append(key)

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.recordedKeys = finalKeys
                    }

                    // Save and close after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.savedShortcutKeys = finalKeys
                        withAnimation {
                            self.isRecording = false
                        }
                        self.stopRecording()
                    }
                    return nil
                }
            }
            return event
        }
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - Onboarding Shortcut Tooltip

struct OnboardingShortcutTooltip: View {
    let recordedKeys: [String]

    var body: some View {
        VStack(spacing: 0) {
            // Tooltip content
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("e.g.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "999999"))

                    // Always show 3 key slots
                    ForEach(0..<3, id: \.self) { index in
                        if index < recordedKeys.count {
                            OnboardingTooltipKey(text: recordedKeys[index])
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.5).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .id("key-\(index)-\(recordedKeys[index])")
                        } else {
                            OnboardingTooltipKey(text: "")
                                .opacity(0.4)
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text("Recording...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))

                    Text("Press \u{2318} or \u{2325} + key")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "999999"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e0e0e0"), lineWidth: 1)
            )

            // Arrow pointing down
            OnboardingTooltipArrow()
                .fill(Color.white)
                .frame(width: 16, height: 10)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - Onboarding Tooltip Key

struct OnboardingTooltipKey: View {
    let text: String

    var body: some View {
        ZStack {
            // Bottom layer (3D effect) - lighter color like container keys
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "d0d0d0"))
                .frame(width: 28, height: 28)
                .offset(y: 2)

            // Top layer - white like container keys
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "e0e0e0"), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "333333"))
        }
        .frame(width: 28, height: 30)
    }
}

// MARK: - Onboarding Tooltip Arrow

struct OnboardingTooltipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Onboarding Shortcut Key Display

struct OnboardingShortcutKey: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: "333333"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // 3D effect bottom
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "d0d0d0"))
                        .offset(y: 2)

                    // Top
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "e0e0e0"), lineWidth: 1)
                        )
                }
            )
    }
}

// MARK: - Keyboard Hint Tooltip (Animated)

struct KeyboardHintTooltip: View {
    @State private var activeKeyIndex = 0
    @State private var floatOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0.3

    private let keys = ["\u{2318}", "\u{2325}"] // Command, Option

    var body: some View {
        VStack(spacing: 0) {
            // Arrow pointing up to keyboard
            KeyboardHintArrow()
                .fill(Color.white)
                .frame(width: 16, height: 10)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: -2)

            // Tooltip content
            HStack(spacing: 12) {
                Text("Use")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))

                ForEach(0..<keys.count, id: \.self) { index in
                    KeyboardHintKey(
                        text: keys[index],
                        isActive: activeKeyIndex == index
                    )
                }

                Text("or")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "999999"))

                Text("+ key")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .offset(y: floatOffset)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Key highlight cycling animation
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                activeKeyIndex = (activeKeyIndex + 1) % keys.count
            }
        }

        // Floating animation
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -6
        }
    }
}

// MARK: - Keyboard Hint Key (with animation)

struct KeyboardHintKey: View {
    let text: String
    let isActive: Bool

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(hex: "1976D2") : Color(hex: "d0d0d0"))
                .frame(width: 32, height: 32)
                .offset(y: 2)

            // Top layer
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(hex: "2196F3") : Color.white)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color(hex: "1976D2") : Color(hex: "e0e0e0"), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? .white : Color(hex: "333333"))
        }
        .frame(width: 32, height: 34)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

// MARK: - Keyboard Hint Arrow (pointing up)

struct KeyboardHintArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Wavy Edge Orange

struct WavyEdgeOrange: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let notchRadius: CGFloat = 4
                let notchSpacing: CGFloat = 20

                // Start from top-right corner
                path.move(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))

                // Create semicircular notches from bottom to top (biting into the right/colored side)
                var y: CGFloat = height - notchSpacing / 2

                while y > 0 {
                    // Line up to notch
                    path.addLine(to: CGPoint(x: 0, y: y + notchRadius))

                    // Semicircle notch biting to the right (into the colored area)
                    path.addArc(
                        center: CGPoint(x: 0, y: y),
                        radius: notchRadius,
                        startAngle: .degrees(90),
                        endAngle: .degrees(-90),
                        clockwise: true
                    )

                    y -= notchSpacing
                }

                // Line to top
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: width, y: 0))
                path.closeSubpath()
            }
            .fill(Color(hex: "ff7300"))
        }
    }
}
