//
//  Models.swift
//  typo
//

import Foundation
import Combine

// MARK: - Action Type

enum ActionType: String, Codable, CaseIterable {
    case ai = "ai"                      // Regular AI text transformation
    case webSearch = "webSearch"        // Web search via Perplexity
    case plugin = "plugin"              // Native plugin
}

// MARK: - Plugin Type

enum PluginType: String, Codable, CaseIterable {
    case qrGenerator = "qrGenerator"
    case jsonFormatter = "jsonFormatter"
    case base64Encode = "base64Encode"
    case base64Decode = "base64Decode"
    case colorConverter = "colorConverter"
    case uuidGenerator = "uuidGenerator"
    case hashGenerator = "hashGenerator"
    case urlEncode = "urlEncode"
    case urlDecode = "urlDecode"
    case wordCount = "wordCount"
    case imageConverter = "imageConverter"

    var displayName: String {
        switch self {
        case .qrGenerator: return "QR Code Generator"
        case .jsonFormatter: return "JSON Formatter"
        case .base64Encode: return "Base64 Encode"
        case .base64Decode: return "Base64 Decode"
        case .colorConverter: return "Color Converter"
        case .uuidGenerator: return "UUID Generator"
        case .hashGenerator: return "Hash Generator"
        case .urlEncode: return "URL Encode"
        case .urlDecode: return "URL Decode"
        case .wordCount: return "Word Count"
        case .imageConverter: return "Image Converter"
        }
    }

    var description: String {
        switch self {
        case .qrGenerator: return "Generate QR codes from text or URLs"
        case .jsonFormatter: return "Format and beautify JSON"
        case .base64Encode: return "Encode text to Base64"
        case .base64Decode: return "Decode Base64 to text"
        case .colorConverter: return "Convert colors between HEX, RGB, HSL"
        case .uuidGenerator: return "Generate unique UUIDs"
        case .hashGenerator: return "Generate MD5/SHA hashes"
        case .urlEncode: return "URL encode text"
        case .urlDecode: return "URL decode text"
        case .wordCount: return "Count words, characters, lines"
        case .imageConverter: return "Convert images between PNG, JPEG, WEBP, TIFF"
        }
    }

    var icon: String {
        switch self {
        case .qrGenerator: return "qrcode"
        case .jsonFormatter: return "curlybraces"
        case .base64Encode: return "arrow.right.circle"
        case .base64Decode: return "arrow.left.circle"
        case .colorConverter: return "paintpalette"
        case .uuidGenerator: return "number.circle"
        case .hashGenerator: return "lock.shield"
        case .urlEncode: return "link"
        case .urlDecode: return "link.badge.plus"
        case .wordCount: return "textformat.123"
        case .imageConverter: return "photo.on.rectangle.angled"
        }
    }

    var category: PluginCategory {
        switch self {
        case .qrGenerator: return .generators
        case .jsonFormatter: return .formatters
        case .base64Encode, .base64Decode: return .encoders
        case .colorConverter: return .converters
        case .uuidGenerator: return .generators
        case .hashGenerator: return .encoders
        case .urlEncode, .urlDecode: return .encoders
        case .wordCount: return .utilities
        case .imageConverter: return .converters
        }
    }

    // Whether the output is an image (needs special handling)
    var outputsImage: Bool {
        switch self {
        case .qrGenerator, .imageConverter: return true
        default: return false
        }
    }

    // Whether the plugin requires image input from clipboard
    var requiresImageInput: Bool {
        switch self {
        case .imageConverter: return true
        default: return false
        }
    }

    // Whether the plugin requires text input
    var requiresTextInput: Bool {
        switch self {
        case .uuidGenerator, .imageConverter: return false
        default: return true
        }
    }
}

enum PluginCategory: String, CaseIterable {
    case generators = "Generators"
    case formatters = "Formatters"
    case encoders = "Encoders"
    case converters = "Converters"
    case utilities = "Utilities"
}

// MARK: - Action

struct Action: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var prompt: String
    var shortcut: String
    var actionType: ActionType
    var pluginType: PluginType?

    init(id: UUID = UUID(), name: String, icon: String, prompt: String, shortcut: String = "", actionType: ActionType = .ai, pluginType: PluginType? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.shortcut = shortcut
        self.actionType = actionType
        self.pluginType = pluginType
    }

    // Convenience for backwards compatibility
    var isWebSearch: Bool {
        return actionType == .webSearch
    }

    var isPlugin: Bool {
        return actionType == .plugin
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, prompt, shortcut, actionType, pluginType
        case isWebSearch // Legacy key for reading old data
    }

    // Custom decoding to handle existing actions without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        prompt = try container.decode(String.self, forKey: .prompt)
        shortcut = try container.decodeIfPresent(String.self, forKey: .shortcut) ?? ""

        // Handle legacy isWebSearch field
        if let legacyWebSearch = try container.decodeIfPresent(Bool.self, forKey: .isWebSearch), legacyWebSearch {
            actionType = .webSearch
        } else {
            actionType = try container.decodeIfPresent(ActionType.self, forKey: .actionType) ?? .ai
        }

        pluginType = try container.decodeIfPresent(PluginType.self, forKey: .pluginType)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(shortcut, forKey: .shortcut)
        try container.encode(actionType, forKey: .actionType)
        try container.encodeIfPresent(pluginType, forKey: .pluginType)
    }
}

