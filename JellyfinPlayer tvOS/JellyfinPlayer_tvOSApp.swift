//
//  JellyfinPlayer_tvOSApp.swift
//  JellyfinPlayer tvOS
//
//  Created by Aiden Vigue on 6/3/21.
//

import SwiftUI

@main
struct JellyfinPlayer_tvOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
