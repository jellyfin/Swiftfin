//
//  SettingsView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @Binding var close: Bool;
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var jsi: justSignedIn
    @State private var username: String = "";
    @State private var inNetworkStreamBitrate: Int = 40000000;
    @State private var outOfNetworkStreamBitrate: Int = 40000000;
    
    func onAppear() {
        _username.wrappedValue = globalData.user?.username ?? "";
        let defaults = UserDefaults.standard
        _inNetworkStreamBitrate.wrappedValue = defaults.integer(forKey: "InNetworkBandwidth");
        _outOfNetworkStreamBitrate.wrappedValue = defaults.integer(forKey: "OutOfNetworkBandwidth");
    }
    
    var body: some View {
        NavigationView() {
            Form() {
                Section(header: Text("Playback settings")) {
                    Picker("Default local playback bitrate", selection: $inNetworkStreamBitrate) {
                        ForEach(self.viewModel.bitrates, id: \.self) { bitrate in
                            Text(bitrate.name).tag(bitrate.value)
                        }
                    }.onChange(of: inNetworkStreamBitrate) { _ in
                        let defaults = UserDefaults.standard
                        defaults.setValue(_inNetworkStreamBitrate.wrappedValue, forKey: "InNetworkBandwidth")
                    }
                    
                    Picker("Default remote playback bitrate", selection: $outOfNetworkStreamBitrate) {
                        ForEach(self.viewModel.bitrates, id: \.self) { bitrate in
                            Text(bitrate.name).tag(bitrate.value)
                        }
                    }.onChange(of: outOfNetworkStreamBitrate) { _ in
                        let defaults = UserDefaults.standard
                        defaults.setValue(_outOfNetworkStreamBitrate.wrappedValue, forKey: "OutOfNetworkBandwidth")
                    }
                }
                
                Section() {
                    Button {
                        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Server")
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                        do {
                            try viewContext.execute(deleteRequest)
                        } catch _ as NSError {
                            // TODO: handle the error
                        }
                        
                        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SignedInUser")
                        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)

                        do {
                            try viewContext.execute(deleteRequest2)
                        } catch _ as NSError {
                            // TODO: handle the error
                        }
                        
                        globalData.server = nil
                        globalData.user = nil
                        globalData.authToken = ""
                        globalData.authHeader = ""
                        jsi.did = true
                        // TODO: This should redirect to the server selection screen
                        exit(-1)
                    } label: {
                        Text("Log out")
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        close = false
                    } label: {
                        HStack() {
                            Text("Back").font(.callout)
                        }
                    }
                }
            }
        }.onAppear(perform: onAppear)
    }
}
