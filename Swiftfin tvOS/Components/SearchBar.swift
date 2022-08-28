//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SearchBar: UIViewControllerRepresentable {
    
    @Binding
    var searchText: String

    func makeUIViewController(context: UIViewControllerRepresentableContext<SearchBar>) -> UINavigationController {
        let searchController = UISearchController(searchResultsController: context.coordinator)
        searchController.searchResultsUpdater = context.coordinator
        
        let containerController = UISearchContainerViewController(searchController: searchController)
        return UINavigationController(rootViewController: containerController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: UIViewController, UISearchResultsUpdating {
        func updateSearchResults(for searchController: UISearchController) {
            
        }
    }
}

//struct SearchBar: UIViewControllerRepresentable {
//
//    @Binding
//    var searchText: String
//
//    func makeUIViewController(context: Context) -> UISearchContainerViewController {
//        let searchController = UISearchController(searchResultsController: UIViewController())
//        searchController.searchBar.placeholder = NSLocalizedString("Enter keyword", comment: "")
//        searchController.searchBar.delegate = context.coordinator
//
//        let searchContainer = UISearchContainerViewController(searchController: searchController)
//        return searchContainer
//    }
//
//    func updateUIViewController(_ uiViewController: UISearchContainerViewController, context: Context) {
//
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, UISearchBarDelegate {
//
//        var parent: SearchBar!
//
//        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//            parent.searchText = searchText
//        }
//    }
//}
