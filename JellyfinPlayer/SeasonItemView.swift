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
    @EnvironmentObject var orientationInfo: OrientationInfo
    @State private var isLoading: Bool = true;
    var item: ResumeItem;
    var fullItem: DetailItem;
    @State var episodes: [DetailItem] = [];
    @State private var progressString: String = "";
    @State private var hasAppearedOnce: Bool = false;
    init(item: ResumeItem) {
        self.item = item;
        self.fullItem = DetailItem();
    }
    
    func loadData() {
        if(hasAppearedOnce) {
            return;
        }
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
                    fullItem.ProductionYear = json["ProductionYear"].int ?? 0
                    fullItem.Poster = json["ImageTags"]["Primary"].string ?? ""
                    fullItem.PosterBlurHash = json["ImageBlurHashes"]["Primary"][fullItem.Poster].string ?? ""
                    fullItem.Backdrop = json["BackdropImageTags"][0].string ?? ""
                    fullItem.BackdropBlurHash = json["ImageBlurHashes"]["Backdrop"][fullItem.Backdrop].string ?? ""
                    fullItem.Name = json["Name"].string ?? ""
                    fullItem.Type = json["Type"].string ?? ""
                    fullItem.IndexNumber = json["IndexNumber"].int ?? nil
                    fullItem.SeriesId = json["ParentId"].string ?? nil
                    fullItem.Id = item.Id
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
                            cast.Image = URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(cast.Id)/Images/Primary?maxWidth=2000&quality=90&tag=\(imageTag)")!
                            fullItem.Cast.append(cast);
                        }
                    }
                    
                    let url2 = "/Shows/\(fullItem.SeriesId ?? "")/Episodes?SeasonId=\(item.Id)&UserId=\(globalData.user?.user_id ?? "")&Fields=ItemCounts%2CPrimaryImageAspectRatio%2CBasicSyncInfo%2CCanDelete%2CMediaSourceCount%2COverview"
                    let request2 = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + url2)
                    request2.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                    request2.contentType = "application/json"
                    request2.acceptType = "application/json"
                    
                    request2.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                        switch result {
                        case .success(let response):
                            let body = response.body
                            do {
                                let jsonroot = try JSON(data: body)
                                for (_,json):(String, JSON) in jsonroot["Items"] {
                                    let episode = DetailItem()
                                    episode.ProductionYear = json["ProductionYear"].int ?? 0
                                    episode.Poster = json["ImageTags"]["Primary"].string ?? ""
                                    episode.PosterBlurHash = json["ImageBlurHashes"]["Primary"][fullItem.Poster].string ?? ""
                                    episode.Backdrop = json["BackdropImageTags"][0].string ?? ""
                                    episode.BackdropBlurHash = json["ImageBlurHashes"]["Backdrop"][fullItem.Backdrop].string ?? ""
                                    episode.Name = json["Name"].string ?? ""
                                    episode.Type = "Episode"
                                    episode.IndexNumber = json["IndexNumber"].int ?? nil
                                    episode.Id = json["Id"].string ?? ""
                                    episode.ParentIndexNumber = json["ParentIndexNumber"].int ?? nil
                                    episode.SeasonId = json["SeasonId"].string ?? nil
                                    episode.SeriesId = json["SeriesId"].string ?? nil
                                    episode.Overview = json["Overview"].string ?? ""
                                    episode.SeriesName = json["SeriesName"].string ?? nil
                                    episode.Progress = Double(json["UserData"]["PlaybackPositionTicks"].int ?? 0)
                                    episode.OfficialRating = json["OfficialRating"].string ?? "PG-13"
                                    episode.Watched = json["UserData"]["Played"].bool ?? false;
                                    episode.ParentId = episode.SeasonId ?? "";
                                    episode.CommunityRating = String(json["CommunityRating"].float ?? 0.0)
                                    
                                    let rI = ResumeItem()
                                    rI.Name = episode.Name;
                                    rI.Id = episode.Id;
                                    rI.IndexNumber = episode.IndexNumber;
                                    rI.ParentIndexNumber = episode.ParentIndexNumber;
                                    rI.Image = episode.Poster;
                                    rI.ImageType = "Primary";
                                    rI.BlurHash = episode.PosterBlurHash;
                                    rI.Type = "Episode";
                                    rI.SeasonId = episode.SeasonId;
                                    rI.SeriesId = episode.SeriesId;
                                    rI.SeriesName = episode.SeriesName;
                                    rI.ProductionYear = episode.ProductionYear;
                                    episode.ResumeItem = rI;
                                    
                                    let seconds: Int = ((json["RunTimeTicks"].int ?? 0)/10000000)
                                    episode.RuntimeTicks = json["RunTimeTicks"].int ?? 0;
                                    let hours = (seconds/3600)
                                    let minutes = ((seconds - (hours * 3600))/60)
                                    if(hours != 0) {
                                        episode.Runtime = "\(hours):\(String(minutes).leftPad(toWidth: 2, withString: "0"))"
                                    } else {
                                        episode.Runtime = "\(String(minutes).leftPad(toWidth: 2, withString: "0"))m"
                                    }
                                    
                                    if(episode.Progress != 0) {
                                        let remainingSecs = (Double(json["RunTimeTicks"].int ?? 0) - episode.Progress)/10000000
                                        let proghours = Int(remainingSecs/3600)
                                        let progminutes = Int((Int(remainingSecs) - (proghours * 3600))/60)
                                        if(proghours != 0) {
                                            episode.ProgressStr = "\(proghours):\(String(progminutes).leftPad(toWidth: 2, withString: "0"))"
                                        } else {
                                            episode.ProgressStr = "\(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
                                        }
                                    }
                                    
                                    _episodes.wrappedValue.append(episode)
                                }
                                _isLoading.wrappedValue = false;
                                _hasAppearedOnce.wrappedValue = true;
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
                    if(orientationInfo.orientation == .portrait) {
                        GeometryReader { geometry in
                            VStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Backdrop?maxWidth=750&quality=80&tag=\(item.SeasonImage ?? "")")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (item.SeasonImageBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.SeasonImageBlurHash ?? ""), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    }
                                    
                                    .opacity(0.4)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    .shadow(radius: 5)
                                    .overlay(
                                        HStack() {
                                            WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)")!)
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
                                                Text(fullItem.Name).font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .offset(y: -4)
                                                if(fullItem.ProductionYear != 0) {
                                                    Text(String(fullItem.ProductionYear)).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }.offset(x: 0, y: 45)
                                        }.offset(x: 16, y: 22)
                                        , alignment: .bottomLeading)
                                VStack(alignment: .leading) {
                                    ScrollView() {
                                        VStack(alignment: .leading) {
                                            if(fullItem.Tagline != "") {
                                                Text(fullItem.Tagline).font(.body).italic().padding(.top, 7).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing,16)
                                            }
                                            Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16).padding(.trailing,16)
                                            ForEach(episodes, id: \.Id) { episode in
                                                NavigationLink(destination: ItemView(item: episode.ResumeItem ?? ResumeItem())) {
                                                    HStack() {
                                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(episode.Id)/Images/Primary?maxWidth=300&quality=90&tag=\(episode.Poster)")!)
                                                            .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                                            .placeholder {
                                                                Image(uiImage: UIImage(blurHash: (episode.PosterBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.PosterBlurHash), size: CGSize(width: 32, height: 32))!)
                                                                    .resizable()
                                                                    .frame(width: 150, height: 90)
                                                                    .cornerRadius(10)
                                                            }.aspectRatio(contentMode: .fill)
                                                            .shadow(radius: 5)
                                                            .frame(width: 150, height: 90)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10, style: .circular)
                                                                    .fill(Color(red: 172/255, green: 92/255, blue: 195/255).opacity(0.4))
                                                                    .frame(width: CGFloat((episode.Progress/Double(episode.RuntimeTicks))*150), height: 90)
                                                                .padding(0), alignment: .bottomLeading
                                                            )
                                                        VStack(alignment: .leading) {
                                                            HStack() {
                                                                Text(episode.Name).font(.subheadline)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.primary)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                                    .lineLimit(1)
                                                                Spacer()
                                                                Text(episode.Runtime).font(.subheadline)
                                                                    .fontWeight(.medium)
                                                                    .foregroundColor(.secondary)
                                                                    .lineLimit(1)
                                                            }
                                                            Spacer()
                                                            Text(episode.Overview).font(.footnote).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                                            Spacer()
                                                        }.padding(.trailing, 20).offset(y: 2)
                                                    }.offset(x: 12, y: 0)
                                                }
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
                    } else {
                        GeometryReader { geometry in
                            ZStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Backdrop?maxWidth=750&quality=80&tag=\(item.SeasonImage ?? "")")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (item.SeasonImageBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.SeasonImageBlurHash ?? ""), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    }
                                    
                                    .opacity(0.4)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    .edgesIgnoringSafeArea(.all)
                                HStack() {
                                    VStack(alignment: .leading) {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)")!)
                                            .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (fullItem.PosterBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.PosterBlurHash), size: CGSize(width: 32, height: 32))!)
                                                    .resizable()
                                                    .frame(width: 120, height: 180)
                                                    .cornerRadius(10)
                                            }.aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(10)
                                        Spacer().frame(height: 4)
                                        if(fullItem.ProductionYear != 0) {
                                            Text(String(fullItem.ProductionYear)).font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    ScrollView() {
                                        VStack(alignment: .leading) {
                                            if(fullItem.Tagline != "") {
                                                Text(fullItem.Tagline).font(.body).italic().padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing,16)
                                            }
                                            Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16).padding(.trailing,16)
                                            ForEach(episodes, id: \.Id) { episode in
                                                NavigationLink(destination: ItemView(item: episode.ResumeItem ?? ResumeItem())) {
                                                    HStack() {
                                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(episode.Id)/Images/Primary?maxWidth=300&quality=90&tag=\(episode.Poster)")!)
                                                            .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                                            .placeholder {
                                                                Image(uiImage: UIImage(blurHash: (episode.PosterBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.PosterBlurHash), size: CGSize(width: 32, height: 32))!)
                                                                    .resizable()
                                                                    .frame(width: 150, height: 90)
                                                                    .cornerRadius(10)
                                                            }.aspectRatio(contentMode: .fill)
                                                            .shadow(radius: 5)
                                                            .frame(width: 150, height: 90)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10, style: .circular)
                                                                    .fill(Color(red: 172/255, green: 92/255, blue: 195/255).opacity(0.4))
                                                                    .frame(width: CGFloat((episode.Progress/Double(episode.RuntimeTicks))*150), height: 90)
                                                                .padding(0), alignment: .bottomLeading
                                                            )
                                                        VStack(alignment: .leading) {
                                                            HStack() {
                                                                Text(episode.Name).font(.subheadline)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.primary)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                                    .lineLimit(1)
                                                                Text(episode.Runtime).font(.subheadline)
                                                                    .fontWeight(.medium)
                                                                    .foregroundColor(.secondary)
                                                                    .lineLimit(1)
                                                                if(episode.OfficialRating != "") {
                                                                    Text(episode.OfficialRating).font(.subheadline)
                                                                        .fontWeight(.medium)
                                                                        .foregroundColor(.secondary)
                                                                        .lineLimit(1)
                                                                        .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 2)
                                                                                .stroke(Color.secondary, lineWidth: 1)
                                                                        )
                                                                }
                                                                if(episode.CommunityRating != "") {
                                                                    HStack() {
                                                                        Image(systemName: "star").foregroundColor(.secondary)
                                                                        Text(episode.CommunityRating).font(.subheadline)
                                                                            .fontWeight(.semibold)
                                                                            .foregroundColor(.secondary)
                                                                            .lineLimit(1)
                                                                            .offset(x: -6, y: 0)
                                                                    }
                                                                }
                                                                Spacer()
                                                            }
                                                            Spacer()
                                                            Text(episode.Overview).font(.footnote).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                                            Spacer()
                                                        }.padding(.trailing, 20).offset(y: 2)
                                                    }.offset(x: 12, y: 0)
                                                }
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
                                            Spacer().frame(height: 195);
                                        }.frame(maxHeight: .infinity)
                                    }.padding(.trailing, 55)
                                }.padding(.top, 12)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(item.Name)
        }.onAppear(perform: loadData)
    }
}
