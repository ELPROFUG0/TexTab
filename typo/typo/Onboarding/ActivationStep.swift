//
//  ActivationStep.swift
//  typo
//

import SwiftUI

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

                    Text("To continue, please activate your\nlicense of TexTab.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(3)

                    Spacer()
                        .frame(height: 30)

                    Text("Enter your license key below.")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "333333"))

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
                        .foregroundColor(licenseInput.filter({ $0 != "-" }).count >= 32 ? .white : Color(hex: "999999"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            ZStack {
                                // Bottom shadow layer (3D effect) - lighter color
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(licenseInput.filter({ $0 != "-" }).count >= 32 ? Color(hex: "58d965") : Color(hex: "e0e0e0"))
                                    .offset(y: 5)

                                // Main button - original color
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(licenseInput.filter({ $0 != "-" }).count >= 32 ? Color(hex: "00ce44") : Color(hex: "cccccc"))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseInput.filter({ $0 != "-" }).count < 32 || isValidating)

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

// MARK: - License Dots Input Component

struct LicenseDotsInput: View {
    @Binding var licenseInput: String
    @FocusState private var isFocused: Bool
    @State private var cursorVisible = true

    private let totalChars = 32
    private let dotsPerRow = 16
    private let totalRows = 3

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hidden TextField to capture input
            TextField("", text: $licenseInput)
                .textFieldStyle(.plain)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isFocused)
                .onChange(of: licenseInput) { _, newValue in
                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                    if cleaned.count <= totalChars + 4 { // 32 chars + 4 dashes max
                        licenseInput = cleaned
                    } else {
                        licenseInput = String(cleaned.prefix(totalChars + 4))
                    }
                }

            // 2 full rows of 16 + 1 row of 4 dots (36 total for 32 chars + 4 dashes)
            VStack(alignment: .leading, spacing: 18) {
                ForEach(0..<totalRows, id: \.self) { row in
                    let dotsInThisRow = row < 2 ? dotsPerRow : 4 // Last row only has 4 dots
                    HStack(spacing: 6) {
                        ForEach(0..<dotsInThisRow, id: \.self) { col in
                            let dotIndex = row * dotsPerRow + col
                            let hasChar = dotIndex < licenseInput.count
                            let isCursorPosition = dotIndex == licenseInput.count && isFocused

                            ZStack {
                                // Dot (hidden when char is typed or cursor is here)
                                Circle()
                                    .fill(Color(hex: "d0d0d0"))
                                    .frame(width: 3, height: 3)
                                    .opacity(hasChar || isCursorPosition ? 0 : 1)

                                // Character
                                if hasChar {
                                    let index = licenseInput.index(licenseInput.startIndex, offsetBy: dotIndex)
                                    Text(String(licenseInput[index]))
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(hex: "555555"))
                                }

                                // Cursor
                                if isCursorPosition {
                                    Rectangle()
                                        .fill(Color(hex: "2196F3"))
                                        .frame(width: 2, height: 14)
                                        .opacity(cursorVisible ? 1 : 0)
                                }
                            }
                            .frame(width: 9, height: 16)
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
            startCursorBlink()
        }
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                startCursorBlink()
            }
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }
}

// MARK: - Wavy Edge Blue

struct WavyEdgeBlue: View {
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
            .fill(Color(hex: "2196F3"))
        }
    }
}
