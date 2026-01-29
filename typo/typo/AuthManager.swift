//
//  AuthManager.swift
//  typo
//
//  Authentication manager for TexTab using Supabase
//

import Foundation
import Combine
import AppKit
import CryptoKit
import IOKit

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
    let deviceId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case subscriptionStatus = "subscription_status"
        case stripeCustomerId = "stripe_customer_id"
        case currentPeriodEnd = "current_period_end"
        case deviceId = "device_id"
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

    // Edge Function for dynamic checkout
    private let createCheckoutURL: String = "https://ywbrvymvyndeixorggkx.supabase.co/functions/v1/create-checkout"

    // OAuth redirect URI - GitHub Pages callback page
    private let redirectURI = "https://elprofug0.github.io/textab-auth/auth/callback.html"

    // PKCE code verifier key
    private let codeVerifierKey = "typo_code_verifier"

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
    private let userCreatedAtKey = "typo_user_created_at"
    private let subscriptionStatusKey = "typo_subscription_status"
    private let subscriptionEndKey = "typo_subscription_end"
    private var subscriptionTimer: Timer?

    private init() {
        loadSession()
        startSubscriptionPolling()
    }

    private func startSubscriptionPolling() {
        subscriptionTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self, self.isAuthenticated else { return }
            Task {
                await self.refreshSubscription()
            }
        }
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
        await saveDeviceId()
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
        await saveDeviceId()

        // Fetch subscription status after login
        try await fetchSubscriptionStatus()
    }

    // MARK: - Sign Out

    func signOut() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userCreatedAtKey)
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
        guard let email = currentUser?.email else { return }

        Task {
            do {
                guard let url = URL(string: createCheckoutURL) else { return }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                var body: [String: String] = ["email": email]
                if let deviceId = Self.hardwareUUID {
                    body["device_id"] = deviceId
                }
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Checkout error: bad response")
                    return
                }

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let checkoutURLString = json["url"] as? String,
                   let checkoutURL = URL(string: checkoutURLString) {
                    _ = await MainActor.run {
                        NSWorkspace.shared.open(checkoutURL)
                    }
                }
            } catch {
                print("Checkout error: \(error)")
            }
        }
    }

    func openStripePortal() {
        // Open Stripe customer portal for managing subscription
        if let url = URL(string: "https://billing.stripe.com/p/login/test_00g7w03vhg3y3L2bII") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Google Sign In (PKCE Flow)

    func signInWithGoogle() {
        // Generate PKCE code verifier (random 32 bytes, base64url encoded)
        let verifier = generateCodeVerifier()
        // Store verifier for later use when exchanging the code
        UserDefaults.standard.set(verifier, forKey: codeVerifierKey)

        // Generate code challenge (SHA256 hash of verifier, base64url encoded)
        let challenge = generateCodeChallenge(from: verifier)

        // Construct the OAuth URL for Supabase Google provider with PKCE
        var components = URLComponents(string: "\(supabaseURL)/auth/v1/authorize")!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    // Generate a random code verifier for PKCE (43-128 chars, base64url)
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // Generate code challenge from verifier using SHA256
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // Handle OAuth callback URL (PKCE flow)
    func handleOAuthCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.invalidResponse
        }

        guard let verifier = UserDefaults.standard.string(forKey: codeVerifierKey) else {
            throw AuthError.serverError("Missing code verifier")
        }

        guard let tokenURL = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=pkce") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "auth_code": code,
            "code_verifier": verifier
        ]
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

        UserDefaults.standard.removeObject(forKey: codeVerifierKey)

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        await MainActor.run {
            saveSession(authResponse)
            ActionsStore.shared.loadActions()
        }
        await saveDeviceId()

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

    // MARK: - Device ID

    static var hardwareUUID: String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        guard let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else {
            return nil
        }
        return uuid
    }

    private func saveDeviceId() async {
        guard let token = accessToken, let userId = currentUser?.id, let deviceId = Self.hardwareUUID else { return }

        guard let url = URL(string: "\(supabaseURL)/rest/v1/profiles?id=eq.\(userId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["device_id": deviceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: request)
    }

    private func saveSession(_ response: AuthResponse) {
        accessToken = response.accessToken
        currentUser = response.user
        isAuthenticated = true

        UserDefaults.standard.set(response.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(response.refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(response.user.id, forKey: userIdKey)
        UserDefaults.standard.set(response.user.email, forKey: userEmailKey)
        if let createdAt = response.user.createdAt {
            UserDefaults.standard.set(createdAt, forKey: userCreatedAtKey)
        }
    }

    private func loadSession() {
        if let token = UserDefaults.standard.string(forKey: accessTokenKey),
           let userId = UserDefaults.standard.string(forKey: userIdKey) {
            accessToken = token
            let email = UserDefaults.standard.string(forKey: userEmailKey)
            let createdAt = UserDefaults.standard.string(forKey: userCreatedAtKey)
            currentUser = SupabaseUser(id: userId, email: email, createdAt: createdAt)
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
