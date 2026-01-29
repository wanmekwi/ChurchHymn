# Today's Worship Service Feature - macOS Implementation Plan

## Overview

This document outlines the comprehensive implementation plan for the "Today's Worship Service" feature for the macOS app, which enables church song leaders to create, manage, and organize hymn playlists for worship services. The feature provides intuitive hymn selection, reordering, filtering, and service management capabilities while integrating seamlessly with the existing external display presentation system. This plan adapts the iOS feature set to macOS-specific UI patterns, interaction models, and platform conventions.

## Feature Requirements

### Core Functionality
1. **Service Creation & Management**
   - Create new worship services with date and optional title/notes
   - Add hymns to services from the main hymn library
   - Remove hymns from services
   - Delete entire services when no longer needed
   - Multi-window support for service management

2. **Hymn Selection & Organization**
   - Quick "Add to Today's Service" action from hymn list (context menu, toolbar button, keyboard shortcut)
   - Drag-and-drop reordering within service (macOS native drag support)
   - Visual indication of hymns already in service
   - Batch selection for adding multiple hymns (Command+Click, Shift+Click)
   - Column-based service view with sortable columns

3. **Service Filtering & Navigation**
   - "Today's Service" filter in main hymn list (sidebar filter, menu bar option)
   - Dedicated service view showing only selected hymns
   - Quick toggle between library view and service view (keyboard shortcut, menu bar)
   - Service hymn count and metadata display in status bar
   - Sidebar navigation for service history

4. **Service Workflow Support**
   - Clear visual order indication (numbered rows, sortable order column)
   - Easy service clearing at end of worship (menu bar action, keyboard shortcut)
   - Service archiving for future reference
   - Export service lists for sharing (File menu, drag-and-drop)
   - Print service lists

## Data Architecture

### New Data Models

#### WorshipService Model
```swift
@Model
class WorshipService {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var isActive: Bool // Marks the current/today's service
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var serviceHymns: [ServiceHymn] = []
    
    init(title: String, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.isActive = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### ServiceHymn Model (Junction Table with Ordering)
```swift
@Model
class ServiceHymn {
    @Attribute(.unique) var id: UUID
    var hymnId: UUID // Reference to Hymn
    var serviceId: UUID // Reference to WorshipService
    var order: Int
    var addedAt: Date
    
    // Computed property to get hymn (requires context query)
    // var hymn: Hymn? { /* Query hymn by hymnId */ }
    
    init(hymnId: UUID, serviceId: UUID, order: Int) {
        self.id = UUID()
        self.hymnId = hymnId
        self.serviceId = serviceId
        self.order = order
        self.addedAt = Date()
    }
}
```

### Design Rationale
- **Separate ServiceHymn Entity**: Maintains hymn order without modifying core Hymn model
- **Reference by ID**: Avoids complex SwiftData relationships while maintaining data integrity
- **isActive Flag**: Simple way to mark "today's" service without complex date logic
- **Lightweight Design**: Minimal impact on existing hymn management system
- **Shared Data Models**: Same models as iOS for cross-platform data compatibility

## UI/UX Design

### Main Interface Integration

#### 1. Library View Enhancements
**Location**: `HymnListView.swift` (macOS version)

**New Elements**:
- **"Add to Service" Button**: Toolbar button, context menu (right-click), and menu bar item
- **Service Indicator**: Badge or icon in hymn list row showing hymns already in today's service
- **Service Filter**: Sidebar filter option and menu bar filter toggle
- **Batch Add Mode**: Multi-select (Command+Click, Shift+Click) to add multiple hymns to service
- **Column-based Display**: Optional table view with sortable columns including service status

#### 2. Service Management Interface
**New Component**: `ServiceView.swift` (macOS version)

**Features**:
- **Service Header**: Date, title, hymn count, service notes (toolbar or header area)
- **Reorderable Table**: Drag-and-drop rows for hymn reordering (macOS native table drag)
- **Service Controls**: Menu bar items and toolbar buttons for clear, archive, create new service
- **Quick Actions**: Context menu (right-click) for remove hymns, add more hymns, start presentation
- **Split View Support**: Optional split view showing service alongside hymn library
- **Column Sorting**: Sort by order, title, date added, etc.

#### 3. Menu Bar & Toolbar Integration
**Location**: `AppMenu.swift`, `ContentView.swift`, and `HymnToolbarView.swift`

**New Menu Bar Items**:
- **Service Menu**: Dedicated menu with service actions
  - New Service (⌘N)
  - Today's Service (⌘T)
  - Clear Service (⌘K)
  - Service History...
- **View Menu**: Add service filter toggle
- **File Menu**: Export Service List, Print Service List

**New Toolbar Items**:
- **Service Toggle**: Button to switch between library and service view
- **Service Count Badge**: Shows number of hymns in today's service
- **Service Actions Menu**: Dropdown menu for service operations
- **Add to Service Button**: Quick add button (only visible in library view)

### Navigation Flow

```
Main Library View (macOS Window)
├── Sidebar: Filters
│   ├── All Hymns (default)
│   ├── Today's Service
│   └── Service History
├── Toolbar: Service Actions
│   ├── Add to Service Button
│   ├── Service Toggle
│   └── Service Count Badge
├── Menu Bar: Service Menu
│   ├── New Service (⌘N)
│   ├── Today's Service (⌘T)
│   ├── Clear Service (⌘K)
│   └── Service History...
└── Context Menu (Right-click)
    ├── Add to Service
    └── Remove from Service (if in service)
