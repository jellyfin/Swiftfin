//
//  LibraryListView.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/27.
//

import Foundation
import SwiftUI

struct LibraryListView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var globalData: GlobalData
    @State
    private var libraryIDs: [String] = []
    @State
    private var libraryNames: [String: String] = [:]
    @State
    private var viewDidLoad: Bool = false
    @State
    private var closeSearch: Bool = false

    init(libraryNames: [String: String], libraryIDs: [String]) {
        self._libraryNames = State(initialValue: libraryNames)
        self._libraryIDs = State(initialValue: libraryIDs)
    }

    func listOnAppear() {
        if viewDidLoad == false {
            viewDidLoad = true
            libraryIDs.append("favorites")
            libraryNames["favorites"] = "Favorites"

            libraryIDs.append("genres")
            libraryNames["genres"] = "Genres - WIP"
        }
    }

    var body: some View {
        List(libraryIDs, id: \.self) { id in
            switch id {
            case "favorites":
                NavigationLink(destination: LibraryView(viewModel: .init(filter: Filter(filterTypes: [.isFavorite])),
                                                        title: libraryNames[id] ?? "")) {
                    Text(libraryNames[id] ?? "").foregroundColor(Color.primary)
                }
            case "genres":
                Text(libraryNames[id] ?? "").foregroundColor(Color.primary)
            default:
                NavigationLink(destination: LibraryView(viewModel: .init(filter: Filter(parentID: id)), title: libraryNames[id] ?? "")) {
                    Text(libraryNames[id] ?? "").foregroundColor(Color.primary)
                }
            }
        }
        .onAppear(perform: listOnAppear)
        .navigationTitle("All Media")
        .navigationBarItems(trailing:
            NavigationLink(destination: LibrarySearchView(viewModel: .init(filter: .init()))) {
                Image(systemName: "magnifyingglass")
            })
    }
}
