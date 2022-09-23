//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import Socket

class WebSockets {
    
//    private var localServerSocket: Socket?
    private var isSearchingLocalServers: Bool = false
    private let localServerSubject = PassthroughSubject<LocalServerResponse, Error>()
    
    func searchLocalServers() -> AnyPublisher<LocalServerResponse, Error> {
        let listeningSocket = try! createLocalServerSocket()
        _searchLocalServers(with: listeningSocket)
        return localServerSubject.eraseToAnyPublisher()
    }
    
    func cancelLocalServerSearch() {
        isSearchingLocalServers = false
        localServerSubject.send(completion: .finished)
    }
    
    private func createLocalServerSocket() throws -> Socket {
        let newSocket = try Socket.create(type: .datagram, proto: .udp)
        try newSocket.udpBroadcast(enable: true)
        return newSocket
    }
    
//    private func readLocalServerResponse(on socket: Socket) {
//        do {
//            var data = Data(capacity: 4096)
//            let _ = try? socket.readDatagram(into: &data)
//            guard let response = try? JSONDecoder().decode(LocalServerResponse.self, from: data) else { return }
//            localServerSubject.send(response)
//
//            guard localServerSocket?.isListening ?? false else { return }
//            readLocalServerResponse(on: socket)
//        } catch let error {
//            print("error on reading: \(error)")
//            localServerSubject.send(completion: .failure(error))
//        }
//    }
    
    private func _searchLocalServers(with socket: Socket) {
        DispatchQueue.global().async {
            do {
//                try socket.listen(on: 8000, allowPortReuse: false)
//                try socket.setBlocking(mode: false)
                
                var nothing = Data(capacity: 4096)
                let broadcast = Socket.createAddress(for: "255.255.255.255", on: 7359)!
//                try socket.listen(on: 0)
                
                print("listening: \(socket.isListening)")
                
                try socket.write(from: "Who is JellyfinServer?".data(using: .utf8)!, to: broadcast)
                print("send broadcast")
                
                self.isSearchingLocalServers = true
                
                repeat {
                    var data = Data(capacity: 4096)
                    let _ = try socket.readDatagram(into: &data)
                    guard let response = try? JSONDecoder().decode(LocalServerResponse.self, from: data) else { return }
                    
                    self.localServerSubject.send(response)
                } while self.isSearchingLocalServers
                
                print("Done: \(socket.isActive)")
//                self.readLocalServerResponse(on: socket)
            } catch let error {
                print("error here: \(error)")
                self.localServerSubject.send(completion: .failure(error))
            }
        }
    }
}

extension WebSockets {
    
    static let service = Factory(scope: .singleton) {
        WebSockets()
    }
}
