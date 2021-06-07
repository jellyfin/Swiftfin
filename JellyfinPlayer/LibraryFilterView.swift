/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import SwiftyJSON
import SwiftyRequest

struct Genre: Hashable, Identifiable {
    var name: String
    var id: String { name }
}

struct LibraryFilterView: View {
    @Environment(\.presentationMode)
    var presentationMode
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var globalData: GlobalData

    @State
    var library: String

    @Binding
    var filter: Filter
    @State
    private var isLoading: Bool = true
    @State
    private var onlyUnplayed: Bool = false
    @State
    private var allGenres: [Genre] = []
    @State
    private var selectedGenres: Set<Genre> = []

    @State
    private var allRatings: [Genre] = []
    @State
    private var selectedRatings: Set<Genre> = []
    @State
    private var sortBySelection: String = "SortName"
    @State
    private var sortOrder: String = "Descending"
    @State
    private var viewDidLoad: Bool = false

    func onAppear() {
        if _viewDidLoad.wrappedValue == true {
            return
        }
        _viewDidLoad.wrappedValue = true
        if filter.filterTypes.contains(.isUnplayed) {
            _onlyUnplayed.wrappedValue = true
        }
        if !filter.genres.isEmpty {
            _selectedGenres.wrappedValue = Set(filter.genres.map { Genre(name: $0) })
        }
        if !filter.officialRatings.isEmpty {
            _selectedRatings.wrappedValue = Set(filter.officialRatings.map { Genre(name: $0) })
        }
        _sortBySelection.wrappedValue = filter.sort?.rawValue ?? sortBySelection
        _sortOrder.wrappedValue = filter.asc?.rawValue ?? sortOrder

        _allGenres.wrappedValue = []
        let url = "/Items/Filters?UserId=\(globalData.user.user_id ?? "")&ParentId=\(library)"
        let request = RestRequest(method: .get, url: (globalData.server.baseURI ?? "") + url)
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"

        request.responseData { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case let .success(response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    let arr = json["Genres"].arrayObject as? [String] ?? []
                    for genreName in arr {
                        // print(genreName)
                        let genre = Genre(name: genreName)
                        allGenres.append(genre)
                    }

                    let arr2 = json["OfficialRatings"].arrayObject as? [String] ?? []
                    for genreName in arr2 {
                        // print(genreName)
                        let genre = Genre(name: genreName)
                        allRatings.append(genre)
                    }
                } catch {}
            case let .failure(error):
                debugPrint(error)
            }
            isLoading = false
        }
    }

    var body: some View {
        NavigationView {
            LoadingView(isShowing: $isLoading) {
                Form {
                    Toggle("Only show unplayed items", isOn: $onlyUnplayed)
                        .onChange(of: onlyUnplayed) { value in
                            if value {
                                filter.filterTypes.append(.isUnplayed)
                            } else {
                                filter.filterTypes.removeAll { $0 == .isUnplayed }
                            }
                        }
                    MultiSelector(label: "Genres",
                                  options: allGenres,
                                  optionToString: { $0.name },
                                  selected: $selectedGenres)
                        .onChange(of: selectedGenres) { genres in
                            filter.genres = genres.map(\.id)
                        }
                    MultiSelector(label: "Parental Ratings",
                                  options: allRatings,
                                  optionToString: { $0.name },
                                  selected: $selectedRatings)
                        .onChange(of: selectedRatings) { ratings in
                            filter.officialRatings = ratings.map(\.id)
                        }

                    Section(header: Text("Sort settings")) {
                        Picker("Sort by", selection: $sortBySelection) {
                            Text("Name").tag("SortName")
                            Text("Date Added").tag("DateCreated")
                            Text("Date Played").tag("DatePlayed")
                            Text("Date Released").tag("PremiereDate")
                            Text("Runtime").tag("Runtime")
                        }.onChange(of: sortBySelection) { value in
                            guard let sort = SortType(rawValue: value) else { return }
                            filter.sort = sort
                        }
                        Picker("Sort order", selection: $sortOrder) {
                            Text("Ascending").tag("Ascending")
                            Text("Descending").tag("Descending")
                        }.onChange(of: sortOrder) { order in
                            guard let asc = ASC(rawValue: order) else { return }
                            filter.asc = asc
                        }
                    }
                }
            }.onAppear(perform: onAppear)
                .navigationBarTitle("Filters", displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack {
                                Text("Back").font(.callout)
                            }
                        }
                    }
                }
        }
    }
}
