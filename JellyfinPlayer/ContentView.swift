/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

import KeychainSwift
import Nuke
import JellyfinAPI
import WidgetKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var orientationInfo: OrientationInfo
    @EnvironmentObject var jsi: justSignedIn

    @StateObject private var globalData = GlobalData()

    @FetchRequest(entity: Server.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)])
        private var servers: FetchedResults<Server>

    @FetchRequest(entity: SignedInUser.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username, ascending: true)])
        private var savedUsers: FetchedResults<SignedInUser>

    @State private var needsToSelectServer = false
    @State private var isLoading = false
    @State private var tabSelection: String = "Home"
    @State private var libraries: [String] = []
    @State private var library_names: [String: String] = [:]
    @State private var librariesShowRecentlyAdded: [String] = []
    @State private var libraryPrefillID: String = ""
    @State private var showSettingsPopover: Bool = false
    @State private var viewDidLoad: Bool = false
    @State private var loadState: Int = 2

    private var recentFilterSet: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.descending], sortBy: ["DateCreated"])

    func startup() {
        if viewDidLoad == true {
            return
        }

        viewDidLoad = true

        let size = UIScreen.main.bounds.size
        if size.width < size.height {
            orientationInfo.orientation = .portrait
        } else {
            orientationInfo.orientation = .landscape
        }

        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk

        if servers.isEmpty {
            isLoading = false
            needsToSelectServer = true
        } else {
            isLoading = true
            let savedUser = savedUsers[0]

            let keychain = KeychainSwift()
            keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
            if keychain.get("AccessToken_\(savedUser.user_id ?? "")") != nil {
                globalData.authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") ?? ""
                globalData.server = servers[0]
                globalData.user = savedUser
            }

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            var deviceName = UIDevice.current.name
            deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
            deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

            var header = "MediaBrowser "
            header.append("Client=\"SwiftFin\", ")
            header.append("Device=\"\(deviceName)\", ")
            header.append("DeviceId=\"\(globalData.user.device_uuid ?? "")\", ")
            header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
            header.append("Token=\"\(globalData.authToken)\"")

            globalData.authHeader = header
            JellyfinAPI.basePath = globalData.server.baseURI ?? ""
            JellyfinAPI.customHeaders = ["X-Emby-Authorization": globalData.authHeader]

            DispatchQueue.global(qos: .userInitiated).async {
                UserAPI.getCurrentUser()
                    .sink(receiveCompletion: { completion in
                        HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                        loadState = loadState - 1
                    }, receiveValue: { response in
                        libraries = response.configuration?.orderedViews ?? []
                        librariesShowRecentlyAdded = libraries.filter { element in
                            return !(response.configuration?.latestItemsExcludes?.contains(element))!
                        }

                        if loadState == 1 {
                            isLoading = false
                        }
                    })
                    .store(in: &globalData.pendingAPIRequests)

                UserViewsAPI.getUserViews(userId: globalData.user.user_id ?? "")
                    .sink(receiveCompletion: { completion in
                        HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                        loadState = loadState - 1
                    }, receiveValue: { response in
                        response.items?.forEach({ item in
                            library_names[item.id ?? ""] = item.name
                        })

                        if loadState == 1 {
                            isLoading = false
                        }
                    })
                    .store(in: &globalData.pendingAPIRequests)
            }

            let defaults = UserDefaults.standard
            if defaults.integer(forKey: "InNetworkBandwidth") == 0 {
                defaults.setValue(40_000_000, forKey: "InNetworkBandwidth")
            }
            if defaults.integer(forKey: "OutOfNetworkBandwidth") == 0 {
                defaults.setValue(40_000_000, forKey: "OutOfNetworkBandwidth")
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        if needsToSelectServer == true {
            NavigationView {
                ConnectToServerView(isActive: $needsToSelectServer)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else if globalData.expiredCredentials == true {
            NavigationView {
                ConnectToServerView(skip_server: true, skip_server_prefill: globalData.server,
                                    reauth_deviceId: globalData.user.device_uuid!, isActive: $globalData.expiredCredentials)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else {
            if !jsi.did {
                if isLoading || globalData.user == nil || globalData.user.user_id == nil {
                    ProgressView()
                        .onAppear(perform: startup)
                } else {
                    VStack {
                        TabView(selection: $tabSelection) {
                            NavigationView {
                                VStack(alignment: .leading) {
                                    ScrollView {
                                        Spacer().frame(height: orientationInfo.orientation == .portrait ? 0 : 16)
                                        ContinueWatchingView()
                                        NextUpView()

                                        ForEach(librariesShowRecentlyAdded, id: \.self) { library_id in
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("Latest \(library_names[library_id] ?? "")").font(.title2).fontWeight(.bold)
                                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                                    Spacer()
                                                    NavigationLink(destination: LazyView {
                                                        LibraryView(usingParentID: library_id,
                                                                    title: library_names[library_id] ?? "", usingFilters: recentFilterSet)
                                                    }) {
                                                        HStack {
                                                            Text("See All").font(.subheadline).fontWeight(.bold)
                                                            Image(systemName: "chevron.right").font(Font.subheadline.bold())
                                                        }
                                                    }
                                                }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                                LatestMediaView(usingParentID: library_id)
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
                                LibraryListView(libraries: library_names)
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
                        Alert(title: Text("Network Error"), message: Text("An error occured while performing a network request"), dismissButton: .default(Text("Ok")))
                    }
                }
            } else {
                Text("Please wait...")
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
