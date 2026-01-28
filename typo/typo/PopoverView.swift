//
//  PopoverView.swift
//  typo
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Pointer Cursor Modifier

extension View {
    func pointerCursor() -> some View {
        self.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Web Search Detection

// Detect if prompt requires web search based on keywords
func promptRequiresWebSearch(_ prompt: String) -> Bool {
    let lowercased = prompt.lowercased()
    let webSearchKeywords = [
        "search", "buscar", "busca", "google", "web",
        "internet", "online", "find online", "look up",
        "latest", "current", "recent", "today", "news",
        "actualidad", "noticias", "último", "última",
        "what is", "who is", "where is", "when is",
        "qué es", "quién es", "dónde", "cuándo"
    ]

    return webSearchKeywords.contains { lowercased.contains($0) }
}

struct PopoverView: View {
    @StateObject private var store = ActionsStore.shared
    @StateObject private var textManager = CapturedTextManager.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedIndex = 0
    @State private var isProcessing = false
    @State private var resultText: String?
    @State private var resultImage: NSImage?
    @State private var activeAction: Action?
    @State private var shouldScrollToSelection = false

    // Image converter states
    @State private var clipboardImage: NSImage?
    @State private var selectedImageFormat: ImageFormat = .png
    @State private var jpegQuality: Double = 0.9
    @State private var convertedImageData: Data?
    @State private var showImageConverter = false

    // Chat state
    @State private var showChat = false

    // Quick prompt state
    @State private var quickPromptText: String = ""
    @FocusState private var isQuickPromptFocused: Bool
    @State private var showPaywall = false

    // Theme preference (using AppStorage for automatic updates)
    @AppStorage("appTheme") private var appTheme: String = "System"
    @Environment(\.colorScheme) var colorScheme

    var onClose: () -> Void
    var onOpenSettings: () -> Void
    var initialAction: Action?

    var popoverWidth: CGFloat {
        initialAction != nil ? 560 : 320
    }

    // Get saved color scheme for theme
    private var savedColorScheme: ColorScheme? {
        switch appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // System follows OS
        }
    }

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // Show login required message when not authenticated
                loginRequiredPopup
            } else if showChat {
                // Chat view
                ChatView(onClose: {
                    showChat = false
                })
                .onAppear {
                    // Notify AppDelegate to suspend click-outside monitor
                    NotificationCenter.default.post(name: NSNotification.Name("ChatOpened"), object: nil)
                }
                .onDisappear {
                    // Notify AppDelegate to restore click-outside monitor
                    NotificationCenter.default.post(name: NSNotification.Name("ChatClosed"), object: nil)
                }
            } else {
                VStack(spacing: 0) {
                    if showImageConverter, let action = activeAction {
                        // Image converter view
                        imageConverterView(action: action)
                    } else if let image = resultImage, let action = activeAction {
                        // Image result view (for plugins like QR generator)
                        imageResultView(image: image, action: action)
                    } else if let result = resultText, let action = activeAction {
                        // Text result view
                        resultView(result: result, action: action)
                    } else if let action = activeAction, isProcessing {
                        // Loading view with skeleton
                        loadingView(action: action)
                    } else if let action = initialAction, activeAction == nil {
                        // Initial loading state when action is provided but not yet started
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
            }
        }
        .preferredColorScheme(savedColorScheme)
        .paywall(isPresented: $showPaywall)
        .onAppear {
            // Reset all states when popup appears
            clipboardImage = nil
            showImageConverter = false
            convertedImageData = nil
            resultText = nil
            resultImage = nil

            if let action = initialAction {
                activeAction = action
                isProcessing = true
                executeAction(action)
            } else {
                activeAction = nil
                isProcessing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isQuickPromptFocused = true
                }
            }
        }
    }

    // MARK: - Login Required Popup

    private var loginRequiredPopup: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("logo textab")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)

            Text("Sign In Required")
                .font(.nunitoBold(size: 20))
                .foregroundColor(.primary)

            Text("Please sign in to use TexTab")
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Sign Up button - Black 3D style
            Button(action: {
                onOpenSettings()
            }) {
                Text("Sign Up")
                    .font(.nunitoBold(size: 15))
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "333333"))
                                .offset(y: 5)
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "1a1a1a"))
                        }
                    )
            }
            .buttonStyle(PopoverNoFadeButtonStyle())
            .pointerCursor()

            Spacer()

            // Footer
            HStack(spacing: 4) {
                KeyboardKey("esc")
                Text("close")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }

    // MARK: - Main View

    var mainView: some View {
        VStack(spacing: 0) {
            // Chat button (only if chat plugin is installed)
            if store.isPluginInstalled(.chat) {
                ChatButtonView(onTap: {
                    showChat = true
                })
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)
            }

            // Quick prompt input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(appBlue)

                TextField("Tell AI what to do...", text: $quickPromptText)
                    .textFieldStyle(.plain)
                    .font(.nunitoRegularBold(size: 14))
                    .foregroundColor(.primary)
                    .focused($isQuickPromptFocused)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .padding(.top, store.isPluginInstalled(.chat) ? 0 : 10)

            // Selected text preview (full width)
            if !textManager.capturedText.isEmpty {
                Text(textManager.capturedText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        colorScheme == .light
                            ? Color(red: 241/255, green: 241/255, blue: 239/255)
                            : Color(white: 1).opacity(0.05)
                    )
            }

            // Content area (fixed height)
            ZStack {
                // Actions list
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(store.actions.enumerated()), id: \.element.id) { index, action in
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
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                            }

                            // New Action button
                            NewActionRow(isSelected: store.actions.count == selectedIndex)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onOpenSettings()
                                }
                                .onHover { hovering in
                                    if hovering {
                                        selectedIndex = store.actions.count
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                        }
                        .padding(8)
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        if shouldScrollToSelection {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                            shouldScrollToSelection = false
                        }
                    }
                }
                .opacity(quickPromptText.isEmpty ? 1 : 0)

                // Quick prompt preview (shown while typing)
                if !quickPromptText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "return")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color(red: 235/255, green: 235/255, blue: 233/255)
                                        : Color(white: 1).opacity(0.08))
                            )

                        Text("Quick Action")
                            .font(.nunitoRegularBold(size: 15))
                            .foregroundColor(.primary)

                        Text(quickPromptText)
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(appBlue)
                            )

                        Text("Press Enter to run")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 340)

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
                    Text("navigate")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
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
            guard !isQuickPromptFocused else { return .ignored }
            shouldScrollToSelection = true
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !isQuickPromptFocused else { return .ignored }
            shouldScrollToSelection = true
            selectedIndex = min(store.actions.count, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            if isQuickPromptFocused && !quickPromptText.isEmpty {
                quickPromptText = ""
                return .handled
            }
            onClose()
            return .handled
        }
        .onKeyPress(.return) {
            if !quickPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                executeQuickPrompt()
                return .handled
            }
            selectCurrentAction()
            return .handled
        }
    }

    func executeQuickPrompt() {
        let prompt = quickPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        guard authManager.isPro else {
            showPaywall = true
            return
        }

        let quickAction = Action(
            name: "Quick Prompt",
            icon: "bolt.fill",
            prompt: prompt,
            shortcut: "",
            shortcutModifiers: []
        )

        quickPromptText = ""
        onClose()

        globalAppDelegate?.pendingAction = quickAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            globalAppDelegate?.showPopoverWithAction(skipCapture: true)
        }
    }

    // MARK: - Loading View (Action Popup)

    func loadingView(action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(appBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appBlue.opacity(0.1))
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
                .pointerCursor()
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

                ProgressView()
                    .scaleEffect(0.7)
                    .frame(height: 31)
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

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // MARK: - Result View (Action Popup)

    func resultView(result: String, action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(appBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if promptRequiresWebSearch(action.prompt) {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                if action.isPlugin {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

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
                .pointerCursor()
            }
            .padding(16)

            Divider()

            // Result content - expands to fill available space
            ScrollView {
                MarkdownView(text: result)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .textSelection(.enabled)
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

                HStack(spacing: 10) {
                    // Copy button - secondary style
                    Button(action: {
                        copyToClipboard(result)
                    }) {
                        Text("Copy")
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(appBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(appBlue.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    if !promptRequiresWebSearch(action.prompt) && !action.isPlugin {
                        // Replace button - primary style
                        Button(action: {
                            replaceOriginalText(with: result)
                        }) {
                            Text("Replace")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(appBlue)
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
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

    // MARK: - Image Result View (for plugins like QR generator)

    func imageResultView(image: NSImage, action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(appBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    resultImage = nil
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
                .pointerCursor()
            }
            .padding(16)

            Divider()

            // Image content with input text
            ScrollView {
                VStack(spacing: 16) {
                    // QR Code image
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .padding(.top, 20)

                    // Show the encoded text
                    if !textManager.capturedText.isEmpty {
                        VStack(spacing: 4) {
                            Text("Encoded content:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(textManager.capturedText)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 10)
                    }
                }
                .frame(maxWidth: .infinity)
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

                HStack(spacing: 10) {
                    // Copy button - secondary style
                    Button(action: {
                        copyImageToClipboard(image)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                            Text("Copy")
                                .font(.nunitoRegularBold(size: 13))
                        }
                        .foregroundColor(appBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(appBlue.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    // Save button - primary style
                    Button(action: {
                        saveImage(image)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 11))
                            Text("Save")
                                .font(.nunitoRegularBold(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(appBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.escape) {
            resultImage = nil
            activeAction = nil
            if initialAction != nil {
                onClose()
            }
            return .handled
        }
    }

    // MARK: - Image Converter View

    func imageConverterView(action: Action) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(appBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showImageConverter = false
                    clipboardImage = nil
                    activeAction = nil
                    convertedImageData = nil
                    if initialAction != nil {
                        onClose()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(16)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Image preview
                    if let image = clipboardImage {
                        VStack(spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 300, maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                // Remove image button
                                Button(action: {
                                    clipboardImage = nil
                                    convertedImageData = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 8, y: -8)
                            }

                            Text(PluginProcessor.shared.getImageInfo(image))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                    } else {
                        // No image state
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)

                            Text("No image loaded")
                                .font(.nunitoRegularBold(size: 14))
                                .foregroundColor(.secondary)

                            Text("Copy an image and click the button below")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)

                            Button(action: {
                                if let image = PluginProcessor.shared.getImageFromClipboard() {
                                    clipboardImage = image
                                    convertedImageData = nil
                                    updateConvertedPreview()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 12))
                                    Text("Paste Image")
                                        .font(.nunitoRegularBold(size: 13))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(red: 0.0, green: 0.45, blue: 0.8))
                                            .offset(y: 2)
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(appBlue)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .pointerCursor()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }

                    // Format selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Output Format")
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(.primary)

                        // Format buttons grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(ImageFormat.allCases, id: \.self) { format in
                                Button(action: {
                                    selectedImageFormat = format
                                }) {
                                    Text(format.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(selectedImageFormat == format ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedImageFormat == format ? appBlue : Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .pointerCursor()
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Quality slider for JPEG
                    if selectedImageFormat == .jpeg {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Quality")
                                    .font(.nunitoRegularBold(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int(jpegQuality * 100))%")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.1)
                                .tint(appBlue)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Converted size preview
                    if let data = convertedImageData {
                        let sizeKB = Double(data.count) / 1024.0
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            if sizeKB > 1024 {
                                Text("Converted: \(String(format: "%.1f", sizeKB / 1024.0)) MB")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Converted: \(String(format: "%.1f", sizeKB)) KB")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
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

                HStack(spacing: 10) {
                    // Refresh from clipboard - secondary style
                    Button(action: {
                        if let image = PluginProcessor.shared.getImageFromClipboard() {
                            clipboardImage = image
                            convertedImageData = nil
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(appBlue)
                            .padding(10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appBlue.opacity(0.3))
                                        .offset(y: 2)
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appBlue.opacity(0.15))
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .help("Refresh from clipboard")

                    // Convert button - primary style
                    Button(action: {
                        convertAndSaveImage()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("Convert & Save")
                                .font(.nunitoRegularBold(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(clipboardImage == nil ? Color.gray.opacity(0.4) : Color(red: 0.0, green: 0.45, blue: 0.8))
                                    .offset(y: 2)
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(clipboardImage == nil ? Color.gray.opacity(0.3) : appBlue)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .disabled(clipboardImage == nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.escape) {
            showImageConverter = false
            clipboardImage = nil
            activeAction = nil
            convertedImageData = nil
            if initialAction != nil {
                onClose()
            }
            return .handled
        }
        .onChange(of: selectedImageFormat) { _, _ in
            // Update preview when format changes
            updateConvertedPreview()
        }
        .onChange(of: jpegQuality) { _, _ in
            // Update preview when quality changes
            if selectedImageFormat == .jpeg {
                updateConvertedPreview()
            }
        }
    }

    func updateConvertedPreview() {
        guard let image = clipboardImage else { return }

        Task { @MainActor in
            let result = PluginProcessor.shared.convertImage(image, to: selectedImageFormat, quality: jpegQuality)
            if case .imageData(let data, _) = result {
                convertedImageData = data
            }
        }
    }

    func convertAndSaveImage() {
        guard let image = clipboardImage else { return }

        let result = PluginProcessor.shared.convertImage(image, to: selectedImageFormat, quality: jpegQuality)

        switch result {
        case .imageData(let data, let format):
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType(filenameExtension: format.fileExtension) ?? .png]
            savePanel.nameFieldStringValue = "converted.\(format.fileExtension)"
            savePanel.canCreateDirectories = true

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        // Close the view after successful save
                        DispatchQueue.main.async {
                            self.showImageConverter = false
                            self.clipboardImage = nil
                            self.activeAction = nil
                            self.convertedImageData = nil
                            if self.initialAction != nil {
                                self.onClose()
                            }
                        }
                    } catch {
                        self.resultText = "Error saving file: \(error.localizedDescription)"
                    }
                }
            }
        case .error(let error):
            resultText = error
            showImageConverter = false
        default:
            break
        }
    }

    // MARK: - Actions

    func selectCurrentAction() {
        if selectedIndex < store.actions.count {
            executeAction(store.actions[selectedIndex])
        } else {
            onOpenSettings()
        }
    }

    func executeAction(_ action: Action) {
        // If we're in the main popup (no initialAction), close and reopen with action popup
        if initialAction == nil {
            onClose()
            globalAppDelegate?.pendingAction = action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                globalAppDelegate?.showPopoverWithAction()
            }
            return
        }

        let textToProcess = textManager.capturedText

        // Check if plugin requires image input
        if action.isPlugin, let pluginType = action.pluginType, pluginType.requiresImageInput {
            // Handle image converter specially - show empty state, user must click Paste
            activeAction = action
            isProcessing = false
            clipboardImage = nil  // Always start with no image
            convertedImageData = nil
            showImageConverter = true
            return
        }

        // Check if plugin requires color picker
        if action.isPlugin, let pluginType = action.pluginType, pluginType.requiresColorPicker {
            activeAction = action
            isProcessing = true
            // Close popup temporarily to allow color picking
            onClose()

            // Small delay to ensure popup closes before showing color sampler
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                PluginProcessor.shared.pickColorFromScreen { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .text(let text):
                            // Re-open popup with result
                            self.resultText = text
                            self.isProcessing = false
                            // Post notification to reopen with result
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowColorPickerResult"),
                                object: nil,
                                userInfo: ["result": text, "action": action]
                            )
                        case .error(let error):
                            self.resultText = "Error: \(error)"
                            self.isProcessing = false
                        default:
                            break
                        }
                    }
                }
            }
            return
        }

        // Check if text input is needed
        let needsInput = action.pluginType?.requiresTextInput ?? true

        guard !textToProcess.isEmpty || !needsInput else {
            resultText = "No text selected. Select some text first!"
            activeAction = action
            return
        }

        isProcessing = true
        activeAction = action
        resultImage = nil
        resultText = nil
        showImageConverter = false

        // Handle plugins
        if action.isPlugin, let pluginType = action.pluginType {
            // Process plugin asynchronously to allow UI to update
            Task { @MainActor in
                // Small delay to ensure UI shows loading state first
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

                let pluginResult = PluginProcessor.shared.process(pluginType: pluginType, input: textToProcess)

                switch pluginResult {
                case .text(let text):
                    resultText = text
                case .image(let image):
                    resultImage = image
                case .imageData(_, _):
                    break // Handled separately
                case .error(let error):
                    resultText = "Error: \(error)"
                }
                isProcessing = false
            }
            return
        }

        // Handle AI actions
        Task {
            do {
                let result: String
                // Auto-detect if prompt requires web search
                let requiresWebSearch = promptRequiresWebSearch(action.prompt)

                if requiresWebSearch {
                    // Use Perplexity for web search
                    result = try await AIService.shared.webSearch(
                        prompt: action.prompt,
                        query: textToProcess,
                        apiKey: store.perplexityApiKey
                    )
                } else {
                    // Use regular AI provider
                    result = try await AIService.shared.processText(
                        prompt: action.prompt,
                        text: textToProcess,
                        apiKey: store.apiKey,
                        provider: store.selectedProvider,
                        model: store.selectedModel
                    )
                }
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
        triggerCopyNotification()
    }

    func triggerCopyNotification() {
        CopyNotificationWindow.show()
    }

    func replaceOriginalText(with text: String) {
        // Copy the result to clipboard (without notification)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // Show replaced notification
        CopyNotificationWindow.show(message: "Text replaced", icon: "arrow.left.arrow.right")

        // Use the global app delegate to close popup, restore focus, and paste
        globalAppDelegate?.performPasteInPreviousApp()
    }

    func copyImageToClipboard(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        triggerCopyNotification()
    }

    func saveImage(_ image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "image.png"
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
}

// MARK: - Chat Button View

struct ChatButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    var onTap: () -> Void

    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 1).opacity(0.1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image("logo textab")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)

                Text("Chat with AI")
                    .font(.nunitoRegularBold(size: 14))
                    .foregroundColor(.gray)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(appBlue)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }
}

// MARK: - Quick Prompt Button

struct QuickPromptButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    var onTap: () -> Void

    var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 1).opacity(0.1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 18)

                Text("Quick Prompt")
                    .font(.nunitoRegularBold(size: 14))
                    .foregroundColor(.gray)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .pointerCursor()
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
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.gray)
                .frame(width: 24)

            Text(action.name)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(Color.gray)

            if promptRequiresWebSearch(action.prompt) {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            if !action.shortcut.isEmpty {
                HStack(spacing: 4) {
                    ForEach(action.shortcutModifiers, id: \.self) { mod in
                        KeyboardKey(mod)
                    }
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

// MARK: - Markdown Image View

struct MarkdownImageView: View {
    let url: URL
    let altText: String

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading image...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

            case .failure:
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                    Text(altText.isEmpty ? "Image failed to load" : altText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            @unknown default:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
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

// MARK: - Color Picker Result View

struct ColorPickerResultView: View {
    let result: String
    let action: Action
    var onClose: () -> Void

    // Theme preference (using AppStorage for automatic updates)
    @AppStorage("appTheme") private var appTheme: String = "System"

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // Get saved color scheme for theme
    private var savedColorScheme: ColorScheme? {
        switch appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // System follows OS
        }
    }

    var extractedColor: NSColor? {
        // Parse HEX from result
        let lines = result.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("HEX: ") {
                let hex = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                return colorFromHex(hex)
            }
        }
        return nil
    }

    func colorFromHex(_ hex: String) -> NSColor? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHex = cleanHex.replacingOccurrences(of: "#", with: "")

        guard cleanHex.count == 6, let hexValue = Int(cleanHex, radix: 16) else {
            return nil
        }

        let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
        let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
        let b = CGFloat(hexValue & 0xFF) / 255.0

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(action.name)
                    .font(.nunitoRegularBold(size: 13))
                    .foregroundColor(appBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(16)

            Divider()

            // Color preview and values
            VStack(spacing: 16) {
                // Large color preview
                if let color = extractedColor {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(color))
                        .frame(width: 120, height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }

                // Color values
                Text(result)
                    .font(.system(size: 13, design: .monospaced))
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
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

                HStack(spacing: 10) {
                    // Copy All button - secondary style
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                    }) {
                        Text("Copy All")
                            .font(.nunitoRegularBold(size: 13))
                            .foregroundColor(appBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(appBlue.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()

                    // Copy HEX button - primary style
                    if let hexLine = result.components(separatedBy: "\n").first(where: { $0.hasPrefix("HEX:") }) {
                        let hex = String(hexLine.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(hex, forType: .string)
                        }) {
                            Text("Copy HEX")
                                .font(.nunitoRegularBold(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(appBlue)
                                )
                        }
                        .buttonStyle(.plain)
                        .pointerCursor()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 380, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .preferredColorScheme(savedColorScheme)
    }
}

// MARK: - Copy Notification Window

class CopyNotificationWindow: NSWindow {
    private static var currentWindow: CopyNotificationWindow?
    private var dismissWorkItem: DispatchWorkItem?

    static func show(message: String = "Copied to clipboard", icon: String = "checkmark") {
        DispatchQueue.main.async {
            // Dismiss any existing notification
            currentWindow?.close()
            currentWindow = nil

            // Create the notification view and hosting view first to measure size
            let notificationView = CopyNotificationView(message: message, icon: icon)
            let hostingView = NSHostingView(rootView: notificationView)
            let fittingSize = hostingView.fittingSize

            // Create the notification window with the exact content size
            let notificationWindow = CopyNotificationWindow(
                contentRect: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            notificationWindow.contentView = hostingView

            notificationWindow.isOpaque = false
            notificationWindow.backgroundColor = .clear
            notificationWindow.level = .floating
            notificationWindow.hasShadow = true
            notificationWindow.ignoresMouseEvents = true
            notificationWindow.isReleasedWhenClosed = false

            // Position at bottom center of screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - (fittingSize.width / 2)
                let y = screenFrame.minY + 80
                notificationWindow.setFrameOrigin(NSPoint(x: x, y: y))
            }

            // Store reference
            currentWindow = notificationWindow

            // Show with fade in
            notificationWindow.alphaValue = 0
            notificationWindow.orderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                notificationWindow.animator().alphaValue = 1
            }

            // Schedule dismiss
            let dismissWork = DispatchWorkItem { [weak notificationWindow] in
                guard let window = notificationWindow else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    window.animator().alphaValue = 0
                }, completionHandler: { [weak window] in
                    window?.orderOut(nil)
                    if currentWindow === window {
                        currentWindow = nil
                    }
                })
            }
            notificationWindow.dismissWorkItem = dismissWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: dismissWork)
        }
    }

    override func close() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        super.close()
    }
}

// MARK: - Copy Notification View

struct CopyNotificationView: View {
    var message: String = "Copied to clipboard"
    var icon: String = "checkmark"

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(message)
                .font(.nunitoBold(size: 15))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

// MARK: - No Fade Button Style

struct PopoverNoFadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1)
    }
}

#Preview {
    PopoverView(onClose: {}, onOpenSettings: {}, initialAction: nil)
        .frame(height: 420)
}
