//
//  ThumbnailService.swift
//  Demoly
//

import UIKit
import WebKit

/// Fixed aspect ratio matching the web frontend (iPhone portrait 9:19.5)
let thumbnailAspectRatio: CGFloat = 9.0 / 19.5

struct ThumbnailUploadResult {
    let url: String
    let aspectRatio: CGFloat
}

actor ThumbnailService {
    static let shared = ThumbnailService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Auto-capture + upload (called from save)

    @MainActor
    func captureAndUpload(from webView: WKWebView, projectId: String) async throws -> ThumbnailUploadResult {
        let screenshot = try await captureScreenshot(from: webView)
        let cropped = Self.cropToRatio(screenshot, targetRatio: thumbnailAspectRatio)
        return try await upload(image: cropped, projectId: projectId)
    }

    // MARK: - Upload

    func upload(image: UIImage, projectId: String) async throws -> ThumbnailUploadResult {
        let ratio = image.size.width / image.size.height

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ThumbnailError.compressionFailed
        }

        struct UploadResponse: Decodable {
            let url: String
            let aspectRatio: Double?
        }

        let responseData = try await api.upload(
            "/upload/thumbnail/\(projectId)",
            fileData: data,
            fileName: "\(projectId).jpg",
            mimeType: "image/jpeg",
            extraFields: ["aspectRatio": "\(ratio)"]
        )

        let response = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return ThumbnailUploadResult(
            url: response.url,
            aspectRatio: CGFloat(response.aspectRatio ?? Double(ratio))
        )
    }

    // MARK: - Screenshot Capture

    @MainActor
    private func captureScreenshot(from webView: WKWebView) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds

            webView.takeSnapshot(with: config) { image, error in
                if let error {
                    continuation.resume(throwing: ThumbnailError.captureFailed(error))
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: ThumbnailError.noImage)
                }
            }
        }
    }

    // MARK: - Cropping

    static func cropToRatio(_ image: UIImage, targetRatio: CGFloat) -> UIImage {
        let originalSize = image.size
        let originalRatio = originalSize.width / originalSize.height

        var cropRect: CGRect
        if originalRatio > targetRatio {
            let newWidth = originalSize.height * targetRatio
            let xOffset = (originalSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: originalSize.height)
        } else {
            let newHeight = originalSize.width / targetRatio
            let yOffset = (originalSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: originalSize.width, height: newHeight)
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

    // MARK: - Errors

    enum ThumbnailError: LocalizedError {
        case captureFailed(Error)
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
