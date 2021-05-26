//
//  ContentView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI

import KeychainSwift
import SwiftyRequest
import SwiftyJSON
import Sentry
import SDWebImageSwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var orientationInfo: OrientationInfo
    @StateObject private var globalData = GlobalData()
    @EnvironmentObject var jsi: justSignedIn

    @FetchRequest(entity: Server.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)]) private var servers: FetchedResults<Server>
    
    @FetchRequest(entity: SignedInUser.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username, ascending: true)]) private var savedUsers: FetchedResults<SignedInUser>
    
    @State private var needsToSelectServer = false;
    @State private var isSignInErrored = false;
    @State private var isNetworkErrored = false;
    @State private var isLoading = false;
    @State private var tabSelection: String = "Home";
    @State private var libraries: [String] = [];
    @State private var library_names: [String: String] = [:];
    @State private var librariesShowRecentlyAdded: [String] = [];
    @State private var libraryPrefillID: String = "";
    @State private var showSettingsPopover: Bool = false;
    @State private var viewDidLoad: Bool = false;

    func startup() {
        let size = UIScreen.main.bounds.size
        if size.width < size.height {
            orientationInfo.orientation = .portrait;
        } else {
            orientationInfo.orientation = .landscape;
        }
        
        if(_viewDidLoad.wrappedValue) {
            return
        }
        
        _viewDidLoad.wrappedValue = true;
        SentrySDK.start { options in
            options.dsn = "https://75ac77d6af4d406eb989f3d8ef0f119f@o513670.ingest.sentry.io/5778242"
            options.debug = false // Enabled debug when first installing is always helpful
            options.tracesSampleRate = 1.0
            options.releaseName = "ios-" + (Bundle.main.infoDictionary?["CFBundleVersion"] as! String);
            options.enableOutOfMemoryTracking = true
        }
        
        let cache = SDImageCache(namespace: "tiny")
        cache.config.maxMemoryCost = 125 * 1024 * 1024 // 125MB memory
        cache.config.maxDiskSize = 1000 * 1024 * 1024 // 1000MB disk
        SDImageCachesManager.shared.addCache(cache)
        SDWebImageManager.defaultImageCache = SDImageCachesManager.shared
        
        _libraries.wrappedValue = []
        _library_names.wrappedValue = [:]
        _librariesShowRecentlyAdded.wrappedValue = []
        if(servers.isEmpty) {
            _isLoading.wrappedValue = false;
            _needsToSelectServer.wrappedValue = true;
        } else {
            _isLoading.wrappedValue = true;
            let savedUser = savedUsers[0];

            let keychain = KeychainSwift();
            if(keychain.get("AccessToken_\(savedUser.user_id ?? "")") != nil) {
                _globalData.wrappedValue.authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") ?? ""
                _globalData.wrappedValue.server = servers[0]
                _globalData.wrappedValue.user = savedUser
            }
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
            globalData.authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(globalData.user?.device_uuid ?? "")\", Version=\"\(appVersion ?? "0.0.1")\", Token=\"\(globalData.authToken)\"";
            
            let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/Me")
            request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
            request.contentType = "application/json"
            request.acceptType = "application/json"
            
            request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                switch result {
                case .success( let resp):
                    do {
                        let json = try JSON(data: resp.body)
                        let array2 = json["Configuration"]["LatestItemsExcludes"].arrayObject as? [String] ?? []
                        
                        let request2 = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Views")
                        request2.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                        request2.contentType = "application/json"
                        request2.acceptType = "application/json"
                        
                        request2.responseData() { (result2: Result<RestResponse<Data>, RestError>) in
                            switch result2 {
                            case .success( let resp):
                                do {
                                    let json2 = try JSON(data: resp.body)
                                    for (_,item2):(String, JSON) in json2["Items"] {
                                        _library_names.wrappedValue[item2["Id"].string ?? ""] = item2["Name"].string ?? ""
                                    }
                                    
                                    for (_,item2):(String, JSON) in json2["Items"] {
                                        if(item2["CollectionType"].string == "tvshows" || item2["CollectionType"].string == "movies") {
                                            _libraries.wrappedValue.append(item2["Id"].string ?? "")
                                            _librariesShowRecentlyAdded.wrappedValue.append(item2["Id"].string ?? "")
                                        }
                                    }
                                    
                                    _librariesShowRecentlyAdded.wrappedValue = _libraries.wrappedValue.filter { element in
                                        return !array2.contains(element)
                                    }
                                    
                                    _libraries.wrappedValue.forEach { library in
                                        if(_library_names.wrappedValue[library] == nil) {
                                            _libraries.wrappedValue.removeAll { ele in
                                                if(library == ele) {
                                                    return true
                                                } else {
                                                    return false
                                                }
                                            }
                                        }
                                    }
                                    
                                    dump(_libraries.wrappedValue)
                                    dump(_librariesShowRecentlyAdded.wrappedValue)
                                    dump(_library_names.wrappedValue)
                                } catch {
                                    
                                }
                                break
                            case .failure(let error):
                                SentrySDK.capture(error: error)
                                break
                            }
                            let defaults = UserDefaults.standard;
                            if(defaults.integer(forKey: "InNetworkBandwidth") == 0) {
                                defaults.setValue(40000000, forKey: "InNetworkBandwidth")
                            }
                            if(defaults.integer(forKey: "OutOfNetworkBandwidth") == 0) {
                                defaults.setValue(40000000, forKey: "OutOfNetworkBandwidth")
                            }
                            _isLoading.wrappedValue = false;
                        }
                    } catch {
                        
                    }
                    break
                case .failure( let error):
                    if(error.response?.status.code == 401) {
                        _isLoading.wrappedValue = false;
                        _isSignInErrored.wrappedValue = true;
                    } else {
                        SentrySDK.capture(error: error)
                        _isLoading.wrappedValue = false;
                        _isNetworkErrored.wrappedValue = true;
                    }
                }
            }
        }
    }

    var body: some View {
        if(needsToSelectServer) {
            NavigationView() {
                ConnectToServerView(isActive: $needsToSelectServer)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else if(isSignInErrored) {
            NavigationView() {
                ConnectToServerView(skip_server: true, skip_server_prefill: globalData.server, reauth_deviceId: globalData.user?.device_uuid ?? "", isActive: $isSignInErrored)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(globalData)
        } else {
            if(!jsi.did) {
                LoadingView(isShowing: $isLoading) {
                    TabView(selection: $tabSelection) {
                        NavigationView() {
                            VStack(alignment: .leading) {
                                ScrollView() {
                                    Spacer().frame(height: orientationInfo.orientation == .portrait ? 0 : 15)
                                    ContinueWatchingView()
                                    NextUpView().padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                                    ForEach(librariesShowRecentlyAdded, id: \.self) { library_id in
                                        VStack(alignment: .leading) {
                                            HStack() {
                                                Text("Latest \(library_names[library_id] ?? "")").font(.title2).fontWeight(.bold).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                                Spacer()
                                                NavigationLink(destination: LibraryView(prefill: library_id, names: [library_id: library_names[library_id] ?? ""], libraries: [library_id], filter: "&SortBy=DateCreated&SortOrder=Descending")) {
                                                    Text("See All").font(.subheadline).fontWeight(.bold)
                                                }
                                            }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                            LatestMediaView(library: library_id)
                                        }.padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                                    }
                                    Spacer().frame(height: 7)
                                }
                            }
                            .navigationTitle("Home")
                            .toolbar {
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                    Button {
                                        showSettingsPopover = true;
                                    } label: {
                                        Image(systemName: "gear")
                                    }
                                }
                            }.fullScreenCover( isPresented: $showSettingsPopover) { SettingsView(viewModel: SettingsViewModel(), close: $showSettingsPopover) }
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                        .tabItem({
                            Text("Home")
                            Image(systemName: "house")
                        })
                        .tag("Home")
                        
                        NavigationView() {
                            LibraryView(prefill: "", names: library_names, libraries: libraries)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                        .tabItem({
                            Text("All Media")
                            Image(systemName: "folder")
                        })
                        .tag("All Media")
                    }
                }
                .environmentObject(globalData)
                .onAppear(perform: startup)
                .alert(isPresented: $isNetworkErrored) {
                    Alert(title: Text("Network Error"), message: Text("Couldn't connect to Jellyfin"), dismissButton: .default(Text("Ok")))
                }
            } else {
                Text("Signing in...")
                .onAppear(perform: {
                    DispatchQueue.main.async { [self] in
                        _viewDidLoad.wrappedValue = false
                        usleep(500000);
                        self.jsi.did = false;
                    }
                })
            }
        }
    }
}
