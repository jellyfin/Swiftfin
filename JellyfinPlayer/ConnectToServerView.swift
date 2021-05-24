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
import Sentry
import SDWebImageSwiftUI

class publicUser: ObservableObject {
    @Published var username: String = "";
    @Published var hasPassword: Bool = true;
    @Published var primaryImageTag: String = "";
    @Published var id: String = "";
}

struct ConnectToServerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var jsi: justSignedIn
    @State private var uri = "";
    @State private var isWorking = false;
    @State private var isErrored = false;
    @State private var isDone = false;
    @State private var isSignInErrored = false;
    @State private var isConnected = false;
    @State private var serverName = "";
    @State private var publicUsers: [publicUser] = [];
    @State private var lastPublicUsers: [publicUser] = [];
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
            _uri.wrappedValue = skip_server_obj?.baseURI ?? ""
            let request = RestRequest(method: .get, url: uri + "/users/public")
            request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                switch result {
                case .success(let response):
                    do {
                        let body = response.body;
                        let json = try JSON(data: body);
                        
                        for (_,publicUserDto):(String, JSON) in json {
                            let newPublicUser = publicUser()
                            newPublicUser.username = publicUserDto["Name"].string ?? ""
                            newPublicUser.hasPassword = publicUserDto["HasPassword"].bool ?? true
                            newPublicUser.primaryImageTag = publicUserDto["PrimaryImageTag"].string ?? ""
                            newPublicUser.id = publicUserDto["Id"].string ?? ""
                            _publicUsers.wrappedValue.append(newPublicUser)
                        }
                    } catch(_) {
                        
                    }
                    _serverSkipped.wrappedValue = true;
                    _serverSkippedAlert.wrappedValue = true;
                    _server_id.wrappedValue = skip_server_obj?.server_id ?? ""
                    _serverName.wrappedValue = skip_server_obj?.name ?? ""
                    _isConnected.wrappedValue = true;
                    break
                case .failure(_):
                    _serverSkipped.wrappedValue = true;
                    _serverSkippedAlert.wrappedValue = true;
                    _server_id.wrappedValue = skip_server_obj?.server_id ?? ""
                    _serverName.wrappedValue = skip_server_obj?.name ?? ""
                    _isConnected.wrappedValue = true;
                    break
                }

            }
        }
    }
    
    func doLogin() {
        _isWorking.wrappedValue = true
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
        let authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(UIDevice.current.name)\", DeviceId=\"\(serverSkipped ? reauthDeviceID : userUUID.uuidString)\", Version=\"\(appVersion ?? "0.0.1")\"";
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
                        DispatchQueue.main.async { [self] in
                            globalData.authHeader = authHeader
                            _rootIsActive.wrappedValue = false
                            jsi.did = true
                        }
                    } catch {
                        SentrySDK.capture(error: error)
                    }
                } catch {
                    
                }
            case .failure(let error):
                SentrySDK.capture(error: error)
                _isSignInErrored.wrappedValue = true;
            }
            _isWorking.wrappedValue = false;
        }
    }
    
    var body: some View {
        Form {
            if(!isConnected) {
                Section(header: Text("Server Information")) {
                    TextField("Jellyfin Server URL", text: $uri)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    Button {
                        _isWorking.wrappedValue = true;
                        if(!_uri.wrappedValue.contains("http")) {
                            _uri.wrappedValue = "http://" + _uri.wrappedValue;
                        }
                        if(_uri.wrappedValue.last == "/") {
                            _uri.wrappedValue = String(_uri.wrappedValue.dropLast())
                        }
                        let request = RestRequest(method: .get, url: uri + "/System/Info/Public")
                        request.responseObject() { (result: Result<RestResponse<ServerPublicInfoResponse>, RestError>) in
                            switch result {
                            case .success(let response):
                                let server = response.body
                                _serverName.wrappedValue = server.ServerName
                                _server_id.wrappedValue = server.Id
                                if(server.StartupWizardCompleted) {
                                    _isConnected.wrappedValue = true;
                                }
                                
                                let request2 = RestRequest(method: .get, url: uri + "/users/public")
                                request2.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                                    switch result {
                                    case .success(let response):
                                        do {
                                            let body = response.body;
                                            let json = try JSON(data: body);
                                            
                                            for (_,publicUserDto):(String, JSON) in json {
                                                let newPublicUser = publicUser()
                                                newPublicUser.username = publicUserDto["Name"].string ?? ""
                                                newPublicUser.hasPassword = publicUserDto["HasPassword"].bool ?? true
                                                newPublicUser.primaryImageTag = publicUserDto["PrimaryImageTag"].string ?? ""
                                                newPublicUser.id = publicUserDto["Id"].string ?? ""
                                                _publicUsers.wrappedValue.append(newPublicUser)
                                            }
                                        } catch(_) {
                                            
                                        }
                                        _isWorking.wrappedValue = false;
                                        break
                                    case .failure(_):
                                        _isErrored.wrappedValue = true;
                                        _isWorking.wrappedValue = false;
                                        break
                                    }
                                }
                            case .failure(_):
                                _isErrored.wrappedValue = true;
                                _isWorking.wrappedValue = false;
                            }
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
                if(_publicUsers.wrappedValue.count == 0) {
                    Section(header: Text("\(serverSkipped ? "Reauthenticate" : "Login") to \(serverName)")) {
                        TextField("Username", text: $username)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        Button {
                            doLogin()
                        } label: {
                            HStack {
                                Text("Login")
                                Spacer()
                                ProgressView().isHidden(!isWorking)
                            }
                        }.disabled(isWorking || username.isEmpty)
                        .alert(isPresented: $isSignInErrored) {
                            Alert(title: Text("Error"), message: Text("Invalid credentials"), dismissButton: .default(Text("Back")))
                        }
                    }
                    
                    if(serverSkipped) {
                        Section() {
                            Button {
                                _serverSkippedAlert.wrappedValue = false;
                                _server_id.wrappedValue = ""
                                _serverName.wrappedValue = ""
                                _isConnected.wrappedValue = false;
                                _serverSkipped.wrappedValue = false;
                            } label: {
                                HStack() {
                                    HStack() {
                                        Image(systemName: "chevron.left")
                                        Text("Change Server")
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        Section() {
                            Button {
                                _publicUsers.wrappedValue = _lastPublicUsers.wrappedValue
                            } label: {
                                HStack() {
                                    HStack() {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("\(serverSkipped ? "Reauthenticate" : "Login") to \(serverName)")) {
                        ForEach(publicUsers, id: \.id) { pubuser in
                            HStack() {
                                Button() {
                                    if(pubuser.hasPassword) {
                                        _lastPublicUsers.wrappedValue = _publicUsers.wrappedValue
                                        _username.wrappedValue = pubuser.username
                                        _publicUsers.wrappedValue = []
                                    } else {
                                        _publicUsers.wrappedValue = []
                                        _password.wrappedValue = "";
                                        _username.wrappedValue = pubuser.username
                                        doLogin()
                                    }
                                } label: {
                                    HStack() {
                                        Text(pubuser.username).font(.subheadline).fontWeight(.semibold)
                                        Spacer()
                                        if(pubuser.primaryImageTag != "") {
                                            WebImage(url: URL(string: "\(uri)/Users/\(pubuser.id)/Images/Primary?width=200&quality=80&tag=\(pubuser.primaryImageTag)")!)
                                                .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .cornerRadius(30.0)
                                                .shadow(radius: 6)
                                        } else {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.8))
                                                .font(.system(size: 35))
                                                .frame(width: 60, height: 60)
                                                .background(Color(red: 98/255, green: 121/255, blue: 205/255))
                                                .cornerRadius(30.0)
                                                .shadow(radius: 6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section() {
                        Button() {
                            _publicUsers.wrappedValue = []
                        } label: {
                            HStack() {
                                Text("Other User").font(.subheadline).fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.8))
                                    .font(.system(size: 35))
                                    .frame(width: 60, height: 60)
                                    .background(Color(red: 98/255, green: 121/255, blue: 205/255))
                                    .cornerRadius(30.0)
                                    .shadow(radius: 6)
                            }
                        }
                    }
                }
            }
        }.navigationTitle("Connect to Server")
        .alert(isPresented: $serverSkippedAlert) {
            Alert(title: Text("Error"), message: Text("Credentials have expired"), dismissButton: .default(Text("Sign in again")))
        }
        .onAppear(perform: start)
    }
}
