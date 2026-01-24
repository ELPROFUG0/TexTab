//
//  PopoverView.swift
//  typo
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PopoverView: View {
    @StateObject private var store = ActionsStore.shared
    @StateObject private var textManager = CapturedTextManager.shared
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @State private var isProcessing = false
    @State private var resultText: String?
    @State private var resultImage: NSImage?
    @State private var activeAction: Action?
    @State private var shouldScrollToSelection = false
    @FocusState private var isSearchFocused: Bool

    // Image converter states
    @State private var clipboardImage: NSImage?
    @State private var selectedImageFormat: ImageFormat = .png
    @State private var jpegQuality: Double = 0.9
    @State private var convertedImageData: Data?
    @State private var showImageConverter = false

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

                if action.isWebSearch {
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
            }
            .padding(16)

            Divider()

            // Result content - expands to fill available space
            ScrollView {
                if action.isWebSearch {
                    // Render markdown for web search results
                    MarkdownTextView(text: result)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                } else {
                    Text(result)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
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

                    if !action.isWebSearch && !action.isPlugin {
                        Button("Replace") {
                            replaceOriginalText(with: result)
                        }
                        .buttonStyle(.borderedProminent)
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
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.1))
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

                HStack(spacing: 8) {
                    Button(action: {
                        copyImageToClipboard(image)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                            Text("Copy")
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        saveImage(image)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 11))
                            Text("Save")
                        }
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
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.1))
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
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
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
                                        .background(selectedImageFormat == format ? Color.accentColor : Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
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
                                .tint(.accentColor)
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

                HStack(spacing: 8) {
                    // Refresh from clipboard
                    Button(action: {
                        if let image = PluginProcessor.shared.getImageFromClipboard() {
                            clipboardImage = image
                            convertedImageData = nil
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh from clipboard")

                    // Convert button
                    Button(action: {
                        convertAndSaveImage()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("Convert & Save")
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
        if selectedIndex < filteredActions.count {
            executeAction(filteredActions[selectedIndex])
        } else {
            onOpenSettings()
        }
    }

    func executeAction(_ action: Action) {
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
                if action.isWebSearch {
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
                        provider: store.selectedProvider
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

    func copyImageToClipboard(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
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

            if action.isWebSearch {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }

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

// MARK: - Markdown Text View

struct MarkdownTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseMarkdown(text).enumerated()), id: \.offset) { _, element in
                element
            }
        }
    }

    func parseMarkdown(_ text: String) -> [AnyView] {
        var views: [AnyView] = []
        let lines = text.components(separatedBy: "\n")
        var currentParagraph = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Check for standalone image ![alt](url)
            if let imageView = parseImageLine(trimmedLine) {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                views.append(imageView)
            }
            // Headers
            else if trimmedLine.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                let headerText = String(trimmedLine.dropFirst(4))
                views.append(AnyView(
                    Text(headerText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                ))
            } else if trimmedLine.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                let headerText = String(trimmedLine.dropFirst(3))
                views.append(AnyView(
                    Text(headerText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                ))
            } else if trimmedLine.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                let headerText = String(trimmedLine.dropFirst(2))
                views.append(AnyView(
                    Text(headerText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 12)
                ))
            }
            // Bullet points
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                let bulletText = String(trimmedLine.dropFirst(2))
                views.append(AnyView(
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        formattedText(bulletText)
                    }
                    .padding(.leading, 4)
                ))
            }
            // Numbered lists
            else if let _ = trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
                let parts = trimmedLine.split(separator: " ", maxSplits: 1)
                if parts.count == 2 {
                    let number = String(parts[0])
                    let content = String(parts[1])
                    views.append(AnyView(
                        HStack(alignment: .top, spacing: 4) {
                            Text(number)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .trailing)
                            formattedText(content)
                        }
                    ))
                }
            }
            // Empty line = paragraph break
            else if trimmedLine.isEmpty {
                if !currentParagraph.isEmpty {
                    views.append(AnyView(paragraphView(currentParagraph)))
                    currentParagraph = ""
                }
            }
            // Regular text
            else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmedLine
            }
        }

        // Add remaining paragraph
        if !currentParagraph.isEmpty {
            views.append(AnyView(paragraphView(currentParagraph)))
        }

        return views
    }

    // Parse standalone image line: ![alt text](url)
    func parseImageLine(_ line: String) -> AnyView? {
        let imagePattern = #"^!\[([^\]]*)\]\(([^)]+)\)$"#
        guard let regex = try? NSRegularExpression(pattern: imagePattern, options: []) else {
            return nil
        }

        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: nsRange) else {
            return nil
        }

        guard let altRange = Range(match.range(at: 1), in: line),
              let urlRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let altText = String(line[altRange])
        let urlString = String(line[urlRange])

        guard let url = URL(string: urlString) else {
            return nil
        }

        return AnyView(
            MarkdownImageView(url: url, altText: altText)
        )
    }

    func paragraphView(_ text: String) -> some View {
        formattedText(text)
    }

    func formattedText(_ text: String) -> some View {
        // First, extract and remove inline images to process separately
        let (cleanedText, inlineImages) = extractInlineImages(text)

        // Parse inline markdown (bold, links, etc)
        var attributedString = AttributedString(cleanedText)

        // Process bold **text**
        let boldPattern = #"\*\*([^*]+)\*\*"#
        if let regex = try? NSRegularExpression(pattern: boldPattern, options: []) {
            let nsRange = NSRange(cleanedText.startIndex..., in: cleanedText)
            let matches = regex.matches(in: cleanedText, options: [], range: nsRange)

            for match in matches.reversed() {
                if let range = Range(match.range, in: cleanedText),
                   let contentRange = Range(match.range(at: 1), in: cleanedText) {
                    let content = String(cleanedText[contentRange])
                    if let attrRange = attributedString.range(of: String(cleanedText[range])) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content, attributes: AttributeContainer([.font: NSFont.boldSystemFont(ofSize: 14)])))
                    }
                }
            }
        }

        // Process links [text](url)
        let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern, options: []) {
            let currentText = String(attributedString.characters)
            let nsRange = NSRange(currentText.startIndex..., in: currentText)
            let matches = regex.matches(in: currentText, options: [], range: nsRange)

            for match in matches.reversed() {
                if let fullRange = Range(match.range, in: currentText),
                   let textRange = Range(match.range(at: 1), in: currentText),
                   let urlRange = Range(match.range(at: 2), in: currentText) {
                    let linkText = String(currentText[textRange])
                    let urlString = String(currentText[urlRange])

                    if let url = URL(string: urlString),
                       let attrRange = attributedString.range(of: String(currentText[fullRange])) {
                        var linkAttr = AttributedString(linkText)
                        linkAttr.link = url
                        linkAttr.foregroundColor = .accentColor
                        linkAttr.underlineStyle = .single
                        attributedString.replaceSubrange(attrRange, with: linkAttr)
                    }
                }
            }
        }

        // If there are inline images, return a VStack with text and images
        if !inlineImages.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text(attributedString)
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .textSelection(.enabled)

                    ForEach(inlineImages, id: \.url) { imageInfo in
                        MarkdownImageView(url: imageInfo.url, altText: imageInfo.alt)
                    }
                }
            )
        }

        return AnyView(
            Text(attributedString)
                .font(.system(size: 14))
                .lineSpacing(4)
                .textSelection(.enabled)
        )
    }

    // Extract inline images from text and return cleaned text + image info
    func extractInlineImages(_ text: String) -> (String, [(url: URL, alt: String)]) {
        let imagePattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: imagePattern, options: []) else {
            return (text, [])
        }

        var cleanedText = text
        var images: [(url: URL, alt: String)] = []

        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        for match in matches.reversed() {
            if let fullRange = Range(match.range, in: text),
               let altRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text) {
                let altText = String(text[altRange])
                let urlString = String(text[urlRange])

                if let url = URL(string: urlString) {
                    images.insert((url: url, alt: altText), at: 0)
                }

                // Remove the image markdown from text
                if let cleanRange = Range(match.range, in: cleanedText) {
                    cleanedText.replaceSubrange(cleanRange, with: "")
                }
            }
        }

        return (cleanedText.trimmingCharacters(in: .whitespaces), images)
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

#Preview {
    PopoverView(onClose: {}, onOpenSettings: {}, initialAction: nil)
        .frame(height: 420)
}
