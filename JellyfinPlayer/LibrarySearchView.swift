//
//  LibrarySearchView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/2/21.
//

import SwiftUI
import SwiftyJSON
import SwiftyRequest
import ExyteGrid
import SDWebImageSwiftUI

struct LibrarySearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var url: String;
    @Binding var close: Bool;
    @State var open: Bool = false;
    @State private var isLoading: Bool = true;
    @State private var onlyUnplayed: Bool = false;
    @State private var viewDidLoad: Bool = false;
    @State var items: [ResumeItem] = []
    @State var linkedItem: ResumeItem = ResumeItem();
    @State var searchQuery: String = "" {
        didSet {
            self.onAppear();
        }
    };
    
    func onAppear() {
        _isLoading.wrappedValue = true;
        _items.wrappedValue = [];
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + _url.wrappedValue + "&searchTerm=" + searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! + (_url.wrappedValue.contains("SortBy") ? "" : "&SortBy=Name&SortOrder=Descending"))
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
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
            isLoading = false;
        }
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    var isPortrait: Bool {
        let result = verticalSizeClass == .regular && horizontalSizeClass == .compact
        return result
    }
    
    var tracks: [GridTrack] {
        self.isPortrait ? 3 : 6
    }
    
    var body: some View {
        VStack() {
            NavigationLink(destination: ItemView(item: linkedItem), isActive: $open) {
                EmptyView();
            };
            Spacer().frame(height:6);
            TextField("Search", text: $searchQuery, onEditingChanged: { _ in
                print("changed")
            }, onCommit: {
                self.onAppear()
            })
            .padding(.horizontal, 10)
            .foregroundColor(Color.secondary)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            LoadingView(isShowing: $isLoading) {
                GeometryReader { geometry in
                    Grid(tracks: self.tracks, spacing: GridSpacing(horizontal: 0, vertical: 20)) {
                        ForEach(items, id: \.Id) { item in
                            Button() {
                                _linkedItem.wrappedValue = item;
                                _close.wrappedValue = false;
                                _open.wrappedValue = true;
                            } label: {
                                VStack(alignment: .leading) {
                                    if(item.Type == "Movie") {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                                            .resizable()
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 32, height: 32))!)
                                                    .resizable()
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(10)
                                            }
                                            .frame(width:100, height: 150)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    } else {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                                            .resizable()
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 32, height: 32))!)
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
                                            .shadow(radius: 5)
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
                    }.gridContentMode(.scroll)
                }
            }
        }.onAppear(perform: onAppear)
        .navigationBarTitle("Search", displayMode: .inline)
    }
}
