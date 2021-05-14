//
//  JellyfinPlayerApp.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI

class justSignedIn: ObservableObject {
    @Published var did: Bool = false
}

@main
struct JellyfinPlayerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var jsi = justSignedIn()
    
    var body: some Scene {
        WindowGroup {
            if(!jsi.did) {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(jsi)
                    .withHostingWindow() { window in
                        window?.rootViewController = PreferenceUIHostingController(wrappedView: ContentView().environment(\.managedObjectContext, persistenceController.container.viewContext)
                                                                                    .environmentObject(jsi))
                    }
            } else {
                Text("Please wait...")
                    .onAppear(perform: {
                        print("Signing in")
                        sleep(1)
                        jsi.did = false
                    })
            }
        }
    }
}
