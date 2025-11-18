//
//  PreprocessingManager.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import AppKit
import SwiftImagePrep

/// Manages image preprocessing using SwiftImagePrep
@MainActor
class PreprocessingManager: ObservableObject {
    // MARK: - Published Properties
    @Published var beforeImage: NSImage?
    @Published var afterImage: NSImage?
    @Published var isProcessing = false
    @Published var currentOptions = PreprocessOptions.documentOCRPreset

    // MARK: - Preview

    /// Preview preprocessing with current options
    func previewPreprocessing(image: NSImage, options: PreprocessOptions) async throws {
        beforeImage = image
        isProcessing = true
        defer { isProcessing = false }

        let pipeline = try buildPipeline(from: options)
        afterImage = try pipeline.process(image)
    }

    // MARK: - Single Page Processing

    /// Preprocess a single page
    func preprocessPage(
        pageIndex: Int,
        projectURL: URL,
        options: PreprocessOptions
    ) async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Load original page
        let pagesDir = projectURL.appendingPathComponent("pages")
        let pageURL = try getPageURL(at: pageIndex, in: pagesDir)

        guard let originalImage = NSImage(contentsOf: pageURL) else {
            throw AlmanakError.invalidImage
        }

        // Build and apply pipeline
        let pipeline = try buildPipeline(from: options)
        let processedImage = try pipeline.process(originalImage)

        // Save to preprocessed directory
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        let outputURL = preprocessedDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).png"
        )

        try saveImageAsPNG(processedImage, to: outputURL)
    }

    // MARK: - Batch Processing

    /// Preprocess all pages
    func preprocessAllPages(
        projectURL: URL,
        options: PreprocessOptions,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Get all page files
        let pagesDir = projectURL.appendingPathComponent("pages")
        let pageFiles = try FileManager.default.contentsOfDirectory(
            at: pagesDir,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() != "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        // Load all images
        let images = try pageFiles.compactMap { url -> NSImage? in
            guard let image = NSImage(contentsOf: url) else {
                throw AlmanakError.invalidImage
            }
            return image
        }

        // Build pipeline
        let pipeline = try buildPipeline(from: options)

        // Batch process (concurrent)
        let processedImages = try await pipeline.processBatch(images)

        // Save all processed images
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")

        for (index, processedImage) in processedImages.enumerated() {
            let outputURL = preprocessedDir.appendingPathComponent(
                "page_\(String(format: "%03d", index)).png"
            )
            try saveImageAsPNG(processedImage, to: outputURL)
            progressHandler(index + 1, processedImages.count)
        }
    }

    /// Preprocess a range of pages
    func preprocessPages(
        _ indices: [Int],
        projectURL: URL,
        options: PreprocessOptions,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws {
        isProcessing = true
        defer { isProcessing = false }

        let total = indices.count
        for (completed, index) in indices.enumerated() {
            try await preprocessPage(
                pageIndex: index,
                projectURL: projectURL,
                options: options
            )
            progressHandler(completed + 1, total)
        }
    }

    // MARK: - Pipeline Building

    /// Build an image processing pipeline from options
    private func buildPipeline(from options: PreprocessOptions) throws -> ImagePipeline {
        if options.usePreset {
            // Use preset pipeline
            switch options.presetType {
            case .documentOCR:
                return ImagePipeline.documentOCR()
            case .scannedDocument:
                return ImagePipeline.scannedDocument()
            case .photoText:
                return ImagePipeline.photoText()
            }
        } else {
            // Build custom pipeline
            var pipeline = ImagePipeline()

            if options.grayscale {
                pipeline = pipeline.add(.grayscale)
            }

            if options.deskew {
                pipeline = pipeline.add(.deskew(tolerance: options.deskewTolerance))
            }

            if options.denoise {
                pipeline = pipeline.add(.denoise(method: .gaussian(radius: options.denoiseRadius)))
            }

            if options.enhanceContrast {
                pipeline = pipeline.add(.enhanceContrast(method: .histogramEqualization))
            }

            if options.binarize {
                pipeline = pipeline.add(.binarize(method: .otsu))
            }

            return pipeline
        }
    }

    // MARK: - Utilities

    /// Check if a page has been preprocessed
    func isPagePreprocessed(pageIndex: Int, projectURL: URL) -> Bool {
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: preprocessedDir,
            includingPropertiesForKeys: nil
        ) else {
            return false
        }

        return files.contains(where: {
            $0.lastPathComponent.contains(String(format: "%03d", pageIndex))
        })
    }

    /// Get count of preprocessed pages
    func preprocessedPageCount(projectURL: URL) -> Int {
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: preprocessedDir,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }

        return files.filter { $0.pathExtension.lowercased() != "json" }.count
    }

    /// Delete all preprocessed images (to start over)
    func clearPreprocessedPages(projectURL: URL) throws {
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        let files = try FileManager.default.contentsOfDirectory(
            at: preprocessedDir,
            includingPropertiesForKeys: nil
        )

        for file in files where file.pathExtension.lowercased() != "json" {
            try FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Helper Methods

    private func getPageURL(at index: Int, in directory: URL) throws -> URL {
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() != "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard index < files.count else {
            throw AlmanakError.fileNotFound(directory)
        }

        return files[index]
    }

    private func saveImageAsPNG(_ image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw AlmanakError.imageConversionFailed
        }

        try pngData.write(to: url)
    }

    // MARK: - Cleanup

    func reset() {
        beforeImage = nil
        afterImage = nil
        isProcessing = false
        currentOptions = .documentOCRPreset
    }
}
