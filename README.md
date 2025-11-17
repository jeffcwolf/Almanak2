# Almanak2

A macOS application for transcribing historical documents (especially 18th-century printed books) using multiple OCR engines and optional LLM enhancement.

## Overview

Almanak2 is a complete rebuild of the OCR transcription workflow, properly architected around foundation Swift packages with app-level orchestration. The app focuses on one thing exceptionally well: **transcribing historical printed documents with high accuracy**.

### Key Features

- **Multi-Engine OCR**: Apple Vision (built-in) and Ollama VLLM (optional)
- **Image Preprocessing**: Deskew, binarize, denoise, contrast enhancement
- **LLM Enhancement**: Optional text improvement using local Ollama models
- **Markdown Editing**: Full-featured markdown editor with auto-save
- **Session Persistence**: Resume exactly where you left off
- **Flexible Workflow**: Skip optional stages, compare OCR engines

## Architecture

```
Almanak2 (macOS App)
    ↓
App-Level Orchestration (AppState + Managers)
    ↓
Foundation Packages (6 total)
```

### Foundation Packages

1. **SwiftProjectKit** - Project management and file organization
2. **SwiftReader** - PDF and image viewing (supports PDF, JP2, PNG, JPEG, TIFF, etc.)
3. **SwiftImagePrep** - Image preprocessing for OCR optimization
4. **SwiftOCR** - OCR engine abstraction (Vision, Ollama)
5. **SwiftLLM** - LLM text enhancement
6. **SwiftEditorMD** - Markdown editor component

## Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0+ (for building from source)
- **Swift**: 5.9+
- **Memory**: 8GB RAM (16GB recommended)
- **Storage**: 2GB free space per project

### Optional

