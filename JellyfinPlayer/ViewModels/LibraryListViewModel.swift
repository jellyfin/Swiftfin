//
//  LibraryListViewModel.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/28.
//

import Combine
import CombineMoya
import Foundation
import Moya
import SwiftyJSON

final class LibraryListViewModel: ObservableObject {
    fileprivate var provider =
        MoyaProvider<JellyfinAPI>()
    
    @Published
    var libraryIDs = [String]()
    @Published
    var libraryNames = [String: String]()
    
    fileprivate var cancellables = Set<AnyCancellable>()

    init(libraryNames: [String: String], libraryIDs: [String]) {
        self.libraryIDs = libraryIDs
        self.libraryNames = libraryNames
        refresh()
    }
    
    func refresh() {
        libraryIDs.append("favorites")
        libraryNames["favorites"] = "Favorites"

        libraryIDs.append("genres")
        libraryNames["genres"] = "Genres - WIP"
    }
}
