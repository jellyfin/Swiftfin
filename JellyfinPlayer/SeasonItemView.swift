//
//  SeasonItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/13/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import Introspect
import SDWebImageSwiftUI

struct SeasonItemView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var isLoading: Bool = true;
    var item: ResumeItem;
    var fullItem: DetailItem;
    var episodes: [DetailItem];
    @State private var progressString: String = "";
    
    init(item: ResumeItem) {
        self.item = item;
        self.fullItem = DetailItem();
        self.episodes = [];
    }
    
    func loadData() {
        let url = "/Users/\(globalData.user?.user_id ?? "")/Items/\(item.Id)"
        
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
                    dump(json)
                    fullItem.ProductionYear = json["ProductionYear"].int ?? 0
                    fullItem.Poster = json["ImageTags"]["Primary"].string ?? ""
                    fullItem.PosterBlurHash = json["ImageBlurHashes"]["Primary"][fullItem.Poster].string ?? ""
                    fullItem.Backdrop = json["BackdropImageTags"][0].string ?? ""
                    fullItem.BackdropBlurHash = json["ImageBlurHashes"]["Backdrop"][fullItem.Backdrop].string ?? ""
                    fullItem.Name = json["Name"].string ?? ""
                    fullItem.Type = json["Type"].string ?? ""
                    fullItem.IndexNumber = json["IndexNumber"].int ?? nil
                    fullItem.Id = json["Id"].string ?? ""
                    fullItem.SeasonId = json["SeasonId"].string ?? nil
                    fullItem.SeriesId = json["Id"].string ?? nil
                    fullItem.Overview = json["Overview"].string ?? ""
                    fullItem.Tagline = json["Taglines"][0].string ?? ""
                    fullItem.SeriesName = json["SeriesName"].string ?? nil
                    fullItem.ParentId = json["ParentId"].string ?? ""
                    //People
                    fullItem.Directors = []
                    fullItem.Studios = []
                    fullItem.Writers = []
                    fullItem.Cast = []
                    fullItem.Genres = []
                    
                    for (_,person):(String, JSON) in json["People"] {
                        if(person["Type"].stringValue == "Director") {
                            fullItem.Directors.append(person["Name"].string ?? "");
                        } else if(person["Type"].stringValue == "Writer") {
                            fullItem.Writers.append(person["Name"].string ?? "");
                        } else if(person["Type"].stringValue == "Actor") {
                            let cast = CastMember();
                            cast.Name = person["Name"].string ?? "";
                            cast.Id = person["Id"].string ?? "";
                            let imageTag = person["PrimaryImageTag"].string ?? "";
                            cast.ImageBlurHash = person["ImageBlurHashes"]["Primary"][imageTag].string ?? "";
                            cast.Role = person["Role"].string ?? "";
                            cast.Image = URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(cast.Id)/Images/Primary?fillHeight=744&fillWidth=496&quality=96&tag=\(imageTag)")!
                            fullItem.Cast.append(cast);
                        }
                    }
                    
                    let url2 = "/Shows/\(fullItem.SeriesId ?? "")/Episodes?SeasonId=\(fullItem.SeasonId ?? "")&UserId=\(globalData.user?.user_id ?? "")&Fields=ItemCounts%2CPrimaryImageAspectRatio%2CBasicSyncInfo%2CCanDelete%2CMediaSourceCount"
                    
                    let request2 = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + url2)
                    request2.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                    request2.contentType = "application/json"
                    request2.acceptType = "application/json"
                    
                    request2.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                        switch result {
                        case .success(let response):
                            let body = response.body
                            do {
                                let json = try JSON(data: body)
                                for (_,episode):(String, JSON) in json["Items"] {
                                    dump(episode)
                                }
                                _isLoading.wrappedValue = false;
                            } catch {
                                
                            }
                            break
                        case .failure(let error):
                            debugPrint(error)
                            break
                        }
                    }
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    var isPortrait: Bool {
        let result = verticalSizeClass == .regular && horizontalSizeClass == .compact
        return result
    }
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            VStack(alignment:.leading) {
                if(!isLoading) {
                    if(isPortrait) {
                        GeometryReader { geometry in
                            VStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Backdrop?maxWidth=3840&quality=90&tag=\(fullItem.Backdrop)")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (fullItem.BackdropBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.BackdropBlurHash), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    }
                                    
                                    .opacity(0.4)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    .shadow(radius: 5)
                                    .overlay(
                                        HStack() {
                                            WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Primary?fillWidth=300&fillHeight=450&quality=90&tag=\(fullItem.Poster)")!)
                                                .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                                .placeholder {
                                                    Image(uiImage: UIImage(blurHash: (fullItem.PosterBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.PosterBlurHash), size: CGSize(width: 32, height: 32))!)
                                                        .resizable()
                                                        .frame(width: 120, height: 180)
                                                        .cornerRadius(10)
                                                }.aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 180)
                                                .cornerRadius(10)
                                            VStack(alignment: .leading) {
                                                Spacer()
                                                Text(fullItem.Name).font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .offset(y: -4)
                                                HStack() {
                                                    Text(String(fullItem.ProductionYear)).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    Text(fullItem.Runtime).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    if(fullItem.OfficialRating != "") {
                                                        Text(fullItem.OfficialRating).font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 2)
                                                                    .stroke(Color.secondary, lineWidth: 1)
                                                            )
                                                    }
                                                    if(fullItem.CommunityRating != "") {
                                                        HStack() {
                                                            Image(systemName: "star").foregroundColor(.secondary)
                                                            Text(fullItem.CommunityRating).font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .offset(x: -7, y: 0.7)
                                                        }
                                                    }
                                                }
                                                
                                            }.offset(x: 0, y: -46)
                                        }.offset(x: 16, y: 40)
                                        , alignment: .bottomLeading)
                                VStack(alignment: .leading) {
                                    ScrollView() {
                                        VStack(alignment: .leading) {
                                            if(fullItem.Tagline != "") {
                                                Text(fullItem.Tagline).font(.body).italic().padding(.top, 7).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing,16)
                                            }
                                            Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16).padding(.trailing,16)
                                            if(fullItem.Cast.count != 0) {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    VStack() {
                                                        Spacer().frame(height: 8);
                                                        HStack() {
                                                            Spacer().frame(width: 16)
                                                            ForEach(fullItem.Cast, id: \.Id) { cast in
                                                                NavigationLink(destination: LibraryView(extraParams: "&PersonIds=\(cast.Id)", title: cast.Name)) {
                                                                    VStack() {
                                                                        WebImage(url: cast.Image)
                                                                            .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                                                            .placeholder {
                                                                                Image(uiImage: UIImage(blurHash: (cast.ImageBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : cast.ImageBlurHash), size: CGSize(width: 32, height: 32))!)
                                                                                    .resizable()
                                                                                    .aspectRatio(contentMode: .fill)
                                                                                    .frame(width: 100, height: 100)
                                                                                    .cornerRadius(10)
                                                                            }
                                                                            .aspectRatio(contentMode: .fill)
                                                                            .frame(width: 100, height: 100)
                                                                            .cornerRadius(10).shadow(radius: 6)
                                                                        Text(cast.Name).font(.footnote).fontWeight(.regular).lineLimit(1).frame(width: 100).foregroundColor(Color.primary)
                                                                        if(cast.Role != "") {
                                                                            Text(cast.Role).font(.caption).fontWeight(.medium).lineLimit(1).foregroundColor(Color.secondary).frame(width: 100)
                                                                        }
                                                                    }
                                                                }
                                                                Spacer().frame(width: 10)
                                                            }
                                                            Spacer().frame(width: 16)
                                                        }
                                                    }
                                                }.padding(.top, -3)
                                            }
                                            if(fullItem.Directors.count != 0) {
                                                HStack() {
                                                    Text("Directors:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Directors.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing,16)
                                            }
                                            if(fullItem.Writers.count != 0) {
                                                HStack() {
                                                    Text("Writers:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Writers.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing,16)
                                            }
                                            if(fullItem.Studios.count != 0) {
                                                HStack() {
                                                    Text("Studios:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Studios.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing,16)
                                            }
                                            Spacer().frame(height: 3)
                                        }
                                    }
                                }.padding(EdgeInsets(top: 24, leading: 0, bottom: 0, trailing: 0))
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(fullItem.Name)
        }.onAppear(perform: loadData)
    }
}
