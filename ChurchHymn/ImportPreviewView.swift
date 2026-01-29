import SwiftUI
import AppKit
import SwiftData

// MARK: - Import Preview
struct ImportPreviewHymn: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let lyrics: String?
    let musicalKey: String?
    let author: String?
    let copyright: String?
    let notes: String?
    let tags: [String]?
    let songNumber: Int?
    let isDuplicate: Bool
    let existingHymnID: PersistentIdentifier?
    
    init(from hymn: Hymn, isDuplicate: Bool = false, existingHymn: Hymn? = nil) {
        self.title = hymn.title
        self.lyrics = hymn.lyrics
        self.musicalKey = hymn.musicalKey
        self.author = hymn.author
        self.copyright = hymn.copyright
        self.notes = hymn.notes
        self.tags = hymn.tags
        self.songNumber = hymn.songNumber
        self.isDuplicate = isDuplicate
        self.existingHymnID = existingHymn?.persistentModelID
    }
}

struct ImportPreview: Sendable {
    let hymns: [ImportPreviewHymn]
    let duplicates: [ImportPreviewHymn]
    let errors: [String]
    let fileName: String
    
    var totalHymns: Int { hymns.count + duplicates.count }
    var validHymns: Int { hymns.count }
    var duplicateCount: Int { duplicates.count }
    var errorCount: Int { errors.count }
}

// MARK: - Import Preview View
struct ImportPreviewView: View {
    let preview: ImportPreview
    @Binding var selectedHymns: Set<UUID>
    @Binding var duplicateResolution: DuplicateResolution
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Import Preview")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Header with summary
            VStack(alignment: .leading, spacing: 8) {
                Text("File: \(preview.fileName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    ImportSummaryItem(label: "Total", count: preview.totalHymns, color: .blue)
                    ImportSummaryItem(label: "New", count: preview.validHymns, color: .green)
                    ImportSummaryItem(label: "Duplicates", count: preview.duplicateCount, color: .orange)
                    if preview.errorCount > 0 {
                        ImportSummaryItem(label: "Errors", count: preview.errorCount, color: .red)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Duplicate resolution picker
            if preview.duplicateCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duplicate Resolution")
                        .font(.headline)
                    
                    Picker("Resolution", selection: $duplicateResolution) {
                        ForEach(DuplicateResolution.allCases, id: \.self) { resolution in
                            Text(resolution.description).tag(resolution)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(Color(.controlBackgroundColor))
            }
            
            // Hymn list
            List {
                if !preview.hymns.isEmpty {
                    Section("New Hymns (\(preview.validHymns))") {
                        ForEach(preview.hymns) { hymn in
                            ImportPreviewHymnRow(
                                hymn: hymn,
                                isSelected: selectedHymns.contains(hymn.id),
                                onToggle: { isSelected in
                                    if isSelected {
                                        selectedHymns.insert(hymn.id)
                                    } else {
                                        selectedHymns.remove(hymn.id)
                                    }
                                }
                            )
                        }
                    }
                }
                
                if !preview.duplicates.isEmpty {
                    Section("Duplicates (\(preview.duplicateCount))") {
                        ForEach(preview.duplicates) { hymn in
                            ImportPreviewHymnRow(
                                hymn: hymn,
                                isSelected: selectedHymns.contains(hymn.id),
                                onToggle: { isSelected in
                                    if isSelected {
                                        selectedHymns.insert(hymn.id)
                                    } else {
                                        selectedHymns.remove(hymn.id)
                                    }
                                }
                            )
                        }
                    }
                }
                
                if !preview.errors.isEmpty {
                    Section("Errors (\(preview.errorCount))") {
                        ForEach(preview.errors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        
        // Toolbar buttons
        HStack {
            Spacer()
            Button("Cancel") {
                onCancel()
                dismiss()
            }
            .keyboardShortcut(.escape)
            
            Button("Import") {
                onConfirm()
                dismiss()
            }
            .keyboardShortcut(.return)
            .disabled(selectedHymns.isEmpty)
        }
        .padding()
        .onAppear {
            // Select all hymns by default
            selectedHymns = Set(preview.hymns.map { $0.id } + preview.duplicates.map { $0.id })
        }
    }
}

struct ImportSummaryItem: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ImportPreviewHymnRow: View {
    let hymn: ImportPreviewHymn
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(hymn.title)
                        .fontWeight(.medium)
                    
                    if hymn.isDuplicate {
                        Text("(Duplicate)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let author = hymn.author, !author.isEmpty {
                    Text("Author: \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let key = hymn.musicalKey, !key.isEmpty {
                    Text("Key: \(key)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let lyrics = hymn.lyrics, !lyrics.isEmpty {
                    Text(lyrics.prefix(100) + (lyrics.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