class ActionsStore: ObservableObject {
    @Published var actions: [Action] = []
    @Published var apiKey: String = ""
    @Published var selectedProvider: AIProvider = .openai
    @Published var perplexityApiKey: String = ""
    @Published var installedPlugins: Set<PluginType> = []

    private let actionsKey = "typo_actions"
    private let apiKeyKey = "typo_api_key"
    private let providerKey = "typo_provider"
    private let perplexityApiKeyKey = "typo_perplexity_api_key"
    private let installedPluginsKey = "typo_installed_plugins"

    static let shared = ActionsStore()

    init() {
        loadActions()
        loadApiKey()
        loadProvider()
        loadPerplexityApiKey()
        loadInstalledPlugins()
    }

    func loadActions() {
        if let data = UserDefaults.standard.data(forKey: actionsKey),
           let decoded = try? JSONDecoder().decode([Action].self, from: data) {
            actions = decoded
        } else {
            // Acciones por defecto
            actions = Self.defaultActions
            saveActions()
        }
    }

    func saveActions() {
        if let encoded = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(encoded, forKey: actionsKey)
        }
    }

    func loadApiKey() {
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
    }

    func saveApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    func loadProvider() {
        if let providerRaw = UserDefaults.standard.string(forKey: providerKey),
           let provider = AIProvider(rawValue: providerRaw) {
            selectedProvider = provider
        }
    }

    func saveProvider(_ provider: AIProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
    }

    func loadPerplexityApiKey() {
        perplexityApiKey = UserDefaults.standard.string(forKey: perplexityApiKeyKey) ?? ""
    }

    func savePerplexityApiKey(_ key: String) {
        perplexityApiKey = key
        UserDefaults.standard.set(key, forKey: perplexityApiKeyKey)
    }

    func loadInstalledPlugins() {
        if let data = UserDefaults.standard.data(forKey: installedPluginsKey),
           let decoded = try? JSONDecoder().decode([PluginType].self, from: data) {
            installedPlugins = Set(decoded)
        }
    }

    func saveInstalledPlugins() {
        if let encoded = try? JSONEncoder().encode(Array(installedPlugins)) {
            UserDefaults.standard.set(encoded, forKey: installedPluginsKey)
        }
    }

    func installPlugin(_ pluginType: PluginType) {
        installedPlugins.insert(pluginType)
        saveInstalledPlugins()

        // Add as action
        let action = Action(
            name: pluginType.displayName,
            icon: pluginType.icon,
            prompt: "",
            shortcut: "",
            actionType: .plugin,
            pluginType: pluginType
        )
        addAction(action)
    }

    func uninstallPlugin(_ pluginType: PluginType) {
        installedPlugins.remove(pluginType)
        saveInstalledPlugins()

        // Remove associated actions
        actions.removeAll { $0.pluginType == pluginType }
        saveActions()
    }

    func isPluginInstalled(_ pluginType: PluginType) -> Bool {
        return installedPlugins.contains(pluginType)
    }

    func addAction(_ action: Action) {
        actions.append(action)
        saveActions()
    }

    func updateAction(_ action: Action) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
            saveActions()
        }
    }

    func deleteAction(_ action: Action) {
        actions.removeAll { $0.id == action.id }
        saveActions()
    }

    static let defaultActions: [Action] = [
        Action(
            name: "Fix Grammar",
            icon: "pencil",
            prompt: "Fix the grammar and spelling errors in the following text. Return only the corrected text without explanations:",
            shortcut: "G"
        ),
        Action(
            name: "Rephrase Text",
            icon: "arrow.triangle.2.circlepath",
            prompt: "Rephrase the following text to make it clearer and more engaging while preserving the original meaning. Return only the rephrased text:",
            shortcut: "R"
        ),
        Action(
            name: "Shorten Text",
            icon: "arrow.down.left.and.arrow.up.right",
            prompt: "Shorten the following text while keeping the key points and meaning. Return only the shortened text:",
            shortcut: "S"
        ),
        Action(
            name: "Formalize Tone",
            icon: "doc.text",
            prompt: "Rewrite the following text in a more formal and professional tone. Return only the rewritten text:",
            shortcut: "F"
        ),
        Action(
            name: "Translate to English",
            icon: "globe",
            prompt: "Translate the following text to English. Return only the translation:",
            shortcut: "E"
        ),
        Action(
            name: "Translate to Spanish",
            icon: "globe.americas",
            prompt: "Translate the following text to Spanish. Return only the translation:",
            shortcut: "T"
        ),
    ]
}
