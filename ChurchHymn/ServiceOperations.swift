import Foundation
import SwiftData

@MainActor
final class ServiceOperations: ObservableObject, @unchecked Sendable {
    @Published var currentService: WorshipService?
    @Published var isLoading = false

    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
        self.currentService = fetchActiveService()
    }

    func updateContext(_ newContext: ModelContext) {
        context = newContext
        currentService = fetchActiveService()
    }

    // MARK: - Service Fetch/Create

    func fetchActiveService() -> WorshipService? {
        let descriptor = FetchDescriptor<WorshipService>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func getOrCreateTodaysService(title: String = "Today's Service", date: Date = Date()) throws -> WorshipService {
        if let existing = fetchActiveService() {
            currentService = existing
            return existing
        }

        let service = WorshipService(title: title, date: date, isActive: true)
        context.insert(service)
        try context.save()
        currentService = service
        return service
    }

    func setActiveService(_ service: WorshipService) throws {
        // Deactivate any currently active service
        let activeDescriptor = FetchDescriptor<WorshipService>(
            predicate: #Predicate { $0.isActive == true }
        )
        let active = (try? context.fetch(activeDescriptor)) ?? []
        for s in active where s.id != service.id {
            s.isActive = false
            s.touch()
        }

        service.isActive = true
        service.touch()
        try context.save()
        currentService = service
    }

    @discardableResult
    func createService(
        title: String,
        date: Date = Date(),
        notes: String? = nil,
        makeActive: Bool = true
    ) throws -> WorshipService {
        let service = WorshipService(title: title, date: date, isActive: false, notes: notes)
        context.insert(service)

        if makeActive {
            try setActiveService(service)
        } else {
            try context.save()
        }

        return service
    }

    // MARK: - Service Hymns

    func fetchServiceHymns(serviceId: UUID) -> [ServiceHymn] {
        let descriptor = FetchDescriptor<ServiceHymn>(
            predicate: #Predicate { $0.serviceId == serviceId },
            sortBy: [SortDescriptor(\ServiceHymn.order, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func isHymnInService(hymnId: UUID, serviceId: UUID) -> Bool {
        let sid = serviceId
        let hid = hymnId
        let descriptor = FetchDescriptor<ServiceHymn>(
            predicate: #Predicate<ServiceHymn> { ($0.serviceId == sid) && ($0.hymnId == hid) }
        )
        return ((try? context.fetch(descriptor)) ?? []).isEmpty == false
    }

    func addHymnToTodaysService(_ hymn: Hymn) throws {
        let service = try getOrCreateTodaysService()
        try addHymn(hymn, to: service)
    }

    func addHymnsToTodaysService(_ hymns: [Hymn]) throws {
        let service = try getOrCreateTodaysService()
        for hymn in hymns {
            try addHymn(hymn, to: service)
        }
    }

    func addHymn(_ hymn: Hymn, to service: WorshipService) throws {
        if isHymnInService(hymnId: hymn.id, serviceId: service.id) {
            return
        }

        let existing = fetchServiceHymns(serviceId: service.id)
        let nextOrder = (existing.last?.order ?? -1) + 1

        let link = ServiceHymn(
            hymnId: hymn.id,
            serviceId: service.id,
            order: nextOrder
        )
        context.insert(link)
        service.touch()
        try context.save()
        currentService = service
    }

    func removeHymnFromTodaysService(hymnId: UUID) throws {
        guard let service = fetchActiveService() else { return }
        try removeHymn(hymnId: hymnId, from: service)
    }

    func removeHymn(hymnId: UUID, from service: WorshipService) throws {
        let sid = service.id
        let hid = hymnId
        let descriptor = FetchDescriptor<ServiceHymn>(
            predicate: #Predicate<ServiceHymn> { ($0.serviceId == sid) && ($0.hymnId == hid) }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        for item in matches {
            context.delete(item)
        }

        try normalizeOrder(for: service)
        service.touch()
        try context.save()
        currentService = service
    }

    func clearTodaysService() throws {
        guard let service = fetchActiveService() else { return }
        try clearService(service)
    }

    func clearService(_ service: WorshipService) throws {
        let items = fetchServiceHymns(serviceId: service.id)
        for item in items {
            context.delete(item)
        }
        service.touch()
        try context.save()
        currentService = service
    }

    // MARK: - Archive / Delete

    func archiveActiveService() throws {
        guard let service = fetchActiveService() else { return }
        service.isActive = false
        service.touch()
        try context.save()
        currentService = nil
    }

    func deleteService(_ service: WorshipService) throws {
        // Delete linked hymns first
        let links = fetchServiceHymns(serviceId: service.id)
        for link in links {
            context.delete(link)
        }

        let wasActive = service.isActive
        context.delete(service)
        try context.save()

        if wasActive {
            currentService = fetchActiveService()
        }
    }

    func reorderServiceHymns(service: WorshipService, from: Int, to: Int) throws {
        var items = fetchServiceHymns(serviceId: service.id)
        guard from != to, from >= 0, to >= 0, from < items.count, to < items.count else { return }
        let moved = items.remove(at: from)
        items.insert(moved, at: to)
        for (idx, item) in items.enumerated() {
            item.order = idx
        }
        service.touch()
        try context.save()
        currentService = service
    }

    // MARK: - Helpers

    private func normalizeOrder(for service: WorshipService) throws {
        let items = fetchServiceHymns(serviceId: service.id)
        for (idx, item) in items.enumerated() {
            if item.order != idx {
                item.order = idx
            }
        }
    }
}

