import SwiftUI
import SwiftData

struct ServiceHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorshipService.date, order: .reverse) private var services: [WorshipService]

    @ObservedObject var serviceOperations: ServiceOperations

    @State private var selection: WorshipService?
    @State private var showingDeleteConfirm = false

    private var activeServiceId: UUID? {
        services.first(where: { $0.isActive })?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service History")
                .font(.headline)

            List(services, selection: $selection) { service in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.title.isEmpty ? "Untitled Service" : service.title)
                        Text(service.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if service.id == activeServiceId {
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .tag(service)
            }
            .frame(minHeight: 320)

            HStack {
                Button("Close") { dismiss() }
                Spacer()

                Button("Set Active") { setActive() }
                    .disabled(selection == nil)

                Button("Delete", role: .destructive) { showingDeleteConfirm = true }
                    .disabled(selection == nil)
            }
        }
        .padding(16)
        .frame(width: 520)
        .alert("Delete Service?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteSelected() }
        } message: {
            Text("This will permanently delete the service and its hymn list.")
        }
        .onAppear {
            selection = services.first(where: { $0.isActive }) ?? services.first
        }
    }

    private func setActive() {
        guard let service = selection else { return }
        do {
            try serviceOperations.setActiveService(service)
            dismiss()
        } catch {
            print("Failed to set active service: \(error)")
        }
    }

    private func deleteSelected() {
        guard let service = selection else { return }
        do {
            try serviceOperations.deleteService(service)
            selection = services.first(where: { $0.isActive }) ?? services.first
        } catch {
            print("Failed to delete service: \(error)")
        }
    }
}

