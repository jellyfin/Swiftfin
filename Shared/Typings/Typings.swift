//
//  Typings.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 6/3/21.
//

import Foundation

class justSignedIn: ObservableObject {
    @Published var did: Bool = false
}

class GlobalData: ObservableObject {
    @Published var user: SignedInUser?
    @Published var authToken: String = ""
    @Published var server: Server?
    @Published var authHeader: String = ""
    @Published var isInNetwork: Bool = true;
}

extension GlobalData: Equatable {
    
    static func == (lhs: GlobalData, rhs: GlobalData) -> Bool {
        lhs.user == rhs.user
            && lhs.authToken == rhs.authToken
            && lhs.server == rhs.server
            && lhs.authHeader == rhs.authHeader
    }
}
