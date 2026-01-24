//
//  OnboardingView.swift
//  typo
//

import SwiftUI
import AppKit
import Combine

// MARK: - Onboarding Manager

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasCompletedOnboardingKey = "typo_has_completed_onboarding"
    private let licenseKeyKey = "typo_license_key"
    private let isLicenseValidKey = "typo_is_license_valid"

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }

    @Published var licenseKey: String {
        didSet {
            UserDefaults.standard.set(licenseKey, forKey: licenseKeyKey)
        }
    }

    @Published var isLicenseValid: Bool {
        didSet {
            UserDefaults.standard.set(isLicenseValid, forKey: isLicenseValidKey)
        }
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        self.licenseKey = UserDefaults.standard.string(forKey: licenseKeyKey) ?? ""
        self.isLicenseValid = UserDefaults.standard.bool(forKey: isLicenseValidKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        licenseKey = ""
        isLicenseValid = false
    }

    func validateLicense(_ key: String) async -> Bool {
        // TODO: Implement actual license validation with your server
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Validate 32 alphanumeric characters (UUID format without dashes)
        let pattern = "^[A-Z0-9]{32}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(trimmedKey.startIndex..., in: trimmedKey)

        if regex?.firstMatch(in: trimmedKey, options: [], range: range) != nil {
            // Format with dashes for storage (8-4-4-4-12)
            let formatted = "\(trimmedKey.prefix(8))-\(trimmedKey.dropFirst(8).prefix(4))-\(trimmedKey.dropFirst(12).prefix(4))-\(trimmedKey.dropFirst(16).prefix(4))-\(trimmedKey.dropFirst(20))"
            licenseKey = formatted
            isLicenseValid = true
            return true
        }

        return false
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentStep = 0
    @State private var licenseInput = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onComplete: () -> Void

    private let totalSteps = 4

    // Brand colors - matching TypoTap style
    private let brandBlue = Color(hex: "2196F3")
    private let brandBlueDark = Color(hex: "1976D2")
    private let brandBlueLight = Color(hex: "64B5F6")
    private let brandCyan = Color(hex: "4DD0E1")

    var body: some View {
        Group {
            switch currentStep {
            case 0:
                WelcomeStep(onNext: nextStep)
            case 1:
                FeaturesStep(onNext: nextStep, onBack: previousStep)
            case 2:
                PermissionsStep(onNext: nextStep, onBack: previousStep)
            case 3:
                ActivationStep(
                    licenseInput: $licenseInput,
                    isValidating: $isValidating,
                    showError: $showError,
                    errorMessage: $errorMessage,
                    onActivate: activateLicense,
                    onBack: previousStep
                )
            default:
                EmptyView()
            }
        }
        .frame(width: 800, height: 520)
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < totalSteps - 1 {
                currentStep += 1
            }
        }
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }

    private func activateLicense() {
        isValidating = true
        showError = false

        Task {
            let isValid = await onboardingManager.validateLicense(licenseInput)

            await MainActor.run {
                isValidating = false

                if isValid {
                    onboardingManager.completeOnboarding()
                    onComplete()
                } else {
                    showError = true
                    errorMessage = "Invalid license key. Use format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
                }
            }
        }
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    var onNext: () -> Void

    var body: some View {
        ZStack {
            // Gradient background like TypoTap
            LinearGradient(
                colors: [
                    Color(hex: "1E88E5"),
                    Color(hex: "42A5F5"),
                    Color(hex: "4DD0E1")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main title - bold, white, centered
                VStack(spacing: 6) {
                    Text("Meet your")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("new writing assistant")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Get Started button - glassmorphism style
                Button(action: onNext) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

// MARK: - Step 2: Features

struct FeaturesStep: View {
    var onNext: () -> Void
    var onBack: () -> Void

    private let features = [
        FeatureItem(icon: "wand.and.stars", title: "AI Transformations", description: "Fix grammar, rephrase, translate instantly"),
        FeatureItem(icon: "globe", title: "Web Search", description: "Search with Perplexity AI integration"),
        FeatureItem(icon: "keyboard", title: "Global Shortcuts", description: "Works anywhere with custom hotkeys"),
        FeatureItem(icon: "puzzlepiece.extension", title: "Plugins", description: "QR codes, color picker, and more")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1E88E5"),
                    Color(hex: "42A5F5"),
                    Color(hex: "4DD0E1")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 16)

                Text("What Typo can do")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Features grid
                VStack(spacing: 12) {
                    ForEach(features) { feature in
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: feature.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }

                            // Text
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(feature.description)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 60)

                Spacer()

                // Navigation
                HStack(spacing: 14) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onNext) {
                        HStack(spacing: 6) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
                    .frame(height: 30)
            }
        }
    }
}

struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Step 3: Permissions (Split Layout like TypoTap)

struct PermissionsStep: View {
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var hasAccessibilityPermission = false
    @State private var isWaiting = false
    @State private var rotationAngle: Double = 0
    @State private var permissionCheckTimer: Timer?

    // Colors
    private let accentRed = Color(hex: "E53935")
    private let accentRedDark = Color(hex: "C62828")
    private let accentGreen = Color(hex: "43A047")
    private let accentGreenDark = Color(hex: "2E7D32")
    private let stepBlue = Color(hex: "2196F3")

    var body: some View {
        HStack(spacing: 0) {
            // Left side - White with instructions
            ZStack(alignment: .trailing) {
                Color.white

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 40)

                    Text("Accessibility")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1a1a1a"))

                    Spacer()
                        .frame(height: 10)

                    Text("Accessibility permissions are required\nfor Typo to function.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(3)

                    Spacer()
                        .frame(height: 24)

                    // Steps
                    VStack(spacing: 12) {
                        StepRow(number: 1, text: "Click 'Grant Permissions'")
                        StepRow(number: 2, text: "Find Typo in the list")
                        StepRow(number: 3, text: "Enable using the toggle")
                    }

                    Spacer()
                        .frame(height: 16)

                    // Help link
                    Button(action: {}) {
                        Text("I need help")
                            .font(.system(size: 13))
                            .foregroundColor(stepBlue)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // 3D Duolingo-style button
                    Button(action: grantPermissions) {
                        Text("Grant Permissions")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                ZStack {
                                    // Bottom shadow layer (3D effect)
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(hasAccessibilityPermission ? accentGreenDark : accentRedDark)
                                        .offset(y: 4)

                                    // Main button
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(hasAccessibilityPermission ? accentGreen : accentRed)
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(hasAccessibilityPermission)

                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 32)
                .padding(.trailing, 24)

                // Wavy edge
                WavyEdge(isGreen: hasAccessibilityPermission)
                    .frame(width: 22)
                    .offset(x: 10)
            }
            .frame(width: 340)

            // Right side - Red/Green with status
            ZStack {
                (hasAccessibilityPermission ? accentGreen : accentRed)
                    .animation(.easeInOut(duration: 0.5), value: hasAccessibilityPermission)

                // Decorative icons scattered
                GeometryReader { geo in
                    ForEach(0..<8, id: \.self) { index in
                        let icons = ["xmark.circle", "exclamationmark.triangle", "shield.slash", "hand.raised.slash", "nosign", "circle.slash", "xmark.octagon", "exclamationmark.circle"]
                        let positions: [(CGFloat, CGFloat)] = [
                            (0.85, 0.12), (0.15, 0.25), (0.80, 0.35),
                            (0.20, 0.55), (0.75, 0.60), (0.10, 0.75),
                            (0.85, 0.80), (0.50, 0.90)
                        ]

                        Image(systemName: hasAccessibilityPermission ? "checkmark.circle" : icons[index % icons.count])
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.15))
                            .position(
                                x: geo.size.width * positions[index].0,
                                y: geo.size.height * positions[index].1
                            )
                    }
                }

                // Status indicator
                HStack(spacing: 10) {
                    Image(systemName: hasAccessibilityPermission ? "checkmark" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hasAccessibilityPermission ? accentGreen : accentRed)
                        .rotationEffect(.degrees(hasAccessibilityPermission ? 0 : rotationAngle))

                    Text(hasAccessibilityPermission ? "Permission Granted!" : "Waiting for Permissions")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(hasAccessibilityPermission ? accentGreen : accentRed)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            checkAccessibilityPermission()
            startRotationAnimation()
            startPermissionCheck()
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
        }
        .onChange(of: hasAccessibilityPermission) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onNext()
                }
            }
        }
    }

    private func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    private func startPermissionCheck() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkAccessibilityPermission()
        }
    }

    private func startRotationAnimation() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }

    private func grantPermissions() {
        isWaiting = true
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// Smooth wavy edge shape with rounded zigzag
struct WavyEdge: View {
    let isGreen: Bool

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let waveDepth: CGFloat = 10
                let waveHeight: CGFloat = 14

                // Start from top-right corner
                path.move(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: waveDepth, y: height))

                // Zigzag from bottom to top
                var y: CGFloat = height
                var toLeft = true

                while y > 0 {
                    let endY = max(y - waveHeight, 0)
                    let endX: CGFloat = toLeft ? 0 : waveDepth

                    // Simple rounded corner to next point
                    path.addQuadCurve(
                        to: CGPoint(x: endX, y: endY),
                        control: CGPoint(x: toLeft ? 0 : waveDepth, y: y - waveHeight / 2)
                    )

                    y = endY
                    toLeft.toggle()
                }

                path.addLine(to: CGPoint(x: width, y: 0))
                path.closeSubpath()
            }
            .fill(isGreen ? Color(hex: "43A047") : Color(hex: "E53935"))
        }
        .animation(.easeInOut(duration: 0.5), value: isGreen)
    }
}

