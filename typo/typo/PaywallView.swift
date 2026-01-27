//
//  PaywallView.swift
//  typo
//
//  Paywall modal for TexTab Pro upgrade
//

import SwiftUI

struct PaywallView: View {
    @StateObject private var authManager = AuthManager.shared
    @Binding var isPresented: Bool
    var onUpgrade: (() -> Void)?

    // Green accent color like the design
    private let accentGreen = Color(hex: "00CE44")
    private let darkGreen = Color(hex: "00B03A")

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 4) {
                Text("Yearly")
                    .font(.nunitoBold(size: 24))
                    .foregroundColor(.white)

                Text("Unlock Full Potential")
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 2)
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 2)
                }
                .padding(.horizontal, 20),
                alignment: .bottom
            )

            // Price section
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$1.25")
                        .font(.custom("Nunito-Black", size: 48))
                        .foregroundColor(.white)

                    Text("/ month")
                        .font(.nunitoBold(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                Text("Billed yearly at $14.99")
                    .font(.nunitoRegularBold(size: 12))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.vertical, 16)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 2)
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 2)
                }
                .padding(.horizontal, 20),
                alignment: .bottom
            )

            // Features list
            VStack(alignment: .leading, spacing: 10) {
                PaywallCheckItem(text: "Unlimited actions")
                PaywallCheckItem(text: "All TexTab features")
                PaywallCheckItem(text: "Priority support")
                PaywallCheckItem(text: "Free updates")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // CTA Button - white with 3D effect
            Button(action: {
                if authManager.isAuthenticated {
                    authManager.openStripePayment()
                    onUpgrade?()
                } else {
                    isPresented = false
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenAccountTab"),
                        object: nil
                    )
                }
            }) {
                Text(authManager.isAuthenticated ? "Get started" : "Sign in to upgrade")
                    .font(.nunitoBold(size: 14))
                    .foregroundColor(Color(hex: "262626"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            // Shadow/3D layer
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color(hex: "E3E3E3"))
                                .offset(y: 4)

                            // Main button
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.white)
                        }
                    )
            }
            .buttonStyle(.plain)
            .pointerCursor()
            .padding(.horizontal, 20)

            // Close button
            Button(action: {
                isPresented = false
            }) {
                Text("Maybe later")
                    .font(.nunitoRegularBold(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .pointerCursor()
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(accentGreen)
        )
        .overlay(
            // Save badge con flama que sobresale
            ZStack {
                // Badge base
                HStack(spacing: 4) {
                    Text("Save 33%")
                        .font(.nunitoBold(size: 11))
                        .foregroundColor(.white)

                    // Espacio para la flama
                    Color.clear.frame(width: 14, height: 1)
                }
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 6)
                .background(
                    ZStack {
                        // Main badge background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "262626"))

                        // Top inner highlight/gradient for 3D effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "222222"), lineWidth: 2)
                )

                // Flama en capa superior (fuera del clipping del badge)
                AnimatedFlameIcon()
                    .offset(x: 32, y: -6)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .offset(y: -12),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Check Item

struct PaywallCheckItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)

            Text(text)
                .font(.nunitoBold(size: 13))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Paywall Modifier

struct PaywallModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onUpgrade: (() -> Void)?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }

                PaywallView(isPresented: $isPresented, onUpgrade: onUpgrade)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func paywall(isPresented: Binding<Bool>, onUpgrade: (() -> Void)? = nil) -> some View {
        modifier(PaywallModifier(isPresented: isPresented, onUpgrade: onUpgrade))
    }
}

// MARK: - Animated Flame Icon (Lottie)

struct AnimatedFlameIcon: View {
    var body: some View {
        // La animación original es 617x812, necesitamos escalarla
        LottieView(name: "flame")
            .frame(width: 617, height: 812)
            .scaleEffect(0.04)
            .frame(width: 20, height: 26)
            .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    PaywallView(isPresented: .constant(true))
}
