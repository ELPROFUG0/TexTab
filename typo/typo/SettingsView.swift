//
//  SettingsView.swift
//  typo
//

import SwiftUI
import AppKit

// MARK: - Custom Font Extension

extension Font {
    static func nunitoBold(size: CGFloat) -> Font {
        return .custom("Nunito ExtraBold", size: size)
    }

    static func nunitoRegularBold(size: CGFloat) -> Font {
        return .custom("Nunito Bold", size: size)
    }
}

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
        VStack(spacing: 0) {
            // Custom Tab Bar - solo textos con Nunito
            HStack(spacing: 24) {
                TabTextButton(title: "General", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabTextButton(title: "Actions", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabTextButton(title: "Plugins", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabTextButton(title: "About", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(.vertical, 12)

            Divider()

            // Tab Content
            switch selectedTab {
            case 0:
                GeneralSettingsView()
            case 1:
                ActionsSettingsView(selectedAction: $selectedAction)
            case 2:
                PluginsMarketplaceView()
            case 3:
                AboutView()
            default:
                EmptyView()
            }
        }
        .frame(width: 700, height: 540)
    }
}

// MARK: - Custom Tab Text Button

struct TabTextButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.nunitoBold(size: 14))
                .foregroundColor(isSelected ? Color(red: 0.0, green: 0.584, blue: 1.0) : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @State private var apiKeyInput: String = ""
    @State private var perplexityApiKeyInput: String = ""
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
                    .font(.nunitoBold(size: 13))
            }

            Section {
                SecureField("Perplexity API Key", text: $perplexityApiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        perplexityApiKeyInput = store.perplexityApiKey
                    }
                    .onChange(of: perplexityApiKeyInput) { _, newValue in
                        store.savePerplexityApiKey(newValue)
                    }

                Text("Required for web search actions. Get your key from perplexity.ai/settings/api")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Web Search (Perplexity)")
                    .font(.nunitoBold(size: 13))
            }

            Section {
                HStack {
                    Text("Global Shortcut")
                        .font(.nunitoBold(size: 14))
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
                    .font(.nunitoBold(size: 13))
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility Permission")
                            .font(.nunitoBold(size: 14))
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
                    .font(.nunitoBold(size: 13))
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

                // New Action button - Fixed at bottom
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                    Text("New Action")
                        .font(.nunitoRegularBold(size: 14))

                    Spacer()
                }
                .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .onTapGesture {
                    addNewAction()
                }
            }
            .frame(width: 220)
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
                                .font(.nunitoBold(size: 20))
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
                                .font(.nunitoBold(size: 15))
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

    // Adaptive gray: darker in light mode, lighter in dark mode
    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: action.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textGrayColor)
                .frame(width: 24)

            // Name
            Text(action.name.isEmpty ? "New Action" : action.name)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(textGrayColor)
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
    @State private var hasUnsavedChanges = false
    @State private var showIconPicker = false
    @State private var isNameFocused = false
    @State private var showDeleteConfirmation = false

    // Input background color: #f1f1ef for light mode, controlBackgroundColor for dark mode
    var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(NSColor.controlBackgroundColor)
    }

    // Adaptive gray: darker in light mode, lighter in dark mode
    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header with icon and name
                        HStack(spacing: 12) {
                            // Custom Icon Picker Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showIconPicker.toggle()
                                }
                            }) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(textGrayColor)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)

                            TextField("New Action", text: $action.name, onEditingChanged: { editing in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    isNameFocused = editing
                                }
                            })
                                .textFieldStyle(.plain)
                                .font(.nunitoBold(size: 22))
                                .foregroundColor(textGrayColor)
                                .scaleEffect(isNameFocused ? 1.05 : 1.0, anchor: .leading)
                                .onChange(of: action.name) { _, _ in
                                    hasUnsavedChanges = true
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

                    // Plugin info (only for plugins)
                    if action.isPlugin, let pluginType = action.pluginType {
                        PluginInfoView(pluginType: pluginType, inputBackgroundColor: inputBackgroundColor, textGrayColor: textGrayColor)
                    } else {
                        // Prompt editor with Enhance button inside (only for AI actions)
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                if action.prompt.isEmpty {
                                    Text("Enter your prompt here")
                                        .font(.nunitoRegularBold(size: 14))
                                        .foregroundColor(textGrayColor.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }

                                TextEditor(text: $action.prompt)
                                    .font(.nunitoRegularBold(size: 14))
                                    .foregroundColor(textGrayColor)
                                    .scrollContentBackground(.hidden)
                                    .scrollDisabled(true)
                                    .background(Color.clear)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .onChange(of: action.prompt) { _, _ in
                                        hasUnsavedChanges = true
                                    }
                            }
                            .frame(minHeight: 220)

                            // Enhance button inside container
                            HStack {
                                Button(action: {
                                    improvePromptWithAI()
                                }) {
                                    HStack(spacing: 5) {
                                        ZStack {
                                            if isImprovingPrompt {
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            } else {
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 11))
                                            }
                                        }
                                        .frame(width: 14, height: 14)

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

                        // Web Search Toggle (only for AI actions)
                        HStack {
                            Toggle(isOn: Binding(
                                get: { action.actionType == .webSearch },
                                set: { newValue in
                                    action.actionType = newValue ? .webSearch : .ai
                                    hasUnsavedChanges = true
                                }
                            )) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(action.actionType == .webSearch ? .accentColor : textGrayColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Web Search")
                                            .font(.nunitoRegularBold(size: 14))
                                            .foregroundColor(textGrayColor)
                                        Text("Uses Perplexity to search the web for up-to-date information")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(inputBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }

                // Footer with Delete and Saved buttons
                HStack {
                    Button(action: {
                        if showDeleteConfirmation {
                            onDelete()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteConfirmation = true
                            }
                            // Reset after 3 seconds if not confirmed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteConfirmation = false
                                }
                            }
                        }
                    }) {
                        Text(showDeleteConfirmation ? "Are you sure?" : "Delete")
                            .font(.nunitoRegularBold(size: 15))
                            .foregroundColor(.red)
                            .padding(.horizontal, showDeleteConfirmation ? 16 : 0)
                            .padding(.vertical, showDeleteConfirmation ? 8 : 0)
                            .background(
                                Capsule()
                                    .fill(showDeleteConfirmation ? Color.red.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Save button
                    Button(action: saveChanges) {
                        Text(hasUnsavedChanges ? "Save" : "Saved")
                            .font(.nunitoRegularBold(size: 15))
                            .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.0, green: 0.584, blue: 1.0).opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasUnsavedChanges)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(NSColor.windowBackgroundColor))
            }

            // Floating Icon Picker - above everything
            if showIconPicker {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showIconPicker = false
                        }
                    }

                IconPickerView(
                    selectedIcon: action.icon,
                    onSelect: { icon in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            action.icon = icon
                            hasUnsavedChanges = true
                            showIconPicker = false
                        }
                    }
                )
                .fixedSize()
                .offset(x: 24, y: 68)
                .transition(.opacity)
            }
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
                    self.hasUnsavedChanges = true

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

    func saveChanges() {
        onSave(action)
        withAnimation {
            hasUnsavedChanges = false
        }
    }

    func improvePromptWithAI() {
        isImprovingPrompt = true

        Task {
            do {
                let improvedPrompt = try await PromptImprover.improve(prompt: action.prompt)
                await MainActor.run {
                    action.prompt = improvedPrompt
                    hasUnsavedChanges = true
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

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Environment(\.colorScheme) var colorScheme
    let selectedIcon: String
    let onSelect: (String) -> Void

    @State private var hoveredIcon: String?

    // Icon list with more categories
    let icons: [String] = [
        // Writing & Text
        "pencil", "pencil.line", "highlighter", "scribble.variable", "signature", "text.cursor",
        "pencil.tip", "pencil.and.outline", "square.and.pencil", "rectangle.and.pencil.and.ellipsis",
        // Communication
        "text.bubble", "bubble.left", "quote.bubble", "captions.bubble", "ellipsis.message", "phone",
        "message.fill", "envelope.fill", "paperplane.fill", "megaphone.fill",
        // Hands - All gestures
        "hand.raised.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill", "hand.point.right.fill", "hand.wave.fill", "hands.clap.fill",
        "hand.point.up.fill", "hand.point.up.left.fill", "hand.point.down.fill", "hand.point.left.fill",
        "hand.draw.fill", "hand.tap.fill", "hand.point.up.braille.fill",
        "hands.and.sparkles.fill",
        // People & Figures
        "person.fill", "person.2.fill", "person.3.fill", "figure.stand", "figure.walk", "figure.run",
        "figure.wave", "figure.arms.open", "figure.2.arms.open", "figure.dance", "figure.martial.arts",
        "person.crop.circle.fill", "person.badge.plus.fill", "person.badge.clock.fill",
        // Actions & Magic
        "bolt.fill", "wand.and.stars", "sparkles", "star.fill", "heart.fill", "flame.fill",
        "wand.and.rays", "ant.fill", "ladybug.fill", "leaf.fill", "tornado", "wind",
        // Documents & Lists
        "doc.text.fill", "doc.plaintext.fill", "list.bullet", "checklist", "bookmark.fill", "tag.fill",
        "doc.richtext.fill", "doc.append.fill", "note.text", "list.clipboard.fill",
        // Ideas & Mind
        "lightbulb.fill", "brain", "eye.fill", "face.smiling.fill", "moon.fill", "sun.max.fill",
        "brain.head.profile", "eyes", "mustache.fill", "mouth.fill", "nose.fill", "ear.fill",
        // Tools & Work
        "gearshape.fill", "wrench.and.screwdriver.fill", "hammer.fill", "paintbrush.fill", "scissors", "waveform",
        "briefcase.fill", "folder.fill", "archivebox.fill", "tray.full.fill", "externaldrive.fill",
        // Symbols & Alerts
        "checkmark.circle.fill", "xmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill", "questionmark.circle.fill", "bell.fill",
        "flag.fill", "location.fill", "pin.fill", "mappin.circle.fill", "scope",
        // Arrows & Movement
        "arrow.triangle.2.circlepath", "arrow.clockwise", "repeat", "shuffle", "arrow.up.circle.fill", "arrow.down.circle.fill",
        "arrow.left.arrow.right", "arrow.up.arrow.down", "arrow.uturn.backward", "arrow.uturn.forward",
        // Objects & Things
        "cup.and.saucer.fill", "gift.fill", "bag.fill", "cart.fill", "creditcard.fill", "building.2.fill",
        "house.fill", "car.fill", "airplane", "bicycle", "bus.fill", "tram.fill",
        // Media & Entertainment
        "play.circle.fill", "pause.circle.fill", "music.note", "mic.fill", "camera.fill", "photo.fill",
        "film.fill", "tv.fill", "gamecontroller.fill", "headphones",
        // Nature & Weather
        "cloud.fill", "cloud.rain.fill", "cloud.bolt.fill", "snowflake", "drop.fill", "thermometer.sun.fill",
        // Tech & Devices
        "desktopcomputer", "laptopcomputer", "iphone", "keyboard.fill", "printer.fill", "display",
        // Health & Fitness
        "heart.circle.fill", "cross.fill", "pills.fill", "bandage.fill", "stethoscope", "figure.yoga"
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 6), count: 6), spacing: 6) {
                    ForEach(icons, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon,
                            isHovered: hoveredIcon == icon,
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            onSelect(icon)
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredIcon = hovering ? icon : nil
                            }
                        }
                    }
                }
                .padding(12)
                .padding(.bottom, 20)
            }

            // Fade gradient at bottom to indicate more content
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.windowBackgroundColor).opacity(0),
                    Color(NSColor.windowBackgroundColor)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            .allowsHitTesting(false)
        }
        .frame(width: 320, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let colorScheme: ColorScheme

    var backgroundColor: Color {
        if isSelected {
            return Color.gray.opacity(0.3)
        } else if isHovered {
            return colorScheme == .light
                ? Color(white: 0.9)
                : Color(white: 0.25)
        }
        return Color.clear
    }

    var iconColor: Color {
        return Color.gray
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(iconColor)
                .scaleEffect(isHovered && !isSelected ? 1.15 : 1.0)
        }
        .frame(width: 44, height: 44)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
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
                .font(.nunitoBold(size: 34))

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

// MARK: - Plugins Marketplace View

struct PluginsMarketplaceView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store = ActionsStore.shared
    @State private var selectedCategory: PluginCategory? = nil
    @State private var searchText = ""

    var filteredPlugins: [PluginType] {
        var plugins = PluginType.allCases

        if let category = selectedCategory {
            plugins = plugins.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            plugins = plugins.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return plugins
    }

    var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 247/255, green: 247/255, blue: 245/255)
            : Color(white: 0.12)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Plugins")
                    .font(.nunitoBold(size: 20))

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search plugins...", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(PluginCategory.allCases, id: \.self) { category in
                        CategoryPill(title: category.rawValue, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)

            Divider()

            // Plugins Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredPlugins, id: \.self) { plugin in
                        PluginCard(plugin: plugin, isInstalled: store.isPluginInstalled(plugin)) {
                            if store.isPluginInstalled(plugin) {
                                store.uninstallPlugin(plugin)
                            } else {
                                store.installPlugin(plugin)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(backgroundColor)
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PluginCard: View {
    @Environment(\.colorScheme) var colorScheme
    let plugin: PluginType
    let isInstalled: Bool
    let onToggle: () -> Void

    var cardBackground: Color {
        colorScheme == .light ? .white : Color(white: 0.18)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: plugin.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.displayName)
                        .font(.nunitoRegularBold(size: 14))
                        .foregroundColor(.primary)

                    Text(plugin.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(plugin.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer()

            // Install/Uninstall Button
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isInstalled ? "checkmark" : "arrow.down.circle")
                        .font(.system(size: 12, weight: .medium))
                    Text(isInstalled ? "Installed" : "Install")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isInstalled ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.15))
                .foregroundColor(isInstalled ? .green : .accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(height: 160)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Plugin Info View (for action editor)

struct PluginInfoView: View {
    let pluginType: PluginType
    let inputBackgroundColor: Color
    let textGrayColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Plugin type badge
            HStack {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
                Text("Native Plugin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(Capsule())

            // Plugin description
            Text(pluginType.description)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(textGrayColor)

            // Plugin-specific info
            VStack(alignment: .leading, spacing: 8) {
                pluginSpecificInfo
            }

            // Category
            HStack {
                Text("Category:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(pluginType.category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textGrayColor)
            }

            // Output type
            HStack {
                Text("Output:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(pluginType.outputsImage ? "Image" : "Text")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textGrayColor)
                if pluginType.outputsImage {
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(inputBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    var pluginSpecificInfo: some View {
        switch pluginType {
        case .qrGenerator:
            infoRow(icon: "qrcode", title: "Input", description: "Any text or URL to encode")
        case .jsonFormatter:
            infoRow(icon: "curlybraces", title: "Input", description: "Raw JSON to format and beautify")
        case .base64Encode:
            infoRow(icon: "arrow.right.circle", title: "Input", description: "Plain text to encode to Base64")
        case .base64Decode:
            infoRow(icon: "arrow.left.circle", title: "Input", description: "Base64 string to decode")
        case .colorConverter:
            infoRow(icon: "paintpalette", title: "Input", description: "HEX (#FF5733) or RGB (255, 87, 51)")
        case .uuidGenerator:
            infoRow(icon: "number.circle", title: "Input", description: "No input required - generates random UUID")
        case .hashGenerator:
            infoRow(icon: "lock.shield", title: "Input", description: "Text to generate MD5, SHA-256, SHA-512 hashes")
        case .urlEncode:
            infoRow(icon: "link", title: "Input", description: "Text with special characters to URL encode")
        case .urlDecode:
            infoRow(icon: "link.badge.plus", title: "Input", description: "URL encoded string to decode")
        case .wordCount:
            infoRow(icon: "textformat.123", title: "Input", description: "Text to count words, characters, lines")
        case .imageConverter:
            infoRow(icon: "photo.on.rectangle.angled", title: "Input", description: "Copy an image to clipboard, then run this action")
        }
    }

    func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textGrayColor)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
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
