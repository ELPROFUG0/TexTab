//
//  Models.swift
//  typo
//

import Foundation
import Combine
import Carbon.HIToolbox

// MARK: - Action Type

enum ActionType: String, Codable, CaseIterable {
    case ai = "ai"                      // Regular AI text transformation
    case webSearch = "webSearch"        // Web search via Perplexity
    case plugin = "plugin"              // Native plugin
}

// MARK: - Plugin Type

enum PluginType: String, Codable, CaseIterable {
    case qrGenerator = "qrGenerator"
    case imageConverter = "imageConverter"
    case colorPicker = "colorPicker"

    var displayName: String {
        switch self {
        case .qrGenerator: return "QR Code Generator"
        case .imageConverter: return "Image Converter"
        case .colorPicker: return "Color Picker"
        }
    }

    var description: String {
        switch self {
        case .qrGenerator: return "Generate QR codes from text or URLs"
        case .imageConverter: return "Convert images between PNG, JPEG, WEBP, TIFF"
        case .colorPicker: return "Pick any color from your screen with an eyedropper"
        }
    }

    var icon: String {
        switch self {
        case .qrGenerator: return "qrcode"
        case .imageConverter: return "photo.on.rectangle.angled"
        case .colorPicker: return "eyedropper"
        }
    }

    var category: PluginCategory {
        switch self {
        case .qrGenerator: return .generators
        case .imageConverter: return .converters
        case .colorPicker: return .utilities
        }
    }

    // Whether the output is an image (needs special handling)
    var outputsImage: Bool {
        switch self {
        case .qrGenerator, .imageConverter: return true
        case .colorPicker: return false
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
        case .qrGenerator: return true
        case .imageConverter, .colorPicker: return false
        }
    }

    // Whether the plugin requires screen color picking
    var requiresColorPicker: Bool {
        switch self {
        case .colorPicker: return true
        default: return false
        }
    }
}

enum PluginCategory: String, CaseIterable {
    case generators = "Generators"
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
    var shortcutModifiers: [String]
    var actionType: ActionType
    var pluginType: PluginType?

    init(id: UUID = UUID(), name: String, icon: String, prompt: String, shortcut: String = "", shortcutModifiers: [String] = ["\u{2318}", "\u{21E7}"], actionType: ActionType = .ai, pluginType: PluginType? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.shortcut = shortcut
        self.shortcutModifiers = shortcutModifiers
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

    /// Convert stored modifier symbols to Carbon modifier flags
    var carbonModifiers: UInt32 {
        var mods: UInt32 = 0
        for m in shortcutModifiers {
            switch m {
            case "\u{2318}": mods |= UInt32(cmdKey)
            case "\u{21E7}": mods |= UInt32(shiftKey)
            case "\u{2325}": mods |= UInt32(optionKey)
            case "^":        mods |= UInt32(controlKey)
            default: break
            }
        }
        return mods
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, prompt, shortcut, shortcutModifiers, actionType, pluginType
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
        shortcutModifiers = try container.decodeIfPresent([String].self, forKey: .shortcutModifiers) ?? ["\u{2318}", "\u{21E7}"]

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
        try container.encode(shortcutModifiers, forKey: .shortcutModifiers)
        try container.encode(actionType, forKey: .actionType)
        try container.encodeIfPresent(pluginType, forKey: .pluginType)
    }
}

class ActionsStore: ObservableObject {
    @Published var actions: [Action] = []
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var selectedProvider: AIProvider = .openai
    @Published var selectedModelIds: [AIProvider: String] = [:]
    @Published var perplexityApiKey: String = ""
    @Published var installedPlugins: Set<PluginType> = []
    @Published var mainShortcut: String = "T"
    @Published var mainShortcutModifiers: [String] = ["\u{2318}", "\u{21E7}"]

