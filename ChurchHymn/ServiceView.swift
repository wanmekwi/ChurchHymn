import SwiftUI

struct ServiceView: View {
    let hymns: [Hymn]
    let todaysService: WorshipService?
    let todaysServiceHymns: [ServiceHymn]

    @Binding var selected: Hymn?
    let onSwitchToLibrary: () -> Void

    @ObservedObject var serviceOperations: ServiceOperations

    @State private var showingCreateService = false
    @State private var showingServiceHistory = false
    @State private var showingClearConfirm = false
    @State private var showingArchiveConfirm = false

    private var hymnById: [UUID: Hymn] {
        Dictionary(uniqueKeysWithValues: hymns.map { ($0.id, $0) })
    }

    private var orderedItems: [ServiceHymn] {
        todaysServiceHymns.sorted { $0.order < $1.order }
    }

    private var serviceTitle: String {
        todaysService?.title.isEmpty == false ? (todaysService?.title ?? "") : "Today's Service"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            list
        }
        .sheet(isPresented: $showingCreateService) {
            ServiceCreationView(serviceOperations: serviceOperations)
        }
        .sheet(isPresented: $showingServiceHistory) {
            ServiceHistoryView(serviceOperations: serviceOperations)
        }
        .alert("Clear Today's Service?", isPresented: $showingClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearService()
            }
        } message: {
            Text("This removes all hymns from the current service.")
        }
        .alert("Archive Current Service?", isPresented: $showingArchiveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                archiveService()
            }
        } message: {
            Text("This will keep the service in history and unmark it as active.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceTitle)
                        .font(.headline)
                    if let date = todaysService?.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No active service")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("\(orderedItems.count) hymns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Button("Add Hymns…") { onSwitchToLibrary() }
                    .disabled(todaysService == nil && hymns.isEmpty)

                Button("New Service…") { showingCreateService = true }

                Button("History…") { showingServiceHistory = true }

                Spacer()

                Button("Archive") { showingArchiveConfirm = true }
                    .disabled(todaysService == nil)

                Button("Clear", role: .destructive) { showingClearConfirm = true }
                    .disabled(orderedItems.isEmpty)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var list: some View {
        List(selection: $selected) {
            if todaysService == nil {
                ContentUnavailableView(
                    "No active service",
                    systemImage: "music.note.list",
                    description: Text("Create a new service or select one from history.")
                )
            } else if orderedItems.isEmpty {
                ContentUnavailableView(
                    "No hymns in service",
                    systemImage: "plus.circle",
                    description: Text("Use “Add Hymns…” to add hymns to today’s service.")
                )
            } else {
                ForEach(orderedItems, id: \.id) { item in
                    if let hymn = hymnById[item.hymnId] {
                        ServiceHymnRow(order: item.order + 1, hymn: hymn)
                            .tag(hymn)
                            .contextMenu {
                                Button("Remove from Service") {
                                    removeFromService(hymn)
                                }
                            }
                    } else {
                        HStack {
                            Text("\(item.order + 1).")
                                .foregroundColor(.secondary)
                                .frame(width: 32, alignment: .trailing)
                            Text("Missing hymn")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onMove(perform: move)
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        guard let service = todaysService else { return }
        guard let from = source.first else { return }
        var to = destination
        // SwiftUI gives destination in the post-removal coordinate space
        if to > from { to -= 1 }
        do {
            try serviceOperations.reorderServiceHymns(service: service, from: from, to: to)
        } catch {
            // Keep UI responsive; errors will be visible in console.
            print("Failed to reorder service hymns: \(error)")
        }
    }

    private func removeFromService(_ hymn: Hymn) {
        do {
            try serviceOperations.removeHymnFromTodaysService(hymnId: hymn.id)
        } catch {
            print("Failed to remove hymn from service: \(error)")
        }
    }

    private func clearService() {
        do {
            try serviceOperations.clearTodaysService()
        } catch {
            print("Failed to clear service: \(error)")
        }
    }

    private func archiveService() {
        do {
            try serviceOperations.archiveActiveService()
            onSwitchToLibrary()
        } catch {
            print("Failed to archive service: \(error)")
        }
    }
}

private struct ServiceHymnRow: View {
    let order: Int
    let hymn: Hymn

    var body: some View {
        HStack(spacing: 10) {
            Text("\(order).")
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
            Text(hymn.title)
                .lineLimit(1)
            Spacer()
        }
    }
}

