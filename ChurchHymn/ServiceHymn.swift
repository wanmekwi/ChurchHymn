import Foundation
import SwiftData

@Model
final class ServiceHymn: Identifiable {
    @Attribute(.unique) var id: UUID
    var hymnId: UUID
    var serviceId: UUID
    var order: Int
    var addedAt: Date
    var modelVersion: Int

    init(
        id: UUID = UUID(),
        hymnId: UUID,
        serviceId: UUID,
        order: Int,
        addedAt: Date = Date(),
        modelVersion: Int = 1
    ) {
        self.id = id
        self.hymnId = hymnId
        self.serviceId = serviceId
        self.order = order
        self.addedAt = addedAt
        self.modelVersion = modelVersion
    }
}

extension ServiceHymn: Hashable {
    static func == (lhs: ServiceHymn, rhs: ServiceHymn) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
