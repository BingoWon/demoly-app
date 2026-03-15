//
//  APIClient.swift
//  Swipop
//
//  Central HTTP client for the Cloudflare Worker API
//

import ClerkKit
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case forbidden
    case serverError(Int, String?)
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .unauthorized: "Please sign in"
        case .notFound: "Not found"
        case .forbidden: "Access denied"
        case let .serverError(code, msg): msg ?? "Server error (\(code))"
        case let .decodingFailed(err): "Decoding error: \(err.localizedDescription)"
        case let .networkError(err): err.localizedDescription
        }
    }
}

nonisolated struct EmptyPayload: Encodable, Sendable {}

actor APIClient {
    static let shared = APIClient()

    private let session = Config.urlSession

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        nonisolated(unsafe) let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        nonisolated(unsafe) let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = iso.date(from: str) { return date }
            if let date = isoBasic.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private init() {}

    // MARK: - Token

    private func authToken() async -> String? {
        try? await Clerk.shared.session?.getToken()
    }

    // MARK: - HTTP Methods

    func get<T: Decodable>(_ path: String, query: [String: String]? = nil) async throws -> T {
        let data = try await request("GET", path: path, query: query)
        return try decode(data)
    }

    func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        let data = try await request("POST", path: path, body: body)
        return try decode(data)
    }

    func post(_ path: String, body: some Encodable) async throws {
        _ = try await request("POST", path: path, body: body)
    }

    func patch<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        let data = try await request("PATCH", path: path, body: body)
        return try decode(data)
    }

    func patch(_ path: String, body: some Encodable) async throws {
        _ = try await request("PATCH", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        _ = try await request("DELETE", path: path)
    }

    // MARK: - Multipart Upload

    func upload(_ path: String, fileData: Data, fileName: String, mimeType: String, extraFields: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: "\(Config.apiBaseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        for (key, value) in extraFields {
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        body.append(Data(boundaryPrefix.utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    // MARK: - Raw JSON POST (for [String: Any] bodies like AI chat)

    private let streamingSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config)
    }()

    func postRaw(_ path: String, jsonObject: Any) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        guard let url = URL(string: "\(Config.apiBaseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)

        let (bytes, response) = try await streamingSession.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(0, "Invalid response")
        }
        if httpResponse.statusCode != 200 {
            throw APIError.serverError(httpResponse.statusCode, nil)
        }
        return (bytes, httpResponse)
    }

    // MARK: - Private

    private func request(_ method: String, path: String, query: [String: String]? = nil, body: (some Encodable)? = Optional<EmptyPayload>.none) async throws -> Data {
        guard var components = URLComponents(string: "\(Config.apiBaseURL)\(path)") else {
            throw APIError.invalidURL
        }

        if let query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200 ... 299: return
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 404: throw APIError.notFound
        default:
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String }
            throw APIError.serverError(http.statusCode, message)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
