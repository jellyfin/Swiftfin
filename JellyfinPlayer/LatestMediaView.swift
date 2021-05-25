//
//  LatestMediaView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct LatestMediaView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    private var library_id: String = "";
    @State private var viewDidLoad: Int = 0;
    
    init(library: String) {
        library_id = library;
    }
    
    init() {
        library_id = "";
    }
    
    func onAppear() {
        if(globalData.server?.baseURI == "") {
            return
        }
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items/Latest?Limit=12&IncludeItemTypes=Movie%2CSeries&Limit=16&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo%2CPath&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&ParentId=\(library_id)")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    for (_,item):(String, JSON) in json {
                        // Do something you want
                        let itemObj = ResumeItem()
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
                        itemObj.Watched = item["UserData"]["Played"].bool ?? false
                        
                        if(itemObj.Type == "Series") {
                            itemObj.ItemBadge = item["UserData"]["UnplayedItemCount"].int ?? 0
                        }
                        
                        if(itemObj.Type != "Episode") {
                            _resumeItems.wrappedValue.append(itemObj)
                        }
                    }
                    //print("latestmediaview done https")
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                _viewDidLoad.wrappedValue = 0;
                break
            }
        }
    }
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack() {
                    Spacer().frame(width:14)
                    ForEach(resumeItems, id: \.Id) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            VStack(alignment: .leading) {
                                if(item.Type == "Series") {
                                    Spacer().frame(height:10)
                                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)")!)
                                        .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                        .placeholder {
                                            Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 16, height: 16))!)
                                                .resizable()
                                                .frame(width: 100, height: 150)
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                        .overlay(
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
                                            
                                        ).shadow(radius: 6)
                                } else {
                                    Spacer().frame(height:10)
                                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)")!)
                                        .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                        .placeholder {
                                            Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 16, height: 16))!)
                                                .resizable()
                                                .frame(width: 100, height: 150)
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                        .shadow(radius: 6)
                                }
                                Text(item.Name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer().frame(height:5)
                            }.frame(width: 100)
                        }
                        Spacer().frame(width: 14)
                    }
                    Spacer().frame(width:14)
                }.frame(height: 190)
            }.onAppear(perform: onAppear).padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0)).frame(height: 190)
    }
}

struct LatestMediaView_Previews: PreviewProvider {
    static var previews: some View {
        LatestMediaView()
    }
}
