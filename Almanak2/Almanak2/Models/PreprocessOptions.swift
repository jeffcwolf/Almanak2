//
//  PreprocessOptions.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation

/// Configuration options for image preprocessing
struct PreprocessOptions: Codable {
    // MARK: - Preset Options
    var usePreset: Bool
    var presetType: PresetType

    // MARK: - Custom Options
    var grayscale: Bool
    var deskew: Bool
    var deskewTolerance: Double
    var denoise: Bool
    var denoiseRadius: Double
    var enhanceContrast: Bool
    var binarize: Bool

    // MARK: - Preset Types
    enum PresetType: String, Codable, CaseIterable {
        case documentOCR = "Document OCR"
        case scannedDocument = "Scanned Document"
        case photoText = "Photo Text"

        var description: String {
            switch self {
            case .documentOCR:
                return "Optimized for clean printed documents"
            case .scannedDocument:
                return "Optimized for scanned pages with potential skew"
            case .photoText:
                return "Optimized for photos containing text"
            }
        }
    }

    // MARK: - Default Presets

    static let documentOCRPreset = PreprocessOptions(
        usePreset: true,
        presetType: .documentOCR,
        grayscale: true,
        deskew: true,
        deskewTolerance: 5.0,
        denoise: false,
        denoiseRadius: 2.0,
        enhanceContrast: false,
        binarize: true
    )

    static let scannedDocumentPreset = PreprocessOptions(
        usePreset: true,
        presetType: .scannedDocument,
        grayscale: true,
        deskew: true,
        deskewTolerance: 10.0,
        denoise: true,
        denoiseRadius: 2.0,
        enhanceContrast: true,
        binarize: true
    )

    static let photoTextPreset = PreprocessOptions(
        usePreset: true,
        presetType: .photoText,
        grayscale: true,
        deskew: false,
        deskewTolerance: 5.0,
        denoise: true,
        denoiseRadius: 3.0,
        enhanceContrast: true,
        binarize: false
    )

    static let custom = PreprocessOptions(
        usePreset: false,
        presetType: .documentOCR,
        grayscale: false,
        deskew: false,
        deskewTolerance: 5.0,
        denoise: false,
        denoiseRadius: 2.0,
        enhanceContrast: false,
        binarize: false
    )

    // MARK: - Initialization

    init(
        usePreset: Bool = true,
        presetType: PresetType = .documentOCR,
        grayscale: Bool = true,
        deskew: Bool = true,
        deskewTolerance: Double = 5.0,
        denoise: Bool = true,
        denoiseRadius: Double = 2.0,
        enhanceContrast: Bool = true,
        binarize: Bool = true
    ) {
        self.usePreset = usePreset
        self.presetType = presetType
        self.grayscale = grayscale
        self.deskew = deskew
        self.deskewTolerance = deskewTolerance
        self.denoise = denoise
        self.denoiseRadius = denoiseRadius
        self.enhanceContrast = enhanceContrast
        self.binarize = binarize
    }

    // MARK: - Helper Methods

    /// Apply preset to current options
    mutating func applyPreset(_ preset: PresetType) {
        usePreset = true
        presetType = preset
        switch preset {
        case .documentOCR:
            self = .documentOCRPreset
        case .scannedDocument:
            self = .scannedDocumentPreset
        case .photoText:
            self = .photoTextPreset
        }
    }

    /// Check if any custom option is enabled
    var hasCustomOptions: Bool {
        !usePreset && (grayscale || deskew || denoise || enhanceContrast || binarize)
    }

    /// Summary of enabled options
    var summary: String {
        if usePreset {
            return presetType.rawValue
        }

        var options: [String] = []
        if grayscale { options.append("Grayscale") }
        if deskew { options.append("Deskew") }
        if denoise { options.append("Denoise") }
        if enhanceContrast { options.append("Contrast") }
        if binarize { options.append("Binarize") }

        return options.isEmpty ? "None" : options.joined(separator: ", ")
    }
}
