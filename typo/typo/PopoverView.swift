//
//  PopoverView.swift
//  typo
//

import SwiftUI
import AppKit

struct PopoverView: View {
    @StateObject private var store = ActionsStore.shared
    @StateObject private var textManager = CapturedTextManager.shared
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @State private var isProcessing = false
    @State private var resultText: String?
    @State private var activeAction: Action?
    @State private var shouldScrollToSelection = false
    @FocusState private var isSearchFocused: Bool

    var onClose: () -> Void
    var onOpenSettings: () -> Void
    var initialAction: Action?

    var filteredActions: [Action] {
        if searchText.isEmpty {
            return store.actions
        }
        return store.actions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var popoverWidth: CGFloat {
        initialAction != nil ? 560 : 320
    }

    var body: some View {
        VStack(spacing: 0) {
            if let result = resultText, let action = activeAction {
                // Result view
                resultView(result: result, action: action)
            } else if isProcessing, let action = activeAction {
                // Loading view with skeleton
                loadingView(action: action)
            } else if initialAction == nil {
                // Main popup view (only when no initial action)
                mainView
            }
        }
        .frame(width: popoverWidth)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .onAppear {
            if let action = initialAction {
                activeAction = action
                isProcessing = true
                executeAction(action)
            }
        }
    }

    // MARK: - Main View

    var mainView: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                onSubmit: selectCurrentAction
            )
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }

            // Actions list
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                            ActionRow(
                                action: action,
                                isSelected: index == selectedIndex
                            )
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                executeAction(action)
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = index
                                }
                            }
                        }

                        // New Action button
                        NewActionRow(isSelected: filteredActions.count == selectedIndex)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onOpenSettings()
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = filteredActions.count
                                }
                            }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 340)
                .onChange(of: selectedIndex) { _, newValue in
                    if shouldScrollToSelection {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                        shouldScrollToSelection = false
                    }
                }
            }

            Divider()

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
                    KeyboardKey("↑")
                    KeyboardKey("↓")
                }

                Spacer()

                HStack(spacing: 4) {
                    KeyboardKey("↵")
                    Text("select")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onKeyPress(.upArrow) {
            shouldScrollToSelection = true
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            shouldScrollToSelection = true
            selectedIndex = min(filteredActions.count, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .onKeyPress(.return) {
            selectCurrentAction()
            return .handled
        }
    }

    // MARK: - Loading View (Action Popup)

    func loadingView(action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Button(action: {
                    isProcessing = false
                    activeAction = nil
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Skeleton text area - expands to fill available space
            VStack(alignment: .leading, spacing: 14) {
                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: 420)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: 380)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: 320)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: 400)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                ShimmerView()
                    .frame(height: 14)
                    .frame(maxWidth: 280)

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            // Footer
            HStack {
                HStack(spacing: 4) {
                    KeyboardKey("esc")
                    Text("cancel")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Processing...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.escape) {
            isProcessing = false
            activeAction = nil
            onClose()
            return .handled
        }
    }

    // MARK: - Result View (Action Popup)

    func resultView(result: String, action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Button(action: {
                    resultText = nil
                    activeAction = nil
                    if initialAction != nil {
                        onClose()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Result content - expands to fill available space
            ScrollView {
                Text(result)
                    .font(.system(size: 14))
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with buttons
            HStack {
                HStack(spacing: 4) {
                    KeyboardKey("esc")
                    Text("close")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("Copy") {
                        copyToClipboard(result)
                    }
                    .buttonStyle(.bordered)

                    Button("Replace") {
                        replaceOriginalText(with: result)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.escape) {
            resultText = nil
            activeAction = nil
            if initialAction != nil {
                onClose()
            }
            return .handled
        }
    }

    // MARK: - Actions

    func selectCurrentAction() {
        if selectedIndex < filteredActions.count {
            executeAction(filteredActions[selectedIndex])
        } else {
            onOpenSettings()
        }
    }

    func executeAction(_ action: Action) {
        let textToProcess = textManager.capturedText

        guard !textToProcess.isEmpty else {
            resultText = "No text selected. Select some text first!"
            activeAction = action
            return
        }

        isProcessing = true
        activeAction = action

        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: action.prompt,
                    text: textToProcess,
                    apiKey: store.apiKey,
                    provider: store.selectedProvider
                )
                await MainActor.run {
                    resultText = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    resultText = "Error: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func replaceOriginalText(with text: String) {
        // Copy the result to clipboard
        copyToClipboard(text)

        // Close the popup first
        onClose()

        // Small delay to let the popup close and focus return to original app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Simulate Cmd+V to paste
            let source = CGEventSource(stateID: .combinedSessionState)

            // Key down V with Cmd
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
            vDown?.flags = .maskCommand

            // Key up V
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand

            // Post events
            vDown?.post(tap: .cgSessionEventTap)
            vUp?.post(tap: .cgSessionEventTap)
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 1).opacity(0.1)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))

            TextField("Search actions...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.nunitoRegularBold(size: 14))
                .focused(isSearchFocused)
                .onSubmit {
                    onSubmit()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
}

// MARK: - Action Row

struct ActionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let action: Action
    let isSelected: Bool

    // Selected background color: light gray
    var selectedBackgroundColor: Color {
        if !isSelected {
            return Color.clear
        }
        return colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 0.2)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 24)

            Text(action.name)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(Color.gray)

            Spacer()

            if !action.shortcut.isEmpty {
                HStack(spacing: 4) {
                    KeyboardKey("⌘")
                    KeyboardKey("⇧")
                    KeyboardKey(action.shortcut)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedBackgroundColor)
        )
    }
}

// MARK: - New Action Row

struct NewActionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let isSelected: Bool

    var selectedBackgroundColor: Color {
        if !isSelected {
            return Color.clear
        }
        return colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 0.2)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.0, green: 0.584, blue: 1.0))

            Text("New Action")
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(Color.gray)

            Spacer()

            HStack(spacing: 4) {
                KeyboardKey("⌘")
                KeyboardKey("⇧")
                KeyboardKey("N")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedBackgroundColor)
        )
    }
}

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.6)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Keyboard Key

struct KeyboardKey: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    PopoverView(onClose: {}, onOpenSettings: {}, initialAction: nil)
        .frame(height: 420)
}
