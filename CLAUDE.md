# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Church Hymn is a native macOS application for managing and presenting church hymns. Built with SwiftUI and SwiftData, it supports import/export of hymn collections, presentation mode for projection, and a "Today's Service" feature for planning worship services.

**Target Platform**: macOS 14.0+ (Sonoma)
**Primary Language**: Swift 5.9+
**Frameworks**: SwiftUI, SwiftData, AppKit (for window management)

## Build & Run Commands

### Building the App
```bash
# Open project in Xcode
open ChurchHymn.xcodeproj

# Build from command line
xcodebuild -scheme ChurchHymn -configuration Debug build

# Build for release
xcodebuild -scheme ChurchHymn -configuration Release build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme ChurchHymn -destination 'platform=macOS'

# Run only unit tests
xcodebuild test -scheme ChurchHymn -destination 'platform=macOS' -only-testing:ChurchHymnTests

# Run only UI tests
xcodebuild test -scheme ChurchHymn -destination 'platform=macOS' -only-testing:ChurchHymnUITests
```

### Running the App
- Press `Cmd+R` in Xcode
- Or build and run from Applications folder after archiving

## Architecture Overview

### Data Layer (SwiftData Models)

The app uses three interconnected SwiftData models:

1. **Hymn** (`Hymn.swift`) - Core hymn data model
   - Primary fields: `title` (required), `lyrics`, `musicalKey`, `author`, `copyright`, `tags`, `notes`, `songNumber`
   - Includes Codable support for JSON serialization
   - Contains import/export methods for plain text and JSON formats
   - `parts` computed property: Parses lyrics into labeled sections (Verse 1, Chorus, etc.)

2. **WorshipService** (`WorshipService.swift`) - Represents a worship service
   - Fields: `title`, `date`, `isActive` (only one active at a time), `notes`
   - Used for the "Today's Service" feature
   - Tracks which service is currently being planned

3. **ServiceHymn** (`ServiceHymn.swift`) - Junction table linking hymns to services
   - Many-to-many relationship between Hymn and WorshipService
   - Fields: `hymnId`, `serviceId`, `order` (for sequencing in service)
   - Enables hymn reordering within a service

### Operations Layer

Business logic is separated into three operations classes:

1. **HymnOperations** (`HymnOperations.swift`) - Main import/export orchestrator
   - `@ObservableObject` with `@Published` progress properties
   - Import methods: `importPlainTextHymn()`, `importBatchJSON()`, `importLargeJSONStreaming()`
   - Export methods: `exportPlainTextHymn()`, `exportSingleJSONHymn()`, `exportBatchJSON()`, `exportLargeJSONStreaming()`
   - Duplicate detection by title (case-insensitive)
   - Error handling with domain-specific `ImportError` enum

2. **HymnStreamingOperations** (`HymnStreamingOperations.swift`) - Memory-efficient large file handler
   - Processes files in 8KB chunks (configurable)
   - 50MB max memory usage limit
   - Progress tracking with `StreamingProgress` model
   - Uses OSLog for debugging (`HymnStreamingLogger`)

3. **ServiceOperations** (`ServiceOperations.swift`) - Service lifecycle management
   - `@MainActor` for UI safety
   - Key methods:
     - `getOrCreateTodaysService()` - Gets or creates "Today's Service"
     - `fetchServiceHymns()` - Gets hymns in a service (sorted by order)
     - `addHymnToTodaysService()`, `removeHymnFromTodaysService()` - Manage service content
     - `reorderServiceHymns()` - Change hymn order in service
     - `archiveActiveService()` - Deactivate current service
     - `deleteService()` - Remove service and all links

### View Layer (SwiftUI)

**Main Structure**: `NavigationSplitView` (three-column layout on macOS)

**ContentView** (`ContentView.swift`) - Central coordinator (~900 lines)
- Manages all application state (`@State`, `@StateObject`)
- Orchestrates file import/export with `fileImporter`/`fileExporter`
- Handles presentation mode lifecycle
- Filters view between "All Hymns" and "Today's Service" modes
- Uses `@Query` for reactive SwiftData updates

**Key Views**:
- **HymnListView**: Sidebar showing hymn library with search/filter
- **ServiceView**: Shows active service with hymn reordering
- **DetailView**: Right pane showing selected hymn details
- **PresenterView**: Full-screen presentation window (separate NSWindow)
- **HymnEditView**: Modal form for creating/editing hymns
- **ImportPreviewView**: Preview and duplicate resolution for imports
- **ExportSelectionView**: Hymn selection and format choice for exports
- **ServiceCreationView**: Form for creating new services
- **ServiceHistoryView**: List all services with activate/delete actions

### Presentation System

**Two-Window Architecture**:
- Main window: App interface (editing, selection)
- Presenter window: Separate NSWindow for projection (managed by global `presenterWindow` variable)

**Components**:
- `PresenterSession`: Observable object tracking current hymn and part index
- `PresenterView`: Black background with large white text (80pt bold)
- Part navigation: Arrow keys move between verses/choruses
- Chorus interleaving: After each verse, chorus is shown automatically

**Keyboard Controls**:
- Return or Present button → Start presentation
- Left/Right arrows → Navigate between parts
- ESC → Close presenter window

### Import/Export File Formats

**Plain Text Format**:
- First non-empty, non-`#` line is the title
- Metadata lines: `#Number:`, `#Key:`, `#Author:`, `#Copyright:`, `#Tags:`, `#Notes:`
- Lyrics follow, separated by empty lines
- Chorus blocks start with `CHORUS` on its own line

**JSON Format**:
- Single hymn: Object with hymn fields
- Batch: Array of hymn objects
- Only `title` is required
- Streaming available for large files (>10MB triggers automatic streaming)

