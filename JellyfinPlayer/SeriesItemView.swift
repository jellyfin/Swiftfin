//
//  SeriesItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import ExyteGrid
import SDWebImageSwiftUI

struct SeriesItemView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var isLoading: Bool = true;
    var item: ResumeItem;
    @State private var items: [ResumeItem] = [];
    @State private var hasAppearedOnce: Bool = false;
    func onAppear() {
        if(hasAppearedOnce) {
            return;
        }
        _isLoading.wrappedValue = true;
        let url = "/Shows/\(item.Id )/Seasons?userId=\(globalData.user?.user_id ?? "")&Fields=ItemCounts%2CPrimaryImageAspectRatio%2CBasicSyncInfo%2CCanDelete%2CMediaSourceCount"
        
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
                    for (_,item):(String, JSON) in json["Items"] {
                        // Do something you want
                        let itemObj = ResumeItem()
                        itemObj.Type = "Season"
                        itemObj.Id = item["Id"].string ?? ""
                        itemObj.ProductionYear = item["ProductionYear"].int ?? 0
                        itemObj.ItemBadge = item["UserData"]["UnplayedItemCount"].int ?? 0
                        itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                        itemObj.ImageType = "Primary"
                        itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                        itemObj.SeriesName = item["SeriesName"].string ?? ""
                        itemObj.Name = item["Name"].string ?? ""
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
            _hasAppearedOnce.wrappedValue = true;
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
        LoadingView(isShowing: $isLoading) {
            GeometryReader { geometry in
                Grid(tracks: self.tracks, spacing: GridSpacing(horizontal: 0, vertical: 20)) {
                    ForEach(items, id: \.Id) { item in
                        NavigationLink(destination: ItemView(item: item )) {
                            VStack(alignment: .leading) {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                                    .resizable()
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: 100, height: 150)
                                            .cornerRadius(10)
                                    }.overlay(
                                        ZStack {
                                            Text("\(String(item.ItemBadge ?? 0))")
                                                .font(.caption)
                                                .padding(3)
                                                .foregroundColor(.white)
                                        }.background(Color.black)
                                        .opacity(0.8)
                                        .cornerRadius(10.0)
                                        .padding(3), alignment: .topTrailing
                                    )
                                    .frame(width:100, height: 150)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
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
                    Spacer().frame(height: 2).gridSpan(column: self.isPortrait ? 3 : 6)
                }.gridContentMode(.scroll)
            }
        }
        .overrideViewPreference(.unspecified)
        .onAppear(perform: onAppear)
        .navigationTitle(item.Name)
    }
}