    private let actionsKey = "typo_actions"
    private let apiKeysKey = "typo_api_keys"
    private let providerKey = "typo_provider"
    private let modelIdsKey = "typo_model_ids"
    private let perplexityApiKeyKey = "typo_perplexity_api_key"
    private let installedPluginsKey = "typo_installed_plugins"
    private let mainShortcutKey = "typo_main_shortcut"
    private let mainShortcutModifiersKey = "typo_main_shortcut_modifiers"

    static let shared = ActionsStore()

    // Current API key for selected provider
    var apiKey: String {
        apiKeys[selectedProvider] ?? ""
    }

    // Current model ID for selected provider
    var selectedModelId: String {
        selectedModelIds[selectedProvider] ?? selectedProvider.defaultModelId
    }

    var selectedModel: AIModel {
        if let model = AIModel.models(for: selectedProvider).first(where: { $0.id == selectedModelId }) {
            return model
        }
        return AIModel.defaultModel(for: selectedProvider)
    }

    // Free tier limit: 5 actions max
    static let freeActionLimit = 5

    // Check if user can create a new action
    var canCreateAction: Bool {
        AuthManager.shared.isPro || actions.count < Self.freeActionLimit
    }

    // Number of remaining actions for free users
    var remainingFreeActions: Int {
        max(0, Self.freeActionLimit - actions.count)
    }

    var mainCarbonModifiers: UInt32 {
        var mods: UInt32 = 0
        for m in mainShortcutModifiers {
            switch m {
            case "\u{2318}": mods |= UInt32(cmdKey)
            case "\u{21E7}": mods |= UInt32(shiftKey)
            case "\u{2325}": mods |= UInt32(optionKey)
            case "^":        mods |= UInt32(controlKey)
            default: break
            }
        }
        return mods
    }

    init() {
        loadActions()
        loadApiKeys()
        loadProvider()
        loadModelIds()
        loadPerplexityApiKey()
        loadInstalledPlugins()
        loadMainShortcut()
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

    func loadApiKeys() {
        if let data = UserDefaults.standard.data(forKey: apiKeysKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            // Convert string keys back to AIProvider
            for (key, value) in decoded {
                if let provider = AIProvider(rawValue: key) {
                    apiKeys[provider] = value
                }
            }
        }
    }

    func saveApiKey(_ key: String, for provider: AIProvider? = nil) {
        let targetProvider = provider ?? selectedProvider
        apiKeys[targetProvider] = key
        // Convert to string keys for encoding
        let stringKeyed = Dictionary(uniqueKeysWithValues: apiKeys.map { ($0.key.rawValue, $0.value) })
        if let encoded = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(encoded, forKey: apiKeysKey)
        }
    }

    func apiKey(for provider: AIProvider) -> String {
        apiKeys[provider] ?? ""
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

    func loadModelIds() {
        if let data = UserDefaults.standard.data(forKey: modelIdsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            for (key, value) in decoded {
                if let provider = AIProvider(rawValue: key) {
                    selectedModelIds[provider] = value
                }
            }
        }
    }

    func saveModel(_ modelId: String, for provider: AIProvider? = nil) {
        let targetProvider = provider ?? selectedProvider
        selectedModelIds[targetProvider] = modelId
        let stringKeyed = Dictionary(uniqueKeysWithValues: selectedModelIds.map { ($0.key.rawValue, $0.value) })
        if let encoded = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(encoded, forKey: modelIdsKey)
        }
    }

    func modelId(for provider: AIProvider) -> String {
        selectedModelIds[provider] ?? provider.defaultModelId
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

    func loadMainShortcut() {
        if let key = UserDefaults.standard.string(forKey: mainShortcutKey) {
            mainShortcut = key
        }
        if let mods = UserDefaults.standard.stringArray(forKey: mainShortcutModifiersKey) {
            mainShortcutModifiers = mods
        }
    }

    func saveMainShortcut() {
        UserDefaults.standard.set(mainShortcut, forKey: mainShortcutKey)
        UserDefaults.standard.set(mainShortcutModifiers, forKey: mainShortcutModifiersKey)
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
