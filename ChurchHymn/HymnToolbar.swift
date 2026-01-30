import SwiftUI
import SwiftData

struct HymnToolbar {
    let hymns: [Hymn]
    let todaysServiceCount: Int
    @Binding var hymnFilter: HymnFilter
    @Binding var selected: Hymn?
    @Binding var isLivePresenting: Bool
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
                // Primary: Present
                Button {
                    if let hymn = selected {
                        onPresent(hymn)
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.green)
                }
                .disabled(selected == nil)
                .help("Present selected hymn")
                .keyboardShortcut(.return, modifiers: [])

                // Primary: Add Hymn
                Button {
                    let hymn = Hymn(title: "")
                    context.insert(hymn)
                    newHymn = hymn
                    selected = hymn
                    showingEdit = true
                } label: {
                    Image(systemName: "plus")
                        .symbolRenderingMode(.hierarchical)
                }
                .help("Add new hymn (⌘N)")

                // Import (icon-only, toolbar convenience)
                Button {
                    importType = .auto
                    currentImportType = .auto
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .symbolRenderingMode(.hierarchical)
                        .font(.body.weight(.semibold))
                }
                .help("Import songs (⌘I)")

                // Edit current (icon-only, toolbar convenience)
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .symbolRenderingMode(.hierarchical)
                        .font(.body.weight(.semibold))
                }
                .disabled(selected == nil)
                .help("Edit selected song (⌘E)")

                // Service menu (with badge)
                Menu {
                    Button(hymnFilter == .todaysService ? "Show Library" : "Show Today's Service") {
                        onToggleTodaysServiceFilter()
                    }

                    Divider()

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
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: hymnFilter == .todaysService ? "music.note.list" : "music.note")
                            .symbolRenderingMode(.hierarchical)

                        if todaysServiceCount > 0 {
                            Text("\(todaysServiceCount)")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                                .offset(x: 9, y: -7)
                        }
                    }
                }
                .help(hymnFilter == .todaysService ? "Service (showing Today's Service)" : "Service")
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Help icon – far right
                Button {
                    openWindow(id: "importHelp")   // must match the WindowGroup id above
                } label: {
                    Image(systemName: "questionmark.circle")
                        .symbolRenderingMode(.hierarchical)
                }
                .help("Show import-file help")
                
                // Export Menu
                Menu {
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
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .symbolRenderingMode(.hierarchical)
                }
                .help("Export")
                
                // Management Menu
                Menu {
                    Toggle("Live presenter updates", isOn: $isLivePresenting)

                    Divider()

                    Button(isMultiSelectMode ? "Exit Multi-Select" : "Multi-Select") {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode {
                            selectedHymnsForDelete.removeAll()
                        }
                    }
                    // Shortcut is defined in the app menu; toolbar is convenience.
                    
                    if isMultiSelectMode {
                        Divider()
                        Button("Select All") {
                            selectedHymnsForDelete = Set(hymns.map { $0.id })
                        }
                        .disabled(hymns.isEmpty)
                        
                        Button("Deselect All") {
                            selectedHymnsForDelete.removeAll()
                        }
                        .disabled(selectedHymnsForDelete.isEmpty)

                        Divider()

                        Button("Add Selected to Today's Service") {
                            onAddSelectedToTodaysService()
                        }
                        .disabled(selectedHymnsForDelete.isEmpty)

                        Divider()

                        Button("Delete Selected Hymns", role: .destructive) {
                            if !selectedHymnsForDelete.isEmpty {
                                showingBatchDeleteConfirmation = true
                            }
                        }
                        .disabled(selectedHymnsForDelete.isEmpty)
                    } else {
                        Divider()

                        Button("Delete Selected Hymn", role: .destructive) {
                            if let hymn = selected {
                                hymnToDelete = hymn
                                showingDeleteConfirmation = true
                            }
                        }
                        .disabled(selected == nil)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .symbolRenderingMode(.hierarchical)
                }
                .help("Manage")
            }
        }
    }
} 
