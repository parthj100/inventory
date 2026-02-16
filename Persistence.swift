import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        func configuredContainer(inMemory: Bool) -> NSPersistentContainer {
            let container = NSPersistentContainer(name: "Costume_Inventory")
            if inMemory {
                container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            }
            container.persistentStoreDescriptions.forEach { description in
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
            return container
        }

        let primaryContainer = configuredContainer(inMemory: inMemory)
        var primaryError: NSError?
        primaryContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                primaryError = error
            }
        }

        if let primaryError {
            assertionFailure("Primary persistent store failed to load: \(primaryError), \(primaryError.userInfo)")
            let fallback = configuredContainer(inMemory: true)
            fallback.loadPersistentStores { _, error in
                if let error = error as NSError? {
                    assertionFailure("Fallback in-memory store failed to load: \(error), \(error.userInfo)")
                }
            }
            container = fallback
        } else {
            container = primaryContainer
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
