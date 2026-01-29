import Foundation
import SwiftData

@Model
final class WorshipService: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var isActive: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var modelVersion: Int

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        isActive: Bool = false,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        modelVersion: Int = 1
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.isActive = isActive
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.modelVersion = modelVersion
    }

    func touch() {
        updatedAt = Date()
    }
}

extension WorshipService: Hashable {
    static func == (lhs: WorshipService, rhs: WorshipService) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
