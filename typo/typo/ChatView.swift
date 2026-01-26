//
//  ChatView.swift
//  typo
//
//  AI Chat interface for TexTab
//

import SwiftUI
import Carbon.HIToolbox

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content
    }
}

// MARK: - Chat View

struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store = ActionsStore.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var streamingMessageId: UUID? = nil
    @FocusState private var isInputFocused: Bool

    var onClose: () -> Void

    // App accent blue color
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    private var inputBackgroundColor: Color {
        colorScheme == .light
            ? Color(red: 241/255, green: 241/255, blue: 239/255)
            : Color(white: 1).opacity(0.1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            Divider()

            // Messages area
            messagesArea

            Divider()

            // Input area
            inputArea
        }
        .frame(width: 560, height: 620)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                    .foregroundColor(appBlue)

                Text("AI Chat")
                    .font(.nunitoBold(size: 15))
                    .foregroundColor(.primary)
            }

            Spacer()

            // Model indicator
            Text(store.selectedModel.name)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .pointerCursor()
        }
        .padding(16)
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { message in
                            // Hide empty streaming message (we show typing indicator instead)
                            if !(message.id == streamingMessageId && message.content.isEmpty) {
                                MessageBubble(message: message, appBlue: appBlue)
                                    .id(message.id)
                            }
                        }

                        // Show typing indicator only when processing AND streaming message is empty
                        if isProcessing && isStreamingMessageEmpty {
                            typingIndicator
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(appBlue.opacity(0.6))

            Text("Start a conversation")
                .font(.nunitoBold(size: 16))
                .foregroundColor(.primary)

            Text("Ask me anything! I can help with writing,\ncoding, analysis, and more.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    // Check if streaming message is empty
    private var isStreamingMessageEmpty: Bool {
        guard let id = streamingMessageId,
              let message = messages.first(where: { $0.id == id }) else {
            return true
        }
        return message.content.isEmpty
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        TypingDotsView(appBlue: appBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Calculate input height based on content (1-3 lines)
    private var inputHeight: CGFloat {
        let lineHeight: CGFloat = 20
        let padding: CGFloat = 16

        // Count actual lines (including wrapped text estimation)
        let newlineCount = inputText.components(separatedBy: "\n").count

        // Estimate additional lines from long text (rough estimate: ~50 chars per line)
        let charCount = inputText.count
        let estimatedWrapLines = max(0, (charCount / 50))

        let totalLines = max(1, min(3, newlineCount + estimatedWrapLines))
        return lineHeight * CGFloat(totalLines) + padding
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input with scroll (dynamic height 1-3 lines)
            ChatInputField(
                text: $inputText,
                isProcessing: isProcessing,
                onSend: sendMessage,
                backgroundColor: inputBackgroundColor
            )
            .frame(height: inputHeight)
            .animation(.easeInOut(duration: 0.1), value: inputHeight)
            .focused($isInputFocused)

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing ? .gray : appBlue)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .pointerCursor()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isProcessing else { return }

        // Add user message
        let userMessage = ChatMessage(content: trimmedText, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // Create empty AI message for streaming
        let aiMessage = ChatMessage(content: "", isUser: false)
        messages.append(aiMessage)
        streamingMessageId = aiMessage.id

        // Process with AI using streaming
        isProcessing = true

        Task {
            do {
                // Build conversation context (exclude the empty AI message)
                let conversationContext = buildConversationContext()

                try await AIService.shared.chatStream(
                    messages: conversationContext,
                    apiKey: store.apiKey,
                    provider: store.selectedProvider,
                    model: store.selectedModel
                ) { chunk in
                    // Append chunk to the streaming message
                    if let index = messages.firstIndex(where: { $0.id == streamingMessageId }) {
                        messages[index].content += chunk
                    }
                }

                await MainActor.run {
                    streamingMessageId = nil
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    // Update the streaming message with error
                    if let index = messages.firstIndex(where: { $0.id == streamingMessageId }) {
                        messages[index].content = "Error: \(error.localizedDescription)"
                    }
                    streamingMessageId = nil
                    isProcessing = false
                }
            }
        }
    }

    private func buildConversationContext() -> [(role: String, content: String)] {
        var context: [(role: String, content: String)] = []

        for message in messages {
            // Skip the empty streaming message
            if message.id == streamingMessageId { continue }
            // Skip empty messages
            if message.content.isEmpty { continue }

            context.append((
                role: message.isUser ? "user" : "assistant",
                content: message.content
            ))
        }

        return context
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    @Environment(\.colorScheme) var colorScheme
    let message: ChatMessage
    let appBlue: Color

    var bubbleColor: Color {
        if message.isUser {
            return appBlue
        } else {
            return colorScheme == .light
                ? Color(red: 241/255, green: 241/255, blue: 239/255)
                : Color(white: 0.15)
        }
    }

    var textColor: Color {
        message.isUser ? .white : .primary
    }

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isUser {
                    // User message - simple text
                    Text(message.content)
                        .font(.nunitoRegularBold(size: 14))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    // AI message - with markdown support
                    VStack(alignment: .leading, spacing: 0) {
                        MarkdownView(text: message.content)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Chat Input Field

struct ChatInputField: NSViewRepresentable {
    @Binding var text: String
    var isProcessing: Bool
    var onSend: () -> Void
    var backgroundColor: Color

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = ChatTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont(name: "Nunito Bold", size: 14) ?? NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.labelColor
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 10, height: 8)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        // Placeholder
        textView.placeholderString = "Type a message... (Shift+Enter for new line)"

        // Set the callback for sending
        textView.onSend = onSend

        scrollView.documentView = textView

        // Set background with rounded corners
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 16
        scrollView.layer?.masksToBounds = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ChatTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        textView.onSend = onSend

        // Update background color
        let nsColor = NSColor(backgroundColor)
        scrollView.backgroundColor = nsColor
        scrollView.drawsBackground = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatInputField

        init(_ parent: ChatInputField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// Custom NSTextView that handles Enter vs Shift+Enter
class ChatTextView: NSTextView {
    var onSend: (() -> Void)?
    var placeholderString: String = ""

    override func keyDown(with event: NSEvent) {
        // Check if Enter key is pressed
        if event.keyCode == 36 { // Return key
            if event.modifierFlags.contains(.shift) {
                // Shift+Enter: insert new line
                insertNewline(nil)
            } else {
                // Enter only: send message
                onSend?()
            }
            return
        }

        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw placeholder if empty
        if string.isEmpty && !placeholderString.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: font ?? NSFont.systemFont(ofSize: 14)
            ]
            let inset = textContainerInset
            let rect = NSRect(x: inset.width + 5, y: inset.height, width: bounds.width - inset.width * 2, height: bounds.height)
            placeholderString.draw(in: rect, withAttributes: attrs)
        }
    }

    override var intrinsicContentSize: NSSize {
        // Single line height by default
        let lineHeight: CGFloat = 20
        let minHeight: CGFloat = lineHeight + textContainerInset.height * 2
        return NSSize(width: NSView.noIntrinsicMetric, height: minHeight)
    }
}

// MARK: - Typing Dots Animation

struct TypingDotsView: View {
    let appBlue: Color
    @State private var animatingDots: [Bool] = [false, false, false]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(appBlue.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .offset(y: animatingDots[index] ? -4 : 0)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Staggered bounce animation for each dot
        for index in 0..<3 {
            let delay = Double(index) * 0.15
            withAnimation(
                Animation
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
            ) {
                animatingDots[index] = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView(onClose: {})
}
