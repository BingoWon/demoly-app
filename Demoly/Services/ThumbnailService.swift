//
//  ThumbnailService.swift
//  Demoly
//

import UIKit
import WebKit

struct ThumbnailUploadResult {
    let url: String
    let aspectRatio: CGFloat
}

enum ThumbnailAspectRatio: String, CaseIterable, Identifiable {
    case portrait = "3:4"
    case square = "1:1"
    case landscape = "4:3"

    var id: String {
        rawValue
    }

    var ratio: CGFloat {
        switch self {
        case .portrait: 3.0 / 4.0
        case .square: 1.0
        case .landscape: 4.0 / 3.0
        }
    }

    var icon: String {
        switch self {
        case .portrait: "rectangle.portrait"
        case .square: "square"
        case .landscape: "rectangle"
        }
    }
}

actor ThumbnailService {
    static let shared = ThumbnailService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Public API

    @MainActor
    func capture(from webView: WKWebView, aspectRatio: ThumbnailAspectRatio) async throws -> UIImage {
        let screenshot = try await captureScreenshot(from: webView)
        return Self.cropToRatio(screenshot, targetRatio: aspectRatio.ratio)
    }

    func upload(image: UIImage, projectId: String) async throws -> ThumbnailUploadResult {
        let cropped = Self.cropToValidRatio(image)
        let aspectRatio = cropped.size.width / cropped.size.height

        guard let data = cropped.jpegData(compressionQuality: 0.8) else {
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
            extraFields: ["aspectRatio": "\(aspectRatio)"]
        )

        let response = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return ThumbnailUploadResult(
            url: response.url,
            aspectRatio: CGFloat(response.aspectRatio ?? Double(aspectRatio))
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

    // MARK: - Aspect Ratio Cropping

    static func cropToValidRatio(_ image: UIImage) -> UIImage {
        let minRatio: CGFloat = 3.0 / 4.0
        let maxRatio: CGFloat = 4.0 / 3.0
        let currentRatio = image.size.width / image.size.height
        if currentRatio >= minRatio && currentRatio <= maxRatio { return image }
        let targetRatio = currentRatio < minRatio ? minRatio : maxRatio
        return cropToRatio(image, targetRatio: targetRatio)
    }

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
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .captureFailed(let error): "Failed to capture: \(error.localizedDescription)"
            case .noImage: "No image captured"
            case .compressionFailed: "Failed to compress image"
            case .notAuthenticated: "Please sign in"
            }
        }
    }
}
