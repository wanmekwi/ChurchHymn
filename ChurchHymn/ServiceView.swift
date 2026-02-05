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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceTitle)
                        .font(.headline)

                    if let date = todaysService?.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No active service")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Text("\(orderedItems.count)")
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                    .help("\(orderedItems.count) hymns in service")
            }

            HStack(spacing: 12) {
                Button { onSwitchToLibrary() } label: {
                    Image(systemName: "plus")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .help("Add hymns to service")
                .disabled(todaysService == nil && hymns.isEmpty)

                Button { showingCreateService = true } label: {
                    Image(systemName: "calendar.badge.plus")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .help("New service")

                Button { showingServiceHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .help("Service history")

                Spacer(minLength: 0)

                Button { showingArchiveConfirm = true } label: {
                    Image(systemName: "archivebox")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .help("Archive current service")
                .disabled(todaysService == nil)

                Button(role: .destructive) { showingClearConfirm = true } label: {
                    Image(systemName: "trash")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .help("Clear hymns from current service")
                .disabled(orderedItems.isEmpty)
            }
            .buttonStyle(.plain)
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
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                                .frame(width: 28, alignment: .trailing)
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
            // Reorder failed - list will show previous state
        }
    }

    private func removeFromService(_ hymn: Hymn) {
        do {
            try serviceOperations.removeHymnFromTodaysService(hymnId: hymn.id)
        } catch {
            // Remove failed - item will remain in service
        }
    }

    private func clearService() {
        do {
            try serviceOperations.clearTodaysService()
        } catch {
            // Clear failed - service will retain items
        }
    }

    private func archiveService() {
        do {
            try serviceOperations.archiveActiveService()
            onSwitchToLibrary()
        } catch {
            // Archive failed - service will remain active
        }
    }
}

private struct ServiceHymnRow: View {
    let order: Int
    let hymn: Hymn

    var body: some View {
        HStack(spacing: 10) {
            Text("\(order).")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
            Text(hymn.title)
                .lineLimit(1)
            Spacer()
        }
    }
}

