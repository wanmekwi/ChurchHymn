import SwiftUI
import UniformTypeIdentifiers
import AppKit
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Hymn.title, order: .forward) private var hymns: [Hymn]
    @Query(sort: \WorshipService.date, order: .reverse) private var services: [WorshipService]
    @Query(sort: \ServiceHymn.order, order: .forward) private var serviceHymns: [ServiceHymn]
    
    // Core state
    @State private var selected: Hymn? = nil
    @State private var newHymn: Hymn? = nil
    @State private var showingEdit = false
    @State private var editHymn: Hymn? = nil
    @State private var presentedHymnIndex: Int? = nil
    @State private var isPresenting = false
    @State private var isLivePresenting = true
    @State private var presentedHymnId: UUID? = nil
    @State private var presenterWindow: NSWindow? = nil
    @State private var presenterWindowDelegate: PresenterWindowDelegate? = nil
    
    // Import/Export state
    @State private var exportType: ExportType?
    @State private var importType: ImportType?
    @State private var currentImportType: ImportType?
    
    // Error handling states
    @State private var importError: ImportError?
    @State private var showingErrorAlert = false
    @State private var importSuccessMessage: String?
    @State private var showingSuccessAlert = false
    
    // Import preview states
    @State private var importPreview: ImportPreview?
    @State private var showingImportPreview = false
    @State private var selectedHymnsForImport: Set<UUID> = []
    @State private var duplicateResolution: DuplicateResolution = .skip
    
    // Export selection states
    @State private var showingExportSelection = false
    @State private var selectedHymnsForExport: Set<UUID> = []
    @State private var exportFormat: ExportFormat = .json
    
    // Delete confirmation states
    @State private var showingDeleteConfirmation = false
    @State private var hymnToDelete: Hymn?
    
    // Multi-select states for batch delete
    @State private var selectedHymnsForDelete: Set<UUID> = []
    @State private var isMultiSelectMode = false
    @State private var showingBatchDeleteConfirmation = false

    // Today's Service state
    @State private var hymnFilter: HymnFilter = .all
    
    // Operations
    @StateObject private var operations: HymnOperations
    @StateObject private var serviceOperations: ServiceOperations
    @StateObject private var presenterSession: PresenterSession
    
    init() {
        // Initialize operations with a temporary context - will be updated in onAppear
        let tempConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        let tempContainer = try? ModelContainer(
            for: Hymn.self,
            WorshipService.self,
            ServiceHymn.self,
            configurations: tempConfig
        )
        let tempContext = tempContainer.map(ModelContext.init)
            ?? ModelContext(try! ModelContainer(for: Hymn.self, configurations: tempConfig))
        self._operations = StateObject(wrappedValue: HymnOperations(context: tempContext))
        self._serviceOperations = StateObject(wrappedValue: ServiceOperations(context: tempContext))
        self._presenterSession = StateObject(wrappedValue: PresenterSession())
    }

    private var todaysService: WorshipService? {
        services.first(where: { $0.isActive })
    }

    private var todaysServiceHymns: [ServiceHymn] {
        guard let service = todaysService else { return [] }
        return serviceHymns
            .filter { $0.serviceId == service.id }
            .sorted { $0.order < $1.order }
    }

    private var todaysServiceHymnIds: Set<UUID> {
        Set(todaysServiceHymns.map { $0.hymnId })
    }

    private var todaysServiceCount: Int {
        todaysServiceHymns.count
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("Filter", selection: $hymnFilter) {
                    ForEach(HymnFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                if hymnFilter == .todaysService {
                    ServiceView(
                        hymns: hymns,
                        todaysService: todaysService,
                        todaysServiceHymns: todaysServiceHymns,
                        selected: $selected,
                        onSwitchToLibrary: { hymnFilter = .all },
                        serviceOperations: serviceOperations
                    )
                } else {
                    HymnListView(
                        hymns: hymns,
                        todaysServiceHymnIds: todaysServiceHymnIds,
                        selected: $selected,
                        selectedHymnsForDelete: $selectedHymnsForDelete,
                        isMultiSelectMode: $isMultiSelectMode,
                        editHymn: $editHymn,
                        showingEdit: $showingEdit,
                        hymnToDelete: $hymnToDelete,
                        showingDeleteConfirmation: $showingDeleteConfirmation,
                        showingBatchDeleteConfirmation: $showingBatchDeleteConfirmation,
                        onAddToTodaysService: addHymnsToTodaysService,
                        onRemoveFromTodaysService: removeHymnFromTodaysService,
                        onPresent: present
                    )
                }
            }
            .toolbar {
                HymnToolbar(
                    hymns: hymns,
                    todaysServiceCount: todaysServiceCount,
                    hymnFilter: $hymnFilter,
                    selected: $selected,
                    isLivePresenting: $isLivePresenting,
                    selectedHymnsForDelete: $selectedHymnsForDelete,
                    isMultiSelectMode: $isMultiSelectMode,
                    showingEdit: $showingEdit,
                    newHymn: $newHymn,
                    importType: $importType,
                    currentImportType: $currentImportType,
                    selectedHymnsForExport: $selectedHymnsForExport,
                    showingExportSelection: $showingExportSelection,
                    hymnToDelete: $hymnToDelete,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    showingBatchDeleteConfirmation: $showingBatchDeleteConfirmation,
                    context: context,
                    onToggleTodaysServiceFilter: toggleTodaysServiceFilter,
                    onAddSelectedToTodaysService: addSelectedToTodaysService,
                    onRemoveSelectedFromTodaysService: removeSelectedFromTodaysService,
                    onClearTodaysService: clearTodaysService,
                    onPresent: present
                ).createToolbar(
                    openWindow: openWindow
                )
            }
            .fileImporter(
                isPresented: Binding(get: { importType != nil }, set: { if !$0 {
                    importType = nil
                } }),
                allowedContentTypes: importType == .auto ? [UTType.json, UTType.plainText] : (importType == .json ? [UTType.json] : [UTType.plainText]),
                allowsMultipleSelection: true
            ) { result in
                let importTypeToUse = importType ?? currentImportType
                handleImportResult(result, importType: importTypeToUse)
            }
            .fileExporter(
                isPresented: Binding(get: { exportType != nil }, set: { if !$0 {
                    exportType = nil
                    cleanupAfterExport()
                } }),
                document: exportDocument,
                contentType: exportContentType,
                defaultFilename: exportDefaultFilename
            ) { result in
                if case let .success(url) = result, let type = exportType {
                    handleExportResult(type, url: url)
                }
            }
            .alert("Import Error", isPresented: $showingErrorAlert, presenting: importError) { error in
                Button("OK") { }
            } message: { error in
                Text(error.detailedErrorDescription)
            }
            .alert("Import Successful", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(importSuccessMessage ?? "Hymn imported successfully.")
            }
            .deleteConfirmationAlerts(
                hymns: hymns,
                showingDeleteConfirmation: $showingDeleteConfirmation,
                showingBatchDeleteConfirmation: $showingBatchDeleteConfirmation,
                hymnToDelete: $hymnToDelete,
                selectedHymnsForDelete: $selectedHymnsForDelete,
                onDeleteHymn: deleteHymn,
                onDeleteSelectedHymns: deleteSelectedHymns
            )

        } detail: {
            if isMultiSelectMode {
                MultiSelectDetailView(selectedHymnsForDelete: selectedHymnsForDelete)
            } else if let hymn = selected {
                DetailView(
                    hymn: hymn,
                    currentPresentationIndex: presentedHymnIndex,
                    isPresenting: isPresenting,
                    isInTodaysService: todaysServiceHymnIds.contains(hymn.id),
                    onAddToTodaysService: { addHymnsToTodaysService([hymn]) },
                    onRemoveFromTodaysService: { removeHymnFromTodaysService(hymn) },
                    onPresentPart: { partIndex in
                        presentFromDetail(hymn, partIndex: partIndex)
                    }
                )
            } else {
                EmptyDetailView()
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDragAndDrop(providers: providers)
        }
        .contentViewModifiers(
            hymns: hymns,
            selected: selected,
            newHymn: newHymn,
            context: context,
            operations: operations,
            showingEdit: $showingEdit,
            showingImportPreview: $showingImportPreview,
            showingExportSelection: $showingExportSelection,
            importPreview: $importPreview,
            selectedHymnsForImport: $selectedHymnsForImport,
            duplicateResolution: $duplicateResolution,
            selectedHymnsForExport: $selectedHymnsForExport,
            exportFormat: $exportFormat,
            onSave: { savedHymn in
                try? context.save()
                if newHymn == savedHymn {
                    newHymn = nil
                }
            },
            onCleanupEmptyHymn: cleanupEmptyHymn,
            onConfirmImport: confirmImport,
            onCancelImport: cancelImport,
            onConfirmExport: confirmExport,
            onCancelExport: cancelExport
        )
        .onAppear {
            // Update operations context with the actual context
            operations.updateContext(context)
            serviceOperations.updateContext(context)
            setupMenuActionHandling()
            syncPresenterSessionFromPresentedId()
        }
        .onChange(of: presentedHymnId) { _, _ in
            syncPresenterSessionFromPresentedId()
        }
        .onChange(of: hymns.map(\.id)) { _, _ in
            // If the currently presented hymn was deleted, fall back to a safe empty state.
            syncPresenterSessionFromPresentedId()
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuAction)) { notification in
            if let action = notification.object as? MenuAction {
                handleMenuAction(action)
            }
        }
    }

    // MARK: - Actions
    
    private func setupMenuActionHandling() {
        // Menu actions are handled via NotificationCenter
    }
    
    private func handleMenuAction(_ action: MenuAction) {
        switch action {
        case .addNewHymn:
            addNewHymn()
        case .importHymns:
            importHymns()
        case .editCurrentHymn:
            editCurrentHymn()
        case .exportSelected:
            exportSelectedHymn()
        case .exportMultiple:
            exportMultipleHymns()
        case .exportAll:
            exportAllHymns()
        case .toggleTodaysServiceFilter:
            toggleTodaysServiceFilter()
        case .addSelectedToTodaysService:
            addSelectedToTodaysService()
        case .removeSelectedFromTodaysService:
            removeSelectedFromTodaysService()
        case .clearTodaysService:
            clearTodaysService()
        }
    }

    // MARK: - Today's Service Actions

    private func toggleTodaysServiceFilter() {
        hymnFilter = (hymnFilter == .all) ? .todaysService : .all
    }

    private func addHymnsToTodaysService(_ hymnsToAdd: [Hymn]) {
        do {
            try serviceOperations.addHymnsToTodaysService(hymnsToAdd)
        } catch {
            showError(.unknown("Failed to add hymns to today's service: \(error.localizedDescription)"))
        }
    }

    private func removeHymnFromTodaysService(_ hymn: Hymn) {
        do {
            try serviceOperations.removeHymnFromTodaysService(hymnId: hymn.id)
        } catch {
            showError(.unknown("Failed to remove hymn from today's service: \(error.localizedDescription)"))
        }
    }

    private func addSelectedToTodaysService() {
        if isMultiSelectMode, !selectedHymnsForDelete.isEmpty {
            let hymnsToAdd = hymns.filter { selectedHymnsForDelete.contains($0.id) }
            addHymnsToTodaysService(hymnsToAdd)
            return
        }

        if let hymn = selected {
            addHymnsToTodaysService([hymn])
        }
    }

    private func removeSelectedFromTodaysService() {
        guard let hymn = selected else { return }
        removeHymnFromTodaysService(hymn)
    }

    private func clearTodaysService() {
        do {
            try serviceOperations.clearTodaysService()
        } catch {
            showError(.unknown("Failed to clear today's service: \(error.localizedDescription)"))
        }
    }
    
    private func addNewHymn() {
        let hymn = Hymn(title: "")
        context.insert(hymn)
        newHymn = hymn
        selected = hymn
        showingEdit = true
    }
    
    private func importHymns() {
        importType = .auto
        currentImportType = .auto
    }
    
    private func editCurrentHymn() {
        if selected != nil {
            showingEdit = true
        }
    }
    
    private func exportSelectedHymn() {
        if let hymn = selected {
            selectedHymnsForExport = [hymn.id]
            showingExportSelection = true
        }
    }
    
    private func exportMultipleHymns() {
        showingExportSelection = true
    }
    
    private func exportAllHymns() {
        selectedHymnsForExport = Set(hymns.map { $0.id })
        showingExportSelection = true
    }
    
    private func present(_ hymn: Hymn) {
        // Keep manual present behavior when Live Mode is OFF.
        if !isLivePresenting {
            presentedHymnId = hymn.id
        } else if presentedHymnId == nil {
            // Live Mode ON: don't change content on selection/search; ensure the window isn't empty.
            presentedHymnId = hymn.id
        }

        syncPresenterSessionFromPresentedId()
        showPresenterWindow()
    }

    private func syncPresenterSessionFromPresentedId() {
        guard let id = presentedHymnId else { return }
        presenterSession.hymn = hymns.first(where: { $0.id == id })
        if presenterSession.hymn == nil {
            // Hymn no longer exists (e.g. deleted) → safe empty state.
            presentedHymnId = nil
        }
    }

    private func showPresenterWindow() {
        isPresenting = true
        ensurePresenterWindow()
        presenterWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Enter full screen on the target display (only if needed).
        if let window = presenterWindow, !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    private func closePresenterWindow() {
        presentedHymnIndex = nil
        isPresenting = false

        guard let window = presenterWindow else { return }

        // Clear references first to prevent recursion from windowWillClose delegate
        presenterWindow = nil
        presenterWindowDelegate = nil

        // For full screen windows, we need to exit full screen before closing
        if window.styleMask.contains(.fullScreen) {
            // Exit full screen
            window.toggleFullScreen(nil)
            
            // Use notification to close after full screen exit completes
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: window,
                queue: .main
            ) { _ in
                window.close()
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
            }
        } else {
            window.close()
        }
    }

    private func ensurePresenterWindow() {
        guard presenterWindow == nil else { return }

        let rootView = PresenterRootView(
            session: presenterSession,
            onIndexChange: { index in
                presentedHymnIndex = index
            },
            onRequestClose: {
                closePresenterWindow()
            }
        )

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Presenter"
        window.identifier = NSUserInterfaceItemIdentifier("PresenterWindow")

        // Get available screens
        let screens = NSScreen.screens
        let targetScreen = screens.count > 1 ? screens[1] : screens[0]

        // Configure window
        window.styleMask.remove(.titled)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.collectionBehavior = [.fullScreenPrimary]

        // Position on target screen
        let screenFrame = targetScreen.frame
        window.setFrame(screenFrame, display: true)

        let delegate = PresenterWindowDelegate(onClose: {
            closePresenterWindow()
        })
        window.delegate = delegate
        presenterWindowDelegate = delegate

        presenterWindow = window
    }

    private func presentFromDetail(_ hymn: Hymn, partIndex: Int) {
        // This is the only path that changes the presented hymn while Live Mode is ON.
        presentedHymnId = hymn.id
        presenterSession.hymn = hymn
        presenterSession.requestedIndex = partIndex
        showPresenterWindow()
    }
    
    private func deleteHymn() {
        guard let hymn = hymnToDelete else { return }
        
        context.delete(hymn)
        
        if selected == hymn {
            selected = nil
        }
        if editHymn == hymn {
            editHymn = nil
        }
        if newHymn == hymn {
            newHymn = nil
        }
        
        do {
            try context.save()
        } catch {
            // Save failed - context will retain previous state
        }
        
        hymnToDelete = nil
        showingDeleteConfirmation = false
    }
    
    private func deleteSelectedHymns() {
        let hymnsToDelete = hymns.filter { selectedHymnsForDelete.contains($0.id) }
        
        for hymn in hymnsToDelete {
            context.delete(hymn)
            
            if selected == hymn {
                selected = nil
            }
            if editHymn == hymn {
                editHymn = nil
            }
            if newHymn == hymn {
                newHymn = nil
            }
        }
        
        do {
            try context.save()
        } catch {
            // Save failed - context will retain previous state
        }
        
        selectedHymnsForDelete.removeAll()
        isMultiSelectMode = false
        showingBatchDeleteConfirmation = false
    }
    
    private func cleanupEmptyHymn() {
        if let hymn = newHymn, hymn.title.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(hymn)
            
            if selected == hymn {
                selected = nil
            }
            if editHymn == hymn {
                editHymn = nil
            }
            newHymn = nil
            
            do {
                try context.save()
            } catch {
                // Save failed - context will retain previous state
            }
        }
    }
    
    private func cleanupAfterExport() {
        selectedHymnsForExport.removeAll()
    }
    
    // MARK: - Import/Export Handlers
    
    private func handleDragAndDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var fileURLs: [URL] = []
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    defer { group.leave() }
                    
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        
                        let fileExtension = url.pathExtension.lowercased()
                        if fileExtension == "txt" || fileExtension == "json" {
                            fileURLs.append(url)
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !fileURLs.isEmpty {
                // For drag-and-drop, we need to ensure URLs have proper access
                for url in fileURLs {
                    _ = url.startAccessingSecurityScopedResource()
                }
                self.handleImportResult(.success(fileURLs), importType: .auto)
            }
        }
        
        return !fileURLs.isEmpty
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>, importType: ImportType?) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else {
                showError(.unknown("No files selected"))
                return
            }
            
            guard let importType = importType else {
                showError(.unknown("Unknown import type"))
                return
            }
            
            // Process each file
            Task {
                var allHymns: [ImportPreviewHymn] = []
                var allDuplicates: [ImportPreviewHymn] = []
                var allErrors: [String] = []
                
                for (_, url) in urls.enumerated() {
                    // Start accessing security scoped resource for sandboxed app
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Auto-detect file type and size for intelligent import
                    let actualImportType = detectImportType(for: url, requestedType: importType)
                    
                    do {
                        let preview: ImportPreview = try await withCheckedThrowingContinuation { continuation in
                            switch actualImportType {
                            case .plainText:
                                operations.importPlainTextHymn(
                                    from: url,
                                    hymns: hymns,
                                    onComplete: { preview in
                                        continuation.resume(returning: preview)
                                    },
                                    onError: { error in
                                        continuation.resume(throwing: error)
                                    }
                                )
                            case .json:
                                // Check file size to determine if streaming is needed
                                let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                                let largeFileThreshold = 10 * 1024 * 1024 // 10MB
                                
                                if fileSize > largeFileThreshold {
                                    operations.importLargeJSONStreaming(
                                        from: url,
                                        hymns: hymns,
                                        onComplete: { preview in
                                            continuation.resume(returning: preview)
                                        },
                                        onError: { error in
                                            continuation.resume(throwing: error)
                                        }
                                    )
                                } else {
                                    operations.importBatchJSON(
                                        from: url,
                                        hymns: hymns,
                                        onComplete: { preview in
                                            continuation.resume(returning: preview)
                                        },
                                        onError: { error in
                                            continuation.resume(throwing: error)
                                        }
                                    )
                                }
                            case .auto:
                                continuation.resume(throwing: ImportError.unknown("Auto detection failed"))
                            }
                        }
                        
                        // Collect results from this file
                        allHymns.append(contentsOf: preview.hymns)
                        allDuplicates.append(contentsOf: preview.duplicates)
                        allErrors.append(contentsOf: preview.errors)
                        
                    } catch let error as ImportError {
                        allErrors.append("Error importing \(url.lastPathComponent): \(error.localizedDescription)")
                    } catch {
                        allErrors.append("Unexpected error importing \(url.lastPathComponent): \(error.localizedDescription)")
                    }
                }
                
                // Show combined preview for all files
                let combinedPreview = ImportPreview(
                    hymns: allHymns,
                    duplicates: allDuplicates,
                    errors: allErrors,
                    fileName: urls.count == 1 ? urls[0].lastPathComponent : "\(urls.count) files"
                )
                
                await MainActor.run {
                    operations.isImporting = false  // Reset the importing state
                    operations.importProgress = 0.0 // Reset progress
                    operations.progressMessage = "" // Clear message
                    importPreview = combinedPreview
                    showingImportPreview = true
                }
            }
            
        case .failure(let error):
            let nsError = error as NSError
            let specificError = getSpecificFileError(nsError)
            showError(specificError)
            operations.isImporting = false  // Reset the importing state on error
            operations.importProgress = 0.0 // Reset progress
            operations.progressMessage = "" // Clear message
        }
        
        currentImportType = nil
    }
    
    private func handleExportResult(_ type: ExportType, url: URL) {
        switch type {
        case .singlePlainText:
            if let hymn = selected {
                operations.exportPlainTextHymn(
                    hymn,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        case .singleJSON:
            if let hymn = selected {
                operations.exportSingleJSONHymn(
                    hymn,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        case .multipleJSON:
            let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
            let largeCollectionThreshold = 1000 // Use streaming for collections > 1000 hymns
            
            if hymnsToExport.count > largeCollectionThreshold {
                operations.exportLargeJSONStreaming(
                    hymns: hymnsToExport,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            } else {
                operations.exportBatchJSON(
                    hymnsToExport,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        case .batchJSON:
            let largeCollectionThreshold = 1000 // Use streaming for collections > 1000 hymns
            
            if hymns.count > largeCollectionThreshold {
                operations.exportLargeJSONStreaming(
                    hymns: hymns,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            } else {
                operations.exportBatchJSON(
                    hymns,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        }
    }
    
    // MARK: - Import Preview Functions
    
    private func confirmImport() {
        guard let preview = importPreview else { return }
        
        let selectedValidHymns = preview.hymns.filter { selectedHymnsForImport.contains($0.id) }
        let selectedDuplicateHymns = preview.duplicates.filter { selectedHymnsForImport.contains($0.id) }
        
        var hymnsToImport: [Hymn] = []
        var duplicatesToProcess: [DuplicateHymn] = []
        
        for previewHymn in selectedValidHymns {
            let hymn = Hymn(
                title: previewHymn.title,
                lyrics: previewHymn.lyrics,
                musicalKey: previewHymn.musicalKey,
                copyright: previewHymn.copyright,
                author: previewHymn.author,
                tags: previewHymn.tags,
                notes: previewHymn.notes,
                songNumber: previewHymn.songNumber
            )
            hymnsToImport.append(hymn)
        }
        
        for previewHymn in selectedDuplicateHymns {
            if let existingHymnID = previewHymn.existingHymnID {
                let newHymn = Hymn(
                    title: previewHymn.title,
                    lyrics: previewHymn.lyrics,
                    musicalKey: previewHymn.musicalKey,
                    copyright: previewHymn.copyright,
                    author: previewHymn.author,
                    tags: previewHymn.tags,
                    notes: previewHymn.notes,
                    songNumber: previewHymn.songNumber
                )
                duplicatesToProcess.append(DuplicateHymn(existingID: existingHymnID, new: newHymn, title: previewHymn.title))
            }
        }
        
        processFinalImport(validHymns: hymnsToImport, duplicates: duplicatesToProcess, errors: preview.errors)
    }
    
    private func cancelImport() {
        showingImportPreview = false
        importPreview = nil
        selectedHymnsForImport.removeAll()
        operations.isImporting = false  // Reset the importing state
        operations.importProgress = 0.0 // Reset progress
        operations.progressMessage = "" // Clear message
    }
    
    private func processFinalImport(validHymns: [Hymn], duplicates: [DuplicateHymn], errors: [String]) {
        Task {
            await MainActor.run {
                operations.isImporting = true
                operations.importProgress = 0.0
                operations.progressMessage = "Processing import..."
            }
            
            do {
                let totalItems = validHymns.count + duplicates.count
                var processedItems = 0
                
                switch duplicateResolution {
                case .skip:
                    break
                case .merge:
                    for duplicate in duplicates {
                        await MainActor.run {
                            operations.importProgress = Double(processedItems) / Double(totalItems)
                            operations.progressMessage = "Merging duplicate: \(duplicate.newHymn.title)..."
                        }
                        if let existingHymn = context.model(for: duplicate.existingHymnID) as? Hymn {
                            mergeHymnData(existing: existingHymn, new: duplicate.newHymn)
                        }
                        processedItems += 1
                    }
                case .replace:
                    for duplicate in duplicates {
                        await MainActor.run {
                            operations.importProgress = Double(processedItems) / Double(totalItems)
                            operations.progressMessage = "Replacing duplicate: \(duplicate.newHymn.title)..."
                        }
                        if let existingHymn = context.model(for: duplicate.existingHymnID) as? Hymn {
                            replaceHymnData(existing: existingHymn, new: duplicate.newHymn)
                        }
                        processedItems += 1
                    }
                }
                
                for hymn in validHymns {
                    await MainActor.run {
                        operations.importProgress = Double(processedItems) / Double(totalItems)
                        operations.progressMessage = "Importing hymn: \(hymn.title)..."
                    }
                    context.insert(hymn)
                    processedItems += 1
                }
                
                await MainActor.run {
                    operations.importProgress = 0.9
                    operations.progressMessage = "Saving to database..."
                }
                
                try context.save()
                
                await MainActor.run {
                    operations.importProgress = 1.0
                    operations.progressMessage = "Import complete!"
                }
                
                var message = "Successfully imported \(validHymns.count) hymn\(validHymns.count == 1 ? "" : "s")"
                
                if !duplicates.isEmpty {
                    let duplicateCount = duplicates.count
                    switch duplicateResolution {
                    case .skip:
                        message += ". Skipped \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    case .merge:
                        message += ". Merged \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    case .replace:
                        message += ". Replaced \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    }
                }
                
                if !errors.isEmpty {
                    message += ". \(errors.count) error\(errors.count == 1 ? "" : "s") encountered"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    operations.isImporting = false
                    showSuccess(message)
                }
                
            } catch {
                await MainActor.run {
                    operations.isImporting = false
                }
                showError(.unknown("Failed to save imported hymns: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func confirmExport() {
        let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
        
        if hymnsToExport.isEmpty {
            showError(.unknown("No hymns selected for export"))
            return
        }
        
        if hymnsToExport.count == 1 {
            exportType = exportFormat == .json ? .singleJSON : .singlePlainText
        } else {
            exportType = exportFormat == .json ? .multipleJSON : .batchJSON
        }
        
        showingExportSelection = false
    }
    
    private func cancelExport() {
        showingExportSelection = false
        selectedHymnsForExport.removeAll()
    }
    
    // MARK: - Helper Functions
    
    private func showError(_ error: ImportError) {
        importError = error
        showingErrorAlert = true
    }
    
    private func showSuccess(_ message: String) {
        importSuccessMessage = message
        showingSuccessAlert = true
    }
    
    private func mergeHymnData(existing: Hymn, new: Hymn) {
        if (existing.lyrics?.isEmpty ?? true) && !(new.lyrics?.isEmpty ?? true) {
            existing.lyrics = new.lyrics
        }
        if (existing.musicalKey?.isEmpty ?? true) && !(new.musicalKey?.isEmpty ?? true) {
            existing.musicalKey = new.musicalKey
        }
        if (existing.author?.isEmpty ?? true) && !(new.author?.isEmpty ?? true) {
            existing.author = new.author
        }
        if (existing.copyright?.isEmpty ?? true) && !(new.copyright?.isEmpty ?? true) {
            existing.copyright = new.copyright
        }
        if (existing.notes?.isEmpty ?? true) && !(new.notes?.isEmpty ?? true) {
            existing.notes = new.notes
        }
        if (existing.tags?.isEmpty ?? true) && !(new.tags?.isEmpty ?? true) {
            existing.tags = new.tags
        }
        if existing.songNumber == nil && new.songNumber != nil {
            existing.songNumber = new.songNumber
        }
    }
    
    private func replaceHymnData(existing: Hymn, new: Hymn) {
        existing.lyrics = new.lyrics
        existing.musicalKey = new.musicalKey
        existing.author = new.author
        existing.copyright = new.copyright
        existing.notes = new.notes
        existing.tags = new.tags
        existing.songNumber = new.songNumber
    }
    
    // MARK: - File Type Detection
    
    private func detectImportType(for url: URL, requestedType: ImportType) -> ImportType {
        // If a specific type was requested, use it
        if requestedType != .auto {
            return requestedType
        }
        
        // Auto-detect based on file extension and content
        let fileExtension = url.pathExtension.lowercased()
        
        // Check file extension first
        if fileExtension == "json" {
            return .json
        } else if fileExtension == "txt" || fileExtension.isEmpty {
            // For .txt files or files without extension, check content
            return detectContentType(for: url)
        }
        
        // Default to plain text for unknown extensions
        return .plainText
    }
    
    private func detectContentType(for url: URL) -> ImportType {
        do {
            let data = try Data(contentsOf: url)
            
            // Try to parse as JSON first
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                // If it's valid JSON, check if it looks like hymn data
                if let jsonDict = jsonObject as? [String: Any] {
                    // Single hymn object
                    if jsonDict["title"] != nil {
                        return .json
                    }
                } else if let jsonArray = jsonObject as? [[String: Any]] {
                    // Array of hymn objects
                    if !jsonArray.isEmpty && jsonArray.first?["title"] != nil {
                        return .json
                    }
                }
            }
            
            // If not JSON, treat as plain text
            return .plainText
            
        } catch {
            // If we can't read the file, default to plain text
            return .plainText
        }
    }
    
    private func getSpecificFileError(_ error: NSError) -> ImportError {
        switch error.code {
        case NSFileReadNoPermissionError:
            return .permissionDenied
        case NSFileReadNoSuchFileError:
            return .fileNotFound
        case NSFileReadCorruptFileError:
            return .corruptedData("File appears to be corrupted")
        case NSFileReadInapplicableStringEncodingError:
            return .invalidFormat("File encoding is not supported. Please ensure the file uses UTF-8 encoding.")
        case NSFileReadTooLargeError:
            return .fileReadFailed("File is too large to read")
        case NSFileReadUnknownStringEncodingError:
            return .invalidFormat("Unknown file encoding. Please ensure the file uses UTF-8 encoding.")
        default:
            return .fileReadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - File Exporter Helpers
    
    private var exportDocument: some FileDocument {
        struct ExportDoc: FileDocument {
            static var readableContentTypes: [UTType] = [.plainText, .json]
            var data: Data
            init(data: Data) { self.data = data }
            init(configuration: ReadConfiguration) throws { self.data = configuration.file.regularFileContents ?? Data() }
            func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: data) }
        }
        switch exportType {
        case .singlePlainText:
            if let hymn = selected {
                return ExportDoc(data: (hymn.toPlainText().data(using: .utf8) ?? Data()))
            }
        case .singleJSON:
            if let hymn = selected, let data = hymn.toJSON(pretty: true) {
                return ExportDoc(data: data)
            }
        case .multipleJSON:
            let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
            if let data = Hymn.arrayToJSON(hymnsToExport, pretty: true) {
                return ExportDoc(data: data)
            }
        case .batchJSON:
            if let data = Hymn.arrayToJSON(hymns, pretty: true) {
                return ExportDoc(data: data)
            }
        case .none:
            break
        }
        return ExportDoc(data: Data())
    }
    
    private var exportContentType: UTType {
        switch exportType {
        case .singlePlainText: return .plainText
        case .singleJSON, .multipleJSON, .batchJSON: return .json
        default: return .plainText
        }
    }
    
    private var exportDefaultFilename: String {
        switch exportType {
        case .singlePlainText: return (selected?.title ?? "Hymn") + ".txt"
        case .singleJSON: return (selected?.title ?? "Hymn") + ".json"
        case .multipleJSON: return "Selected_Hymns.json"
        case .batchJSON: return "Hymns.json"
        default: return "Export"
        }
    }
}

private final class PresenterWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
