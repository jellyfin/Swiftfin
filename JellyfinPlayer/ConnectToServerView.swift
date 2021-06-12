/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import CoreData
import KeychainSwift
import JellyfinAPI

struct ConnectToServerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var jsi: justSignedIn

    @State private var uri = ""
    @State private var isWorking = false
    @State private var isErrored = false
    @State private var isDone = false
    @State private var isSignInErrored = false
    @State private var isConnected = false
    @State private var serverName = ""
    @State private var usernameDisabled: Bool = false
    @State private var publicUsers: [UserDto] = []
    @State private var lastPublicUsers: [UserDto] = []
    @State private var username = ""
    @State private var password = ""
    @State private var server_id = ""
    @State private var serverSkipped: Bool = false
    @State private var serverSkippedAlert: Bool = false
    @State private var skip_server_bool: Bool = false
    @State private var skip_server_obj: Server!

    @Binding var rootIsActive: Bool

    private var reauthDeviceID: String = ""
    private let userUUID = UUID()

    init(skip_server: Bool, skip_server_prefill: Server, reauth_deviceId: String, isActive: Binding<Bool>) {
        _rootIsActive = isActive
        skip_server_bool = skip_server
        skip_server_obj = skip_server_prefill
        reauthDeviceID = reauth_deviceId
    }

    init(isActive: Binding<Bool>) {
        _rootIsActive = isActive
    }

    func start() {
        if skip_server_bool {
            uri = skip_server_obj.baseURI!

            UserAPI.getPublicUsers()
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure:
                            skip_server_bool = false
                            skip_server_obj = Server()
                            break
                    }
                }, receiveValue: { response in
                    publicUsers = response

                    serverSkipped = true
                    serverSkippedAlert = true
                    server_id = skip_server_obj.server_id!
                    serverName = skip_server_obj.name!
                    isConnected = true
                })
                .store(in: &globalData.pendingAPIRequests)
        }
    }

    func doLogin() {
        isWorking = true

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

        let authHeader = "MediaBrowser Client=\"SwiftFin\", Device=\"\(deviceName)\", DeviceId=\"\(serverSkipped ? reauthDeviceID : userUUID.uuidString)\", Version=\"\(appVersion ?? "0.0.1")\""
        print(authHeader)

        JellyfinAPI.customHeaders["X-Emby-Authorization"] = authHeader

        let x: AuthenticateUserByName = AuthenticateUserByName(username: username, pw: password, password: nil)

        UserAPI.authenticateUserByName(authenticateUserByName: x)
            .sink(receiveCompletion: { completion in
                isWorking = false
                HandleAPIRequestCompletion(globalData: globalData, completion: completion)
            }, receiveValue: { response in
                isWorking = true
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Server")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try viewContext.execute(deleteRequest)
                } catch _ as NSError {

                }

                let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SignedInUser")
                let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)

                do {
                    try viewContext.execute(deleteRequest2)
                } catch _ as NSError {

                }

                let newServer = Server(context: viewContext)
                newServer.baseURI = uri
                newServer.name = serverName
                newServer.server_id = server_id

                let newUser = SignedInUser(context: viewContext)
                newUser.device_uuid = userUUID.uuidString
                newUser.username = username
                newUser.user_id = response.user!.id!

                let keychain = KeychainSwift()
                keychain.set(response.accessToken!, forKey: "AccessToken_\(newUser.user_id!)")

                do {
                    try viewContext.save()
                    DispatchQueue.main.async { [self] in
                        globalData.authHeader = authHeader
                        _rootIsActive.wrappedValue = false
                        jsi.did = true
                        print("logged in")
                        isWorking = false
                    }
                } catch {
                    print("Couldn't store objects to CoreData")
                }
            })
            .store(in: &globalData.pendingAPIRequests)
    }

    var body: some View {
        Form {
            if !isConnected {
                Section(header: Text("Server Information")) {
                    TextField("Jellyfin Server URL", text: $uri)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    Button {
                        isWorking = true
                        if !uri.contains("http") {
                            uri = "https://" + uri
                        }
                        if uri.last == "/" {
                            uri = String(uri.dropLast())
                        }

                        JellyfinAPI.basePath = uri
                        SystemAPI.getPublicSystemInfo()
                            .sink(receiveCompletion: { completion in
                                switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        isErrored = true
                                        isWorking = false
                                        break
                                }
                            }, receiveValue: { response in
                                let server = response
                                serverName = server.serverName!
                                server_id = server.id!
                                if server.startupWizardCompleted ?? true {
                                    isConnected = true

                                    UserAPI.getPublicUsers()
                                        .sink(receiveCompletion: { completion in
                                            switch completion {
                                                case .finished:
                                                    break
                                                case .failure:
                                                    isErrored = true
                                                    isWorking = false
                                                    break
                                            }
                                        }, receiveValue: { response in
                                            publicUsers = response
                                            isWorking = false
                                        })
                                        .store(in: &globalData.pendingAPIRequests)
                                }
                            })
                            .store(in: &globalData.pendingAPIRequests)
                    } label: {
                        HStack {
                            Text("Connect")
                            Spacer()
                            if isWorking == true {
                                ProgressView()
                            }
                        }
                    }.disabled(isWorking || uri.isEmpty)
                }.alert(isPresented: $isErrored) {
                    Alert(title: Text("Error"), message: Text("Couldn't connect to server"), dismissButton: .default(Text("Try again")))
                }
            } else {
                if publicUsers.count == 0 {
                    Section(header: Text("\(serverSkipped ? "Reauthenticate" : "Login") to \(serverName)")) {
                        TextField("Username", text: $username)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .disabled(usernameDisabled)
                        SecureField("Password", text: $password)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        Button {
                            doLogin()
                        } label: {
                            HStack {
                                Text("Login")
                                Spacer()
                                if isWorking {
                                    ProgressView()
                                }
                            }
                        }.disabled(isWorking || username.isEmpty)
                        .alert(isPresented: $isSignInErrored) {
                            Alert(title: Text("Error"), message: Text("Invalid credentials"), dismissButton: .default(Text("Back")))
                        }
                    }

                    if serverSkipped {
                        Section {
                            Button {
                                serverSkippedAlert = false
                                server_id = ""
                                serverName = ""
                                isConnected = false
                                serverSkipped = false
                            } label: {
                                HStack {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Change Server")
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        Section {
                            Button {
                                publicUsers = lastPublicUsers
                                usernameDisabled = false
                            } label: {
                                HStack {
                                    HStack {
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
                        ForEach(publicUsers, id: \.id) { publicUser in
                            HStack {
                                Button() {
                                    if publicUser.hasPassword ?? true {
                                        lastPublicUsers = publicUsers
                                        username = publicUser.name ?? ""
                                        usernameDisabled = true
                                        publicUsers = []
                                    } else {
                                        publicUsers = []
                                        password = ""
                                        username = publicUser.name ?? ""
                                        doLogin()
                                    }
                                } label: {
                                    HStack {
                                        Text(publicUser.name ?? "").font(.subheadline).fontWeight(.semibold)
                                        Spacer()
                                        if publicUser.primaryImageTag != nil {
                                            ImageView(src: URL(string: "\(uri)/Users/\(publicUser.id ?? "")/Images/Primary?width=200&quality=80&tag=\(publicUser.primaryImageTag!)")!)
                                                .frame(width: 60, height: 60)
                                                .cornerRadius(30.0)
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

                    Section {
                        Button() {
                            lastPublicUsers = publicUsers
                            publicUsers = []
                            username = ""
                        } label: {
                            HStack {
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