```

### Visual Design Patterns

#### Service Indicators
- **In Service**: Blue badge or checkmark icon in hymn list row
- **Service Order**: Numbered column or badge in service view table
- **Quick Add**: Plus icon button in toolbar with hover state
- **Drag Handle**: Row drag indicator (macOS native table drag)

#### Color Coding
- **Active Service**: Blue accent color (consistent with macOS app theme)
- **Service Indicator**: Blue badge or checkmark
- **Order Numbers**: Blue text or badge
- **Remove Actions**: Red accent for destructive actions (consistent with macOS)

#### macOS-Specific UI Elements
- **Sidebar**: Filter navigation in sidebar (NSOutlineView or SwiftUI List)
- **Table View**: Optional NSTableView for advanced sorting and column management
- **Menu Bar**: Native macOS menu bar integration
- **Toolbar**: Standard macOS toolbar with flexible item arrangement
- **Context Menus**: Right-click context menus throughout
- **Keyboard Shortcuts**: Standard macOS keyboard shortcuts (⌘N, ⌘T, ⌘K, etc.)

## Implementation Phases

### Phase 1: Data Foundation (Week 1)
**Files to Create/Modify**: 
- `WorshipService.swift` - New data model (shared with iOS if possible)
- `ServiceHymn.swift` - New junction model (shared with iOS if possible)
- `ServiceOperations.swift` - Business logic class (macOS-specific implementation)

**Key Tasks**:
- [ ] Implement SwiftData models with proper relationships
- [ ] Create service operations class following `HymnOperations` pattern
- [ ] Implement CRUD operations for services and service hymns
- [ ] Add data migration support for existing installations
- [ ] Ensure data models are compatible with iOS version for future sync

**Data Operations**:
```swift
class ServiceOperations: ObservableObject {
    @Published var currentService: WorshipService?
    @Published var isLoading = false
    
    func createTodaysService() async
    func addHymnToService(hymn: Hymn, service: WorshipService)
    func removeHymnFromService(hymnId: UUID, service: WorshipService)
    func reorderServiceHymns(service: WorshipService, from: Int, to: Int)
    func clearService(service: WorshipService)
    func setActiveService(service: WorshipService)
    func exportServiceList(service: WorshipService) -> String
    func printServiceList(service: WorshipService)
}
```

**Checkpoint**: Data models created, CRUD operations working, unit tests passing

### Phase 2: Core UI Integration (Week 2)
**Files to Modify**:
- `HymnListView.swift` (macOS) - Add service indicators and actions
- `ContentView.swift` (macOS) - Integrate service state management
- `HymnToolbarView.swift` (macOS) - Add service toolbar items
- `AppMenu.swift` - Add service menu items and keyboard shortcuts

**Key Tasks**:
- [ ] Add service indicators to hymn list items (badge or icon)
- [ ] Implement "Add to Service" actions (toolbar button, context menu, menu bar)
- [ ] Create service filter toggle in sidebar and menu bar
- [ ] Add service count badge to toolbar
- [ ] Implement visual feedback for service membership
- [ ] Add keyboard shortcuts for service actions (⌘N, ⌘T, ⌘K)
- [ ] Support multi-select for batch adding hymns

**UI Enhancements**:
```swift
// HymnListView addition (macOS)
var serviceIndicator: some View {
    if isInTodaysService(hymn) {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.accentColor)
            .font(.caption)
    }
}

// Context menu addition (macOS)
.contextMenu {
    if isInTodaysService(hymn) {
        Button("Remove from Service") { removeFromService(hymn) }
            .keyboardShortcut(.delete, modifiers: [])
    } else {
        Button("Add to Service") { addToService(hymn) }
            .keyboardShortcut("a", modifiers: [.command])
    }
}

