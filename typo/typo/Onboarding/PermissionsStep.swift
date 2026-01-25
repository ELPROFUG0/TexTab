//
//  PermissionsStep.swift
//  typo
//

import SwiftUI
import AppKit

struct PermissionsStep: View {
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var hasAccessibilityPermission = false
    @State private var isWaiting = false
    @State private var rotationAngle: Double = 0
    @State private var permissionCheckTimer: Timer?
    @State private var floatAnimationActive = false

    // Colors
    private let accentYellow = Color(hex: "F9A825")
    private let accentYellowDark = Color(hex: "F57F17")
    private let accentGreen = Color(hex: "00ce44")
    private let accentGreenDark = Color(hex: "00a838")
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

                    Text("Accessibility permissions are required\nfor TexTab to function.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(3)

                    Spacer()
                        .frame(height: 24)

                    // Steps or Features
                    if hasAccessibilityPermission {
                        // Show simple feature list when permission is granted
                        VStack(alignment: .leading, spacing: 14) {
                            PermissionCheckItem(text: "Global keyboard shortcuts")
                            PermissionCheckItem(text: "Text selection detection")
                            PermissionCheckItem(text: "Paste transformed text")
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            StepRow(number: 1, text: "Click 'Grant Permissions'")
                            StepRow(number: 2, text: "Find TexTab in the list")
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
                    }

                    Spacer()

                    // 3D Duolingo-style button
                    Button(action: {
                        if hasAccessibilityPermission {
                            onNext()
                        } else {
                            grantPermissions()
                        }
                    }) {
                        Text(hasAccessibilityPermission ? "Continue" : "Grant Permissions")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                ZStack {
                                    // Bottom shadow layer (3D effect) - lighter color
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(hasAccessibilityPermission ? Color(hex: "58d965") : Color(hex: "FFD54F"))
                                        .offset(y: 5)

                                    // Main button - original color
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(hasAccessibilityPermission ? Color(hex: "00ce44") : accentYellow)
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
                WavyEdge(isGreen: hasAccessibilityPermission)
                    .frame(width: 22)
                    .offset(x: 10)
            }
            .frame(width: 340)

            // Right side - Yellow/Green with status
            ZStack {
                (hasAccessibilityPermission ? accentGreen : accentYellow)
                    .animation(.easeInOut(duration: 0.5), value: hasAccessibilityPermission)

                // Floating decorative icons with premium animation
                GeometryReader { geo in
                    ForEach(0..<8, id: \.self) { index in
                        FloatingIcon(
                            index: index,
                            isGranted: hasAccessibilityPermission,
                            geoSize: geo.size,
                            isAnimating: floatAnimationActive
                        )
                    }
                }

                // Status indicator
                HStack(spacing: 10) {
                    ZStack {
                        // Spinning reload icon (fades out when granted)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentYellow)
                            .rotationEffect(.degrees(rotationAngle))
                            .opacity(hasAccessibilityPermission ? 0 : 1)
                            .scaleEffect(hasAccessibilityPermission ? 0.5 : 1)

                        // Checkmark (fades in when granted)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentGreen)
                            .opacity(hasAccessibilityPermission ? 1 : 0)
                            .scaleEffect(hasAccessibilityPermission ? 1 : 0.5)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: hasAccessibilityPermission)

                    Text(hasAccessibilityPermission ? "Permission Granted!" : "Waiting for Permissions")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(hasAccessibilityPermission ? accentGreen : accentYellow)
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
            // Start floating animation
            withAnimation {
                floatAnimationActive = true
            }
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
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

// MARK: - Floating Icon Component

struct FloatingIcon: View {
    let index: Int
    let isGranted: Bool
    let geoSize: CGSize
    let isAnimating: Bool

    @State private var floatOffset: CGFloat = 0
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0

    private let icons = ["xmark.circle", "exclamationmark.triangle", "shield.slash", "hand.raised.slash", "nosign", "circle.slash", "xmark.octagon", "exclamationmark.circle"]
    private let grantedIcons = ["checkmark.circle", "checkmark.seal", "hand.thumbsup", "star.fill", "sparkles", "heart.fill", "shield.checkered", "checkmark.circle.fill"]

    private let positions: [(CGFloat, CGFloat)] = [
        (0.85, 0.10), (0.12, 0.22), (0.82, 0.38),
        (0.18, 0.52), (0.78, 0.65), (0.08, 0.78),
        (0.88, 0.85), (0.50, 0.92)
    ]

    private let sizes: [CGFloat] = [22, 26, 20, 28, 24, 22, 26, 20]
    private let opacities: [Double] = [0.18, 0.22, 0.15, 0.25, 0.20, 0.17, 0.23, 0.16]

    // Different animation parameters for each icon
    private var floatDuration: Double {
        [3.2, 2.8, 3.5, 2.6, 3.0, 3.3, 2.9, 3.1][index]
    }

    private var floatDistance: CGFloat {
        [12, 15, 10, 18, 14, 11, 16, 13][index]
    }

    private var rotationAmount: Double {
        [8, -10, 12, -8, 10, -12, 8, -10][index]
    }

    private var animationDelay: Double {
        Double(index) * 0.15
    }

    var body: some View {
        Image(systemName: isGranted ? grantedIcons[index % grantedIcons.count] : icons[index % icons.count])
            .font(.system(size: sizes[index], weight: .medium))
            .foregroundColor(.white.opacity(opacities[index]))
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))
            .offset(y: floatOffset)
            .position(
                x: geoSize.width * positions[index].0,
                y: geoSize.height * positions[index].1
            )
            .onAppear {
                startFloatingAnimation()
            }
            .onChange(of: isGranted) { _, newValue in
                // Celebration animation when granted
                if newValue {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        iconScale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            iconScale = 1.0
                        }
                    }
                }
            }
    }

    private func startFloatingAnimation() {
        // Floating up and down
        withAnimation(
            .easeInOut(duration: floatDuration)
            .repeatForever(autoreverses: true)
            .delay(animationDelay)
        ) {
            floatOffset = floatDistance
        }

        // Gentle rotation
        withAnimation(
            .easeInOut(duration: floatDuration * 1.2)
            .repeatForever(autoreverses: true)
            .delay(animationDelay)
        ) {
            iconRotation = rotationAmount
        }
    }
}

// MARK: - Step Row Component

struct StepRow: View {
    let number: Int
    let text: String

    private let stepGreen = Color(hex: "00ce44")

    var body: some View {
        HStack(spacing: 12) {
            // Number circle
            ZStack {
                Circle()
                    .fill(stepGreen)
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
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e8e8e8"), lineWidth: 1)
                )
        )
    }
}

// MARK: - Permission Check Item

struct PermissionCheckItem: View {
    let text: String

    private let checkGreen = Color(hex: "00ce44")

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(checkGreen)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "333333"))
        }
    }
}

// MARK: - Wavy Edge

struct WavyEdge: View {
    let isGreen: Bool

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
            .fill(isGreen ? Color(hex: "00ce44") : Color(hex: "F9A825"))
        }
        .animation(.easeInOut(duration: 0.5), value: isGreen)
    }
}
