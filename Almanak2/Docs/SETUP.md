# Almanak2 Setup Guide

Complete setup instructions for building and running Almanak2.

## Prerequisites

### Required Software

1. **macOS Ventura (13.0) or later**
2. **Xcode 15.0 or later**
   - Download from Mac App Store
   - Or from [developer.apple.com](https://developer.apple.com/download/)
3. **Git**
   - Pre-installed on macOS
   - Or install via Homebrew: `brew install git`

### Optional Software

1. **Ollama** (for advanced OCR and LLM features)
   ```bash
   # Install Ollama
   brew install ollama

   # Or download from ollama.ai
   ```

2. **Homebrew** (recommended for package management)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Step 1: Clone Repositories

### Recommended Workspace Structure

Create a workspace directory and clone all repositories:

```bash
# Create workspace
mkdir ~/Almanak2Workspace
cd ~/Almanak2Workspace

# Clone main app
git clone https://github.com/jeffcwolf/Almanak2.git

# Clone foundation packages
git clone https://github.com/jeffcwolf/SwiftProjectKit.git
git clone https://github.com/jeffcwolf/SwiftReader.git
git clone https://github.com/jeffcwolf/SwiftImagePrep.git
git clone https://github.com/jeffcwolf/SwiftOCR.git
git clone https://github.com/jeffcwolf/SwiftLLM.git
git clone https://github.com/jeffcwolf/SwiftEditorMD.git
```

Your directory structure should look like:
```
~/Almanak2Workspace/
├── Almanak2/
├── SwiftProjectKit/
├── SwiftReader/
├── SwiftImagePrep/
├── SwiftOCR/
├── SwiftLLM/
└── SwiftEditorMD/
```

## Step 2: Open Xcode Project

```bash
cd Almanak2/Almanak2
open Almanak2.xcodeproj
```

## Step 3: Add Local Package Dependencies

In Xcode:

1. **File → Add Package Dependencies** (or ⌘⇧A)

2. Click **Add Local...** button (bottom left)

3. Navigate to each package directory and add:
   - `~/Almanak2Workspace/SwiftProjectKit`
   - `~/Almanak2Workspace/SwiftReader`
   - `~/Almanak2Workspace/SwiftImagePrep`
   - `~/Almanak2Workspace/SwiftOCR`
   - `~/Almanak2Workspace/SwiftLLM`
   - `~/Almanak2Workspace/SwiftEditorMD`

4. For each package:
   - Select the package folder
   - Click **Add Package**
   - Select "Almanak2" target
   - Click **Add Package**

## Step 4: Verify Package Dependencies

1. In Xcode's Project Navigator, expand the "Package Dependencies" section
2. You should see all 6 packages listed:
   - SwiftProjectKit
   - SwiftReader
   - SwiftImagePrep
   - SwiftOCR
   - SwiftLLM
   - SwiftEditorMD

3. If any packages show errors:
   - Right-click on the package
   - Select "Update Package"

## Step 5: Configure Signing & Capabilities

1. Select "Almanak2" project in Navigator
2. Select "Almanak2" target
3. Go to "Signing & Capabilities" tab
4. Select your development team
5. Xcode will automatically configure:
   - App Sandbox
   - File Access (User Selected Files - Read/Write)
   - Network (Outgoing Connections)

## Step 6: Build the App

1. Select "Almanak2" scheme (top left, next to Play button)
2. Select "My Mac" as destination
3. Press ⌘B to build
4. Wait for build to complete (first build may take 2-3 minutes)

## Step 7: Run the App

1. Press ⌘R to run the app
2. The app should launch and show the project creation screen

## Step 8: Optional - Set Up Ollama

For enhanced OCR and LLM capabilities:

```bash
# Install Ollama
brew install ollama

# Start Ollama server (in a separate terminal)
ollama serve

# Pull required models
ollama pull llava      # For vision-based OCR
ollama pull llama3     # For text enhancement

# Verify models are installed
ollama list
```

Keep the Ollama server running while using Almanak2 for LLM features.

## Troubleshooting

### Build Errors

**Problem**: "No such module 'SwiftProjectKit'" (or other package)

**Solution**:
1. File → Packages → Resolve Package Versions
2. Clean build folder: Product → Clean Build Folder (⌘⇧K)
3. Rebuild: Product → Build (⌘B)

**Problem**: "Package dependency is missing"

**Solution**:
1. Verify package exists in workspace directory
2. Re-add the package via File → Add Package Dependencies
3. Ensure you selected "Add Local" not "Add Remote"

### Runtime Errors

**Problem**: "The operation couldn't be completed. Permission denied"

**Solution**:
1. Check entitlements are properly configured
2. Verify App Sandbox and File Access capabilities are enabled
3. Clean and rebuild the app

**Problem**: "Ollama not available"

**Solution**:
1. Verify Ollama is installed: `which ollama`
2. Start Ollama server: `ollama serve`
3. Check server is running: `curl http://localhost:11434/api/tags`
4. Restart Almanak2

### Package Version Conflicts

**Problem**: "Package dependency has conflicts"

**Solution**:
1. Ensure all packages are from the same version/branch
2. Update all packages: File → Packages → Update to Latest Package Versions
3. If issues persist, delete all packages and re-add them

## Development Workflow

### Making Changes to Foundation Packages

If you need to modify a foundation package:

1. Make changes in the package directory
2. Xcode will automatically detect changes
3. Build to verify changes work with Almanak2
4. Commit changes to the package repository

### Updating Package Dependencies

```bash
# In each package directory
cd ~/Almanak2Workspace/SwiftProjectKit
git pull origin main

# Repeat for all packages
```

Then in Xcode:
- File → Packages → Update to Latest Package Versions

### Running Tests

```bash
# From Almanak2 directory
cd ~/Almanak2Workspace/Almanak2

# Run tests
xcodebuild test -scheme Almanak2 -destination 'platform=macOS'
```

Or in Xcode:
- Product → Test (⌘U)

## Alternative: Using Package.swift

If you prefer using Swift Package Manager directly:

1. Create a `Package.swift` file in the workspace root:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Almanak2Workspace",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Almanak2", targets: ["Almanak2"])
    ],
    dependencies: [
        .package(path: "./SwiftProjectKit"),
        .package(path: "./SwiftReader"),
        .package(path: "./SwiftImagePrep"),
        .package(path: "./SwiftOCR"),
        .package(path: "./SwiftLLM"),
        .package(path: "./SwiftEditorMD"),
    ],
    targets: [
        .executableTarget(
            name: "Almanak2",
            dependencies: [
                "SwiftProjectKit",
                "SwiftReader",
                "SwiftImagePrep",
                "SwiftOCR",
                "SwiftLLM",
                "SwiftEditorMD",
            ]
        )
    ]
)
```

2. Build with SPM:
```bash
swift build
swift run
```

Note: The Xcode project approach is recommended for macOS app development.

## Next Steps

Once setup is complete:

1. Read the [README](README.md) for usage instructions
2. Review [IMPLEMENTATION_GUIDE.md](Docs/IMPLEMENTATION_GUIDE.md) for architecture details
3. Try the quick start workflow with a sample PDF
4. Explore the foundation package documentation in `Docs/`

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/jeffcwolf/Almanak2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jeffcwolf/Almanak2/discussions)
- **Documentation**: See `Docs/` folder
- **Package Docs**: Each package has its own README

---

**Last Updated**: 2025-11-17
