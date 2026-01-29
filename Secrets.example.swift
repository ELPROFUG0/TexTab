//
//  Secrets.example.swift
//  typo
//
//  Copy this file to Secrets.swift and fill in your own values.
//  Secrets.swift is excluded from git via .gitignore.
//

import Foundation

enum Secrets {
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    static let createCheckoutURL = "https://YOUR_PROJECT.supabase.co/functions/v1/create-checkout"
    static let redirectURI = "https://YOUR_OAUTH_CALLBACK_URL"
    static let stripePortalURL = "https://billing.stripe.com/p/login/YOUR_PORTAL_ID"
}
