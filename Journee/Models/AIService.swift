import Foundation

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case emptyKey
    case networkError(Error)
    case decodingError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "API key is missing. Please add your Gemini API key in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse the AI response. Please try again."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Gemini Request Models

struct GeminiRequest: Encodable {
    let systemInstruction: GeminiContent
    let contents: [GeminiContent]

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

// MARK: - Gemini Response Models

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let error: GeminiErrorDetail?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

struct GeminiErrorDetail: Decodable {
    let message: String
    let code: Int?
}

// MARK: - AI Service

struct AIService {

    static let systemPrompt = """
    You are Journee AI, a strict, data-driven personal financial analyst operating entirely offline. \
    Your goal is to audit the user's spending habits for the current payday cycle. \
    Analyze the structured transaction summary provided. \
    Output your audit in exactly 3 bullet points: \
    1. One critical budget leak or alarming spending velocity trend. \
    2. One positive metric or category where they successfully saved money. \
    3. One actionable adjustment for the next payday cycle. \
    Do not include greetings, introductions, or verbose filler text. Be direct and objective.
    """

    /// Maximum number of retry attempts for transient failures.
    private static let maxRetries = 3

    /// Base delay (seconds) for exponential backoff.
    private static let baseDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

    /// Request timeout interval in seconds.
    private static let timeoutInterval: TimeInterval = 30

    /// Sends a spending summary prompt to the Gemini API and returns the audit text.
    /// Automatically retries up to 3 times with exponential backoff on network errors and rate limits (429).
    static func generateContent(prompt: String, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.emptyKey
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIServiceError.apiError("Invalid URL.")
        }

        // Build request body
        let body = GeminiRequest(
            systemInstruction: GeminiContent(parts: [GeminiPart(text: systemPrompt)]),
            contents: [GeminiContent(parts: [GeminiPart(text: prompt)])]
        )

        let encodedBody = try JSONEncoder().encode(body)

        var lastError: Error = AIServiceError.networkError(
            NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
        )

        for attempt in 0..<maxRetries {
            // Wait before retrying (exponential backoff: 0s, 1s, 2s, 4s...)
            if attempt > 0 {
                let delay = baseDelay * UInt64(1 << (attempt - 1))
                try? await Task.sleep(nanoseconds: delay)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = encodedBody
            request.timeoutInterval = timeoutInterval

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch {
                // Network error — retry
                lastError = AIServiceError.networkError(error)
                continue
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = AIServiceError.networkError(
                    NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                )
                continue
            }

            // Rate limited (429) — retry after backoff
            if httpResponse.statusCode == 429 {
                lastError = AIServiceError.apiError("Rate limited by Gemini API. Retrying…")
                continue
            }

            // Server error (5xx) — retry
            if (500...599).contains(httpResponse.statusCode) {
                lastError = AIServiceError.apiError("Server error (HTTP \(httpResponse.statusCode)). Retrying…")
                continue
            }

            // Other non-success status — don't retry, fail immediately
            if !(200...299).contains(httpResponse.statusCode) {
                if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                   let errorDetail = geminiResponse.error {
                    throw AIServiceError.apiError(errorDetail.message)
                }
                throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
            }

            // Decode the response
            guard let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data) else {
                throw AIServiceError.decodingError
            }

            // Check for API-level error
            if let errorDetail = geminiResponse.error {
                throw AIServiceError.apiError(errorDetail.message)
            }

            // Extract generated text
            guard let text = geminiResponse.candidates?.first?.content.parts.first?.text,
                  !text.isEmpty else {
                throw AIServiceError.decodingError
            }

            return text
        }

        // All retries exhausted
        throw lastError
    }
}
