//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct ServerDetailView: View {
    
    @ObservedObject var viewModel = ServerDetailViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(ServerEnvironment.current.server.name ?? "")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("URI")
                    Spacer()
                    Text(ServerEnvironment.current.server.baseURI ?? "")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text(ServerEnvironment.current.server.version ?? "")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Operating System")
                    Spacer()
                    Text(ServerEnvironment.current.server.os ?? "")
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                viewModel.refreshServerLibrary()
            }, label: {
                HStack {
                    Text("Refresh Library")
                        .font(.callout)
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }).disabled(viewModel.isLoading)
        }
    }
}
