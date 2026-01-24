//
//  WelcomeStep.swift
//  typo
//

import SwiftUI

struct WelcomeStep: View {
    var onNext: () -> Void

    // Animation states
    @State private var waveOffset: CGFloat = 1000
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.8
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50
    @State private var wavePhase: CGFloat = 0

    private let brandBlue = Color(hex: "2196F3")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // White base - visible before waves rise
                Color.white
                    .ignoresSafeArea()

                // Single wave layer with gradient
                WelcomeWaveShape(phase: wavePhase, frequency: 2, amplitude: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0D47A1"),
                                Color(hex: "1976D2"),
                                Color(hex: "42A5F5"),
                                Color(hex: "4DD0E1")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geo.size.height + 500)
                    .offset(y: waveOffset)
                    .ignoresSafeArea()

                // Content - truly centered
                VStack(spacing: 50) {
                    // Main title - Nunito Black
                    VStack(spacing: -8) {
                        Text("Do it 10x")
                            .font(.custom("Nunito-Black", size: 56))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)

                        Text("faster")
                            .font(.custom("Nunito-Black", size: 56))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .scaleEffect(textScale)

                    // Get Started button
                    Button(action: onNext) {
                        Text("Get Started")
                            .font(.custom("Nunito-Bold", size: 17))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 52)
                            .background(
                                ZStack {
                                    // Bottom shadow layer (3D effect)
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(hex: "1565C0"))
                                        .offset(y: 5)

                                    // Main button
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(brandBlue)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .onAppear {
                // Wave rising animation - slower
                withAnimation(.easeOut(duration: 2.0)) {
                    waveOffset = -400
                }

                // Continuous wave animation - slower
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    wavePhase = .pi * 2
                }

                // Text animation
                withAnimation(.easeOut(duration: 0.8).delay(1.2)) {
                    textOpacity = 1
                    textScale = 1
                }

                // Button animation - elastic from bottom
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0).delay(1.6)) {
                    buttonOpacity = 1
                    buttonOffset = 0
                }
            }
        }
    }
}

// MARK: - Wave Shape

struct WelcomeWaveShape: Shape {
    var phase: CGFloat
    var frequency: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: rect.height))

        // Line to bottom right
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Line up right side
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Create wave at top edge going right to left
        for x in stride(from: rect.width, through: 0, by: -2) {
            let normalizedX = x / rect.width
            let y = sin(normalizedX * .pi * frequency + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()

        return path
    }
}
