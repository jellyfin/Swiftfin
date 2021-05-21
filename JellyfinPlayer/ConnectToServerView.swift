//
//  ConnectToServerView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/29/21.
//

import SwiftUI
import HidingViews
import SwiftyRequest
import SwiftyJSON
import CoreData
import KeychainSwift
import Introspect

struct ConnectToServerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var jsi: justSignedIn
    @State private var uri = "";
    @State private var isWorking = false;
    @State private var isErrored = false;
    @State private var isDone = false;
    @State private var isSignInErrored = false;
    @State private var isConnected = false;
    @State private var serverName = "";
    @Binding var rootIsActive : Bool
    
    let userUUID = UUID();
    
    @State private var username = "";
    @State private var password = "";
    @State private var server_id = "";
    
    @State private var serverSkipped: Bool = false;
    @State private var serverSkippedAlert: Bool = false;
    private var reauthDeviceID: String = "";
    private var skip_server_bool: Bool = false;
    private var skip_server_obj: Server?
    
    init(skip_server: Bool, skip_server_prefill: Server?, reauth_deviceId: String, isActive: Binding<Bool>) {
        skip_server_bool = skip_server
        skip_server_obj = skip_server_prefill
        reauthDeviceID = reauth_deviceId
        _rootIsActive = isActive
    }
    
    init(isActive: Binding<Bool>) {
        _rootIsActive = isActive
    }
    
    func start() {
        if(skip_server_bool) {
            _serverSkipped.wrappedValue = true;
            _serverSkippedAlert.wrappedValue = true;
            _server_id.wrappedValue = skip_server_obj?.server_id ?? ""
            _serverName.wrappedValue = skip_server_obj?.name ?? ""
            _uri.wrappedValue = skip_server_obj?.baseURI ?? ""
            _isConnected.wrappedValue = true;
        }
    }
    
    var body: some View {
        Form {
            if(!isConnected) {
                Section(header: Text("Server Information")) {
                    TextField("Server URL", text: $uri)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    Button {
                        _isWorking.wrappedValue = true;
                        if(!_uri.wrappedValue.contains("http")) {
                            _uri.wrappedValue = "http://" + _uri.wrappedValue;
                        }
                        let request = RestRequest(method: .get, url: uri + "/System/Info/Public")
                        request.responseObject() { (result: Result<RestResponse<ServerPublicInfoResponse>, RestError>) in
                            switch result {
                            case .success(let response):
                                let server = response.body
                                print("Found server: " + server.ServerName)
                                _serverName.wrappedValue = server.ServerName
                                _server_id.wrappedValue = server.Id
                                if(!server.StartupWizardCompleted) {
                                    print("Server needs configured")
                                } else {
                                    _isConnected.wrappedValue = true;
                                }
                            case .failure(_):
                                _isErrored.wrappedValue = true;
                            }
                            _isWorking.wrappedValue = false;
                        }
                    } label: {
                        HStack {
                            Text("Connect")
                            Spacer()
                        ProgressView().isHidden(!isWorking)
                        }
                    }.disabled(isWorking || uri.isEmpty)
                }.alert(isPresented: $isErrored) {
                    Alert(title: Text("Error"), message: Text("Couldn't connect to server"), dismissButton: .default(Text("Try again")))
                }
            } else {
                Section(header: Text("\(serverSkipped ? "re" : "")Authenticate to \"\(serverName)\"")) {
                    TextField("Username", text: $username)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    Button {
                        _isWorking.wrappedValue = true
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
                        let authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(serverSkipped ? reauthDeviceID : userUUID.uuidString)\", Version=\"\(appVersion ?? "0.0.1")\"";
                        print(authHeader)
                        let authJson: [String: Any] = ["Username": _username.wrappedValue, "Pw": _password.wrappedValue]
                        let request = RestRequest(method: .post, url: uri + "/Users/authenticatebyname")
                        request.headerParameters["X-Emby-Authorization"] = authHeader
                        request.contentType = "application/json"
                        request.acceptType = "application/json"
                        request.messageBodyDictionary = authJson
                        
                        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                            switch result {
                            case .success(let response):
                                do {
                                    let json = try JSON(data: response.body)
                                    dump(json)
                                    
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
                                    
                                    let newServer = Server(context: viewContext)
                                    newServer.baseURI = _uri.wrappedValue
                                    newServer.name = _serverName.wrappedValue
                                    newServer.server_id = _server_id.wrappedValue
                                    
                                    let newUser = SignedInUser(context: viewContext)
                                    newUser.device_uuid = userUUID.uuidString
                                    newUser.username = _username.wrappedValue
                                    newUser.user_id = json["User"]["Id"].string ?? ""
                                    
                                    let keychain = KeychainSwift()
                                    keychain.set(json["AccessToken"].string ?? "", forKey: "AccessToken_\(json["User"]["Id"].string ?? "")")
                                    
                                    do {
                                        try viewContext.save()
                                        print("Saved to Core Data Store")
                                        _rootIsActive.wrappedValue = false
                                        DispatchQueue.main.async { [self] in
                                            jsi.did = true
                                        }
                                    } catch {
                                        // Replace this implementation with code to handle the error appropriately.
                                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                        let nsError = error as NSError
                                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                    }
                                } catch {
                                    
                                }
                            case .failure(let error):
                                print(error)
                                _isSignInErrored.wrappedValue = true;
                            }
                            _isWorking.wrappedValue = false;
                        }
                    } label: {
                        HStack {
                            Text("Login")
                            Spacer()
                            ProgressView().isHidden(!isWorking)
                        }
                    }.disabled(isWorking || username.isEmpty || password.isEmpty)
                    .alert(isPresented: $isSignInErrored) {
                        Alert(title: Text("Error"), message: Text("Invalid credentials"), dismissButton: .default(Text("Back")))
                    }
                }
            }
        }.navigationTitle("Connect to Server")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $serverSkippedAlert) {
            Alert(title: Text("Error"), message: Text("Credentials have expired"), dismissButton: .default(Text("Sign in again")))
        }
        .onAppear(perform: start)
        .introspectTabBarController { (UITabBarController) in
            UITabBarController.tabBar.isHidden = true
        }
    }
}
