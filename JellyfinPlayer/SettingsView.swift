//
//  SettingsView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI

struct SettingsView: View {
    @Binding var close: Bool;
    @EnvironmentObject private var globalData: GlobalData
    @State private var username: String = "";
    @State private var inNetworkStreamBitrate: Int = 40;
    
    func onAppear() {
        _username.wrappedValue = globalData.user?.username ?? "";
    }
    
    var body: some View {
        NavigationView() {
            Form() {
                Section(header: Text("Playback settings")) {
                    Picker("Local playback bitrate", selection: $inNetworkStreamBitrate) {
                        Group {
                            Text("1080p - 60 Mbps").tag(60)
                            Text("1080p - 40 Mbps").tag(40)
                            Text("1080p - 20 Mbps").tag(20)
                            Text("1080p - 15 Mbps").tag(15)
                            Text("1080p - 10 Mbps").tag(10)
                        }
                        Group {
                            Text("720p - 8 Mbps").tag(8)
                            Text("720p - 6 Mbps").tag(6)
                            Text("720p - 4 Mbps").tag(4)
                        }
                            Text("480p - 3 Mbps").tag(3)
                            Text("480p - 1.5 Mbps").tag(2)
                            Text("480p - 740 Kbps").tag(1)
                    }
                    
                    Picker("Remote playback bitrate", selection: $inNetworkStreamBitrate) {
                        Group {
                            Text("1080p - 60 Mbps").tag(60)
                            Text("1080p - 40 Mbps").tag(40)
                            Text("1080p - 20 Mbps").tag(20)
                            Text("1080p - 15 Mbps").tag(15)
                            Text("1080p - 10 Mbps").tag(10)
                        }
                        Group {
                            Text("720p - 8 Mbps").tag(8)
                            Text("720p - 6 Mbps").tag(6)
                            Text("720p - 4 Mbps").tag(4)
                        }
                            Text("480p - 3 Mbps").tag(3)
                            Text("480p - 1.5 Mbps").tag(2)
                            Text("480p - 740 Kbps").tag(1)
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