// Toolbar addition
ToolbarItem(placement: .primaryAction) {
    Button(action: addSelectedHymnsToService) {
        Label("Add to Service", systemImage: "plus.circle")
    }
    .keyboardShortcut("a", modifiers: [.command])
}
```

**Checkpoint**: Service indicators visible, add/remove actions working, keyboard shortcuts functional

### Phase 3: Service View & Management (Week 3)
**Files to Create**:
- `ServiceView.swift` (macOS) - Dedicated service management interface
- `ServiceCreationView.swift` (macOS) - Sheet/modal for creating new services
- `ServiceHistoryView.swift` (macOS) - View past services (sidebar or separate window)
- `ServiceToolbarView.swift` (macOS) - Service-specific toolbar

**Key Tasks**:
- [ ] Build reorderable service hymn table with macOS native drag-and-drop
- [ ] Implement service header with metadata and controls (toolbar or header area)
- [ ] Create service creation and editing sheets/modals
- [ ] Add service clearing and archiving functionality
- [ ] Implement service history sidebar or separate window
- [ ] Add column sorting and filtering in service view
- [ ] Support split view showing service alongside library
- [ ] Implement print and export functionality

**Service View Features**:
```swift
struct ServiceView: View {
    @StateObject var serviceOperations: ServiceOperations
    @State private var selectedHymns: Set<UUID> = []
    @State private var sortOrder: [KeyPathComparator<ServiceHymn>] = [
        .init(\.order, order: .forward)
    ]
    
    var body: some View {
        NavigationSplitView {
            serviceSidebar
        } detail: {
            serviceTable
                .toolbar {
                    serviceToolbar
                }
        }
    }
    
    var serviceTable: some View {
        Table(serviceHymns, selection: $selectedHymns, sortOrder: $sortOrder) {
            TableColumn("Order", value: \.order)
            TableColumn("Title") { hymn in
                Text(hymn.title)
            }
            TableColumn("Date Added", value: \.addedAt)
        }
        .onMoveCommand { indices, offset in
            reorderHymns(from: indices, to: offset)
        }
    }
}
```

**Checkpoint**: Service view complete, drag-and-drop reordering working, service management functional

### Phase 4: Advanced Features & Integration (Week 4)
**Files to Modify**:
- `ExternalDisplayManager.swift` (macOS) - Integrate service playback
- `ServiceOperations.swift` - Add export and sharing
- `AppMenu.swift` - Add export and print menu items
- Localization files - Add service-related strings

**Key Tasks**:
- [ ] Integrate service hymns with external display presentation
- [ ] Add service export functionality (text, PDF, print)
- [ ] Implement service templates and presets
- [ ] Add advanced service scheduling and reminders
- [ ] Create service analytics and usage tracking
- [ ] Add drag-and-drop export (drag service list to Finder)
- [ ] Implement print preview and formatting

**External Display Integration**:
```swift
extension ExternalDisplayManager {
    func presentServiceHymns(service: WorshipService) {
        // Set up service presentation mode
        // Show service progress indicator
        // Navigate through service hymns in order
        // Support keyboard shortcuts for navigation during presentation
    }
}

// Export functionality
extension ServiceOperations {
    func exportServiceList(service: WorshipService, format: ExportFormat) -> URL? {
        switch format {
        case .text:
            return exportAsText(service)
        case .pdf:
            return exportAsPDF(service)
        case .csv:
            return exportAsCSV(service)
        }
    }
    
    func printServiceList(service: WorshipService) {
        // Use NSPrintOperation for native macOS printing
    }
}
```

**Checkpoint**: External display integration working, export/print functional, all features complete

## Technical Implementation Details

### State Management Strategy

#### Primary State Objects
```swift
// In ContentView (macOS)
@StateObject private var serviceOperations = ServiceOperations()
@Query private var services: [WorshipService]
@Query private var currentServiceHymns: [ServiceHymn]

// Computed Properties
var todaysService: WorshipService? {
    services.first { $0.isActive }
}

var serviceHymns: [Hymn] {
    // Query hymns that match service hymn IDs, ordered by service order
}
```

#### Filter Integration
```swift
// Enhanced filtering in HymnListView (macOS)
enum HymnFilter: CaseIterable {
    case all
    case todaysService
    case recentlyAdded
    case favorites // Future enhancement
}

var filteredHymns: [Hymn] {
    switch selectedFilter {
    case .all: return hymns.filter(searchPredicate)
    case .todaysService: return serviceHymns.filter(searchPredicate)
    // ... other filters
    }
}

