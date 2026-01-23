//
//  SettingsView.swift
//  typo
//

import SwiftUI
import AppKit

// MARK: - Helper Function

func openAccessibilitySettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}

struct SettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @State private var selectedTab = 1
    @State private var selectedAction: Action?

    var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)

            // Actions Tab
            ActionsSettingsView(selectedAction: $selectedAction)
                .tabItem {
                    Label("Actions", systemImage: "list.bullet")
                }
                .tag(1)

            // About Tab
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
        .frame(width: 700, height: 500)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @State private var apiKeyInput: String = ""
    @State private var launchAtLogin = false
    @State private var selectedProvider: AIProvider = .openai

    var body: some View {
        Form {
            Section {
                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProvider) { _, newValue in
                    store.saveProvider(newValue)
                }
                .onAppear {
                    selectedProvider = store.selectedProvider
                }

                SecureField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        apiKeyInput = store.apiKey
                    }
                    .onChange(of: apiKeyInput) { _, newValue in
                        store.saveApiKey(newValue)
                    }

                Text("Get your API key from \(selectedProvider.websiteURL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("API Configuration")
            }

            Section {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    Text("⌘ + ⇧ + T")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)
            } header: {
                Text("Preferences")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility Permission")
                            .font(.body)
                        Text("Required for global keyboard shortcuts to work")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Open Settings") {
                        openAccessibilitySettings()
                    }
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Actions Settings

struct ActionsSettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @Binding var selectedAction: Action?

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar - Actions list
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(store.actions) { action in
                            ActionListRow(
                                action: action,
                                isSelected: selectedAction?.id == action.id
                            )
                            .onTapGesture {
                                selectedAction = action
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)

                Divider()

                // New Action button
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Action")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .onTapGesture {
                    addNewAction()
                }
            }
            .frame(width: 180)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Editor or Empty State
            if let action = selectedAction {
                ActionEditorView(
                    action: action,
                    onSave: { updatedAction in
                        store.updateAction(updatedAction)
                        selectedAction = updatedAction
                    },
                    onDelete: {
                        deleteSelectedAction()
                    }
                )
                .id(action.id)
            } else {
                // Empty state with dot pattern background
                ZStack {
                    // Dot pattern background (canvas style)
                    DotPatternView()

                    VStack(spacing: 24) {
                        // Command icon - 3D style like keyboard key
                        Keyboard3DKeyLarge()

                        VStack(spacing: 10) {
                            Text("No Action Selected")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Start by creating a new action or select an\nexisting one from the list.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }

                        // New Action button - Duolingo 3D style
                        Button(action: {
                            addNewAction()
                        }) {
                            Text("New Action")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        // Bottom layer (3D effect) - darker blue
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color(red: 0.0, green: 0.45, blue: 0.8))
                                            .offset(y: 4)

                                        // Top layer - #0095ff
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color(red: 0.0, green: 0.584, blue: 1.0))
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }

    func addNewAction() {
        let newAction = Action(
            name: "",
            icon: "star",
            prompt: "",
            shortcut: ""
        )
        store.addAction(newAction)
        selectedAction = newAction
    }

    func deleteSelectedAction() {
        if let action = selectedAction {
            store.deleteAction(action)
            selectedAction = nil
        }
    }
}

// MARK: - Action List Row