See `IMPORT_EXPORT_FORMATS.md` for detailed format specifications.

## Key Design Patterns

### MVVM-Style Architecture
- **Model**: SwiftData models (Hymn, WorshipService, ServiceHymn)
- **View-Model**: Operations classes (ObservableObject with @Published properties)
- **View**: SwiftUI views (subscribe to Operations via @ObservedObject)

### State Management
- **@Query**: Auto-updating data from SwiftData
- **@State**: Local view state (selections, toggles, UI flags)
- **@StateObject**: Lifecycle-bound operations objects
- **@Environment(\.modelContext)**: Direct SwiftData access

### Thread Safety
- `@MainActor` on ServiceOperations and PresenterSession
- `@unchecked Sendable` on HymnOperations and HymnStreamingOperations
- `await MainActor.run {}` for UI updates from background tasks

### Publisher Pattern
- `MenuActionPublisher`: Singleton using NotificationCenter
- ContentView listens via `onReceive(NotificationCenter.default.publisher(for: .menuAction))`
- Enables menu commands to trigger actions in ContentView

### Composition Over Inheritance
- View modifiers extract repetitive patterns (`ContentViewModifiers.swift`, `DeleteConfirmationAlerts.swift`)
- Small, focused views composed into larger interfaces

## Development Workflow

### Standard Process (from existing CLAUDE.md)
1. Think through the problem and read relevant files
2. Write a plan to `projectplan.md` with todo items
3. Check in before beginning work
4. Work on todo items, marking them complete as you go
5. Provide high-level explanations at each step
6. Keep changes simple - minimize code impact
7. Add a review section to `projectplan.md` with summary

### Key Principles
- **Simplicity First**: Every change should impact as little code as possible
- **Test Data Models**: Hymn model includes import/export parsing - test with sample files
- **UI Responsiveness**: Use async/await with progress tracking for long operations
- **Error Recovery**: Provide clear error messages with recovery suggestions

## Important Files

### Core Application
- `ChurchHymnApp.swift` - App entry point, window groups, model container configuration
- `ContentView.swift` - Main coordinator, state management, file operations

### Data Models
- `Hymn.swift` - Main model with import/export logic
- `WorshipService.swift`, `ServiceHymn.swift` - Service management models
- `HymnTypes.swift` - Enums and type definitions

### Operations
- `HymnOperations.swift` - Import/export orchestration
- `HymnStreamingOperations.swift` - Large file handling
- `ServiceOperations.swift` - Service lifecycle

### Views
- `HymnListView.swift` - Library sidebar
- `ServiceView.swift` - Service display
- `DetailView.swift` - Hymn details pane
- `PresenterView.swift` - Presentation window
- `HymnEditView.swift` - Edit form

## Common Tasks

### Adding a New Hymn Field
1. Add property to `Hymn.swift` model
2. Increment `modelVersion` for schema migration
3. Update `CodingKeys` enum and `encode/decode` methods if Codable
4. Update plain text import/export if metadata field
5. Add to `HymnEditView.swift` UI
6. Update `DetailView.swift` display if visible field

### Modifying Import/Export Logic
1. Test with sample files in various formats
2. Update parsing in `Hymn.swift` for plain text
3. Update `HymnOperations.swift` for orchestration
4. Consider memory impact - use streaming for large operations
5. Update error handling in `ImportError` enum
6. Update format documentation in `IMPORT_EXPORT_FORMATS.md`

### Adding a New View
1. Create SwiftUI View file
2. Add to ContentView navigation or as modal sheet
3. Pass necessary `@ObservedObject` or `@Binding` parameters
4. Use `@Environment(\.modelContext)` for SwiftData access
5. Consider adding to menu commands if globally accessible

### Testing Presentation Mode
1. Create test hymn with multiple verses and chorus
2. Select hymn and press Return or Present button
3. Verify separate window opens (may appear behind main window)
4. Test arrow key navigation
5. Test ESC to close

## Gotchas & Important Notes

### SwiftData Query Sorting
- `@Query` descriptors must be compatible with the model properties
- Use `SortDescriptor(\Hymn.title)` not string-based sorting

### Presenter Window Lifecycle
- Global `presenterWindow` variable keeps window alive
- Must be set to `nil` when closed or window deallocates
- Uses AppKit NSWindow, not pure SwiftUI

### Service Active Flag
- Only one service can have `isActive = true` at a time
- `ServiceOperations.setActiveService()` handles deactivating others
- Always use this method, don't set `isActive` directly

### File Import Security
- macOS security restrictions apply to file access
- User must grant permission via file picker
- Plain text files must be UTF-8 encoded

### Memory Management
- Streaming operations automatically triggered for files >10MB
- Don't load entire large files into memory
- Use `HymnStreamingOperations` for batch operations on large collections

### Threading
- SwiftData operations must occur on the correct actor
- UI updates must be on `MainActor`
- File I/O should be in `Task` blocks

## Debugging Tips

### View Console Logs
```bash
# View app logs
log show --predicate 'subsystem == "com.churchhymn"' --last 1h --info

# Stream live logs
log stream --predicate 'subsystem == "com.churchhymn"' --level debug
```

### Common Issues
- **Import fails silently**: Check file format, verify first line is title, check for invalid JSON
- **Presenter window doesn't show**: May be behind main window, check Mission Control
- **Service hymns out of order**: Call `normalizeOrder()` to fix gaps in order sequence
- **Duplicate hymns after import**: Review duplicate resolution strategy in ImportPreviewView
- **Memory spike on import**: File may be too large for standard import, should use streaming

## Project Branches

- `main` - Production-ready code
- `today_content_feature` - Current working branch (as of this documentation)

Use `gh` CLI for PR operations or GitHub web interface.