// Sidebar filter integration
List(selection: $selectedFilter) {
    ForEach(HymnFilter.allCases, id: \.self) { filter in
        NavigationLink(value: filter) {
            Label(filter.displayName, systemImage: filter.icon)
        }
    }
}
```

### macOS-Specific Considerations

#### Window Management
- **Single Window**: Main window with sidebar navigation (preferred)
- **Multi-Window**: Optional separate windows for service management
- **Window Restoration**: Remember window state and service view preferences
- **Full Screen Support**: Service view works in full screen mode

#### Keyboard Shortcuts
```swift
// Standard macOS keyboard shortcuts
.keyboardShortcut("n", modifiers: [.command]) // New Service
.keyboardShortcut("t", modifiers: [.command]) // Today's Service
.keyboardShortcut("k", modifiers: [.command]) // Clear Service
.keyboardShortcut("a", modifiers: [.command]) // Add to Service
.keyboardShortcut(.delete, modifiers: []) // Remove from Service
```

#### Drag and Drop
- **Native Table Drag**: Use SwiftUI Table's built-in drag support
- **Finder Integration**: Drag service list to Finder to export
- **Cross-App Drag**: Support dragging hymns between windows/apps (future)

#### Menu Bar Integration
- **App Menu**: Standard macOS app menu structure
- **Service Menu**: Dedicated menu for service actions
- **Context Menus**: Right-click context menus throughout
- **Menu Validation**: Enable/disable menu items based on state

### Performance Considerations

#### Data Optimization
- **Lazy Loading**: Load service hymns only when needed
- **Efficient Queries**: Use SwiftData predicates for filtering
- **Memory Management**: Proper cleanup of service state
- **Background Updates**: Async operations for service modifications
- **Table Virtualization**: Efficient rendering of large hymn lists in table view

#### UI Performance
- **Smooth Animations**: Optimized drag-and-drop with native macOS animations
- **State Synchronization**: Minimal re-renders on service changes
- **Image Caching**: Efficient icon and indicator rendering
- **Large Lists**: Support services with 100+ hymns without performance degradation

### Error Handling & Edge Cases

#### Data Integrity
- **Orphaned Service Hymns**: Cleanup when hymns are deleted
- **Service Consistency**: Ensure proper order numbering
- **Concurrent Modifications**: Handle simultaneous service edits
- **Data Migration**: Graceful upgrades from non-service versions

#### User Experience
- **Large Services**: Performance with 100+ hymns
- **Interrupted Operations**: Recovery from incomplete actions
- **Accessibility**: Full VoiceOver and keyboard navigation support
- **Window State**: Proper restoration of service view state

### Accessibility Implementation

#### VoiceOver Support
```swift
.accessibilityLabel("Hymn \(hymn.title)")
.accessibilityHint(isInService ? "In today's service at position \(servicePosition). Press Delete to remove." : "Press Command-A to add to service")
.accessibilityAddTraits(isInService ? .isSelected : [])
```

#### Keyboard Navigation
- **Tab Order**: Logical navigation through service interface
- **Shortcuts**: Quick keys for common service actions (⌘N, ⌘T, ⌘K, ⌘A)
- **Focus Management**: Proper focus handling in sheets and tables
- **Screen Reader**: Clear announcements for service changes
- **Full Keyboard Access**: All functionality accessible via keyboard

### Localization Strategy

#### New Localization Keys
```swift
// Service Management
"service.todays_service" = "Today's Service"
"service.create_new" = "New Service"
"service.add_hymn" = "Add to Service"
"service.remove_hymn" = "Remove from Service"
"service.clear_service" = "Clear Service"
"service.hymn_count" = "%d hymns in service"

// Service Actions
"service.reorder_hymn" = "Reorder hymn"
"service.position_number" = "Position %d"
"service.start_presentation" = "Start Service Presentation"
"service.export_list" = "Export Service List..."
"service.print_list" = "Print Service List..."

// Keyboard Shortcuts
"service.shortcut.new" = "New Service"
"service.shortcut.todays" = "Today's Service"
"service.shortcut.clear" = "Clear Service"
"service.shortcut.add" = "Add to Service"

