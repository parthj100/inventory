//
//  Costume_InventoryApp.swift
//  Costume Inventory
//
//  Created by Parth Joshi on 4/15/25.
//

import SwiftUI

@main
struct Costume_InventoryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
        }
    }
}
