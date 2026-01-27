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
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedTab = 1
    @State private var selectedAction: Action?

    // Theme preference (using AppStorage for automatic updates)
    @AppStorage("appTheme") private var appTheme: String = "System"

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
            if authManager.isAuthenticated {
                // Show full settings when logged in
                authenticatedView
            } else {
                // Show login view when not logged in
                LoginRequiredView()
            }
        }
        .frame(width: 700, height: 540)
        .preferredColorScheme(savedColorScheme)
    }

    private var authenticatedView: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar - solo textos con Nunito
            HStack(spacing: 24) {
                TabTextButton(title: "General", isSelected: selectedTab == 0) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = 0
                    }
                }
                TabTextButton(title: "Actions", isSelected: selectedTab == 1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = 1
                    }
                }
                TabTextButton(title: "Templates", isSelected: selectedTab == 2) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = 2
                    }
                }
                TabTextButton(title: "Plugins", isSelected: selectedTab == 3) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = 3
                    }
                }
                TabTextButton(title: "About", isSelected: selectedTab == 4) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = 4
                    }
                }
            }
            .padding(.vertical, 12)

            Divider()

            // Tab Content with animation
            Group {
                switch selectedTab {
                case 0:
                    GeneralSettingsView()
                case 1:
                    ActionsSettingsView(selectedAction: $selectedAction)
                case 2:
                    TemplatesView(onNavigateToActions: { action in
                        selectedAction = action
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = 1
                        }
                    })
                case 3:
                    PluginsMarketplaceView()
                case 4:
                    AboutView()
                default:
                    EmptyView()
                }
            }
            .id(selectedTab)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
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

// MARK: - Settings 3D Key (smaller for settings view)

struct Settings3DKey: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String

    var body: some View {
        ZStack {
            // Bottom layer (3D effect) - more pronounced in dark mode
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.7))
                .frame(width: 30, height: 30)
                .offset(y: colorScheme == .dark ? 3 : 2)

            // Top layer
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color(white: 0.3) : Color(white: 0.95))
                .frame(width: 30, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(colorScheme == .dark ? Color(white: 0.4) : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .frame(width: 30, height: colorScheme == .dark ? 33 : 32)
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
    @State private var showPaywall = false
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
        // Check if user can create a new action
        guard store.canCreateAction else {
            showPaywall = true
            return
        }

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
        .paywall(isPresented: $showPaywall)
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
