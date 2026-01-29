import SwiftUI

struct ServiceCreationView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var serviceOperations: ServiceOperations

    @State private var title: String = "Today's Service"
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var makeActive: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Service")
                .font(.headline)

            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                Toggle("Make Active", isOn: $makeActive)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
    }

    private func create() {
        do {
            _ = try serviceOperations.createService(
                title: title,
                date: date,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                makeActive: makeActive
            )
            dismiss()
        } catch {
            // Keep this simple for now; any failures will appear in console.
            print("Failed to create service: \(error)")
        }
    }
}

