//
//  QuickPromptView.swift
//  typo
//
//  Quick Prompt - run a one-off AI prompt on selected text
//

import SwiftUI

struct QuickPromptView: View {
    @StateObject private var textManager = CapturedTextManager.shared
    @State private var promptText: String = ""
    @FocusState private var isPromptFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var appTheme: String = "System"

    var onClose: () -> Void

    private var savedColorScheme: ColorScheme? {
        switch appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)

                Text("Quick Prompt")
                    .font(.nunitoRegularBold(size: 14))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { onClose() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Selected text preview (max 2 lines)
            if !textManager.capturedText.isEmpty {
                HStack(spacing: 0) {
                    Text(textManager.capturedText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    colorScheme == .light
                        ? Color(red: 245/255, green: 245/255, blue: 243/255)
                        : Color(white: 1).opacity(0.05)
                )
            }

            Divider()

            // Prompt input
            HStack(spacing: 10) {
                TextField("Write your prompt...", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.nunitoRegularBold(size: 16))
                    .foregroundColor(.primary)
                    .focused($isPromptFocused)

                if !promptText.isEmpty {
                    Button(action: { executeQuickPrompt() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Footer
            HStack {
                HStack(spacing: 4) {
                    KeyboardKey("esc")
                    Text("close")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    KeyboardKey("↵")
                    Text("run")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                colorScheme == .light
                    ? Color(red: 245/255, green: 245/255, blue: 243/255)
                    : Color(white: 1).opacity(0.05)
            )
        }
        .frame(width: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .preferredColorScheme(savedColorScheme)
        .onAppear {
            isPromptFocused = true
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .onKeyPress(.return) {
            executeQuickPrompt()
            return .handled
        }
    }

    func executeQuickPrompt() {
        let prompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        let quickAction = Action(
            name: "Quick Prompt",
            icon: "bolt.fill",
            prompt: prompt,
            shortcut: "",
            shortcutModifiers: []
        )

        promptText = ""
        onClose()

        globalAppDelegate?.pendingAction = quickAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            globalAppDelegate?.showPopoverWithAction(skipCapture: true)
        }
    }
}