// Step row component
struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color(hex: "2196F3"))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "333333"))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "e8e8e8"), lineWidth: 1)
        )
    }
}

// MARK: - License Dots Input Component

struct LicenseDotsInput: View {
    @Binding var licenseInput: String
    @FocusState private var isFocused: Bool

    // Format: 8-4-4-4-12 = 32 chars total
    // 4 rows: row 0 = 8, row 1 = 4-4, row 2 = 4, row 3 = 12
    private let totalChars = 32
    private let charsPerRow = 8

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hidden TextField to capture input
            TextField("", text: $licenseInput)
                .textFieldStyle(.plain)
                .opacity(0.01)
                .focused($isFocused)
                .onChange(of: licenseInput) { _, newValue in
                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    if cleaned.count <= totalChars {
                        licenseInput = cleaned
                    } else {
                        licenseInput = String(cleaned.prefix(totalChars))
                    }
                }

            // 4 rows of 8 dots each
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<charsPerRow, id: \.self) { col in
                            let charIndex = row * charsPerRow + col
                            let hasChar = charIndex < licenseInput.count

                            ZStack {
                                // Dot (hidden when char is typed)
                                Circle()
                                    .fill(Color(hex: "c0c0c0"))
                                    .frame(width: 8, height: 8)
                                    .opacity(hasChar ? 0 : 1)

                                // Character
                                if hasChar {
                                    let index = licenseInput.index(licenseInput.startIndex, offsetBy: charIndex)
                                    Text(String(licenseInput[index]))
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(hex: "555555"))
                                }
                            }
                            .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Step 4: Activation (Split Layout like TypoTap)