struct ActionListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let action: Action
    let isSelected: Bool

    // Selected background color: #f1f1ef for light mode, accentColor opacity for dark mode
    var selectedBackgroundColor: Color {
        if !isSelected {
            return Color.clear
        }
        return colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color.accentColor.opacity(0.1)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Drag dots
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 3, height: 3)
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .opacity(0.6)

            // Icon
            Image(systemName: action.icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            // Name
            Text(action.name.isEmpty ? "New Action" : action.name)
                .font(.system(size: 13))
                .foregroundColor(action.name.isEmpty ? .secondary : .primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(selectedBackgroundColor)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Action Editor

struct ActionEditorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var action: Action
    var onSave: (Action) -> Void
    var onDelete: () -> Void

    @State private var isRecordingShortcut = false
    @State private var isImprovingPrompt = false
    @State private var recordedKeys: [String] = []
    @State private var isSaved = false

    let iconOptions = [
        "pencil", "arrow.triangle.2.circlepath", "arrow.down.left.and.arrow.up.right",
        "doc.text", "globe", "globe.americas", "star", "bolt", "wand.and.stars",
        "text.bubble", "checkmark.circle", "lightbulb", "brain"
    ]

    // Input background color: #f1f1ef for light mode, controlBackgroundColor for dark mode
    var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(NSColor.controlBackgroundColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon and name
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button(action: {
                                    action.icon = icon
                                    onSave(action)
                                    showSaved()
                                }) {
                                    Label(icon, systemImage: icon)
                                }
                            }
                        } label: {
                            Image(systemName: action.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .frame(width: 36, height: 36)
                        }
                        .menuStyle(.borderlessButton)

                        TextField("New Action", text: $action.name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold))
                            .onChange(of: action.name) { _, _ in
                                onSave(action)
                                showSaved()
                            }

                        Spacer()
                    }

                    // Shortcut field with tooltip
                    VStack(spacing: 0) {
                        // Tooltip appears above
                        if isRecordingShortcut {
                            ShortcutTooltip(recordedKeys: recordedKeys)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                                    removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                                ))
                                .padding(.bottom, 8)
                        }

                        Button(action: {
                            startRecordingShortcut()
                        }) {
                            HStack {
                                if action.shortcut.isEmpty {
                                    Text("Click to record shortcut...")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.gray.opacity(0.5))
                                } else {
                                    HStack(spacing: 6) {
                                        ShortcutInputKey(text: "⌘")
                                        ShortcutInputKey(text: "⇧")
                                        ShortcutInputKey(text: action.shortcut)
                                    }
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(inputBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecordingShortcut)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recordedKeys)

                    // Prompt editor with Enhance button inside
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            if action.prompt.isEmpty {
                                Text("Enter your prompt here")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $action.prompt)
                                .font(.system(size: 14))
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .background(Color.clear)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .onChange(of: action.prompt) { _, _ in
                                    onSave(action)
                                    showSaved()
                                }
                        }
                        .frame(minHeight: 220)

                        // Enhance button inside container
                        HStack {
                            Button(action: {
                                improvePromptWithAI()
                            }) {
                                HStack(spacing: 5) {
                                    if isImprovingPrompt {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                    }
                                    Text("Enhance")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.windowBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(action.prompt.isEmpty || isImprovingPrompt)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                    }
                    .background(inputBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                    Spacer()
                }
                .padding(24)
            }

            // Footer with Delete and Saved buttons
            HStack {
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Spacer()

                // Saved button
                Text(isSaved ? "Saved" : "Saved")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.0, green: 0.584, blue: 1.0))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear {
            // Initialize recorded keys from existing shortcut
            if !action.shortcut.isEmpty {
                recordedKeys = ["⌘", "⇧", action.shortcut]
            }
        }
    }

    func startRecordingShortcut() {
        isRecordingShortcut = true
        recordedKeys = ["⌘", "⇧"]

        // Monitor for key press
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isRecordingShortcut {
                let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
                if !key.isEmpty && key.count == 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.recordedKeys = ["⌘", "⇧", key]
                    }
                    self.action.shortcut = key
                    self.onSave(self.action)
                    self.showSaved()

                    // Close tooltip after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.isRecordingShortcut = false
                        }
                    }
                    return nil
                }
            }
            return event
        }
    }

    func showSaved() {
        withAnimation {
            isSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isSaved = false
            }
        }
    }

    func improvePromptWithAI() {
        isImprovingPrompt = true

        Task {
            do {
                let improvedPrompt = try await PromptImprover.improve(prompt: action.prompt)
                await MainActor.run {
                    action.prompt = improvedPrompt
                    onSave(action)
                    showSaved()
                    isImprovingPrompt = false
                }
            } catch {
                await MainActor.run {
                    isImprovingPrompt = false
                }
            }
        }
    }
}

// MARK: - Shortcut Tooltip

struct ShortcutTooltip: View {
    let recordedKeys: [String]