// Accessibility
"service.accessibility.add_to_service" = "Add hymn to today's service"
"service.accessibility.remove_from_service" = "Remove hymn from service"
"service.accessibility.reorder_handle" = "Drag to reorder hymn position"
```

## Testing Strategy

### Unit Tests
- [ ] Service data model CRUD operations
- [ ] Service hymn ordering logic
- [ ] Filter and search functionality with services
- [ ] Service operations error handling
- [ ] Export and print functionality

### Integration Tests
- [ ] Service creation and management workflows
- [ ] Hymn addition and removal from services
- [ ] External display integration with services
- [ ] Data persistence across app launches
- [ ] Keyboard shortcut functionality
- [ ] Drag-and-drop reordering

### User Testing Scenarios
1. **Service Creation**: Create service, add hymns, reorder, present
2. **Worship Flow**: Use service during actual worship service
3. **Multiple Services**: Manage multiple services (past, future, archive)
4. **External Display**: Present service hymns on external display
5. **Keyboard Navigation**: Complete workflow using only keyboard
6. **Export/Print**: Export and print service lists
7. **Multi-Select**: Batch add multiple hymns to service

## Future Enhancement Opportunities

### Advanced Service Features
- **Service Templates**: Reusable service patterns
- **Recurring Services**: Weekly/monthly service automation
- **Service Sharing**: Share services between devices/users (iCloud sync)
- **Service Analytics**: Track hymn usage and preferences
- **Service Scheduling**: Calendar integration for future services

### Integration Possibilities
- **Calendar Integration**: Schedule services in macOS Calendar app
- **Church Management Systems**: Export to popular church software
- **Music Theory**: Suggest hymn keys and transitions
- **Lyrics Display**: Enhanced external display with service context
- **iCloud Sync**: Sync services between macOS and iOS versions

### Collaboration Features
- **Team Services**: Multi-user service planning
- **Service Comments**: Notes and feedback on hymn choices
- **Version Control**: Track service changes over time
- **Remote Control**: Control presentation from any device

### macOS-Specific Enhancements
- **Spotlight Integration**: Search services from Spotlight
- **Quick Look**: Preview service lists in Finder
- **Services Menu**: macOS Services menu integration
- **Automator Support**: Create Automator workflows for service management
- **Scripting Support**: AppleScript/JavaScript automation

## Implementation Timeline

### Sprint 1 (Week 1): Data Foundation
- **Day 1-2**: Create data models and database schema
- **Day 3-4**: Implement service operations and business logic
- **Day 5-7**: Unit tests and data validation

**Checkpoint**: Data models working, CRUD operations functional, tests passing

### Sprint 2 (Week 2): Basic UI Integration
- **Day 1-2**: Modify hymn list with service indicators
- **Day 3-4**: Add menu bar and toolbar service controls
- **Day 5-6**: Implement keyboard shortcuts
- **Day 7**: Add context menus and multi-select support

**Checkpoint**: Service indicators visible, add/remove actions working, shortcuts functional

### Sprint 3 (Week 3): Service Management Interface
- **Day 1-2**: Build dedicated service view with table
- **Day 3-4**: Implement drag-and-drop reordering
- **Day 5-6**: Add service creation and management sheets
- **Day 7**: Implement service history sidebar

**Checkpoint**: Service view complete, drag-and-drop working, management functional

### Sprint 4 (Week 4): Polish & Advanced Features
- **Day 1-2**: External display integration
- **Day 3-4**: Export and print capabilities
- **Day 5-6**: Testing and bug fixes
- **Day 7**: Documentation and final polish

**Checkpoint**: All features complete, tested, and documented

## Success Metrics

### Functional Requirements
- ✅ Create and manage worship services
- ✅ Add/remove hymns from services with visual feedback
- ✅ Reorder service hymns via drag-and-drop
- ✅ Filter hymn list to show only service hymns
- ✅ Clear service at end of worship
- ✅ External display integration for service presentation
- ✅ Export and print service lists
- ✅ Full keyboard navigation support

### Performance Requirements
- 📊 Service creation in < 2 seconds
- 📊 Hymn addition/removal with < 500ms feedback
- 📊 Smooth drag-and-drop with native macOS animations
- 📊 Filter switching in < 1 second
- 📊 Support services with 100+ hymns without performance degradation
- 📊 Export/print operations complete in < 3 seconds

### User Experience Requirements
- 🎯 Intuitive service creation workflow
- 🎯 Clear visual indication of service membership
- 🎯 Seamless integration with existing hymn management
- 🎯 Accessible interface with full VoiceOver and keyboard support
- 🎯 Consistent with macOS design patterns and conventions
- 🎯 Native macOS feel (menus, toolbars, drag-and-drop)

### macOS-Specific Requirements
- 🎯 Native menu bar integration
- 🎯 Standard keyboard shortcuts (⌘N, ⌘T, ⌘K, ⌘A)
- 🎯 Context menu support throughout
- 🎯 Native table drag-and-drop
- 🎯 Export to Finder via drag-and-drop
- 🎯 Print functionality with preview

This comprehensive implementation plan provides a solid foundation for building the "Today's Worship Service" feature for macOS while maintaining the high quality and user experience standards of the existing application, adapted for macOS-specific UI patterns and interaction models.
