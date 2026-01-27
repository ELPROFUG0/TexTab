//
//  AuthManager.swift
//  typo
//
//  Authentication manager for TexTab using Supabase
//

import Foundation
import Combine
import AppKit

// MARK: - Supabase Auth Models

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct UserProfile: Codable {
    let id: String
    let email: String?
    let subscriptionStatus: String?
    let stripeCustomerId: String?
    let currentPeriodEnd: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case subscriptionStatus = "subscription_status"
        case stripeCustomerId = "stripe_customer_id"
        case currentPeriodEnd = "current_period_end"
    }
}

struct SupabaseError: Codable {
    let error: String?
    let errorDescription: String?
    let message: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
        case msg
    }

    var displayMessage: String {
        errorDescription ?? message ?? msg ?? error ?? "Unknown error"
    }
}

// MARK: - Auth Manager

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // Supabase configuration
    private let supabaseURL = "https://ywbrvymvyndeixorggkx.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3YnJ2eW12eW5kZWl4b3JnZ2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0NzUzNzIsImV4cCI6MjA4NTA1MTM3Mn0.kbQ9_WsHHdhVXqqk-smwNb2K7gQkz7b1i8l2YwgOGRY"

    // Stripe Payment Link (Test Mode)
    let stripePaymentLink = "https://buy.stripe.com/test_dRm28qeFFc9P06x2ceejK00"

    // OAuth redirect URI
    private let redirectURI = "textab://auth/callback"

    // Published state
    @Published var isAuthenticated = false
    @Published var currentUser: SupabaseUser?
    @Published var accessToken: String?
    @Published var isPro = false
    @Published var subscriptionStatus: String = "free"
    @Published var subscriptionEndDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // UserDefaults keys
    private let accessTokenKey = "typo_access_token"
    private let refreshTokenKey = "typo_refresh_token"
    private let userIdKey = "typo_user_id"
    private let userEmailKey = "typo_user_email"
    private let subscriptionStatusKey = "typo_subscription_status"
    private let subscriptionEndKey = "typo_subscription_end"

    private init() {
        loadSession()
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(SupabaseError.self, from: data) {
                throw AuthError.serverError(errorResponse.displayMessage)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        await MainActor.run {
            saveSession(authResponse)
            // Load default actions for new user
            ActionsStore.shared.loadActions()
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(SupabaseError.self, from: data) {
                throw AuthError.serverError(errorResponse.displayMessage)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        await MainActor.run {
            saveSession(authResponse)
            // Reload actions after login (loads defaults if empty)
            ActionsStore.shared.loadActions()
        }

        // Fetch subscription status after login
        try await fetchSubscriptionStatus()
    }

    // MARK: - Sign Out

    func signOut() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: subscriptionStatusKey)
        UserDefaults.standard.removeObject(forKey: subscriptionEndKey)

        isAuthenticated = false
        currentUser = nil
        accessToken = nil
        isPro = false
        subscriptionStatus = "free"
        subscriptionEndDate = nil
        errorMessage = nil

        // Clear all user actions on sign out
        ActionsStore.shared.clearAllActions()
    }

    // MARK: - Fetch Subscription Status

    func fetchSubscriptionStatus() async throws {
        guard let token = accessToken, let userId = currentUser?.id else { return }

        guard let url = URL(string: "\(supabaseURL)/rest/v1/profiles?id=eq.\(userId)&select=*") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return
        }

        let profiles = try JSONDecoder().decode([UserProfile].self, from: data)

        if let profile = profiles.first {
            await MainActor.run {
                subscriptionStatus = profile.subscriptionStatus ?? "free"
                isPro = subscriptionStatus == "active"

                // Parse end date
                if let endDateString = profile.currentPeriodEnd {
                    let formatter = ISO8601DateFormatter()
                    subscriptionEndDate = formatter.date(from: endDateString)

                    // Check if subscription has expired
                    if let endDate = subscriptionEndDate, endDate < Date() {
                        isPro = false
                        subscriptionStatus = "expired"
                    }
                }

                // Save to UserDefaults
                UserDefaults.standard.set(subscriptionStatus, forKey: subscriptionStatusKey)
                if let endDate = subscriptionEndDate {
                    UserDefaults.standard.set(endDate, forKey: subscriptionEndKey)
                }
            }
        }
    }

    // MARK: - Refresh Subscription (call after payment)

    func refreshSubscription() async {
        do {
            try await fetchSubscriptionStatus()
        } catch {
            print("Failed to refresh subscription: \(error)")
        }
    }

    // MARK: - Open Stripe Payment

    func openStripePayment() {
        if let url = URL(string: stripePaymentLink) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() {
        // Construct the OAuth URL for Supabase Google provider
        var components = URLComponents(string: "\(supabaseURL)/auth/v1/authorize")!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURI)
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    // Handle OAuth callback URL
    func handleOAuthCallback(url: URL) async throws {
        // Parse the URL to extract tokens
        // Supabase redirects with fragment: textab://auth/callback#access_token=...&refresh_token=...
        guard let fragment = url.fragment else {
            throw AuthError.invalidResponse
        }

        // Parse fragment parameters
        var params: [String: String] = [:]
        let pairs = fragment.split(separator: "&")
        for pair in pairs {
            let keyValue = pair.split(separator: "=", maxSplits: 1)
            if keyValue.count == 2 {
                let key = String(keyValue[0])
                let value = String(keyValue[1]).removingPercentEncoding ?? String(keyValue[1])
                params[key] = value
            }
        }

        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            throw AuthError.invalidResponse
        }

        // Get user info from the access token
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }

        let user = try JSONDecoder().decode(SupabaseUser.self, from: data)

        await MainActor.run {
            // Save session manually since we have the tokens directly
            self.accessToken = accessToken
            self.currentUser = user
            self.isAuthenticated = true

            UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
            UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
            UserDefaults.standard.set(user.id, forKey: userIdKey)
            UserDefaults.standard.set(user.email, forKey: userEmailKey)

            // Reload actions after login
            ActionsStore.shared.loadActions()
        }

        // Fetch subscription status after login
        try await fetchSubscriptionStatus()
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/recover") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(SupabaseError.self, from: data) {
                throw AuthError.serverError(errorResponse.displayMessage)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Private Helpers

    private func saveSession(_ response: AuthResponse) {
        accessToken = response.accessToken
        currentUser = response.user
        isAuthenticated = true

        UserDefaults.standard.set(response.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(response.refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(response.user.id, forKey: userIdKey)
        UserDefaults.standard.set(response.user.email, forKey: userEmailKey)
    }

    private func loadSession() {
        if let token = UserDefaults.standard.string(forKey: accessTokenKey),
           let userId = UserDefaults.standard.string(forKey: userIdKey) {
            accessToken = token
            let email = UserDefaults.standard.string(forKey: userEmailKey)
            currentUser = SupabaseUser(id: userId, email: email, createdAt: nil)
            isAuthenticated = true

            // Load cached subscription status
            subscriptionStatus = UserDefaults.standard.string(forKey: subscriptionStatusKey) ?? "free"
            isPro = subscriptionStatus == "active"
            subscriptionEndDate = UserDefaults.standard.object(forKey: subscriptionEndKey) as? Date

            // Refresh subscription status from server
            Task {
                try? await fetchSubscriptionStatus()
            }
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let message):
            return message
        }
    }
}
