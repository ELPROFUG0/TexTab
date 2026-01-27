//
//  ActionsView.swift
//  typo
//
//  Actions settings view for managing user actions
//

import SwiftUI
import AppKit

// MARK: - Actions Settings

struct ActionsSettingsView: View {
    @StateObject private var store = ActionsStore.shared
    @Binding var selectedAction: Action?
    @State private var showPaywall = false

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

                        // New Action button - below last action
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .black))
                            Text("New Action")
                                .font(.nunitoRegularBold(size: 14))

                            Spacer()
                        }
                        .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            addNewAction()
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)
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
        .paywall(isPresented: $showPaywall)
    }

    func addNewAction() {
        // Check if user can create a new action
        guard store.canCreateAction else {
            showPaywall = true
            return
        }

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
    @State private var shortcutConflict: String? = nil
    @State private var shortcutMonitor: Any? = nil

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
                            ShortcutTooltip(recordedKeys: recordedKeys, conflictName: shortcutConflict)
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
                                        ForEach(action.shortcutModifiers, id: \.self) { mod in
                                            ShortcutInputKey(text: mod)
                                        }
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
                                    .background(Color.clear)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .onChange(of: action.prompt) { _, _ in
                                        hasUnsavedChanges = true
                                    }
                            }
                            .frame(height: 220)

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
                                    .opacity(ActionsStore.shared.apiKey.isEmpty ? 0.4 : 1)
                                }
                                .buttonStyle(.plain)
                                .disabled(action.prompt.isEmpty || isImprovingPrompt || ActionsStore.shared.apiKey.isEmpty)
                                .help(ActionsStore.shared.apiKey.isEmpty ? "Connect an API key in the AI tab to use Enhance" : "Enhance prompt with AI")

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
                }
                .padding(24)

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
                .fixedSize(horizontal: true, vertical: true)
                .offset(x: 24, y: 68)
                .transition(.opacity)
            }
        }
        .onAppear {
            // Initialize recorded keys from existing shortcut
            if !action.shortcut.isEmpty {
                recordedKeys = action.shortcutModifiers + [action.shortcut]
            }
        }
    }

    func stopRecordingShortcut() {
        if let monitor = shortcutMonitor {
            NSEvent.removeMonitor(monitor)
            shortcutMonitor = nil
        }
        isRecordingShortcut = false
        shortcutConflict = nil
        recordedKeys = []
        globalAppDelegate?.resumeHotkeys()
    }

    func startRecordingShortcut() {
        // Remove any existing monitor first
        if let monitor = shortcutMonitor {
            NSEvent.removeMonitor(monitor)
            shortcutMonitor = nil
        }

        isRecordingShortcut = true
        recordedKeys = []
        shortcutConflict = nil

        // Suspend all hotkeys to prevent actions from firing during recording
        globalAppDelegate?.suspendHotkeys()

        // Monitor for key events (keyDown + flagsChanged for real-time modifier display)
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecordingShortcut else { return event }

            // Escape cancels recording
            if event.type == .keyDown && event.keyCode == 53 {
                withAnimation {
                    self.stopRecordingShortcut()
                }
                return nil
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Build current modifier keys array
            var currentModifiers: [String] = []
            if modifiers.contains(.control) { currentModifiers.append("^") }
            if modifiers.contains(.option) { currentModifiers.append("\u{2325}") }
            if modifiers.contains(.shift) { currentModifiers.append("\u{21E7}") }
            if modifiers.contains(.command) { currentModifiers.append("\u{2318}") }

            if event.type == .flagsChanged {
                // Clear conflict when modifiers change
                self.shortcutConflict = nil
                // Update recorded keys to show current modifiers in real-time
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    self.recordedKeys = currentModifiers
                }
                return event
            }

            if event.type == .keyDown {
                // Must have Command or Option to complete
                let hasCommand = modifiers.contains(.command)
                let hasOption = modifiers.contains(.option)

                if !hasCommand && !hasOption {
                    return event
                }

                // Add the final key
                let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
                if !key.isEmpty && key.count == 1 {
                    var finalKeys = currentModifiers
                    finalKeys.append(key)

                    // Check for conflicts with other actions (compare as sets to ignore order)
                    let currentModSet = Set(currentModifiers)
                    let conflictingAction = ActionsStore.shared.actions.first { other in
                        other.id != self.action.id &&
                        !other.shortcut.isEmpty &&
                        other.shortcut.uppercased() == key &&
                        Set(other.shortcutModifiers) == currentModSet
                    }

                    // Also check against the main popup hotkey (⌘⇧T)
                    let mainStore = ActionsStore.shared
                    let isMainHotkeyConflict = key == mainStore.mainShortcut.uppercased() && currentModSet == Set(mainStore.mainShortcutModifiers)

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.recordedKeys = finalKeys
                    }

                    // Determine conflict name
                    var conflictName: String? = nil
                    if isMainHotkeyConflict {
                        conflictName = "Open TexTab"
                    } else if let conflict = conflictingAction {
                        conflictName = conflict.name
                    }

                    if let name = conflictName {
                        // Show conflict error - don't save
                        withAnimation {
                            self.shortcutConflict = name
                        }
                        // Keep recording open so user can try again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.shortcutConflict != nil {
                                withAnimation {
                                    self.shortcutConflict = nil
                                    self.recordedKeys = []
                                }
                            }
                        }
                        return nil
                    }

                    self.action.shortcutModifiers = currentModifiers
                    self.action.shortcut = key
                    self.hasUnsavedChanges = true
                    self.shortcutConflict = nil

                    // Close tooltip after a delay and restore hotkeys
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.stopRecordingShortcut()
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
        // Show saved notification
        CopyNotificationWindow.show(message: "Action saved", icon: "checkmark")
    }

    func improvePromptWithAI() {
        let store = ActionsStore.shared
        guard !store.apiKey.isEmpty else { return }

        isImprovingPrompt = true

        let provider = store.selectedProvider
        let model = store.selectedModel
        let apiKey = store.apiKey

        Task {
            do {
                let improvedPrompt = try await PromptImprover.improve(
                    prompt: action.prompt,
                    provider: provider,
                    model: model,
                    apiKey: apiKey
                )
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
    var conflictName: String? = nil

    private var hasConflict: Bool { conflictName != nil }

    // Pad to at least 3 slots so all keys are visible
    private var displaySlots: [(id: String, text: String, filled: Bool)] {
        let slotCount = max(recordedKeys.count, 3)
        return (0..<slotCount).map { index in
            if index < recordedKeys.count {
                return (id: "slot-\(index)-\(recordedKeys[index])", text: recordedKeys[index], filled: true)
            } else {
                return (id: "empty-\(index)", text: "", filled: false)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tooltip content
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if !hasConflict {
                        Text("e.g.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    ForEach(displaySlots, id: \.id) { slot in
                        TooltipKey(text: slot.text, isError: hasConflict && slot.filled)
                            .opacity(slot.filled ? 1 : 0.4)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }

                if let conflictName = conflictName {
                    VStack(spacing: 4) {
                        Text("Already in use")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)

                        Text("Used by \"\(conflictName)\"")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                } else {
                    VStack(spacing: 4) {
                        Text("Recording...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Press \u{2318} or \u{2325} + key")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
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
                    .stroke(hasConflict ? Color.red.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: hasConflict ? 2 : 1)
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
    var isError: Bool = false

    var body: some View {
        ZStack {
            // Bottom layer (3D effect)
            RoundedRectangle(cornerRadius: 6)
                .fill(isError ? Color.red.opacity(0.6) : (colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.7)))
                .frame(width: 28, height: 28)
                .offset(y: 2)

            // Top layer
            RoundedRectangle(cornerRadius: 6)
                .fill(isError ? Color.red.opacity(0.15) : (colorScheme == .dark ? Color.white : Color(white: 0.95)))
                .frame(width: 28, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isError ? Color.red.opacity(0.5) : Color.gray.opacity(colorScheme == .dark ? 0 : 0.3), lineWidth: isError ? 2 : 1)
                )

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isError ? .red : .black)
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
    enum PromptImproverError: Error {
        case noApiKey
        case invalidResponse
        case networkError(Error)
    }

    static func improve(prompt: String, provider: AIProvider, model: AIModel, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw PromptImproverError.noApiKey
        }

        let url = URL(string: provider.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set authorization header based on provider
        if provider == .anthropic {
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

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

        let body: [String: Any]

        if provider == .anthropic {
            body = [
                "model": model.id,
                "max_tokens": 1024,
                "system": systemPrompt,
                "messages": [
                    ["role": "user", "content": "Improve this prompt: \(prompt)"]
                ]
            ]
        } else {
            body = [
                "model": model.id,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": "Improve this prompt: \(prompt)"]
                ]
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse response based on provider
        if provider == .anthropic {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstContent = content.first,
               let text = firstContent["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        throw PromptImproverError.invalidResponse
    }
}

// MARK: - Preview

#Preview {
    ActionsSettingsView(selectedAction: .constant(nil))
        .frame(width: 700, height: 520)
}
