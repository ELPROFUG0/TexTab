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

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(16)

            // Content
            VStack(spacing: 24) {
                // Icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [appBlue, appBlue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    Text("Upgrade to Pro")
                        .font(.nunitoBold(size: 28))
                        .foregroundColor(.primary)

                    Text("You've reached the free limit of 5 actions.\nUpgrade to create unlimited actions.")
                        .font(.nunitoRegularBold(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    PaywallFeatureRow(
                        icon: "infinity",
                        title: "Unlimited Actions",
                        description: "Create as many actions as you need"
                    )

                    PaywallFeatureRow(
                        icon: "bolt.fill",
                        title: "Priority Support",
                        description: "Get help faster when you need it"
                    )

                    PaywallFeatureRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Free Updates",
                        description: "Access to all new features"
                    )

                    PaywallFeatureRow(
                        icon: "heart.fill",
                        title: "Support Development",
                        description: "Help us build more amazing features"
                    )
                }
                .padding(.horizontal, 20)

                Spacer()

                // Price and CTA
                VStack(spacing: 16) {
                    // Price
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$14.99")
                            .font(.nunitoBold(size: 36))
                            .foregroundColor(.primary)

                        Text("/ year")
                            .font(.nunitoRegularBold(size: 16))
                            .foregroundColor(.secondary)
                    }

                    Text("That's just $1.25/month")
                        .font(.nunitoRegularBold(size: 13))
                        .foregroundColor(.secondary)

                    // Upgrade button
                    Button(action: {
                        if authManager.isAuthenticated {
                            authManager.openStripePayment()
                            onUpgrade?()
                        } else {
                            // Need to sign in first
                            isPresented = false
                            // Notify to open account tab
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenAccountTab"),
                                object: nil
                            )
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(authManager.isAuthenticated ? "Upgrade Now" : "Sign In to Upgrade")
                                .font(.nunitoBold(size: 16))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(appBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    // Not now button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Maybe Later")
                            .font(.nunitoRegularBold(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 400, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Feature Row

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(appBlue.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(appBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.nunitoBold(size: 15))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(.secondary)
            }

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

// MARK: - Preview

#Preview {
    PaywallView(isPresented: .constant(true))
}
