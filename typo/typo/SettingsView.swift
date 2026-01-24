//
//  SettingsView.swift
//  typo
//

import SwiftUI
import AppKit

// MARK: - Custom Font Extension

extension Font {
    static func nunitoBlack(size: CGFloat) -> Font {
        return .custom("Nunito Black", size: size)
    }

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
                TabTextButton(title: "Templates", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabTextButton(title: "Plugins", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
                TabTextButton(title: "About", isSelected: selectedTab == 4) {
                    selectedTab = 4
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
                TemplatesView(onNavigateToActions: { action in
                    selectedAction = action
                    selectedTab = 1
                })
            case 3:
                PluginsMarketplaceView()
            case 4:
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
    @Environment(\.colorScheme) var colorScheme
    @State private var mousePosition: CGPoint = .zero
    @State private var isHovering: Bool = false

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // Card color - #63C7FF
    private var cardColor: Color {
        Color(red: 0.388, green: 0.78, blue: 1.0) // #63C7FF
    }

    var body: some View {
        HStack(spacing: 50) {
            // Left side - Membership Style Parallax Card
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2

                // Calculate rotation based on mouse position
                let rotateX = isHovering ? (mousePosition.y - centerY) / 18 : 0
                let rotateY = isHovering ? -(mousePosition.x - centerX) / 18 : 0

                ZStack {
                    // Main Card
                    ZStack {
                        // Card background - solid color #00A1FF
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardColor)

                        // Card content - all elements move with the card
                        VStack(alignment: .leading, spacing: 0) {
                            // Top section - Member info
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MEMBER SINCE")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                        .tracking(1.2)

                                    Text("01/26")
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                // Pro badge
                                HStack(spacing: 6) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 12))
                                    Text("PRO")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                            Spacer()

                            // Center - Title/Rank with decorative element
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Text")
                                    .font(.nunitoBlack(size: 44))
                                    .foregroundColor(.white)

                                Text("Master")
                                    .font(.nunitoBlack(size: 44))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 24)

                            Spacer()

                            // Bottom section - Stats
                            VStack(spacing: 14) {
                                // Separator line
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)

                                // Stats row
                                HStack(spacing: 0) {
                                    // Typos fixed
                                    VStack(spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "laurel.leading")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.7))

                                            Text("42")
                                                .font(.nunitoBlack(size: 32))
                                                .foregroundColor(.white)

                                            Image(systemName: "laurel.trailing")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        Text("Fixes")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)

                                    // Divider
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 1, height: 55)

                                    // Days active
                                    VStack(spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "laurel.leading")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.7))

                                            Text("14")
                                                .font(.nunitoBlack(size: 32))
                                                .foregroundColor(.white)

                                            Image(systemName: "laurel.trailing")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        Text("Days")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                }

                                // Bottom separator line
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }

                        // Subtle inner border
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .frame(width: 280, height: 400)
                    .shadow(
                        color: cardColor.opacity(isHovering ? 0.4 : 0.25),
                        radius: isHovering ? 30 : 20,
                        x: 0,
                        y: isHovering ? 15 : 10
                    )
                    .rotation3DEffect(
                        .degrees(Double(rotateX)),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                    .rotation3DEffect(
                        .degrees(Double(rotateY)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .scaleEffect(isHovering ? 1.04 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovering)
                    .animation(.spring(response: 0.15, dampingFraction: 0.8), value: mousePosition)
                    .position(x: centerX, y: centerY)
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mousePosition = location
                        isHovering = true
                    case .ended:
                        isHovering = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            mousePosition = CGPoint(x: centerX, y: centerY)
                        }
                    }
                }
            }
            .frame(width: 340)

            // Right side - Text and Buttons
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                // App name and version
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typo")
                        .font(.nunitoBold(size: 36))
                        .foregroundColor(.primary)

                    Text("Version 1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Description
                Text("Transform text with AI-powered shortcuts. Select any text and use keyboard shortcuts to fix grammar, translate, rephrase, and more.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: 8)

                // Action buttons - vertical stack
                VStack(spacing: 12) {
                    // Check for Updates button - primary style
                    Button(action: {
                        if let url = URL(string: "https://typo.app/updates") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .medium))
                            Text("Check for Updates")
                                .font(.nunitoRegularBold(size: 14))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.0, green: 0.45, blue: 0.8))
                                    .offset(y: 3)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appBlue)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    // Support button - secondary style
                    Button(action: {
                        if let url = URL(string: "https://typo.app/support") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14, weight: .medium))
                            Text("Support")
                                .font(.nunitoRegularBold(size: 14))
                            Spacer()
                        }
                        .foregroundColor(appBlue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appBlue.opacity(0.25))
                                    .offset(y: 3)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appBlue.opacity(0.12))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    // Manage Account button - secondary style
                    Button(action: {
                        if let url = URL(string: "https://typo.app/account") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 14, weight: .medium))
                            Text("Manage Account")
                                .font(.nunitoRegularBold(size: 14))
                            Spacer()
                        }
                        .foregroundColor(appBlue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appBlue.opacity(0.25))
                                    .offset(y: 3)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appBlue.opacity(0.12))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
                .frame(maxWidth: 260)

                Spacer()

                // Footer
                Text("Made with SwiftUI")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 40)
        }
        .padding(.leading, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Plugins Marketplace View

struct PluginsMarketplaceView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store = ActionsStore.shared
    @State private var selectedPlugin: PluginType? = nil

    // Adaptive gray: darker in light mode, lighter in dark mode
    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar - Plugins list
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(PluginType.allCases, id: \.self) { plugin in
                            PluginListRow(
                                plugin: plugin,
                                isSelected: selectedPlugin == plugin,
                                isInstalled: store.isPluginInstalled(plugin)
                            )
                            .onTapGesture {
                                selectedPlugin = plugin
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)

                // Coming soon text
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                    Text("More coming soon...")
                        .font(.nunitoRegularBold(size: 13))
                }
                .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
            }
            .frame(width: 220)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Plugin Detail or Empty State
            if let plugin = selectedPlugin {
                PluginDetailView(
                    plugin: plugin,
                    isInstalled: store.isPluginInstalled(plugin),
                    onToggle: {
                        if store.isPluginInstalled(plugin) {
                            store.uninstallPlugin(plugin)
                        } else {
                            store.installPlugin(plugin)
                        }
                    }
                )
            } else {
                // Empty state with dot pattern background
                ZStack {
                    DotPatternView()

                    VStack(spacing: 24) {
                        // Plugin icon - 3D style
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

                            Image(systemName: "puzzlepiece.extension")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(width: 64, height: 68)

                        VStack(spacing: 10) {
                            Text("No Plugin Selected")
                                .font(.nunitoBold(size: 20))
                                .foregroundColor(.primary)

                            Text("Select a plugin from the list to see\ndetails and install it.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

// MARK: - Plugin List Row

struct PluginListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let plugin: PluginType
    let isSelected: Bool
    let isInstalled: Bool

    // Selected background color
    var selectedBackgroundColor: Color {
        if !isSelected {
            return Color.clear
        }
        return colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color.accentColor.opacity(0.1)
    }

    // Adaptive gray
    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: plugin.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textGrayColor)
                .frame(width: 24)

            // Name
            Text(plugin.displayName)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(textGrayColor)
                .lineLimit(1)

            Spacer()

            // Installed indicator
            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
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

// MARK: - Plugin Detail View

struct PluginDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    let plugin: PluginType
    let isInstalled: Bool
    let onToggle: () -> Void

    var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(NSColor.controlBackgroundColor)
    }

    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon and name
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: plugin.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(textGrayColor)
                            .frame(width: 36, height: 36)

                        Text(plugin.displayName)
                            .font(.nunitoBold(size: 22))
                            .foregroundColor(textGrayColor)

                        Spacer()
                    }

                    // Category badge
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                        Text(plugin.category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.0, green: 0.584, blue: 1.0).opacity(0.1))
                    .clipShape(Capsule())

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.nunitoRegularBold(size: 14))
                            .foregroundColor(textGrayColor)

                        Text(plugin.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(inputBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                    // Plugin info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.nunitoRegularBold(size: 14))
                            .foregroundColor(textGrayColor)

                        // Input type
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Input:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(pluginInputDescription)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(textGrayColor)
                        }

                        // Output type
                        HStack {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Output:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(plugin.outputsImage ? "Image" : "Text")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(textGrayColor)
                            if plugin.outputsImage {
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

                    Spacer()
                }
                .padding(24)
            }

            Divider()

            // Bottom action bar
            HStack {
                if isInstalled {
                    Text("This plugin is installed")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Install/Uninstall button - 3D style like Actions
                Button(action: onToggle) {
                    Text(isInstalled ? "Uninstall" : "Install")
                        .font(.nunitoBold(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                // Bottom layer (3D effect)
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(isInstalled ? Color(red: 0.6, green: 0.2, blue: 0.2) : Color(red: 0.0, green: 0.45, blue: 0.8))
                                    .offset(y: 3)

                                // Top layer
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(isInstalled ? Color.red.opacity(0.8) : Color(red: 0.0, green: 0.584, blue: 1.0))
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    var pluginInputDescription: String {
        switch plugin {
        case .qrGenerator:
            return "Text or URL"
        case .imageConverter:
            return "Image from clipboard"
        case .colorPicker:
            return "None (picks from screen)"
        }
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
        case .imageConverter:
            infoRow(icon: "photo.on.rectangle.angled", title: "Input", description: "Copy an image to clipboard, then run this action")
        case .colorPicker:
            infoRow(icon: "eyedropper", title: "Input", description: "No input required - click anywhere on screen to pick a color")
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

// MARK: - Prompt Suggestion Model

struct PromptSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let prompt: String
    let icon: String
    let category: PromptCategory
}

enum PromptCategory: String, CaseIterable {
    case writing = "Writing"
    case coding = "Coding"
    case productivity = "Productivity"
    case creative = "Creative"
    case analysis = "Analysis"

    var icon: String {
        switch self {
        case .writing: return "pencil.line"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .productivity: return "briefcase"
        case .creative: return "paintbrush"
        case .analysis: return "chart.bar.xaxis"
        }
    }

    var color: Color {
        switch self {
        case .writing: return Color(red: 0.45, green: 0.55, blue: 0.70)    // Soft slate blue
        case .coding: return Color(red: 0.55, green: 0.50, blue: 0.65)     // Muted lavender
        case .productivity: return Color(red: 0.50, green: 0.60, blue: 0.55) // Sage green
        case .creative: return Color(red: 0.65, green: 0.55, blue: 0.50)   // Warm taupe
        case .analysis: return Color(red: 0.60, green: 0.52, blue: 0.58)   // Dusty rose
        }
    }
}

// Predefined prompt suggestions
let promptSuggestions: [PromptSuggestion] = [
    // Writing
    PromptSuggestion(
        name: "Fix Grammar",
        prompt: "Fix the grammar and spelling errors in the following text. Return only the corrected text without explanations:",
        icon: "pencil",
        category: .writing
    ),
    PromptSuggestion(
        name: "Rephrase Text",
        prompt: "Rephrase the following text to make it clearer and more engaging while preserving the original meaning. Return only the rephrased text:",
        icon: "arrow.triangle.2.circlepath",
        category: .writing
    ),
    PromptSuggestion(
        name: "Make Concise",
        prompt: "Make the following text more concise while keeping all key information. Remove unnecessary words and redundancy. Return only the shortened text:",
        icon: "arrow.down.left.and.arrow.up.right",
        category: .writing
    ),
    PromptSuggestion(
        name: "Formalize",
        prompt: "Rewrite the following text in a formal, professional tone suitable for business communication. Return only the rewritten text:",
        icon: "doc.text",
        category: .writing
    ),
    PromptSuggestion(
        name: "Make Casual",
        prompt: "Rewrite the following text in a friendly, casual tone. Make it sound natural and conversational. Return only the rewritten text:",
        icon: "face.smiling",
        category: .writing
    ),
    PromptSuggestion(
        name: "Summarize",
        prompt: "Summarize the following text in 2-3 sentences, capturing the main points. Return only the summary:",
        icon: "text.alignleft",
        category: .writing
    ),

    // Coding
    PromptSuggestion(
        name: "Improve AI Prompt",
        prompt: "Improve this prompt to get better results from AI assistants like Claude, GPT, or Copilot. Make it more specific, add context, define the expected output format, include constraints, and add relevant examples if helpful. Explain what makes the improved version better. Return the improved prompt ready to use:",
        icon: "sparkles",
        category: .coding
    ),
    PromptSuggestion(
        name: "Explain Code",
        prompt: "Explain what this code does in simple terms. Include what inputs it takes and what it returns:",
        icon: "questionmark.circle",
        category: .coding
    ),
    PromptSuggestion(
        name: "Add Comments",
        prompt: "Add clear, helpful comments to this code explaining what each section does. Return the code with comments:",
        icon: "text.bubble",
        category: .coding
    ),
    PromptSuggestion(
        name: "Fix Bug",
        prompt: "Find and fix any bugs in this code. Explain what was wrong and return the corrected code:",
        icon: "ant",
        category: .coding
    ),
    PromptSuggestion(
        name: "Optimize Code",
        prompt: "Optimize this code for better performance and readability. Return the improved code with brief explanation of changes:",
        icon: "bolt",
        category: .coding
    ),
    PromptSuggestion(
        name: "Convert to Swift",
        prompt: "Convert this code to Swift, using modern Swift conventions and best practices. Return only the Swift code:",
        icon: "swift",
        category: .coding
    ),
    PromptSuggestion(
        name: "Write Tests",
        prompt: "Write unit tests for this code covering the main functionality and edge cases:",
        icon: "checkmark.seal",
        category: .coding
    ),
    PromptSuggestion(
        name: "Markdown to HTML",
        prompt: "Convert this Markdown text to clean, semantic HTML. Return only the HTML code:",
        icon: "chevron.left.forwardslash.chevron.right",
        category: .coding
    ),
    PromptSuggestion(
        name: "HTML to Markdown",
        prompt: "Convert this HTML to clean Markdown format. Return only the Markdown text:",
        icon: "text.document",
        category: .coding
    ),

    // Productivity
    PromptSuggestion(
        name: "Extract Tasks",
        prompt: "Extract all action items and tasks from this text. List them as a numbered checklist:",
        icon: "checklist",
        category: .productivity
    ),
    PromptSuggestion(
        name: "Meeting Notes",
        prompt: "Convert these meeting notes into a structured format with: Key Decisions, Action Items, and Next Steps:",
        icon: "person.3",
        category: .productivity
    ),
    PromptSuggestion(
        name: "Email Reply",
        prompt: "Write a professional reply to this email. Be polite and address all the points mentioned:",
        icon: "envelope",
        category: .productivity
    ),
    PromptSuggestion(
        name: "Create Outline",
        prompt: "Create a detailed outline from this content with main topics and subtopics:",
        icon: "list.bullet.indent",
        category: .productivity
    ),

    // Creative
    PromptSuggestion(
        name: "Expand Idea",
        prompt: "Expand on this idea with more details, examples, and creative additions. Keep the original concept but make it richer:",
        icon: "lightbulb",
        category: .creative
    ),
    PromptSuggestion(
        name: "Write Headline",
        prompt: "Write 5 catchy, engaging headlines for this content. Make them attention-grabbing but not clickbait:",
        icon: "textformat.size",
        category: .creative
    ),
    PromptSuggestion(
        name: "Social Post",
        prompt: "Transform this into an engaging social media post. Keep it concise and add relevant hashtag suggestions:",
        icon: "bubble.left.and.bubble.right",
        category: .creative
    ),
    PromptSuggestion(
        name: "Story Hook",
        prompt: "Write a compelling opening hook or introduction for this content that grabs attention:",
        icon: "book",
        category: .creative
    ),

    // Analysis
    PromptSuggestion(
        name: "Pros & Cons",
        prompt: "Analyze this and list the pros and cons in two separate lists. Be objective and thorough:",
        icon: "scale.3d",
        category: .analysis
    ),
    PromptSuggestion(
        name: "Key Points",
        prompt: "Extract the 5 most important key points from this text. List them in order of importance:",
        icon: "star",
        category: .analysis
    ),
    PromptSuggestion(
        name: "Compare",
        prompt: "Compare and contrast the items mentioned in this text. Highlight similarities and differences:",
        icon: "arrow.left.arrow.right",
        category: .analysis
    ),
    PromptSuggestion(
        name: "Fact Check",
        prompt: "Identify any claims in this text that may need verification. Note which statements are opinions vs facts:",
        icon: "magnifyingglass",
        category: .analysis
    ),
]

// MARK: - Templates View (Grid of Cards)

struct TemplatesView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store = ActionsStore.shared
    @State private var selectedCategory: PromptCategory? = nil
    @State private var addedTemplateId: UUID? = nil
    var onNavigateToActions: (Action) -> Void

    var filteredTemplates: [PromptSuggestion] {
        if let category = selectedCategory {
            return promptSuggestions.filter { $0.category == category }
        }
        return promptSuggestions
    }

    var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(NSColor.controlBackgroundColor)
    }

    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    func addTemplateToActions(_ template: PromptSuggestion) {
        let newAction = Action(
            name: template.name,
            icon: template.icon,
            prompt: template.prompt,
            shortcut: "",
            actionType: .ai
        )
        store.addAction(newAction)

        // Show confirmation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            addedTemplateId = template.id
        }

        // Navigate to Actions tab after a short delay and select the new action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                addedTemplateId = nil
            }
            onNavigateToActions(newAction)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with category filter
            VStack(spacing: 12) {
                HStack {
                    Text("Prompt Templates")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(textGrayColor)

                    Spacer()

                    Text("Click to add to Actions")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Category pills
                HStack(spacing: 8) {
                    TemplateCategoryPill(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        textColor: textGrayColor,
                        backgroundColor: inputBackgroundColor
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(PromptCategory.allCases, id: \.self) { category in
                        TemplateCategoryPill(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            textColor: textGrayColor,
                            backgroundColor: inputBackgroundColor
                        ) {
                            selectedCategory = category
                        }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Templates grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(
                            template: template,
                            isAdded: addedTemplateId == template.id,
                            onTap: {
                                addTemplateToActions(template)
                            }
                        )
                    }
                }
                .padding(24)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Template Category Pill

struct TemplateCategoryPill: View {
    let title: String
    let isSelected: Bool
    var textColor: Color
    var backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? textColor.opacity(0.5) : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    @Environment(\.colorScheme) var colorScheme
    let template: PromptSuggestion
    let isAdded: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(NSColor.controlBackgroundColor)
    }

    var textGrayColor: Color {
        colorScheme == .light
            ? Color(white: 0.35)
            : Color(white: 0.65)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon and name header
                HStack(spacing: 10) {
                    // Icon with subtle 3D effect
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(template.category.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .offset(y: 2)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(template.category.color.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: template.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(template.category.color.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(textGrayColor)
                            .lineLimit(1)

                        Text(template.category.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(template.category.color)
                    }

                    Spacer()

                    // Added checkmark or hover indicator
                    if isAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else if isHovered {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(12)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)

                // Prompt preview
                Text(template.prompt)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAdded ? Color.green.opacity(0.05) : inputBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isAdded ? Color.green.opacity(0.3) :
                        isHovered ? Color(red: 0.0, green: 0.584, blue: 1.0).opacity(0.5) :
                        Color.gray.opacity(0.15),
                        lineWidth: isHovered || isAdded ? 2 : 1
                    )
            )
            .scaleEffect(isHovered && !isAdded ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAdded)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(isAdded)
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
