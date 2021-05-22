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

class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    @Published var orientation: Orientation
    
    private var _observer: NSObjectProtocol?
    
    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        }
        else {
            self.orientation = .portrait
        }
        
        // unowned self because we unregister before self becomes invalid
        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            }
            else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }
    
    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

@main
struct JellyfinPlayerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var jsi = justSignedIn()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(OrientationInfo())
                .environmentObject(jsi)
                .withHostingWindow() { window in
                    window?.rootViewController = PreferenceUIHostingController(wrappedView: ContentView().environment(\.managedObjectContext, persistenceController.container.viewContext)
                                                                                .environmentObject(jsi).environmentObject(OrientationInfo()))
                }
        }
    }
}