    var body: some View {
        VStack(spacing: 0) {
            // Tooltip content
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("e.g.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    // Always show 3 key slots
                    ForEach(0..<3, id: \.self) { index in
                        if index < recordedKeys.count {
                            TooltipKey(text: recordedKeys[index])
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.5).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .id("key-\(index)-\(recordedKeys[index])")
                        } else {
                            TooltipKey(text: "")
                                .opacity(0.4)
                        }
                    }
                }

                Text("Recording...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )

            // Arrow pointing down
            TooltipArrow()
                .fill(Color(NSColor.windowBackgroundColor))
                .frame(width: 16, height: 10)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 2)
        }
    }
}

struct TooltipKey: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7))
                .frame(width: 28, height: 28)
                .offset(y: 2)

            // Top layer
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color.white : Color(white: 0.95))
                .frame(width: 28, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(width: 28, height: 30)
    }
}

struct TooltipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Shortcut Input Key (3D effect for input field)

struct ShortcutInputKey: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 5)
                .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7))
                .frame(width: 24, height: 24)
                .offset(y: 2)

            // Top layer
            RoundedRectangle(cornerRadius: 5)
                .fill(colorScheme == .dark ? Color.white : Color(white: 0.95))
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(width: 24, height: 26)
    }
}

// MARK: - Prompt Improver

class PromptImprover {
    static func improve(prompt: String) async throws -> String {
        let apiKey = "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"
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let systemPrompt = """
        You are an expert at writing prompts for text transformation apps.

        The user gives you a basic idea, and you expand it into a detailed prompt that will guide an AI to transform text.

        RULES:
        - Write clear instructions describing the desired style, tone, and characteristics
        - Include specific techniques and qualities the text should have
        - Do NOT include phrases like "Return only the text" or "without explanations" at the end
        - Do NOT start with "Rewrite" or "Transform"
        - Keep it in the same language as the user's input

        EXAMPLES:
        Input: "formal"
        Output: "Use professional and formal language. Employ sophisticated vocabulary, proper grammar, and a respectful tone suitable for business communication. Avoid contractions and colloquialisms."

        Input: "funny"
        Output: "Add humor and wit to the text. Use playful language, clever wordplay, and a light-hearted tone. Include amusing observations while keeping the core message intact."

        Input: "hazlo romántico"
        Output: "Utiliza un lenguaje poético y evocador para expresar emociones profundas. Incluye metáforas, descripciones sensoriales y un tono apasionado pero sincero que resalte la belleza y la conexión."

        Return ONLY the improved prompt, nothing else.
        """

        let body: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Improve this prompt: \(prompt)"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "PromptImprover", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.cursor")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Typo")
                .font(.largeTitle.bold())

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Text("Transform text with AI-powered shortcuts")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Text("Made with SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 3D Keyboard Key

struct Keyboard3DKey: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7))
                .frame(width: 36, height: 36)
                .offset(y: 3)

            // Top layer
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white : Color(white: 0.95))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(width: 36, height: 39)
    }
}

// MARK: - 3D Keyboard Key Large (for empty state)

struct Keyboard3DKeyLarge: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7))
                .frame(width: 64, height: 64)
                .offset(y: 4)

            // Top layer
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white : Color(white: 0.95))
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: 1)
                )

            Image(systemName: "command")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Color(white: 0.35))
        }
        .frame(width: 64, height: 68)
    }
}

// MARK: - 3D Keyboard Key Editable

struct Keyboard3DKeyEditable: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    var onSave: () -> Void

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7))
                .frame(width: 44, height: 36)
                .offset(y: 3)

            // Top layer
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white : Color(white: 0.95))
                .frame(width: 44, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: 1)
                )

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .frame(width: 44, height: 36)
                .onChange(of: text) { _, newValue in
                    text = newValue.uppercased().prefix(1).description
                    onSave()
                }
        }
        .frame(width: 44, height: 39)
    }
}

// MARK: - Dot Pattern Background

struct DotPatternView: View {
    let dotSize: CGFloat = 2
    let spacing: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / spacing) + 1
            let rows = Int(geometry.size.height / spacing) + 1

            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                        context.fill(Circle().path(in: rect), with: .color(Color.gray.opacity(0.15)))
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
