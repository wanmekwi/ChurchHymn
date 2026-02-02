import SwiftUI
import SwiftData

struct HymnListView: View {
    let hymns: [Hymn]
    let todaysServiceHymnIds: Set<UUID>
    @Binding var selected: Hymn?
    @Binding var selectedHymnsForDelete: Set<UUID>
    @Binding var isMultiSelectMode: Bool
    @Binding var editHymn: Hymn?
    @Binding var showingEdit: Bool
    @Binding var hymnToDelete: Hymn?
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingBatchDeleteConfirmation: Bool
    
    let onAddToTodaysService: ([Hymn]) -> Void
    let onRemoveFromTodaysService: (Hymn) -> Void
    let onPresent: (Hymn) -> Void
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .title
    
    enum SortOption: String, CaseIterable, Identifiable {
        case title = "Title"
        case number = "Number"
        case key = "Key"
        case author = "Author"
        
        var id: String { self.rawValue }
    }
    
    var filteredHymns: [Hymn] {
        let filtered: [Hymn]
        if searchText.isEmpty {
            filtered = hymns
        } else {
            filtered = hymns.filter { hymn in
                let searchQuery = searchText.lowercased()
                // Search in title
                if hymn.title.lowercased().contains(searchQuery) {
                    return true
                }
                // Search in song number if present (e.g. "42" or "#42")
                if let number = hymn.songNumber {
                    let numberStr = String(number)
                    let queryForNumber = searchQuery.hasPrefix("#") ? String(searchQuery.dropFirst()) : searchQuery
                    if !queryForNumber.isEmpty && (numberStr.contains(queryForNumber) || queryForNumber == numberStr) {
                        return true
                    }
                }
                // Search in lyrics if present
                if let lyrics = hymn.lyrics,
                   lyrics.lowercased().contains(searchQuery) {
                    return true
                }
                // Search in author if present
                if let author = hymn.author,
                   author.lowercased().contains(searchQuery) {
                    return true
                }
                return false
            }
        }
        // Sort based on selected option
        switch sortOption {
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .number:
            return filtered.sorted {
                ($0.songNumber ?? Int.max) < ($1.songNumber ?? Int.max)
            }
        case .key:
            return filtered.sorted {
                ($0.musicalKey ?? "").localizedCaseInsensitiveCompare($1.musicalKey ?? "") == .orderedAscending
            }
        case .author:
            return filtered.sorted {
                ($0.author ?? "").localizedCaseInsensitiveCompare($1.author ?? "") == .orderedAscending
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search + Sort (refined hierarchy)
            VStack(alignment: .leading, spacing: 8) {
                TextField("Search by title, song number, lyrics…", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Text("Sort:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            Divider()
            
            // Hymns list
            List(filteredHymns, id: \.id, selection: $selected) { hymn in
                HStack {
                    if isMultiSelectMode {
                        Image(systemName: selectedHymnsForDelete.contains(hymn.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedHymnsForDelete.contains(hymn.id) ? .blue : .gray)
                            .onTapGesture {
                                if selectedHymnsForDelete.contains(hymn.id) {
                                    selectedHymnsForDelete.remove(hymn.id)
                                } else {
                                    selectedHymnsForDelete.insert(hymn.id)
                                }
                            }
                    }

                    Text(hymn.title)
                        .tag(hymn)

                    Spacer(minLength: 8)

                    if !isMultiSelectMode {
                        if todaysServiceHymnIds.contains(hymn.id) {
                            Button {
                                onRemoveFromTodaysService(hymn)
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)
                            .help("In Today's Service — click to remove")
                        } else {
                            Button {
                                onAddToTodaysService([hymn])
                            } label: {
                                Image(systemName: "plus.circle")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Add to Today's Service")
                        }
                    }
                }
                .onTapGesture {
                    if !isMultiSelectMode {
                        selected = hymn
                    }
                }
                .contextMenu {
                    Button("Edit") {
                        editHymn = hymn
                        selected = hymn
                        showingEdit = true
                    }

                    Divider()

                    if todaysServiceHymnIds.contains(hymn.id) {
                        Button("Remove from Today's Service") {
                            onRemoveFromTodaysService(hymn)
                        }
                    } else {
                        Button("Add to Today's Service") {
                            onAddToTodaysService([hymn])
                        }
                    }

                    Divider()
                    Button("Delete", role: .destructive) {
                        if isMultiSelectMode {
                            selectedHymnsForDelete.insert(hymn.id)
                            showingBatchDeleteConfirmation = true
                        } else {
                            hymnToDelete = hymn
                            selected = hymn
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            
            // Footer with total count
            Divider()
            HStack {
                Spacer()
                Group {
                    Text("\(filteredHymns.count) of \(hymns.count) hymns")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 200)
    }
}

// SearchBar removed in Phase B (use macOS-native rounded TextField above)