//
//  OpenAIService.swift
//  typo
//

import Foundation

// MARK: - AI Model

struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let provider: AIProvider

    static let allModels: [AIModel] = [
        // OpenAI Models
        AIModel(id: "gpt-4o", name: "GPT-4o", provider: .openai),
        AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", provider: .openai),
        AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", provider: .openai),
        AIModel(id: "gpt-4", name: "GPT-4", provider: .openai),
        AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: .openai),
        AIModel(id: "o1-preview", name: "o1 Preview", provider: .openai),
        AIModel(id: "o1-mini", name: "o1 Mini", provider: .openai),

        // Anthropic Models
        AIModel(id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4", provider: .anthropic),
        AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", provider: .anthropic),
        AIModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", provider: .anthropic),
        AIModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", provider: .anthropic),
        AIModel(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", provider: .anthropic),

        // OpenRouter Models
        AIModel(id: "anthropic/claude-sonnet-4", name: "Claude Sonnet 4", provider: .openrouter),
        AIModel(id: "anthropic/claude-3.5-sonnet", name: "Claude 3.5 Sonnet", provider: .openrouter),
        AIModel(id: "openai/gpt-4o", name: "GPT-4o", provider: .openrouter),
        AIModel(id: "openai/gpt-4o-mini", name: "GPT-4o Mini", provider: .openrouter),
        AIModel(id: "google/gemini-pro-1.5", name: "Gemini Pro 1.5", provider: .openrouter),
        AIModel(id: "meta-llama/llama-3.1-405b-instruct", name: "Llama 3.1 405B", provider: .openrouter),
        AIModel(id: "mistralai/mistral-large", name: "Mistral Large", provider: .openrouter),

        // Perplexity Models
        AIModel(id: "llama-3.1-sonar-small-128k-online", name: "Sonar Small", provider: .perplexity),
        AIModel(id: "llama-3.1-sonar-large-128k-online", name: "Sonar Large", provider: .perplexity),
        AIModel(id: "llama-3.1-sonar-huge-128k-online", name: "Sonar Huge", provider: .perplexity),

        // Groq Models
        AIModel(id: "llama-3.3-70b-versatile", name: "Llama 3.3 70B", provider: .groq),
        AIModel(id: "llama-3.1-70b-versatile", name: "Llama 3.1 70B", provider: .groq),
        AIModel(id: "llama-3.1-8b-instant", name: "Llama 3.1 8B", provider: .groq),
        AIModel(id: "mixtral-8x7b-32768", name: "Mixtral 8x7B", provider: .groq),
        AIModel(id: "gemma2-9b-it", name: "Gemma 2 9B", provider: .groq),
    ]

    static func models(for provider: AIProvider) -> [AIModel] {
        allModels.filter { $0.provider == provider }
    }

    static func defaultModel(for provider: AIProvider) -> AIModel {
        models(for: provider).first ?? AIModel(id: provider.defaultModelId, name: provider.defaultModelId, provider: provider)
    }
}

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case openrouter = "OpenRouter"
    case perplexity = "Perplexity"
    case groq = "Groq"

    var baseURL: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .openrouter:
            return "https://openrouter.ai/api/v1/chat/completions"
        case .perplexity:
            return "https://api.perplexity.ai/chat/completions"
        case .groq:
            return "https://api.groq.com/openai/v1/chat/completions"
        }
    }

    var defaultModelId: String {
        switch self {
        case .openai:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-5-sonnet-20241022"
        case .openrouter:
            return "anthropic/claude-3.5-sonnet"
        case .perplexity:
            return "llama-3.1-sonar-small-128k-online"
        case .groq:
            return "llama-3.1-70b-versatile"
        }
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .openai:
            return "sk-..."
        case .anthropic:
            return "sk-ant-..."
        case .openrouter:
            return "sk-or-..."
        case .perplexity:
            return "pplx-..."
        case .groq:
            return "gsk_..."
        }
    }

    var websiteURL: String {
        switch self {
        case .openai:
            return "platform.openai.com/api-keys"
        case .anthropic:
            return "console.anthropic.com/settings/keys"
        case .openrouter:
            return "openrouter.ai/keys"
        case .perplexity:
            return "perplexity.ai/settings/api"
        case .groq:
            return "console.groq.com/keys"
        }
    }
}

// MARK: - AI Service

class AIService {
    static let shared = AIService()

    func processText(prompt: String, text: String, apiKey: String, provider: AIProvider, model: AIModel) async throws -> String {
        guard !apiKey.isEmpty else {
            return "[Demo Mode] API key not configured. Go to Settings to add your API key."
        }

        switch provider {
        case .anthropic:
            return try await callAnthropic(prompt: prompt, text: text, apiKey: apiKey, model: model)
        default:
            return try await callOpenAICompatible(prompt: prompt, text: text, apiKey: apiKey, provider: provider, model: model)
        }
    }

    // MARK: - Web Search using Perplexity
    func webSearch(prompt: String, query: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            return "[Error] Perplexity API key not configured. Go to Settings > Web Search to add your key."
        }

        let url = URL(string: "https://api.perplexity.ai/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Enhanced system prompt for better formatted results
        let enhancedPrompt = """
        \(prompt)

        Format your response using markdown:
        - Use **bold** for important terms
        - Include relevant links as [link text](url)
        - Use bullet points for lists
        - Use headers (##) to organize sections if needed
        - When relevant, include image URLs using markdown format: ![description](image_url)
        - Be concise but informative
        """

        let body: [String: Any] = [
            "model": "sonar",
            "messages": [
                ["role": "system", "content": enhancedPrompt],
                ["role": "user", "content": query]
            ],
            "max_tokens": 4000,
            "temperature": 0.2
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = decoded.choices.first?.message.content else {
            throw AIError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - OpenAI Compatible APIs (OpenAI, OpenRouter, Perplexity, Groq)

    private func callOpenAICompatible(prompt: String, text: String, apiKey: String, provider: AIProvider, model: AIModel) async throws -> String {
        let url = URL(string: provider.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // OpenRouter requiere headers adicionales
        if provider == .openrouter {
            request.addValue("Typo App", forHTTPHeaderField: "X-Title")
        }

        let body: [String: Any] = [
            "model": model.id,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = decoded.choices.first?.message.content else {
            throw AIError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Anthropic API

    private func callAnthropic(prompt: String, text: String, apiKey: String, model: AIModel) async throws -> String {
        let url = URL(string: AIProvider.anthropic.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model.id,
            "max_tokens": 2000,
            "system": prompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let content = decoded.content.first?.text else {
            throw AIError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
    }
}

struct AnthropicResponse: Codable {
    let content: [ContentBlock]

    struct ContentBlock: Codable {
        let text: String
    }
}

struct AnthropicErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .noContent:
            return "No content in response"
        }
    }
}
