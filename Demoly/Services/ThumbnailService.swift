//
//  ThumbnailService.swift
//  Demoly
//

import UIKit
import WebKit

// MARK: - Constants

enum Thumbnail {
    /// Fixed aspect ratio matching the web frontend (iPhone portrait 9:19.5)
    static let aspectRatio: CGFloat = 9.0 / 19.5
}

// MARK: - Service

@MainActor
final class ThumbnailService {
    static let shared = ThumbnailService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Public API

    func captureAndUpload(from webView: WKWebView, projectId: String) async throws -> UploadResult {
        let screenshot = try await captureScreenshot(from: webView)
        let cropped = Self.cropToRatio(screenshot, targetRatio: Thumbnail.aspectRatio)
        return try await upload(image: cropped, projectId: projectId)
    }

    // MARK: - Upload (internal)

    private func upload(image: UIImage, projectId: String) async throws -> UploadResult {
        let ratio = image.size.width / image.size.height

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw Error.compressionFailed
        }

        let responseData = try await api.upload(
            "/upload/thumbnail/\(projectId)",
            fileData: data,
            fileName: "\(projectId).jpg",
            mimeType: "image/jpeg",
            extraFields: ["aspectRatio": "\(ratio)"]
        )

        let response = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return UploadResult(
            url: response.url,
            aspectRatio: CGFloat(response.aspectRatio ?? Double(ratio))
        )
    }

    // MARK: - Screenshot

    private func captureScreenshot(from webView: WKWebView) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds

            webView.takeSnapshot(with: config) { image, error in
                if let error {
                    continuation.resume(throwing: Error.captureFailed(error))
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: Error.noImage)
                }
            }
        }
    }

    // MARK: - Cropping

    static func cropToRatio(_ image: UIImage, targetRatio: CGFloat) -> UIImage {
        let size = image.size
        let ratio = size.width / size.height

        var cropRect: CGRect
        if ratio > targetRatio {
            let w = size.height * targetRatio
            cropRect = CGRect(x: (size.width - w) / 2, y: 0, width: w, height: size.height)
        } else {
            let h = size.width / targetRatio
            cropRect = CGRect(x: 0, y: (size.height - h) / 2, width: size.width, height: h)
        }

        cropRect = CGRect(
            x: cropRect.origin.x * image.scale,
            y: cropRect.origin.y * image.scale,
            width: cropRect.width * image.scale,
            height: cropRect.height * image.scale
        )

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Types

    struct UploadResult {
        let url: String
        let aspectRatio: CGFloat
    }

    private struct UploadResponse: Decodable {
        let url: String
        let aspectRatio: Double?
    }

    enum Error: LocalizedError {
        case captureFailed(Swift.Error)
        case noImage
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .captureFailed(let error): "Failed to capture: \(error.localizedDescription)"
            case .noImage: "No image captured"
            case .compressionFailed: "Failed to compress image"
            }
        }
    }
}
