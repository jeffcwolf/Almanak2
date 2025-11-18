//
//  DocumentManager.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import AppKit
import PDFKit
import SwiftReader

/// Manages document import and viewing using SwiftReader
@MainActor
class DocumentManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPageImage: NSImage?
    @Published var totalPages: Int = 0
    @Published var currentPageIndex: Int = 0
    @Published var isProcessing = false

    // MARK: - Private Properties
    private var pdfViewModel: SwiftReaderViewModel?
    private var imageViewModel: SwiftImageViewModel?
    private var pageURLs: [URL] = []

    // MARK: - PDF Import

    /// Import a PDF file and extract pages as images
    func importPDF(from url: URL, projectURL: URL) async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Load PDF using SwiftReader
        pdfViewModel = SwiftReaderViewModel()
        await pdfViewModel?.loadPDF(from: url)

        guard let pdfDoc = pdfViewModel?.pdfDocument else {
            throw AlmanakError.invalidPDF("Could not load PDF document")
        }

        totalPages = pdfViewModel?.totalPages ?? 0

        guard totalPages > 0 else {
            throw AlmanakError.invalidPDF("PDF contains no pages")
        }

        // Save source PDF
        let sourceDir = projectURL.appendingPathComponent("source")
        let sourcePDFURL = sourceDir.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: sourcePDFURL)

        // Extract each page as image
        let pagesDir = projectURL.appendingPathComponent("pages")
        pageURLs = []

        for pageIndex in 0..<totalPages {
            guard let page = pdfDoc.page(at: pageIndex) else {
                throw AlmanakError.pageExtractionFailed(pageIndex)
            }

            let bounds = page.bounds(for: .mediaBox)
            let image = renderPage(page, bounds: bounds)

            let pageURL = pagesDir.appendingPathComponent(
                "page_\(String(format: "%03d", pageIndex)).png"
            )
            try saveImageAsPNG(image, to: pageURL)
            pageURLs.append(pageURL)
        }
    }

    /// Render a PDF page as an NSImage
    private func renderPage(_ page: PDFPage, bounds: CGRect) -> NSImage {
        let image = NSImage(size: bounds.size)

        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.setFillColor(NSColor.white.cgColor)
            context.fill(bounds)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
        }
        image.unlockFocus()

        return image
    }

    // MARK: - Image Import

    /// Import a folder of images
    func importImages(from urls: [URL], projectURL: URL) async throws {
        isProcessing = true
        defer { isProcessing = false }

        guard !urls.isEmpty else {
            throw AlmanakError.imageImportFailed("No images selected")
        }

        totalPages = urls.count

        let sourceDir = projectURL.appendingPathComponent("source")
        let pagesDir = projectURL.appendingPathComponent("pages")
        pageURLs = []

        for (index, url) in urls.enumerated() {
            // Verify image is valid
            guard NSImage(contentsOf: url) != nil else {
                throw AlmanakError.imageImportFailed("Invalid image: \(url.lastPathComponent)")
            }

            // Copy to source directory
            let sourceURL = sourceDir.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: sourceURL)

            // Also copy to pages directory for processing
            let ext = url.pathExtension.lowercased()
            let pageURL = pagesDir.appendingPathComponent(
                "page_\(String(format: "%03d", index)).\(ext)"
            )
            try FileManager.default.copyItem(at: url, to: pageURL)
            pageURLs.append(pageURL)
        }
    }

    // MARK: - Page Loading

    /// Load a specific page image
    func loadPage(_ index: Int, projectURL: URL) async throws {
        currentPageIndex = index

        // Determine which directory to load from (preprocessed if exists, else pages)
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        let pagesDir = projectURL.appendingPathComponent("pages")

        var pageURL: URL?

        // Try preprocessed first
        if let preprocessedFiles = try? FileManager.default.contentsOfDirectory(
            at: preprocessedDir,
            includingPropertiesForKeys: nil
        ) {
            pageURL = preprocessedFiles.first(where: {
                $0.lastPathComponent.contains(String(format: "%03d", index))
            })
        }

        // Fall back to original pages
        if pageURL == nil {
            let pageFiles = try FileManager.default.contentsOfDirectory(
                at: pagesDir,
                includingPropertiesForKeys: nil
            )
            pageURL = pageFiles.first(where: {
                $0.lastPathComponent.contains(String(format: "%03d", index))
            })
        }

        guard let imageURL = pageURL else {
            throw AlmanakError.fileNotFound(pagesDir.appendingPathComponent("page_\(index)"))
        }

        // Load image using SwiftReader
        imageViewModel = SwiftImageViewModel()
        await imageViewModel?.loadImage(from: imageURL)

        currentPageImage = imageViewModel?.processedImage ?? imageViewModel?.originalImage

        guard currentPageImage != nil else {
            throw AlmanakError.invalidImage
        }
    }

    /// Load page by URL
    func loadPageImage(from url: URL) async throws -> NSImage? {
        imageViewModel = SwiftImageViewModel()
        await imageViewModel?.loadImage(from: url)
        return imageViewModel?.processedImage ?? imageViewModel?.originalImage
    }

    // MARK: - Navigation

    /// Go to next page
    func nextPage(projectURL: URL) async throws {
        guard currentPageIndex < totalPages - 1 else { return }
        try await loadPage(currentPageIndex + 1, projectURL: projectURL)
    }

    /// Go to previous page
    func previousPage(projectURL: URL) async throws {
        guard currentPageIndex > 0 else { return }
        try await loadPage(currentPageIndex - 1, projectURL: projectURL)
    }

    /// Check if can go to next page
    var canGoNext: Bool {
        currentPageIndex < totalPages - 1
    }

    /// Check if can go to previous page
    var canGoPrevious: Bool {
        currentPageIndex > 0
    }

    // MARK: - Page Information

    /// Get all page URLs
    func getAllPageURLs(projectURL: URL) throws -> [URL] {
        let pagesDir = projectURL.appendingPathComponent("pages")
        let files = try FileManager.default.contentsOfDirectory(
            at: pagesDir,
            includingPropertiesForKeys: nil
        )
        return files.filter { $0.pathExtension.lowercased() != "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Get URL for a specific page
    func pageURL(for index: Int, projectURL: URL, preprocessed: Bool = false) -> URL? {
        let dir = preprocessed
            ? projectURL.appendingPathComponent("preprocessed")
            : projectURL.appendingPathComponent("pages")

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        return files.first(where: {
            $0.lastPathComponent.contains(String(format: "%03d", index))
        })
    }

    // MARK: - Image Utilities

    /// Save an NSImage as PNG
    private func saveImageAsPNG(_ image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw AlmanakError.imageConversionFailed
        }

        try pngData.write(to: url)
    }

    /// Save an NSImage to URL
    func saveImage(_ image: NSImage, to url: URL) throws {
        try saveImageAsPNG(image, to: url)
    }

    // MARK: - Cleanup

    /// Reset manager state
    func reset() {
        currentPageImage = nil
        totalPages = 0
        currentPageIndex = 0
        pageURLs = []
        pdfViewModel = nil
        imageViewModel = nil
    }
}
