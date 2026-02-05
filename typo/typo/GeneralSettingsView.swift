//
//  GeneralSettingsView.swift
//  typo
//
//  General settings view for API configuration, preferences and permissions
//

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct GeneralSettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @State private var apiKeyInput: String = ""
    @State private var perplexityApiKeyInput: String = ""
    @State private var selectedProvider: AIProvider = .openai
    @State private var selectedModelId: String = ""
    @AppStorage("appTheme") private var appThemeString: String = "System"
    @State private var showModelTooltip: Bool = false
    @State private var isRecordingMainShortcut = false
    @State private var mainRecordedKeys: [String] = []
    @State private var mainShortcutConflict: String? = nil
    @State private var mainShortcutMonitor: Any? = nil
    @Environment(\.colorScheme) var colorScheme

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: appThemeString) ?? .system }
    }

    private var availableModels: [AIModel] {
        AIModel.models(for: selectedProvider)
    }

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // API Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Configuration")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.primary)

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "cpu")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.purple)
                            Text("AI Provider")
                                .font(.nunitoRegularBold(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 160, alignment: .leading)

                        Picker("", selection: $selectedProvider) {
                            ForEach(AIProvider.allCases, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .onChange(of: selectedProvider) { _, newValue in
                            store.saveProvider(newValue)
                            // Load saved model for this provider
                            selectedModelId = store.modelId(for: newValue)
                            // Load API key for the new provider
                            apiKeyInput = store.apiKey(for: newValue)
                        }
                        .onAppear {
                            selectedProvider = store.selectedProvider
                            selectedModelId = store.modelId(for: store.selectedProvider)
                            apiKeyInput = store.apiKey(for: store.selectedProvider)
                        }

                        Picker("", selection: $selectedModelId) {
                            ForEach(availableModels) { model in
                                Text(model.name).tag(model.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .onChange(of: selectedModelId) { _, newValue in
                            store.saveModel(newValue)
                        }
                        .popover(isPresented: $showModelTooltip, arrowEdge: .bottom) {
                            if let model = availableModels.first(where: { $0.id == selectedModelId }) {
                                ModelSpecsTooltip(model: model)
                            }
                        }
                        .onHover { hovering in
                            showModelTooltip = hovering
                        }

                        Spacer()
                    }

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.orange)
                            Text("API Key")
                                .font(.nunitoRegularBold(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 160, alignment: .leading)

                        SecureField(selectedProvider.apiKeyPlaceholder, text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.nunitoRegularBold(size: 13))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: apiKeyInput) { _, newValue in
                                store.saveApiKey(newValue, for: selectedProvider)
                            }
                    }

                    Text("Get your API key from \(selectedProvider.websiteURL)")
                        .font(.nunitoRegularBold(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 160)
                }

                Divider()

                // Web Search Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Web Search - Perplexity (Optional)")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.primary)

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.cyan)
                            Text("API Key")
                                .font(.nunitoRegularBold(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 160, alignment: .leading)

                        SecureField("Perplexity API key (Optional)", text: $perplexityApiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.nunitoRegularBold(size: 13))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onAppear {
                                perplexityApiKeyInput = store.perplexityApiKey
                            }
                            .onChange(of: perplexityApiKeyInput) { _, newValue in
                                store.savePerplexityApiKey(newValue)
                            }
                    }

                    Text("Required for web search actions. Get your key from perplexity.ai/settings/api")
                        .font(.nunitoRegularBold(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 160)
                }

                Divider()

                // Preferences Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preferences")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.primary)

                    VStack(spacing: 0) {
                        if isRecordingMainShortcut {
                            ShortcutTooltip(recordedKeys: mainRecordedKeys, conflictName: mainShortcutConflict)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                                    removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                                ))
                                .padding(.bottom, 8)
                        }

                        HStack {
                            HStack(spacing: 10) {
                                Image(systemName: "keyboard.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.pink)
                                Text("Global Shortcut")
                                    .font(.nunitoRegularBold(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                startRecordingMainShortcut()
                            }) {
                                HStack(spacing: 6) {
                                    ForEach(store.mainShortcutModifiers, id: \.self) { mod in
                                        Settings3DKey(text: mod)
                                    }
                                    Settings3DKey(text: store.mainShortcut)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecordingMainShortcut)

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.indigo)
                            Text("Appearance")
                                .font(.nunitoRegularBold(size: 15))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        appThemeString = theme.rawValue
                                        applyTheme(theme)
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: theme.icon)
                                            .font(.system(size: 12))
                                        Text(theme.rawValue)
                                            .font(.nunitoRegularBold(size: 12))
                                    }
                                    .foregroundColor(selectedTheme == theme ? .white : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedTheme == theme ? appBlue : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }

                Divider()

                // Permissions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Permissions")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.primary)

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Accessibility Permission")
                                    .font(.nunitoRegularBold(size: 15))
                                    .foregroundColor(.secondary)
                                Text("Required for global keyboard shortcuts to work")
                                    .font(.nunitoRegularBold(size: 12))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }

                        Spacer()

                        Button(action: {
                            openAccessibilitySettings()
                        }) {
                            Text("Open Settings")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(appBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(appBlue.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                #if DEBUG
                Divider()

                // Developer Section (Testing) - Only visible in debug builds
                VStack(alignment: .leading, spacing: 16) {
                    Text("Developer")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.primary)

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset Onboarding")
                                    .font(.nunitoRegularBold(size: 15))
                                    .foregroundColor(.secondary)
                                Text("Show onboarding screens again on next launch")
                                    .font(.nunitoRegularBold(size: 12))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }

                        Spacer()

                        Button(action: {
                            OnboardingManager.shared.resetOnboarding()
                            NSApp.terminate(nil)
                        }) {
                            Text("Reset & Quit")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                #endif

                Spacer()
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSavedTheme()
        }
    }

    private func applyTheme(_ theme: AppTheme) {
        let appearance: NSAppearance?
        switch theme {
        case .system:
            appearance = nil
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }

        NSApp.appearance = appearance
        // appThemeString is already set via @AppStorage, no need to save again
    }

    private func loadSavedTheme() {
        // Apply the theme from @AppStorage on appear
        applyTheme(selectedTheme)
    }

    private func stopRecordingMainShortcut() {
        if let monitor = mainShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            mainShortcutMonitor = nil
        }
        isRecordingMainShortcut = false
        mainShortcutConflict = nil
        mainRecordedKeys = []
        globalAppDelegate?.resumeHotkeys()
    }

    private func startRecordingMainShortcut() {
        if let monitor = mainShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            mainShortcutMonitor = nil
        }

        isRecordingMainShortcut = true
        mainRecordedKeys = []
        mainShortcutConflict = nil

        globalAppDelegate?.suspendHotkeys()

        let keyCodeMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: "."
        ]

        mainShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecordingMainShortcut else { return event }

            if event.type == .keyDown && event.keyCode == 53 {
                withAnimation {
                    self.stopRecordingMainShortcut()
                }
                return nil
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            var currentModifiers: [String] = []
            if modifiers.contains(.control) { currentModifiers.append("^") }
            if modifiers.contains(.option) { currentModifiers.append("\u{2325}") }
            if modifiers.contains(.shift) { currentModifiers.append("\u{21E7}") }
            if modifiers.contains(.command) { currentModifiers.append("\u{2318}") }

            if event.type == .flagsChanged {
                self.mainShortcutConflict = nil
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    self.mainRecordedKeys = currentModifiers
                }
                return event
            }

            if event.type == .keyDown {
                let hasCommand = modifiers.contains(.command)
                let hasOption = modifiers.contains(.option)

                if !hasCommand && !hasOption {
                    return event
                }

                let key = keyCodeMap[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
                if !key.isEmpty && key.count == 1 {
                    var finalKeys = currentModifiers
                    finalKeys.append(key)

                    // Check for conflicts with action shortcuts
                    let currentModSet = Set(currentModifiers)
                    let conflictingAction = ActionsStore.shared.actions.first { action in
                        !action.shortcut.isEmpty &&
                        action.shortcut.uppercased() == key &&
                        Set(action.shortcutModifiers) == currentModSet
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.mainRecordedKeys = finalKeys
                    }

                    if let conflict = conflictingAction {
                        withAnimation {
                            self.mainShortcutConflict = conflict.name
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.mainShortcutConflict != nil {
                                withAnimation {
                                    self.mainShortcutConflict = nil
                                    self.mainRecordedKeys = []
                                }
                            }
                        }
                        return nil
                    }

                    // Save the new main shortcut
                    self.store.mainShortcutModifiers = currentModifiers
                    self.store.mainShortcut = key
                    self.store.saveMainShortcut()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.stopRecordingMainShortcut()
                        }
                    }
                    return nil
                }
            }
            return event
        }
    }
}

// MARK: - Model Specs Tooltip

struct ModelSpecsTooltip: View {
    let model: AIModel
    @Environment(\.colorScheme) var colorScheme

    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model name with provider icon
            HStack(spacing: 8) {
                Image(model.provider.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                Text(model.name)
                    .font(.nunitoBold(size: 15))
                    .foregroundColor(.primary)
            }

            // Description
            Text(model.specs.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                SpecsBar(label: "Speed", value: model.specs.speed)
                SpecsBar(label: "Intelligence", value: model.specs.intelligence)
                SpecsBar(label: "Token usage", value: model.specs.tokenUsage, inverted: true)
            }
        }
        .padding(14)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
}

struct SpecsBar: View {
    let label: String
    let value: Int // 1-5
    var inverted: Bool = false // For token usage: higher value = lower consumption, so invert display

    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // For inverted bars (like token usage), we flip the display
    // tokenUsage 5 (cheap) shows 1 bar, tokenUsage 1 (expensive) shows 5 bars
    private var displayValue: Int {
        inverted ? (6 - value) : value
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 75, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < displayValue ? appBlue : Color.gray.opacity(0.3))
                        .frame(width: 18, height: 6)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView()
        .frame(width: 700, height: 520)
}
