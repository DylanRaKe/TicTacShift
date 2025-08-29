# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TicTacShift is a SwiftUI iOS application using SwiftData for data persistence. The project structure follows a standard Xcode iOS app template with three main Swift files:

- `TicTacShiftApp.swift` - Main app entry point with SwiftData model container configuration
- `ContentView.swift` - Primary UI view implementing a list-based interface with add/delete functionality
- `Item.swift` - SwiftData model representing a simple item with timestamp

## Architecture

- **Framework**: SwiftUI for UI, SwiftData for data persistence
- **Data Model**: Single `Item` entity with timestamp property using `@Model` macro
- **UI Pattern**: NavigationSplitView with master-detail layout
- **State Management**: SwiftData's `@Query` and `@Environment(\.modelContext)` for data operations

## Development Commands

### Building the Project
```bash
# Build the project
xcodebuild -project TicTacShift.xcodeproj -scheme TicTacShift build

# Build for specific destination (simulator)
xcodebuild -project TicTacShift.xcodeproj -scheme TicTacShift -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project TicTacShift.xcodeproj clean
```

### Running Tests
```bash
# Run tests
xcodebuild -project TicTacShift.xcodeproj -scheme TicTacShift test

# Run tests on specific simulator
xcodebuild -project TicTacShift.xcodeproj -scheme TicTacShift -destination 'platform=iOS Simulator,name=iPhone 15' test
```

### Swift Package Manager (if needed)
```bash
# Resolve package dependencies (if any are added)
swift package resolve

# Build with Swift PM (alternative approach)
swift build
```

## Key Considerations

- The project currently uses a basic SwiftData setup with in-memory fallback configuration
- UI follows iOS Human Interface Guidelines with standard NavigationSplitView patterns
- SwiftData models use the `@Model` macro for automatic persistence
- The app supports standard iOS list operations (add, delete, edit mode)

## Opening the Project

Always open `TicTacShift.xcodeproj` in Xcode rather than individual Swift files to maintain proper build settings and dependencies.