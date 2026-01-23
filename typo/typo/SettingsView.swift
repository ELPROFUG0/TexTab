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
        .frame(width: 600, height: 450)
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
        HSplitView {
            // Sidebar - Actions list
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedAction) {
                    ForEach(store.actions) { action in
                        HStack(spacing: 10) {
                            Image(systemName: action.icon)
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            Text(action.name)
                        }
                        .tag(action)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.sidebar)

                Divider()

                HStack {
                    Button(action: addNewAction) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)

                    Button(action: deleteSelectedAction) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedAction == nil)

                    Spacer()
                }
                .padding(8)
            }
            .frame(minWidth: 180, maxWidth: 200)

            // Editor
            if let action = selectedAction {
                ActionEditorView(action: action) { updatedAction in
                    store.updateAction(updatedAction)
                    selectedAction = updatedAction
                }
                .id(action.id) // Forzar recreación cuando cambia la acción
            } else {
                VStack {
                    Text("Select an action to edit")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedAction == nil, let first = store.actions.first {
                selectedAction = first
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
            selectedAction = store.actions.first
        }
    }
}

// MARK: - Action Editor

struct ActionEditorView: View {
    @State var action: Action
    var onSave: (Action) -> Void

    @State private var isRecordingShortcut = false
    @State private var isImprovingPrompt = false

    let iconOptions = [
        "pencil", "arrow.triangle.2.circlepath", "arrow.down.left.and.arrow.up.right",
        "doc.text", "globe", "globe.americas", "star", "bolt", "wand.and.stars",
        "text.bubble", "checkmark.circle", "lightbulb", "brain"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with icon and name
                HStack(spacing: 16) {
                    Menu {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: {
                                action.icon = icon
                                onSave(action)
                            }) {
                                Label(icon, systemImage: icon)
                            }
                        }
                    } label: {
                        Image(systemName: action.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .menuStyle(.borderlessButton)

                    TextField("Action Name", text: $action.name)
                        .textFieldStyle(.plain)
                        .font(.title2.bold())
                        .onChange(of: action.name) { _, _ in
                            onSave(action)
                        }
                }

                Divider()

                // Shortcut
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard Shortcut")
                        .font(.headline)

                    HStack {
                        Text("⌘ +")
                            .foregroundColor(.secondary)

                        TextField("Key", text: $action.shortcut)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onChange(of: action.shortcut) { _, newValue in
                                action.shortcut = newValue.uppercased().prefix(1).description
                                onSave(action)
                            }

                        Spacer()
                    }
                }

                // Prompt
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prompt")
                            .font(.headline)

                        Spacer()

                        Button(action: {
                            improvePromptWithAI()
                        }) {
                            HStack(spacing: 4) {
                                if isImprovingPrompt {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text("Improve with AI")
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .disabled(action.prompt.isEmpty || isImprovingPrompt)
                    }

                    TextEditor(text: $action.prompt)
                        .font(.body)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: action.prompt) { _, _ in
                            onSave(action)
                        }

                    Text("This prompt will be sent to the AI along with the selected text.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(24)
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

#Preview {
    SettingsView()
}
