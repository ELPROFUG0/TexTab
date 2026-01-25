//
//  FeaturesStep.swift
//  typo
//

import SwiftUI

struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct FeaturesStep: View {
    var onNext: () -> Void
    var onBack: () -> Void

    private let features = [
        FeatureItem(icon: "wand.and.stars", title: "AI Transformations", description: "Fix grammar, rephrase, translate instantly"),
        FeatureItem(icon: "globe", title: "Web Search", description: "Search with Perplexity AI integration"),
        FeatureItem(icon: "keyboard", title: "Global Shortcuts", description: "Works anywhere with custom hotkeys"),
        FeatureItem(icon: "puzzlepiece.extension", title: "Plugins", description: "QR codes, color picker, and more")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1E88E5"),
                    Color(hex: "42A5F5"),
                    Color(hex: "4DD0E1")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 16)

                Text("What TexTab can do")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Features grid
                VStack(spacing: 12) {
                    ForEach(features) { feature in
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: feature.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }

                            // Text
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(feature.description)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 60)

                Spacer()

                // Navigation
                HStack(spacing: 14) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onNext) {
                        HStack(spacing: 6) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
                    .frame(height: 30)
            }
        }
    }
}
