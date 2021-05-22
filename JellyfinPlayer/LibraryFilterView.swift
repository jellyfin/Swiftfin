//
//  LibraryFilterView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/2/21.
//

import SwiftUI
import SwiftyJSON
import SwiftyRequest

struct Genre: Hashable, Identifiable {
    var name: String
    var id: String { name }
}


struct LibraryFilterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var library: String;
    @Binding var output: String;
    @State private var isLoading: Bool = true;
    @State private var onlyUnplayed: Bool = false;
    @State private var allGenres: [Genre] = [];
    @State private var selectedGenres: Set<Genre> = [];
    
    @State private var allRatings: [Genre] = [];
    @State private var selectedRatings: Set<Genre> = [];
    @State private var sortBySelection: String = "SortName";
    @State private var sortOrder: String = "Descending";
    @State private var viewDidLoad: Bool = false;
    @Binding var close: Bool;
    
    func onAppear() {
        if(_viewDidLoad.wrappedValue == true) {
            return
        }
        _viewDidLoad.wrappedValue = true;
        if(_output.wrappedValue.contains("&Filters=IsUnplayed")) {
            _onlyUnplayed.wrappedValue = true;
        }
        if(_output.wrappedValue.contains("&Genres=")) {
            let genreString = _output.wrappedValue.components(separatedBy: "&Genres=")[1].components(separatedBy: "&")[0];
            for genre in genreString.components(separatedBy: "%7C") {
                _selectedGenres.wrappedValue.insert(Genre(name: genre.removingPercentEncoding ?? ""))
            }
        }
        if(_output.wrappedValue.contains("&OfficialRatings=")) {
            let ratingString = _output.wrappedValue.components(separatedBy: "&OfficialRatings=")[1].components(separatedBy: "&")[0];
            for rating in ratingString.components(separatedBy: "%7C") {
                _selectedRatings.wrappedValue.insert(Genre(name: rating.removingPercentEncoding ?? ""))
            }
        }
        let sortBy = _output.wrappedValue.components(separatedBy: "&SortBy=")[1].components(separatedBy: "&")[0];
        _sortBySelection.wrappedValue = sortBy;
        let sortOrder = _output.wrappedValue.components(separatedBy: "&SortOrder=")[1].components(separatedBy: "&")[0];
        _sortOrder.wrappedValue = sortOrder;
        
        recalculateFilters()
        _allGenres.wrappedValue = []
        let url = "/Items/Filters?UserId=\(globalData.user?.user_id ?? "")&ParentId=\(library)"
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + url)
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    let arr = json["Genres"].arrayObject as? [String] ?? []
                    for genreName in arr {
                        //print(genreName)
                        let genre = Genre(name: genreName)
                        allGenres.append(genre)
                    }
                    
                    let arr2 = json["OfficialRatings"].arrayObject as? [String] ?? []
                    for genreName in arr2 {
                        //print(genreName)
                        let genre = Genre(name: genreName)
                        allRatings.append(genre)
                    }
                } catch {
                    
                } 
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
            isLoading = false;
        }
    }
    
    func recalculateFilters() {
        print("recalcFilters running");
        output = "";
        if(_onlyUnplayed.wrappedValue) {
            output = "&Filters=IsUnPlayed";
        }
        
        if(selectedGenres.count != 0) {
            output += "&Genres="
            var genres: [String] = []
            for genre in selectedGenres {
                genres.append(genre.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            }
            output += genres.joined(separator: "%7C")
        }
        
        if(selectedRatings.count != 0) {
            output += "&OfficialRatings="
            var genres: [String] = []
            for genre in selectedRatings {
                genres.append(genre.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            }
            output += genres.joined(separator: "%7C")
        }
        output += "&SortBy=\(sortBySelection)&SortOrder=\(sortOrder)"
        //print(output)
    }
    
    var body: some View {
        NavigationView() {
            LoadingView(isShowing: $isLoading) {
                Form {
                    Toggle("Only show unplayed items", isOn: $onlyUnplayed)
                        .onChange(of: onlyUnplayed) { tag in
                            recalculateFilters()
                        }
                    MultiSelector(
                        label: "Genres",
                        options: allGenres,
                        optionToString: { $0.name },
                        selected: $selectedGenres
                    ).onChange(of: selectedGenres) { tag in
                        recalculateFilters()
                    }
                    MultiSelector(
                        label: "Parental Ratings",
                        options: allRatings,
                        optionToString: { $0.name },
                        selected: $selectedRatings
                    ).onChange(of: selectedRatings) { tag in
                        recalculateFilters()
                    }
                    
                    Section(header: Text("Sort settings")) {
                        Picker("Sort by", selection: $sortBySelection) {
                            Text("Name").tag("SortName")
                            Text("Date Added").tag("DateCreated")
                            Text("Date Played").tag("DatePlayed")
                            Text("Date Released").tag("PremiereDate")
                            Text("Runtime").tag("Runtime") 
                        }.onChange(of: sortBySelection) { tag in
                            recalculateFilters()
                        }
                        Picker("Sort order", selection: $sortOrder) {
                            Text("Ascending").tag("Ascending")
                            Text("Descending").tag("Descending")
                        }.onChange(of: sortOrder) { tag in
                            recalculateFilters()
                        }
                    }
                }
            }.onAppear(perform: onAppear)
            .navigationBarTitle("Filters", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        close = false
                    } label: {
                        HStack() {
                            Text("Back").font(.callout)
                        }
                    }
                }
            }
        }
    }
}