- **Ollama**: For vision-based OCR and LLM text enhancement
  - Install from [ollama.ai](https://ollama.ai)
  - Pull models: `ollama pull llava` and `ollama pull llama3`

## Installation

### From Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jeffcwolf/Almanak2.git
   cd Almanak2
   ```

2. **Install foundation packages**:

   The app expects the following packages to be in sibling directories:
   ```
   Workspace/
   ├── Almanak2/              # This app
   ├── SwiftProjectKit/       # git clone https://github.com/jeffcwolf/SwiftProjectKit
   ├── SwiftReader/           # git clone https://github.com/jeffcwolf/SwiftReader
   ├── SwiftImagePrep/        # git clone https://github.com/jeffcwolf/SwiftImagePrep
   ├── SwiftOCR/              # git clone https://github.com/jeffcwolf/SwiftOCR
   ├── SwiftLLM/              # git clone https://github.com/jeffcwolf/SwiftLLM
   └── SwiftEditorMD/         # git clone https://github.com/jeffcwolf/SwiftEditorMD
   ```

3. **Open in Xcode**:
   ```bash
   open Almanak2/Almanak2.xcodeproj
   ```

4. **Add local package dependencies**:
   - In Xcode: File → Add Package Dependencies → Add Local...
   - Select each package folder from the workspace

5. **Configure entitlements**:
   - The project includes necessary entitlements for file access
   - No additional configuration needed

6. **Build and run**:
   - Select "Almanak2" scheme
   - Press ⌘R to build and run

## Quick Start

### 1. Create a Project

- Launch Almanak2
- Click "New Project"
- Enter book title, author, and optional publication info

### 2. Import Document

- Choose PDF file or image folder
- Supports: PDF, JP2, PNG, JPEG, TIFF, GIF, BMP, WebP, HEIC
- Pages are extracted automatically

### 3. Preprocess (Optional)

- Choose preset: Document OCR, Scanned Document, or Photo Text
- Or configure custom options (deskew, binarize, denoise, etc.)
- Preview before/after
- Can be skipped entirely

### 4. OCR & Enhancement

- Select OCR engine(s): Vision (fast) or Ollama (accurate)
- Compare results if using both engines
- Optionally enhance with LLM for better text quality
- Save transcription

### 5. Edit

- Review and manually correct transcriptions
- Side-by-side view with original image
- Full markdown editing with auto-save
- Navigate between pages

### 6. Export

- Combines all pages into single markdown file
- Optional metadata frontmatter
- Preview before export
- Open in Finder or external editor

## Workflow Stages

| Stage | Required | Description |
|-------|----------|-------------|
| **Setup** | Yes | Create or open project |
| **Import** | Yes | Load PDF or images |
| **Preprocess** | No | Enhance images for OCR |
| **OCR** | Yes | Extract text from images |
| **Edit** | Yes | Review and correct transcriptions |
| **Export** | Yes | Combine and save final document |

## Configuration

### File Locations

Projects are stored in:
```
~/Library/Application Support/Almanak2/Projects/[uuid]/
├── .swiftproject/     # Metadata (managed by SwiftProjectKit)
├── source/            # Original PDF or images
├── pages/             # Extracted page images
├── preprocessed/      # Enhanced images (optional)
├── ocr/
│   ├── vision/        # Apple Vision results
│   └── ollama/        # Ollama results
└── transcription/     # Final markdown files
```

### Ollama Setup (Optional)

For best results with historical documents:

```bash
# Install Ollama
brew install ollama

# Start Ollama server
ollama serve

# Pull vision model (for OCR)
ollama pull llava

# Pull text model (for enhancement)
ollama pull llama3
```

The app will automatically detect if Ollama is available.

## Keyboard Shortcuts

- **⌘N**: New Project
- **⌘O**: Open Project
- **⌘S**: Save Project
- **⌘←/→**: Navigate pages (in editing mode)
- **⌘+/-/0**: Zoom in editor
- **⌘F**: Search in editor
- **⌘B/I/K**: Bold/Italic/Link in editor

## Performance

Target performance on typical hardware:

| Operation | Target Time |
|-----------|-------------|
| Project creation | < 1 second |
| Import 100-page PDF | < 10 seconds |
| Preprocess per page | < 1 second |
| Vision OCR per page | < 3 seconds |
| Ollama OCR per page | < 30 seconds |
| LLM enhancement | < 10 seconds |
| Auto-save | < 1 second |
| Export | < 5 seconds |

## Troubleshooting

### Ollama Not Available

**Problem**: OCR stage shows "Ollama not available"

**Solution**:
1. Install Ollama from ollama.ai
2. Start server: `ollama serve`
3. Pull model: `ollama pull llava`
4. Restart Almanak2

### PDF Import Fails

**Problem**: "Invalid PDF file" error

**Solution**:
1. Open PDF in Preview to verify it's valid
2. Try exporting from Preview to a new PDF
3. Ensure PDF is not password-protected

### Low OCR Accuracy

**Problem**: OCR results are poor quality

**Solutions**:
1. Enable preprocessing (especially for scanned documents)
2. Use "Scanned Document" preset
3. Try Ollama VLLM engine if available
4. Use LLM enhancement to improve results

### Disk Space Issues

**Problem**: "Disk full" error during processing

**Solution**:
1. Free up at least 2GB of space
2. Projects store multiple versions of images (original, preprocessed, etc.)
3. Delete old projects or move to external storage

## Development

### Project Structure

```
Almanak2/
├── Almanak2/
│   ├── AlmanakApp.swift           # App entry point
│   ├── Core/
│   │   ├── AppState.swift         # Central coordinator
│   │   └── Managers/              # Package wrappers
│   ├── Models/                    # Data models
│   ├── Views/                     # SwiftUI views
│   │   ├── StageViews/            # Workflow stages
│   │   └── Components/            # Reusable components
│   └── ViewModels/                # MVVM view models
├── Docs/                          # Documentation
│   └── IMPLEMENTATION_GUIDE.md    # Detailed implementation doc
└── README.md                      # This file
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Document public APIs with doc comments
- Keep functions focused and small

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

**Author**: Jeff Wolf ([@jeffcwolf](https://github.com/jeffcwolf))

**Built with**:
- SwiftUI
- PDFKit
- Vision framework
- Ollama (optional)

**Foundation Packages**:
- SwiftProjectKit - Project management
- SwiftReader - Document viewing
- SwiftImagePrep - Image preprocessing
- SwiftOCR - OCR abstraction
- SwiftLLM - LLM integration
- SwiftEditorMD - Markdown editing

## Support

- **Issues**: [GitHub Issues](https://github.com/jeffcwolf/Almanak2/issues)
- **Documentation**: See [Docs](Docs/) folder
- **Discussions**: [GitHub Discussions](https://github.com/jeffcwolf/Almanak2/discussions)

## Roadmap

### v1.1 (Planned)
- Batch OCR processing
- Thumbnail navigation
- Custom preprocessing profiles
- Multiple LLM model support

### v1.2 (Future)
- Additional OCR engines (Tesseract, Kraken)
- Export formats (DOCX, HTML, EPUB)
- Cloud sync (iCloud)
- Undo/redo for editing

### v2.0 (Vision)
- Annotation workflow
- Layout analysis (columns, tables)
- Collaborative features
- Version control for transcriptions

---

**Last Updated**: 2025-11-17
**Version**: 1.0.0
**Status**: Initial Release
