//
//  AboutView.swift
//  typo
//
//  About view displaying user account info, stats and settings
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var actionsStore = ActionsStore.shared
    @StateObject private var updateChecker = UpdateChecker.shared
    @State private var showPaywall: Bool = false
    @State private var showUpdateAlert: Bool = false

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // Number of actions
    private var actionsCount: Int {
        actionsStore.actions.count
    }

    // Days since account creation
    private var daysSinceCreation: Int {
        guard let createdAtString = authManager.currentUser?.createdAt else { return 0 }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let createdDate = formatter.date(from: createdAtString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let createdDate = formatter.date(from: createdAtString) else { return 0 }
            return Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        }
        return Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
    }

    // Member since date formatted as MM/YY
    private var memberSinceDate: String {
        guard let createdAtString = authManager.currentUser?.createdAt else { return "--/--" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var createdDate = formatter.date(from: createdAtString)
        if createdDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            createdDate = formatter.date(from: createdAtString)
        }
        guard let date = createdDate else { return "--/--" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM/yy"
        return displayFormatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            // Left side - App Logo with stats
            VStack(spacing: 24) {
                // App Logo
                Image("logo textab")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)

                // Member since
                VStack(spacing: 4) {
                    Text("MEMBER SINCE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(1.5)

                    Text(memberSinceDate)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                // Stats row
                HStack(spacing: 36) {
                    // Actions
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("\(actionsCount)")
                                .font(.nunitoBlack(size: 36))
                                .foregroundColor(.primary)

                            Image(systemName: "laurel.trailing")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                        }

                        Text("Actions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Days
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("\(daysSinceCreation)")
                                .font(.nunitoBlack(size: 36))
                                .foregroundColor(.primary)

                            Image(systemName: "laurel.trailing")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                        }

                        Text("Days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 280)
            .padding(.top, 16)

            // Right side - Account info and Buttons
            VStack(alignment: .leading, spacing: 0) {
                // Account section
                VStack(spacing: 0) {
                    // User info row
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(appBlue.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Text(String(authManager.currentUser?.email?.prefix(1).uppercased() ?? "U"))
                                .font(.nunitoBold(size: 18))
                                .foregroundColor(appBlue)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(authManager.currentUser?.email ?? "User")
                                .font(.nunitoBold(size: 16))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            HStack(spacing: 5) {
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
                                .font(.nunitoRegularBold(size: 12))
                                .foregroundColor(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                    .padding(.vertical, 20)

                    Divider()

                    // Subscription row
                    HStack(spacing: 16) {
                        Image(systemName: authManager.isPro ? "creditcard" : "crown")
                            .font(.system(size: authManager.isPro ? 22 : 24))
                            .foregroundColor(Color.gray.opacity(0.45))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(authManager.isPro ? "Manage Subscription" : "Upgrade to Pro")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(authManager.isPro ? "Manage your plan" : "Unlimited actions")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            if authManager.isPro {
                                authManager.openStripePortal()
                            } else {
                                showPaywall = true
                            }
                        }) {
                            Text(authManager.isPro ? "Manage" : "Upgrade")
                                .font(.nunitoRegularBold(size: 12))
                                .foregroundColor(authManager.isPro ? .secondary : appBlue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(authManager.isPro ? Color.gray.opacity(0.1) : appBlue.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                    .padding(.vertical, 20)

                    Divider()

                    // Check for Updates row
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 22))
                            .foregroundColor(Color.gray.opacity(0.45))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Check for Updates")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Version \(updateChecker.currentVersion)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            updateChecker.checkForUpdates()
                        }) {
                            if updateChecker.isChecking {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 60, height: 30)
                            } else {
                                Text("Check")
                                    .font(.nunitoRegularBold(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                        .disabled(updateChecker.isChecking)
                    }
                    .padding(.vertical, 20)
                    .onChange(of: updateChecker.isChecking) { _, isChecking in
                        if !isChecking {
                            showUpdateAlert = true
                        }
                    }
                    .alert(isPresented: $showUpdateAlert) {
                        if updateChecker.updateAvailable {
                            Alert(
                                title: Text("Update Available"),
                                message: Text("Version \(updateChecker.latestVersion ?? "") is available. You are currently on version \(updateChecker.currentVersion)."),
                                primaryButton: .default(Text("Download")) {
                                    updateChecker.openDownloadPage()
                                },
                                secondaryButton: .cancel(Text("Later"))
                            )
                        } else if let error = updateChecker.errorMessage {
                            Alert(
                                title: Text("Error"),
                                message: Text(error),
                                dismissButton: .default(Text("OK"))
                            )
                        } else {
                            Alert(
                                title: Text("Up to Date"),
                                message: Text("You're running the latest version (\(updateChecker.currentVersion))."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }

                    Divider()

                    // Contact Support row
                    HStack(spacing: 16) {
                        Image(systemName: "envelope")
                            .font(.system(size: 22))
                            .foregroundColor(Color.gray.opacity(0.45))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Contact Support")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Get help from our team")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            if let url = URL(string: "https://x.com/elmoidev") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("Contact")
                                .font(.nunitoRegularBold(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                    .padding(.vertical, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 30)
        }
        .padding(.leading, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .paywall(isPresented: $showPaywall)
    }
}

// MARK: - About Action Row

struct AboutActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row: icon + title + button
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.gray.opacity(0.45))
                    .frame(width: 30)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Small bordered button
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            // Subtitle below - aligned under icon
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.leading, 44) // 30 (icon width) + 14 (spacing)
        }
        .padding(.vertical, 18)
    }
}

// MARK: - Preview

#Preview {
    AboutView()
        .frame(width: 700, height: 520)
}
