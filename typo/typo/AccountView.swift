//
//  AccountView.swift
//  typo
//
//  Account settings view for TexTab
//

import SwiftUI

struct AccountView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showPasswordResetSent = false

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if authManager.isAuthenticated {
                    loggedInView
                } else {
                    loginView
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .alert("Password Reset Sent", isPresented: $showPasswordResetSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your email for a password reset link.")
        }
    }

    // MARK: - Logged In View

    private var loggedInView: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Account")
                    .font(.nunitoBold(size: 24))
                    .foregroundColor(.primary)
                Spacer()
            }

            // User Info Card
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(appBlue.opacity(0.1))
                            .frame(width: 60, height: 60)

                        Text(String(authManager.currentUser?.email?.prefix(1).uppercased() ?? "U"))
                            .font(.nunitoBold(size: 24))
                            .foregroundColor(appBlue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.currentUser?.email ?? "User")
                            .font(.nunitoBold(size: 16))
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Image(systemName: authManager.isPro ? "checkmark.seal.fill" : "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(authManager.isPro ? .green : .secondary)

                            Text(authManager.isPro ? "Pro Member" : "Free Plan")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(authManager.isPro ? .green : .secondary)
                        }
                    }

                    Spacer()

                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )

            Divider()

            // Subscription Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Subscription")
                    .font(.nunitoBold(size: 18))
                    .foregroundColor(.primary)

                if authManager.isPro {
                    // Pro subscription info
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("TexTab Pro")
                                    .font(.nunitoBold(size: 16))
                                    .foregroundColor(.primary)
                            }

                            if let endDate = authManager.subscriptionEndDate {
                                Text("Renews on \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.nunitoRegularBold(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Text("Unlimited actions")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(.green)
                        }

                        Spacer()

                        Button(action: {
                            // Open subscription management
                            if let url = URL(string: "https://billing.stripe.com/p/login/test") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("Manage")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(appBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(appBlue.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    // Free plan - upgrade prompt
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Free Plan")
                                    .font(.nunitoBold(size: 16))
                                    .foregroundColor(.primary)

                                Text("5 actions limit")
                                    .font(.nunitoRegularBold(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Divider()

                        // Upgrade benefits
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upgrade to Pro")
                                .font(.nunitoBold(size: 16))
                                .foregroundColor(.primary)

                            FeatureRow(icon: "infinity", text: "Unlimited actions")
                            FeatureRow(icon: "bolt.fill", text: "Priority support")
                            FeatureRow(icon: "heart.fill", text: "Support development")
                        }

                        Button(action: {
                            authManager.openStripePayment()
                        }) {
                            HStack {
                                Text("Upgrade for $14.99/year")
                                    .font(.nunitoBold(size: 15))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(appBlue)
                            )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
            }

            // Refresh subscription button
            if authManager.isAuthenticated {
                Button(action: {
                    Task {
                        await authManager.refreshSubscription()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Refresh subscription status")
                            .font(.nunitoRegularBold(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }

            Spacer()
        }
    }

    // MARK: - Login View

    private var loginView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image("logo textab")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.nunitoBold(size: 24))
                    .foregroundColor(.primary)

                Text(isSignUp ? "Sign up to sync your actions" : "Sign in to your account")
                    .font(.nunitoRegularBold(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Form
            VStack(spacing: 16) {
                // Email field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.nunitoRegularBold(size: 13))
                        .foregroundColor(.secondary)

                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.plain)
                        .font(.nunitoRegularBold(size: 14))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Password field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.nunitoRegularBold(size: 13))
                        .foregroundColor(.secondary)

                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.plain)
                        .font(.nunitoRegularBold(size: 14))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Forgot password (only for sign in)
                if !isSignUp {
                    HStack {
                        Spacer()
                        Button(action: {
                            forgotPasswordEmail = email
                            showForgotPassword = true
                        }) {
                            Text("Forgot password?")
                                .font(.nunitoRegularBold(size: 12))
                                .foregroundColor(appBlue)
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                }

                // Error message
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.nunitoRegularBold(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // Submit button
                Button(action: {
                    Task {
                        do {
                            if isSignUp {
                                try await authManager.signUp(email: email, password: password)
                            } else {
                                try await authManager.signIn(email: email, password: password)
                            }
                        } catch {
                            await MainActor.run {
                                authManager.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.nunitoBold(size: 15))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(appBlue)
                    )
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .font(.nunitoRegularBold(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 4)

                // Google Sign In button
                Button(action: {
                    authManager.signInWithGoogle()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                        Text("Continue with Google")
                            .font(.nunitoBold(size: 15))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .pointerCursor()

                // Toggle sign up/sign in
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(.nunitoRegularBold(size: 13))
                        .foregroundColor(.secondary)

                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            authManager.errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .font(.nunitoBold(size: 13))
                            .foregroundColor(appBlue)
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )

            Spacer()
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.nunitoBold(size: 20))

            Text("Enter your email and we'll send you a link to reset your password.")
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Email", text: $forgotPasswordEmail)
                .textFieldStyle(.plain)
                .font(.nunitoRegularBold(size: 14))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button("Cancel") {
                    showForgotPassword = false
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        do {
                            try await authManager.sendPasswordReset(email: forgotPasswordEmail)
                            showForgotPassword = false
                            showPasswordResetSent = true
                        } catch {
                            authManager.errorMessage = error.localizedDescription
                        }
                    }
                }) {
                    Text("Send Reset Link")
                        .font(.nunitoBold(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(appBlue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(forgotPasswordEmail.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 20)

            Text(text)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    AccountView()
        .frame(width: 600, height: 700)
}
