/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import CombineMoya
import Foundation
import Moya
import SwiftyJSON

final class LibraryListViewModel: ObservableObject {
    fileprivate var provider =
        MoyaProvider<JellyfinAPIOld>()
    
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
