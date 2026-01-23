//
//  Models.swift
//  typo
//

import Foundation
import Combine

struct Action: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var prompt: String
    var shortcut: String
    var isWebSearch: Bool

    init(id: UUID = UUID(), name: String, icon: String, prompt: String, shortcut: String = "", isWebSearch: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.shortcut = shortcut
        self.isWebSearch = isWebSearch
    }

    // Custom decoding to handle existing actions without isWebSearch
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        prompt = try container.decode(String.self, forKey: .prompt)
        shortcut = try container.decodeIfPresent(String.self, forKey: .shortcut) ?? ""
        isWebSearch = try container.decodeIfPresent(Bool.self, forKey: .isWebSearch) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, prompt, shortcut, isWebSearch
    }
}

class ActionsStore: ObservableObject {
    @Published var actions: [Action] = []
    @Published var apiKey: String = ""
    @Published var selectedProvider: AIProvider = .openai
    @Published var perplexityApiKey: String = ""

    private let actionsKey = "typo_actions"
    private let apiKeyKey = "typo_api_key"
    private let providerKey = "typo_provider"
    private let perplexityApiKeyKey = "typo_perplexity_api_key"

    static let shared = ActionsStore()

    init() {
        loadActions()
        loadApiKey()
        loadProvider()
        loadPerplexityApiKey()
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
