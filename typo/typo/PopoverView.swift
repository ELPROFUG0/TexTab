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

    var filteredActions: [Action] {
        if searchText.isEmpty {
            return store.actions
        }
        return store.actions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let result = resultText, let action = activeAction {
                // Result view
                resultView(result: result, action: action)
            } else {
                // Main popup view
                mainView
            }
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
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
                            .onTapGesture {
                                onOpenSettings()
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

    // MARK: - Result View

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
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Result content
            ScrollView {
                Text(result)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(maxHeight: 250)

            Divider()

            // Footer hints
            HStack {
                HStack(spacing: 4) {
                    KeyboardKey("esc")
                    Text("back")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    KeyboardKey("⌘")
                    KeyboardKey("C")
                    Text("copy")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            // Action buttons
            HStack(spacing: 12) {
                Button("Copy") {
                    copyToClipboard(result)
                }
                .buttonStyle(.bordered)

                Button("Copy & Close") {
                    copyToClipboard(result)
                    onClose()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .onKeyPress(.escape) {
            resultText = nil
            activeAction = nil
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
            : Color(white: 0.2)
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
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
    PopoverView(onClose: {}, onOpenSettings: {})
        .frame(height: 420)
}
