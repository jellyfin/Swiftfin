//
//  LibraryView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @State private var prefill_id: String = "";
    @State private var library_names: [String: String] = [:]
    @State private var library_ids: [String] = []
    @State private var selected_library_id: String = "";
    @State private var isLoading: Bool = true;

    @State private var viewDidLoad: Bool = false;
    @State private var filterString: String = "&SortBy=SortName&SortOrder=Descending";
    @State private var showFiltersPopover: Bool = false;
    @State private var showSearchPopover: Bool = false;
    @State private var extraParam: String = "";
    @State private var title: String = "";
    @State private var url: String = "";
    @State private var closeSearch: Bool = false;
    
    private var itemsPerPage: Int = 100;
    
    @State private var firstItemIndex: Int = 0;
    @State private var lastItemIndex: Int = 0;
    @State private var totalItemCount: Int = 0;
    
    init(prefill: String?, names: [String: String], libraries: [String]) {
        _prefill_id = State(wrappedValue: prefill ?? "")
        _library_names = State(wrappedValue: names)
        _library_ids = State(wrappedValue: libraries)
    }
    
    init(prefill: String?, names: [String: String], libraries: [String], filter: String) {
        _prefill_id = State(wrappedValue: prefill ?? "")
        _library_names = State(wrappedValue: names)
        _library_ids = State(wrappedValue: libraries)
        _filterString = State(wrappedValue: filter);
    }
    
    init(filter: String, extraParams: String, title: String) {
        _prefill_id = State(wrappedValue: "erwt");
        _filterString = State(wrappedValue: filter);
        _extraParam = State(wrappedValue: extraParams);
        _title = State(wrappedValue: title)
    }
    
    init(extraParams: String, title: String) {
        _prefill_id = State(wrappedValue: "erwt");
        _extraParam = State(wrappedValue: extraParams);
        _title = State(wrappedValue: title)
    }
    
    @State var items: [ResumeItem] = []
    
    func listOnAppear() {
        if(_viewDidLoad.wrappedValue == false) {
            //print("running VDL")
            _viewDidLoad.wrappedValue = true;
            _library_ids.wrappedValue.append("favorites")
            _library_names.wrappedValue["favorites"] = "Favorites"
            
            _library_ids.wrappedValue.append("genres")
            _library_names.wrappedValue["genres"] = "Genres - WIP"
        }
    }
    
    func loadItems() {
        recalcTracks()
        _isLoading.wrappedValue = true;
        if(_extraParam.wrappedValue == "") {
            _url.wrappedValue = "/Users/\(globalData.user?.user_id ?? "")/Items?Limit=\(lastItemIndex - firstItemIndex)&StartIndex=\(firstItemIndex)&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb%2CBanner&IncludeItemTypes=Movie,Series\(selected_library_id == "favorites" ? "&Filters=IsFavorite" : "&ParentId=" + selected_library_id)\(filterString)"
        } else {
            _url.wrappedValue = "/Users/\(globalData.user?.user_id ?? "")/Items?Limit=\(lastItemIndex - firstItemIndex)&StartIndex=\(firstItemIndex)&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb%2CBanner&IncludeItemTypes=Movie,Series\(filterString)\(extraParam)"
        }
        
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + _url.wrappedValue)
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    _totalItemCount.wrappedValue = json["TotalRecordCount"].int ?? 0;
                    for (_,item):(String, JSON) in json["Items"] {
                        // Do something you want
                        let itemObj = ResumeItem()
                        itemObj.Type = item["Type"].string ?? ""
                        if(itemObj.Type == "Series") {
                            itemObj.ItemBadge = item["UserData"]["UnplayedItemCount"].int ?? 0
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                            itemObj.Name = item["Name"].string ?? ""
                            itemObj.Type = item["Type"].string ?? ""
                            itemObj.IndexNumber = nil
                            itemObj.Id = item["Id"].string ?? ""
                            itemObj.ParentIndexNumber = nil
                            itemObj.SeasonId = nil
                            itemObj.SeriesId = nil
                            itemObj.SeriesName = nil
                            itemObj.ProductionYear = item["ProductionYear"].int ?? 0
                        } else {
                            itemObj.ProductionYear = item["ProductionYear"].int ?? 0
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                            itemObj.Name = item["Name"].string ?? ""
                            itemObj.Type = item["Type"].string ?? ""
                            itemObj.IndexNumber = item["IndexNumber"].int ?? nil
                            itemObj.Id = item["Id"].string ?? ""
                            itemObj.ParentIndexNumber = item["ParentIndexNumber"].int ?? nil
                            itemObj.SeasonId = item["SeasonId"].string ?? nil
                            itemObj.SeriesId = item["SeriesId"].string ?? nil
                            itemObj.SeriesName = item["SeriesName"].string ?? nil
                        }
                        itemObj.Watched = item["UserData"]["Played"].bool ?? false
                        _items.wrappedValue.append(itemObj)
                    }
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
            _isLoading.wrappedValue = false;
        }
    }
    
    func onAppear() {
        if(_prefill_id.wrappedValue != "") {
            _selected_library_id.wrappedValue = _prefill_id.wrappedValue;
        }
        if(_items.wrappedValue.count == 0) {
            _firstItemIndex.wrappedValue = 0;
            _lastItemIndex.wrappedValue = itemsPerPage;
            loadItems()
        }
    }
    
    func nextPage() {
        _firstItemIndex.wrappedValue = _lastItemIndex.wrappedValue;
        _lastItemIndex.wrappedValue = _firstItemIndex.wrappedValue + itemsPerPage;
        
        if(_lastItemIndex.wrappedValue > _totalItemCount.wrappedValue) {
            _firstItemIndex.wrappedValue = _totalItemCount.wrappedValue - itemsPerPage;
            _lastItemIndex.wrappedValue = _totalItemCount.wrappedValue;
        }
        
        _items.wrappedValue = [];
        loadItems()
    }
    
    func previousPage() {
        _lastItemIndex.wrappedValue = _firstItemIndex.wrappedValue;
        _firstItemIndex.wrappedValue = _lastItemIndex.wrappedValue - itemsPerPage;
        
        if(_firstItemIndex.wrappedValue < 0) {
            _firstItemIndex.wrappedValue = 0;
            _lastItemIndex.wrappedValue = itemsPerPage;
        }
        
        _items.wrappedValue = [];
        loadItems()
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    var isPortrait: Bool {
        let result = verticalSizeClass == .regular && horizontalSizeClass == .compact
        return result
    }
    
    func recalcTracks() {
        let trkCnt: Int = Int(floor(UIScreen.main.bounds.size.width / 125));
        _tracks.wrappedValue = []
        for _ in (0..<trkCnt)
        {
            _tracks.wrappedValue.append(GridItem.init(.flexible()))
        }
    }
    
    @State private var tracks: [GridItem] = []
    
    var body: some View {
        if(prefill_id != "") {
            LoadingView(isShowing: $isLoading) {
                ScrollView(.vertical) {
                    Spacer().frame(height: 16)
                    LazyVGrid(columns: tracks) {
                        ForEach(items, id: \.Id) { item in
                            NavigationLink(destination: ItemView(item: item )) {
                                VStack(alignment: .leading) {
                                    if(item.Type == "Movie") {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=150&quality=80&tag=\(item.Image)"))
                                            .resizable()
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 16, height: 16))!)
                                                    .resizable()
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(10)
                                            }
                                            .frame(width:100, height: 150)
                                            .cornerRadius(10)
                                    } else {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=150&quality=80&tag=\(item.Image)"))
                                            .resizable()
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 16, height: 16))!)
                                                    .resizable()
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(10)
                                            }
                                            .frame(width:100, height: 150)
                                            .cornerRadius(10).overlay(
                                                ZStack {
                                                    if(item.ItemBadge == 0) {
                                                        Image(systemName: "checkmark")
                                                            .font(.caption)
                                                            .padding(3)
                                                            .foregroundColor(.white)
                                                    } else {
                                                        Text("\(String(item.ItemBadge ?? 0))")
                                                            .font(.caption)
                                                            .padding(3)
                                                            .foregroundColor(.white)
                                                    }
                                                }.background(Color.black)
                                                .opacity(0.8)
                                                .cornerRadius(10.0)
                                                .padding(3), alignment: .topTrailing
                                            )
                                    }
                                    Text(item.Name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(String(item.ProductionYear))
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }.frame(width: 100)
                            }
                        }
                    }
                    Spacer().frame(height: 16)
                }
                .gesture(
                   DragGesture().onChanged { value in
                      if value.translation.height > 0 {
                         print("Scroll down")
                      } else {
                         print("Scroll up")
                      }
                   }
                )
                .onChange(of: isPortrait) { _ in
                    recalcTracks()
                }
            }
            .overrideViewPreference(.unspecified)
            .onAppear(perform: onAppear)
            .onChange(of: filterString) { tag in
                isLoading = true;
                items = [];
                loadItems();
            }
            .navigationTitle(extraParam == "" ? (library_names[prefill_id] ?? "Library") : title)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if(totalItemCount > itemsPerPage) {
                        if(firstItemIndex != 0) {
                            Button {
                                previousPage()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                        if(lastItemIndex != totalItemCount) {
                            Button {
                                nextPage()
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    NavigationLink(destination: LibrarySearchView(url: url, close: $closeSearch), isActive: $closeSearch) {
                        Image(systemName: "magnifyingglass")
                    }
                    Button {
                        showFiltersPopover = true
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease")
                    }
                }
            }.fullScreenCover( isPresented: self.$showFiltersPopover) { LibraryFilterView(library: selected_library_id, output: $filterString, close: $showFiltersPopover).environmentObject(self.globalData) }
        } else {
            List(library_ids, id:\.self) { id in
                if(id != "genres") {
                    NavigationLink(destination: LibraryView(prefill: id, names: library_names, libraries: library_ids)) {
                        Text(library_names[id] ?? "").foregroundColor(Color.primary)
                    }
                } else {
                    NavigationLink(destination: LibraryView(prefill: id, names: library_names, libraries: library_ids)) {
                        Text(library_names[id] ?? "").foregroundColor(Color.primary)
                    }
                }
            }.onAppear(perform: listOnAppear).overrideViewPreference(.unspecified).navigationTitle("All Media")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LibrarySearchView(url: "/Users/\(globalData.user?.user_id ?? "")/Items?Limit=300&StartIndex=0&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb%2CBanner&IncludeItemTypes=Movie,Series\(extraParam)", close: $closeSearch), isActive: $closeSearch) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            
        }
    }
}
