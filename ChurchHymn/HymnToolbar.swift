import SwiftUI
import SwiftData

struct HymnToolbar {
    let hymns: [Hymn]
    let todaysServiceCount: Int
    @Binding var hymnFilter: HymnFilter
    @Binding var selected: Hymn?
    @Binding var selectedHymnsForDelete: Set<UUID>
    @Binding var isMultiSelectMode: Bool
    @Binding var showingEdit: Bool
    @Binding var newHymn: Hymn?
    @Binding var importType: ImportType?
    @Binding var currentImportType: ImportType?
    @Binding var selectedHymnsForExport: Set<UUID>
    @Binding var showingExportSelection: Bool
    @Binding var hymnToDelete: Hymn?
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingBatchDeleteConfirmation: Bool
    
    let context: ModelContext
    let onToggleTodaysServiceFilter: () -> Void
    let onAddSelectedToTodaysService: () -> Void
    let onRemoveSelectedFromTodaysService: () -> Void
    let onClearTodaysService: () -> Void
    let onPresent: (Hymn) -> Void
    
    func createToolbar(openWindow: OpenWindowAction) -> some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigation) {
                // Play button - prominent placement
                Button(action: {
                    if let hymn = selected {
                        onPresent(hymn)
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Present")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(selected == nil)
                .help("Present selected hymn")
                .keyboardShortcut(.return, modifiers: [])
                
                // Add Hymn button - prominent placement
                Button(action: {
                    let hymn = Hymn(title: "")
                    context.insert(hymn)
                    newHymn = hymn
                    selected = hymn
                    showingEdit = true
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Add")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .help("Add new hymn")
                .keyboardShortcut("n", modifiers: [.command])
                
                // Import button - prominent placement
                Button(action: {
                    importType = .auto
                    currentImportType = .auto
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("Import")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .help("Import hymns from text or JSON files")
                .keyboardShortcut("i", modifiers: [.command])
                
                // Edit button - prominent placement
                Button(action: {
                    showingEdit = true
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(selected == nil)
                .help("Edit selected hymn")
                .keyboardShortcut("e", modifiers: [.command])
                
                // Delete button - prominent placement
                Button(action: {
                    if isMultiSelectMode {
                        if !selectedHymnsForDelete.isEmpty {
                            showingBatchDeleteConfirmation = true
                        }
                    } else if let hymn = selected {
                        hymnToDelete = hymn
                        showingDeleteConfirmation = true
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isMultiSelectMode ? selectedHymnsForDelete.isEmpty : selected == nil)
                .help(isMultiSelectMode ? "Delete selected hymns" : "Delete selected hymn")
                .keyboardShortcut(.delete, modifiers: [.command])

                // Today's Service toggle + count badge
                Button(action: {
                    onToggleTodaysServiceFilter()
                }) {
                    VStack(spacing: 2) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: hymnFilter == .todaysService ? "music.note.list" : "music.note")
                                .font(.title2)
                                .foregroundColor(.accentColor)

                            if todaysServiceCount > 0 {
                                Text("\(todaysServiceCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -8)
                            }
                        }
                        Text("Service")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .help(hymnFilter == .todaysService ? "Showing Today's Service" : "Show Today's Service")
                .keyboardShortcut("t", modifiers: [.command])

                // Today's Service actions (selected hymn / multi-select set)
                Menu("Service") {
                    Button("Add Selected to Today's Service") {
                        onAddSelectedToTodaysService()
                    }
                    .disabled(selected == nil && selectedHymnsForDelete.isEmpty)

                    Button("Remove Selected from Today's Service") {
                        onRemoveSelectedFromTodaysService()
                    }
                    .disabled(selected == nil)

                    Divider()

                    Button("Clear Today's Service", role: .destructive) {
                        onClearTodaysService()
                    }
                    .disabled(todaysServiceCount == 0)
                }
                .help("Today's Service actions")
                
                // Select All button - only visible in multi-select mode
                if isMultiSelectMode {
                    let allHymnIds = Set(hymns.map { $0.id })
                    let isAllSelected = !hymns.isEmpty && selectedHymnsForDelete == allHymnIds
                    
                    Button(action: {
                        if isAllSelected {
                            selectedHymnsForDelete.removeAll()
                        } else {
                            selectedHymnsForDelete = allHymnIds
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: isAllSelected ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(isAllSelected ? "Deselect All" : "Select All")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(hymns.isEmpty)
                    .help(isAllSelected ? "Deselect all hymns" : "Select all hymns")
                    .keyboardShortcut("a", modifiers: [.command])
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Help icon – far right
                Button {
                    openWindow(id: "importHelp")   // must match the WindowGroup id above
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                    Text("Help")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .help("Show import-file help")
                .keyboardShortcut("?", modifiers: [.command])
                
                // Export Menu
                Menu("Export") {
                    Button("Export Selected") { 
                        if let hymn = selected {
                            selectedHymnsForExport = [hymn.id]
                            showingExportSelection = true
                        }
                    }
                    .disabled(selected == nil)
                    
                    Button("Export Multiple") { 
                        showingExportSelection = true
                    }
                    .disabled(hymns.isEmpty)
                    
                    Button("Export All") { 
                        selectedHymnsForExport = Set(hymns.map { $0.id })
                        showingExportSelection = true
                    }
                    .disabled(hymns.isEmpty)
                    
                    Button("Export Large Collection") { 
                        selectedHymnsForExport = Set(hymns.map { $0.id })
                        showingExportSelection = true
                    }
                    .disabled(hymns.isEmpty)
                    .help("Use streaming for large collections (>1000 hymns)")
                }
                
                // Management Menu
                Menu("Manage") {
                    Button(isMultiSelectMode ? "Exit Multi-Select" : "Multi-Select") {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedHymnsForDelete.removeAll()
                        }
                    }
                    .foregroundColor(isMultiSelectMode ? .orange : .blue)
                    .keyboardShortcut("m", modifiers: [.command])
                    
                    if isMultiSelectMode {
                        Divider()
                        Button("Select All") {
                            selectedHymnsForDelete = Set(hymns.map { $0.id })
                        }
                        .disabled(hymns.isEmpty)
                        .keyboardShortcut("a", modifiers: [.command])
                        
                        Button("Deselect All") {
                            selectedHymnsForDelete.removeAll()
                        }
                        .disabled(selectedHymnsForDelete.isEmpty)
                        .keyboardShortcut("d", modifiers: [.command])

                        Divider()

                        Button("Add Selected to Today's Service") {
                            onAddSelectedToTodaysService()
                        }
                        .disabled(selectedHymnsForDelete.isEmpty)
                    }
                }
            }
        }
    }
} 
