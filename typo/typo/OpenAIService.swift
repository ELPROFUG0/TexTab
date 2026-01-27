//
//  OpenAIService.swift
//  typo
//

import Foundation

// MARK: - AI Model

// MARK: - Model Specs

struct ModelSpecs: Hashable, Codable {
    let speed: Int          // 1-5 rating
    let intelligence: Int   // 1-5 rating
    let tokenUsage: Int     // 1-5 rating (lower is better/cheaper)
    let description: String

    static let `default` = ModelSpecs(speed: 3, intelligence: 3, tokenUsage: 3, description: "Standard AI model")
}

struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let provider: AIProvider
    let specs: ModelSpecs

    static let allModels: [AIModel] = [
        // OpenAI Models
        AIModel(id: "gpt-4o", name: "GPT-4o", provider: .openai,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 3, description: "Most capable GPT-4 model with vision")),
        AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", provider: .openai,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Fast, lightweight model optimized for speed and cost efficiency")),
        AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", provider: .openai,
               specs: ModelSpecs(speed: 3, intelligence: 5, tokenUsage: 2, description: "High intelligence with large context window")),
        AIModel(id: "gpt-4", name: "GPT-4", provider: .openai,
               specs: ModelSpecs(speed: 2, intelligence: 5, tokenUsage: 2, description: "Original GPT-4, highly capable")),
        AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: .openai,
               specs: ModelSpecs(speed: 5, intelligence: 3, tokenUsage: 5, description: "Fast and affordable for simple tasks")),
        AIModel(id: "o1-preview", name: "o1 Preview", provider: .openai,
               specs: ModelSpecs(speed: 1, intelligence: 5, tokenUsage: 1, description: "Advanced reasoning model, slower but more thorough")),
        AIModel(id: "o1-mini", name: "o1 Mini", provider: .openai,
               specs: ModelSpecs(speed: 2, intelligence: 4, tokenUsage: 2, description: "Smaller reasoning model, balanced performance")),

        // Anthropic Models
        AIModel(id: "claude-opus-4-20250514", name: "Claude Opus 4", provider: .anthropic,
               specs: ModelSpecs(speed: 2, intelligence: 5, tokenUsage: 1, description: "Most powerful Claude model, exceptional reasoning")),
        AIModel(id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4", provider: .anthropic,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 2, description: "Latest Claude model with excellent reasoning")),
        AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", provider: .anthropic,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 2, description: "Balanced performance and cost")),
        AIModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", provider: .anthropic,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Fast, lightweight model optimized for speed and cost efficiency")),
        AIModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", provider: .anthropic,
               specs: ModelSpecs(speed: 2, intelligence: 5, tokenUsage: 1, description: "Most powerful Claude 3 model")),
        AIModel(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", provider: .anthropic,
               specs: ModelSpecs(speed: 5, intelligence: 3, tokenUsage: 5, description: "Fastest Claude model for simple tasks")),

        // OpenRouter Models
        AIModel(id: "anthropic/claude-opus-4", name: "Claude Opus 4", provider: .openrouter,
               specs: ModelSpecs(speed: 2, intelligence: 5, tokenUsage: 1, description: "Most powerful Claude via OpenRouter")),
        AIModel(id: "anthropic/claude-sonnet-4", name: "Claude Sonnet 4", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 2, description: "Latest Claude via OpenRouter")),
        AIModel(id: "anthropic/claude-3.5-sonnet", name: "Claude 3.5 Sonnet", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 2, description: "Balanced Claude via OpenRouter")),
        AIModel(id: "openai/gpt-4o", name: "GPT-4o", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 5, tokenUsage: 3, description: "GPT-4o via OpenRouter")),
        AIModel(id: "openai/gpt-4o-mini", name: "GPT-4o Mini", provider: .openrouter,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Fast GPT-4o Mini via OpenRouter")),
        AIModel(id: "meta-llama/llama-3.1-405b-instruct", name: "Llama 3.1 405B", provider: .openrouter,
               specs: ModelSpecs(speed: 2, intelligence: 5, tokenUsage: 2, description: "Largest open-source model")),
        AIModel(id: "mistralai/mistral-large", name: "Mistral Large", provider: .openrouter,
               specs: ModelSpecs(speed: 3, intelligence: 4, tokenUsage: 3, description: "Mistral's flagship model")),

        // DeepSeek Models
        AIModel(id: "deepseek/deepseek-chat", name: "DeepSeek Chat", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 4, tokenUsage: 5, description: "Fast and capable chat model")),
        AIModel(id: "deepseek/deepseek-r1-distill-llama-70b", name: "DeepSeek R1 Distill 70B", provider: .openrouter,
               specs: ModelSpecs(speed: 3, intelligence: 4, tokenUsage: 5, description: "Distilled reasoning model")),

        // Free Models
        AIModel(id: "google/gemma-3-27b-it:free", name: "Gemma 3 27B (Free)", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 4, tokenUsage: 5, description: "Free Google multimodal model")),
        AIModel(id: "meta-llama/llama-3.3-70b-instruct:free", name: "Llama 3.3 70B (Free)", provider: .openrouter,
               specs: ModelSpecs(speed: 4, intelligence: 4, tokenUsage: 5, description: "Free multilingual Llama model")),
        AIModel(id: "deepseek/deepseek-r1-0528:free", name: "DeepSeek R1 (Free)", provider: .openrouter,
               specs: ModelSpecs(speed: 3, intelligence: 5, tokenUsage: 5, description: "Free open-source reasoning model")),
        // Perplexity Models
        AIModel(id: "llama-3.1-sonar-small-128k-online", name: "Sonar Small", provider: .perplexity,
               specs: ModelSpecs(speed: 5, intelligence: 3, tokenUsage: 5, description: "Fast online search model")),
        AIModel(id: "llama-3.1-sonar-large-128k-online", name: "Sonar Large", provider: .perplexity,
               specs: ModelSpecs(speed: 4, intelligence: 4, tokenUsage: 3, description: "Balanced online search model")),
        AIModel(id: "llama-3.1-sonar-huge-128k-online", name: "Sonar Huge", provider: .perplexity,
               specs: ModelSpecs(speed: 3, intelligence: 5, tokenUsage: 2, description: "Most capable online search model")),

        // Groq Models
        AIModel(id: "llama-3.3-70b-versatile", name: "Llama 3.3 70B", provider: .groq,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Latest Llama on Groq, ultra-fast")),
        AIModel(id: "llama-3.1-70b-versatile", name: "Llama 3.1 70B", provider: .groq,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Versatile model with fast inference")),
        AIModel(id: "llama-3.1-8b-instant", name: "Llama 3.1 8B", provider: .groq,
               specs: ModelSpecs(speed: 5, intelligence: 3, tokenUsage: 5, description: "Instant responses, best for simple tasks")),
        AIModel(id: "mixtral-8x7b-32768", name: "Mixtral 8x7B", provider: .groq,
               specs: ModelSpecs(speed: 5, intelligence: 4, tokenUsage: 5, description: "Mixture of experts model, fast")),
        AIModel(id: "gemma2-9b-it", name: "Gemma 2 9B", provider: .groq,
               specs: ModelSpecs(speed: 5, intelligence: 3, tokenUsage: 5, description: "Google's efficient model on Groq")),
    ]

    static func models(for provider: AIProvider) -> [AIModel] {
        allModels.filter { $0.provider == provider }
    }

    static func defaultModel(for provider: AIProvider) -> AIModel {
        models(for: provider).first ?? AIModel(id: provider.defaultModelId, name: provider.defaultModelId, provider: provider, specs: .default)
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

    var iconName: String {
        switch self {
        case .openai:
            return "openai"
        case .anthropic:
            return "claude"
        case .openrouter:
            return "openrouter"
        case .perplexity:
            return "perplexity"
        case .groq:
            return "groq"
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

    // MARK: - Chat (Multi-turn conversation)
    func chat(messages: [(role: String, content: String)], apiKey: String, provider: AIProvider, model: AIModel) async throws -> String {
        guard !apiKey.isEmpty else {
            return "[Demo Mode] API key not configured. Go to Settings to add your API key."
        }

        switch provider {
        case .anthropic:
            return try await callAnthropicChat(messages: messages, apiKey: apiKey, model: model)
        default:
            return try await callOpenAICompatibleChat(messages: messages, apiKey: apiKey, provider: provider, model: model)
        }
    }

    // MARK: - Chat with Streaming
    func chatStream(
        messages: [(role: String, content: String)],
        apiKey: String,
        provider: AIProvider,
        model: AIModel,
        onChunk: @escaping (String) -> Void
    ) async throws {
        guard !apiKey.isEmpty else {
            onChunk("[Demo Mode] API key not configured. Go to Settings to add your API key.")
            return
        }

        switch provider {
        case .anthropic:
            try await streamAnthropicChat(messages: messages, apiKey: apiKey, model: model, onChunk: onChunk)
        default:
            try await streamOpenAICompatibleChat(messages: messages, apiKey: apiKey, provider: provider, model: model, onChunk: onChunk)
        }
    }

    // MARK: - OpenAI Compatible Streaming
    private func streamOpenAICompatibleChat(
        messages: [(role: String, content: String)],
        apiKey: String,
        provider: AIProvider,
        model: AIModel,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let url = URL(string: provider.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if provider == .openrouter {
            request.addValue("TexTab App", forHTTPHeaderField: "X-Title")
        }

        // Convert messages to API format
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful AI assistant. Be concise and helpful. Use markdown formatting when appropriate, including code blocks with language tags for code."]
        ]

        for message in messages {
            apiMessages.append(["role": message.role, "content": message.content])
        }

        let body: [String: Any] = [
            "model": model.id,
            "messages": apiMessages,
            "max_tokens": 4000,
            "temperature": 0.7,
            "stream": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Collect error response
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: errorData) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        // Parse SSE stream
        for try await line in bytes.lines {
            // Skip empty lines and comments
            guard line.hasPrefix("data: ") else { continue }

            let data = String(line.dropFirst(6))

            // Check for end of stream
            if data == "[DONE]" { break }

            // Parse JSON
            guard let jsonData = data.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }

            await MainActor.run {
                onChunk(content)
            }
        }
    }

    // MARK: - Anthropic Streaming
    private func streamAnthropicChat(
        messages: [(role: String, content: String)],
        apiKey: String,
        model: AIModel,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let url = URL(string: AIProvider.anthropic.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert messages to Anthropic format
        var apiMessages: [[String: String]] = []
        for message in messages {
            apiMessages.append(["role": message.role, "content": message.content])
        }

        let body: [String: Any] = [
            "model": model.id,
            "max_tokens": 4000,
            "system": "You are a helpful AI assistant. Be concise and helpful. Use markdown formatting when appropriate, including code blocks with language tags for code.",
            "messages": apiMessages,
            "stream": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Collect error response
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            if let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: errorData) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        // Parse SSE stream for Anthropic
        for try await line in bytes.lines {
            // Skip empty lines
            guard line.hasPrefix("data: ") else { continue }

            let data = String(line.dropFirst(6))

            // Parse JSON
            guard let jsonData = data.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }

            // Check event type
            let eventType = json["type"] as? String

            // Handle content_block_delta events
            if eventType == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                await MainActor.run {
                    onChunk(text)
                }
            }

            // Check for message_stop
            if eventType == "message_stop" {
                break
            }
        }
    }

    // MARK: - OpenAI Compatible Chat
    private func callOpenAICompatibleChat(messages: [(role: String, content: String)], apiKey: String, provider: AIProvider, model: AIModel) async throws -> String {
        let url = URL(string: provider.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if provider == .openrouter {
            request.addValue("TexTab App", forHTTPHeaderField: "X-Title")
        }

        // Convert messages to API format
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful AI assistant. Be concise and helpful. Use markdown formatting when appropriate, including code blocks with language tags for code."]
        ]

        for message in messages {
            apiMessages.append(["role": message.role, "content": message.content])
        }

        let body: [String: Any] = [
            "model": model.id,
            "messages": apiMessages,
            "max_tokens": 4000,
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

    // MARK: - Anthropic Chat
    private func callAnthropicChat(messages: [(role: String, content: String)], apiKey: String, model: AIModel) async throws -> String {
        let url = URL(string: AIProvider.anthropic.baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert messages to Anthropic format
        var apiMessages: [[String: String]] = []
        for message in messages {
            apiMessages.append(["role": message.role, "content": message.content])
        }

        let body: [String: Any] = [
            "model": model.id,
            "max_tokens": 4000,
            "system": "You are a helpful AI assistant. Be concise and helpful. Use markdown formatting when appropriate, including code blocks with language tags for code.",
            "messages": apiMessages
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
            request.addValue("TexTab App", forHTTPHeaderField: "X-Title")
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
