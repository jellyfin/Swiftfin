//
//  NextUpView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct NextUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    
    @State var resumeItems: [ResumeItem] = []
    @State private var viewDidLoad: Int = 0;
    @State private var isLoading: Bool = false;
    
    func onAppear() {
        if(globalData.server?.baseURI == "") {
            return
        }
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Shows/NextUp?Limit=12&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&MediaTypes=Video&UserId=\(globalData.user?.user_id ?? "")")
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
                        itemObj.Image = item["SeriesPrimaryImageTag"].string ?? ""
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
                        
                        _resumeItems.wrappedValue.append(itemObj)
                    }
                    _isLoading.wrappedValue = false;
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
        VStack(alignment: .leading) {
            if(resumeItems.count != 0) {
                Text("Next Up").font(.title2).fontWeight(.bold).padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack() {
                        if(isLoading == false) {
                            Spacer().frame(width:14)
                            ForEach(resumeItems, id: \.Id) { item in
                                NavigationLink(destination: ItemView(item: item)) {
                                    VStack(alignment: .leading) {
                                        Spacer().frame(height:10)
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.SeriesId ?? "")/Images/\(item.ImageType)?maxWidth=150&quality=80&tag=\(item.Image)")!)
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
                                        Text(item.SeriesName ?? "")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text("S\(String(item.ParentIndexNumber ?? 0)):E\(String(item.IndexNumber ?? 0))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        Spacer().frame(height:5)
                                    }
                                    .frame(width: 100)
                                    Spacer().frame(width:12)
                                }
                                Spacer().frame(width: 10)
                            }
                            Spacer().frame(width:14)
                        }
                    }.frame(height: 200)
                }.padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0)).frame(height: 200)
            }
        }.onAppear(perform: onAppear).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