struct ActivationStep: View {
    @Binding var licenseInput: String
    @Binding var isValidating: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String

    var onActivate: () -> Void
    var onBack: () -> Void

    private let brandBlue = Color(hex: "2196F3")

    var body: some View {
        HStack(spacing: 0) {
            // Left side - White form
            ZStack(alignment: .trailing) {
                Color.white

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 40)

                    Text("Activate")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1a1a1a"))

                    Spacer()
                        .frame(height: 10)

                    Text("To continue, please activate your\nlicense of Typo.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(3)

                    Spacer()
                        .frame(height: 30)

                    Text("Enter your license key below.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "999999"))

                    Spacer()
                        .frame(height: 14)

                    // License key dots input
                    LicenseDotsInput(licenseInput: $licenseInput)

                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }

                    Spacer()

                    // 3D Duolingo-style Activate button
                    Button(action: onActivate) {
                        HStack(spacing: 8) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isValidating ? "Validating..." : "Activate")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(licenseInput.count >= 32 ? .white : Color(hex: "999999"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            ZStack {
                                // Bottom shadow layer (3D effect)
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(licenseInput.count >= 32 ? Color(hex: "E65100") : Color(hex: "cccccc"))
                                    .offset(y: 4)

                                // Main button
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(licenseInput.count >= 32 ? Color(hex: "FF9500") : Color(hex: "e0e0e0"))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseInput.count < 32 || isValidating)

                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 32)
                .padding(.trailing, 24)

                // Wavy edge
                WavyEdgeBlue()
                    .frame(width: 22)
                    .offset(x: 10)
            }
            .frame(width: 340)

            // Right side - Blue with app icon
            ZStack {
                brandBlue

                // App icon in rounded frame
                ZStack {
                    // Outer glow/frame
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )

                    // Inner icon container
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "ffecd2"), Color(hex: "fcb69f")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)

                    // Icon
                    Image(systemName: "text.cursor")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundColor(Color(hex: "d4a574"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }
}

// Smooth wavy edge for blue section with rounded zigzag
struct WavyEdgeBlue: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let waveDepth: CGFloat = 10
                let waveHeight: CGFloat = 14

                // Start from top-right corner
                path.move(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: waveDepth, y: height))

                // Zigzag from bottom to top
                var y: CGFloat = height
                var toLeft = true

                while y > 0 {
                    let endY = max(y - waveHeight, 0)
                    let endX: CGFloat = toLeft ? 0 : waveDepth

                    // Simple rounded corner to next point
                    path.addQuadCurve(
                        to: CGPoint(x: endX, y: endY),
                        control: CGPoint(x: toLeft ? 0 : waveDepth, y: y - waveHeight / 2)
                    )

                    y = endY
                    toLeft.toggle()
                }

                path.addLine(to: CGPoint(x: width, y: 0))
                path.closeSubpath()
            }
            .fill(Color(hex: "2196F3"))
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
