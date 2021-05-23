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
    
    func onAppear() {
        _username.wrappedValue = globalData.user?.username ?? "";
    }
    
    var body: some View {
        NavigationView() {
            Form() {
                Section(header: Text("Playback settings")) {

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
