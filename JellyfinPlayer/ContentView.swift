/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

import KeychainSwift
import SwiftyJSON
import SwiftyRequest
import Nuke
import Combine
import JellyfinAPI

struct ContentView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var orientationInfo: OrientationInfo
    @StateObject
    private var globalData = GlobalData()
    @EnvironmentObject
    var jsi: justSignedIn

    @FetchRequest(entity: Server.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)])
    private var servers: FetchedResults<Server>

    @FetchRequest(entity: SignedInUser.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username,
                                                     ascending: true)])
    private var savedUsers: FetchedResults<SignedInUser>

    @State
    private var needsToSelectServer = false
    @State
    private var isLoading = false
    @State
    private var tabSelection: String = "Home"
    @State
    private var libraries: [String] = []
    @State
    private var library_names: [String: String] = [:]
    @State
    private var librariesShowRecentlyAdded: [String] = []
    @State
    private var libraryPrefillID: String = ""
    @State
    private var showSettingsPopover: Bool = false
    @State
    private var viewDidLoad: Bool = false

    func startup() {
        let size = UIScreen.main.bounds.size
        if size.width < size.height {
            orientationInfo.orientation = .portrait
        } else {
            orientationInfo.orientation = .landscape
        }

        if viewDidLoad {
            return
        }
        
        viewDidLoad = true

        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk

        if servers.isEmpty {
            isLoading = false
            needsToSelectServer = true
        } else {
            isLoading = true
            let savedUser = savedUsers[0]

            let keychain = KeychainSwift()
            if keychain.get("AccessToken_\(savedUser.user_id ?? "")") != nil {
                globalData.authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") ?? ""
                globalData.server = servers[0]
                globalData.user = savedUser
            }

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            var deviceName = UIDevice.current.name;
            deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
            deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]");
            
            var header = "MediaBrowser "
            header.append("Client=\"SwiftFin\", ")
            header.append("Device=\"\(deviceName)\", ")
            header.append("DeviceId=\"\(globalData.user?.device_uuid ?? "")\", ")
            header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
            header.append("Token=\"\(globalData.authToken)\"")
            
            globalData.authHeader = header
            JellyfinAPI.basePath = globalData.server?.baseURI ?? ""
            JellyfinAPI.customHeaders = ["X-Emby-Authorization": globalData.authHeader]
            
            UserAPI.getCurrentUser()
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                }, receiveValue: { response in
                    //Get all libraries
                    libraries = response.configuration?.orderedViews ?? []
                    librariesShowRecentlyAdded = libraries.filter { element in
                        return !(response.configuration?.latestItemsExcludes?.contains(element))!
                    }
                })
                .store(in: &globalData.pendingAPIRequests)
            
            UserViewsAPI.getUserViews(userId: globalData.user?.user_id ?? "")
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                }, receiveValue: { response in
                    //Get all libraries
                    response.items?.forEach({ item in
                        library_names[item.id ?? ""] = item.name
                    })
                })
                .store(in: &globalData.pendingAPIRequests)
            
            let defaults = UserDefaults.standard
            if defaults.integer(forKey: "InNetworkBandwidth") == 0 {
                defaults.setValue(40_000_000, forKey: "InNetworkBandwidth")
            }
            if defaults.integer(forKey: "OutOfNetworkBandwidth") == 0 {
                defaults.setValue(40_000_000, forKey: "OutOfNetworkBandwidth")
            }
            
            isLoading = false
        }
    }

    var body: some View {
        if (needsToSelectServer == true) {
            NavigationView {
                ConnectToServerView(isActive: $needsToSelectServer)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else if (globalData.expiredCredentials == true) {
            NavigationView {
                ConnectToServerView(skip_server: true, skip_server_prefill: globalData.server,
                                    reauth_deviceId: globalData.user?.device_uuid ?? "", isActive: $globalData.expiredCredentials)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else {
            if !jsi.did {
                LoadingView(isShowing: $isLoading) {
                    TabView(selection: $tabSelection) {
                        NavigationView {
                            VStack(alignment: .leading) {
                                ScrollView {
                                    Spacer().frame(height: orientationInfo.orientation == .portrait ? 0 : 15)
                                    ContinueWatchingView()
                                    NextUpView().padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                                    ForEach(librariesShowRecentlyAdded, id: \.self) { library_id in
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Text("Latest \(library_names[library_id] ?? "")").font(.title2).fontWeight(.bold)
                                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                                Spacer()
                                                NavigationLink(destination: LazyView {
                                                    LibraryView(viewModel: .init(filter: Filter(parentID: library_id)),
                                                                title: library_names[library_id] ?? "")
                                                }) {
                                                    Text("See All").font(.subheadline).fontWeight(.bold)
                                                }
                                            }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                            LatestMediaView(library: library_id)
                                        }.padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                                    }
                                    Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                                }
                                .navigationTitle("Home")
                                .toolbar {
                                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                                        Button {
                                            showSettingsPopover = true
                                        } label: {
                                            Image(systemName: "gear")
                                        }
                                    }
                                }
                                .fullScreenCover(isPresented: $showSettingsPopover) {
                                    SettingsView(viewModel: SettingsViewModel(), close: $showSettingsPopover)
                                }
                            }
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                        .tabItem {
                            Text("Home")
                            Image(systemName: "house")
                        }
                        .tag("Home")
                        NavigationView {
                            LibraryListView(viewModel: .init(libraryNames: library_names, libraryIDs: libraries))
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                        .tabItem {
                            Text("All Media")
                            Image(systemName: "folder")
                        }
                        .tag("All Media")
                    }
                }
                .environmentObject(globalData)
                .onAppear(perform: startup)
                .alert(isPresented: $globalData.networkError) {
                    Alert(title: Text("Network Error"), message: Text("Couldn't connect to Jellyfin"), dismissButton: .default(Text("Ok")))
                }
            } else {
                Text("Signing in...")
                    .onAppear(perform: {
                        DispatchQueue.main.async { [self] in
                            _viewDidLoad.wrappedValue = false
                            usleep(500_000)
                            self.jsi.did = false
                        }
                    })
            }
        }
    }
}
