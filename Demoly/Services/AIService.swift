//
//  AIService.swift
//  Demoly
//

import ClerkKit
import Foundation

@MainActor
final class AIService {
    static let shared = AIService()

    var currentModel: AIModel = .reasoner

    private init() {}

    // MARK: - Streaming Chat

    func streamChat(messages: [[String: Any]]) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard Clerk.shared.user != nil else {
                        throw AIError.unauthorized
                    }

                    var body: [String: Any] = [
                        "model": currentModel.rawValue,
                        "messages": messages,
                    ]

                    if currentModel.supportsThinking {
                        body["thinking"] = ["type": "enabled"]
                    }

                    let (bytes, _) = try await APIClient.shared.postRaw("/ai/chat", jsonObject: body)

                    var toolCallArguments: [Int: String] = [:]
                    var toolCallStarted: Set<Int> = []

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }

                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        if let usage = json["usage"] as? [String: Any] {
                            let promptTokens = usage["prompt_tokens"] as? Int ?? 0
                            let completionTokens = usage["completion_tokens"] as? Int ?? 0
                            var reasoningTokens = 0
                            if let details = usage["completion_tokens_details"] as? [String: Any] {
                                reasoningTokens = details["reasoning_tokens"] as? Int ?? 0
                            }
                            continuation.yield(
                                .usage(
                                    promptTokens: promptTokens,
                                    completionTokens: completionTokens,
                                    reasoningTokens: reasoningTokens
                                )
                            )
                        }

                        guard let choices = json["choices"] as? [[String: Any]],
                            let choice = choices.first,
                            let delta = choice["delta"] as? [String: Any]
                        else { continue }

                        if let reasoning = delta["reasoning_content"] as? String, !reasoning.isEmpty {
                            continuation.yield(.reasoning(reasoning))
                        }

                        if let content = delta["content"] as? String, !content.isEmpty {
                            continuation.yield(.content(content))
                        }

                        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                let index = tc["index"] as? Int ?? 0

                                if toolCallArguments[index] == nil {
                                    toolCallArguments[index] = ""
                                }

                                if let id = tc["id"] as? String,
                                    let function = tc["function"] as? [String: Any],
                                    let name = function["name"] as? String,
                                    !toolCallStarted.contains(index)
                                {
                                    toolCallStarted.insert(index)
                                    continuation.yield(.toolCallStart(index: index, id: id, name: name))
                                }

                                if let function = tc["function"] as? [String: Any],
                                    let args = function["arguments"] as? String
                                {
                                    toolCallArguments[index]! += args
                                    continuation.yield(.toolCallArguments(index: index, delta: args))
                                }
                            }
                        }

                        if let finishReason = choice["finish_reason"] as? String {
                            if finishReason == "tool_calls" {
                                for index in toolCallArguments.keys.sorted() {
                                    let args = toolCallArguments[index] ?? ""
                                    continuation.yield(.toolCallComplete(index: index, arguments: args))
                                }
                                toolCallArguments.removeAll()
                                toolCallStarted.removeAll()
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Types

    enum StreamEvent {
        case reasoning(String)
        case content(String)
        case toolCallStart(index: Int, id: String, name: String)
        case toolCallArguments(index: Int, delta: String)
        case toolCallComplete(index: Int, arguments: String)
        case usage(promptTokens: Int, completionTokens: Int, reasoningTokens: Int)
    }

    enum ToolName: String {
        case updateMetadata = "update_metadata"
        case writeHtml = "write_html"
        case writeCss = "write_css"
        case writeJavascript = "write_javascript"
        case replaceInHtml = "replace_in_html"
        case replaceInCss = "replace_in_css"
        case replaceInJavascript = "replace_in_javascript"
        case summarizeConversation = "summarize_conversation"
    }

    enum AIError: LocalizedError {
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .unauthorized: "Please sign in to use AI"
            }
        }
    }
}
