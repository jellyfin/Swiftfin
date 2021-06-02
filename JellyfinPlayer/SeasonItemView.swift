//
//  SeasonItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/13/21.
//

import NukeUI
import SwiftUI
import SwiftyJSON
import SwiftyRequest

struct SeasonItemView: View {
    @EnvironmentObject
    var globalData: GlobalData
    @EnvironmentObject
    var orientationInfo: OrientationInfo
    @State
    private var isLoading: Bool = true
    var item: ResumeItem
    @State
    var fullItem = DetailItem()
    @State
    var episodes: [DetailItem] = []
    @State
    private var progressString: String = ""
    @State
    private var hasAppearedOnce: Bool = false

    init(item: ResumeItem) {
        self.item = item
    }

    func loadData() {
        if hasAppearedOnce {
            return
        }
        let url = "/Users/\(globalData.user?.user_id ?? "")/Items/\(item.Id)"

        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + url)
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"

        request.responseData { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case let .success(response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    let responseItem = DetailItem()
                    responseItem.ProductionYear = json["ProductionYear"].int ?? 0
                    responseItem.Poster = json["ImageTags"]["Primary"].string ?? ""
                    responseItem.PosterBlurHash = json["ImageBlurHashes"]["Primary"][responseItem.Poster].string ?? ""
                    responseItem.Backdrop = json["BackdropImageTags"][0].string ?? ""
                    responseItem.BackdropBlurHash = json["ImageBlurHashes"]["Backdrop"][responseItem.Backdrop].string ?? ""
                    responseItem.Name = json["Name"].string ?? ""
                    responseItem.Type = json["Type"].string ?? ""
                    responseItem.IndexNumber = json["IndexNumber"].int ?? nil
                    responseItem.SeriesId = json["ParentId"].string ?? nil
                    responseItem.Id = item.Id
                    responseItem.Overview = json["Overview"].string ?? ""
                    responseItem.Tagline = json["Taglines"][0].string ?? ""
                    responseItem.SeriesName = json["SeriesName"].string ?? nil
                    responseItem.ParentId = json["ParentId"].string ?? ""
                    // People
                    responseItem.Directors = []
                    responseItem.Studios = []
                    responseItem.Writers = []
                    responseItem.Cast = []
                    responseItem.Genres = []

                    for (_, person): (String, JSON) in json["People"] {
                        if person["Type"].stringValue == "Director" {
                            responseItem.Directors.append(person["Name"].string ?? "")
                        } else if person["Type"].stringValue == "Writer" {
                            responseItem.Writers.append(person["Name"].string ?? "")
                        } else if person["Type"].stringValue == "Actor" {
                            let cast = CastMember()
                            cast.Name = person["Name"].string ?? ""
                            cast.Id = person["Id"].string ?? ""
                            let imageTag = person["PrimaryImageTag"].string ?? ""
                            cast.ImageBlurHash = person["ImageBlurHashes"]["Primary"][imageTag].string ?? ""
                            cast.Role = person["Role"].string ?? ""
                            cast
                                .Image =
                                URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(cast.Id)/Images/Primary?maxWidth=2000&quality=90&tag=\(imageTag)")!
                            responseItem.Cast.append(cast)
                        }
                    }

                    _fullItem.wrappedValue = responseItem

                    let url2 =
                        "/Shows/\(fullItem.SeriesId ?? "")/Episodes?SeasonId=\(item.Id)&UserId=\(globalData.user?.user_id ?? "")&Fields=ItemCounts%2CPrimaryImageAspectRatio%2CBasicSyncInfo%2CCanDelete%2CMediaSourceCount%2COverview"
                    let request2 = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + url2)
                    request2.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                    request2.contentType = "application/json"
                    request2.acceptType = "application/json"

                    request2.responseData { (result: Result<RestResponse<Data>, RestError>) in
                        switch result {
                        case let .success(response):
                            let body = response.body
                            do {
                                let jsonroot = try JSON(data: body)
                                for (_, json): (String, JSON) in jsonroot["Items"] {
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
                                    episode.Watched = json["UserData"]["Played"].bool ?? false
                                    episode.ParentId = episode.SeasonId ?? ""
                                    episode.CommunityRating = String(json["CommunityRating"].float ?? 0.0)

                                    var rI = ResumeItem()
                                    rI.Name = episode.Name
                                    rI.Id = episode.Id
                                    rI.IndexNumber = episode.IndexNumber
                                    rI.ParentIndexNumber = episode.ParentIndexNumber
                                    rI.Image = episode.Poster
                                    rI.ImageType = "Primary"
                                    rI.BlurHash = episode.PosterBlurHash
                                    rI.Type = "Episode"
                                    rI.SeasonId = episode.SeasonId
                                    rI.SeriesId = episode.SeriesId
                                    rI.SeriesName = episode.SeriesName
                                    rI.ProductionYear = episode.ProductionYear
                                    episode.ResumeItem = rI

                                    let seconds: Int = ((json["RunTimeTicks"].int ?? 0) / 10_000_000)
                                    episode.RuntimeTicks = json["RunTimeTicks"].int ?? 0
                                    let hours = (seconds / 3600)
                                    let minutes = ((seconds - (hours * 3600)) / 60)
                                    if hours != 0 {
                                        episode.Runtime = "\(hours):\(String(minutes).leftPad(toWidth: 2, withString: "0"))"
                                    } else {
                                        episode.Runtime = "\(String(minutes).leftPad(toWidth: 2, withString: "0"))m"
                                    }

                                    if episode.Progress != 0 {
                                        let remainingSecs = (Double(json["RunTimeTicks"].int ?? 0) - episode.Progress) / 10_000_000
                                        let proghours = Int(remainingSecs / 3600)
                                        let progminutes = Int((Int(remainingSecs) - (proghours * 3600)) / 60)
                                        if proghours != 0 {
                                            episode.ProgressStr = "\(proghours):\(String(progminutes).leftPad(toWidth: 2, withString: "0"))"
                                        } else {
                                            episode.ProgressStr = "\(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
                                        }
                                    }

                                    _episodes.wrappedValue.append(episode)
                                }
                                _isLoading.wrappedValue = false
                                _hasAppearedOnce.wrappedValue = true
                            } catch {}
                        case let .failure(error):
                            debugPrint(error)
                        }
                    }
                } catch {}
            case let .failure(error):
                debugPrint(error)
            }
        }
    }

    @Environment(\.verticalSizeClass)
    var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass: UserInterfaceSizeClass?

    var isPortrait: Bool {
        let result = verticalSizeClass == .regular && horizontalSizeClass == .compact
        return result
    }

    @ViewBuilder
    var portraitHeaderView: some View {
        if isLoading {
            EmptyView()
        } else {
            LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Backdrop?maxWidth=550&quality=90&tag=\(item.SeasonImage ?? "")"))
                .placeholderAndFailure {
                    Image(uiImage: UIImage(blurHash: item
                            .SeasonImageBlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                            .SeasonImageBlurHash ?? "",
                        size: CGSize(width: 32, height: 32))!)
                        .resizable()
                }
                .contentMode(.aspectFill)
                .opacity(0.4)
                .shadow(radius: 5)
        }
    }

    var portraitHeaderOverlayView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)"))
                .placeholderAndFailure {
                    Image(uiImage: UIImage(blurHash: fullItem
                            .PosterBlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem
                            .PosterBlurHash,
                        size: CGSize(width: 32, height: 32))!)
                        .resizable()
                        .frame(width: 120, height: 180)
                        .cornerRadius(10)
                }
                .contentMode(.aspectFill)
                .frame(width: 120, height: 180)
                .cornerRadius(10)
            VStack(alignment: .leading) {
//                    Text(fullItem.SeriesName ?? "")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .foregroundColor(.primary)
//                        .padding(.bottom, 8)
                Text(fullItem.Name).font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -4)
                if fullItem.ProductionYear != 0 {
                    Text(String(fullItem.ProductionYear)).font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }.padding(.horizontal, 16)
            .padding(.bottom, -22)
    }

    @ViewBuilder
    var innerBody: some View {
        if orientationInfo.orientation == .portrait {
            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitHeaderOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIScreen.main.bounds.width * 0.5625) {
                LazyVStack(alignment: .leading) {
                    Spacer()
                        .frame(height: 22)
                    if fullItem.Tagline != "" {
                        Text(fullItem.Tagline).font(.body).italic().padding(.top, 7)
                            .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                            .padding(.trailing, 16)
                    }
                    Text(fullItem.Overview).font(.footnote).padding(.top, 3)
                        .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                        .padding(.trailing, 16)
                    ForEach(episodes, id: \.Id) { episode in
                        NavigationLink(destination: ItemView(item: episode.ResumeItem ?? ResumeItem())) {
                            HStack {
                                LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(episode.Id)/Images/Primary?maxWidth=300&quality=90&tag=\(episode.Poster)"))
                                    .placeholderAndFailure {
                                        Image(uiImage: UIImage(blurHash: episode
                                                .PosterBlurHash == "" ?
                                                "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem
                                                .PosterBlurHash,
                                            size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: 150, height: 90)
                                            .cornerRadius(10)
                                    }
                                    .contentMode(.aspectFill)
                                    .shadow(radius: 5)
                                    .frame(width: 150, height: 90)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .circular)
                                        .fill(Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255)
                                            .opacity(0.4))
                                        .frame(width: CGFloat((episode.Progress / Double(episode.RuntimeTicks)) *
                                                   150),
                                        height: 90)
                                        .padding(0), alignment: .bottomLeading)
                                VStack(alignment: .leading) {
                                    HStack {
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
                                    Text(episode.Overview).font(.footnote).foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                    Spacer()
                                }.padding(.trailing, 20).offset(y: 2)
                            }.offset(x: 12, y: 0)
                        }
                    }
                    if !fullItem.Directors.isEmpty {
                        HStack {
                            Text("Directors:").font(.callout).fontWeight(.semibold)
                            Text(fullItem.Directors.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                .foregroundColor(Color.secondary)
                        }.padding(.leading, 16).padding(.trailing, 16)
                    }
                    if !fullItem.Writers.isEmpty {
                        HStack {
                            Text("Writers:").font(.callout).fontWeight(.semibold)
                            Text(fullItem.Writers.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                .foregroundColor(Color.secondary)
                        }.padding(.leading, 16).padding(.trailing, 16)
                    }
                    if !fullItem.Studios.isEmpty {
                        HStack {
                            Text("Studios:").font(.callout).fontWeight(.semibold)
                            Text(fullItem.Studios.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                .foregroundColor(Color.secondary)
                        }.padding(.leading, 16).padding(.trailing, 16)
                    }
                    Spacer().frame(height: 3)
                }
            }
        } else {
            GeometryReader { geometry in
                ZStack {
                    LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Backdrop?maxWidth=\(String(Int(geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing)))&quality=80&tag=\(item.SeasonImage ?? "")"))
                        .placeholderAndFailure {
                            Image(uiImage: UIImage(blurHash: item
                                    .SeasonImageBlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                                    .SeasonImageBlurHash ?? "",
                                size: CGSize(width: 32, height: 32))!)
                                .resizable()
                                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets
                                    .trailing,
                                    height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets
                                        .bottom)
                        }
                        .contentMode(.aspectFill)

                        .opacity(0.4)
                        .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                               height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 2)
                    HStack {
                        VStack(alignment: .leading) {
                            LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)"))
                                .placeholderAndFailure {
                                    Image(uiImage: UIImage(blurHash: fullItem
                                            .PosterBlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" :
                                            fullItem.PosterBlurHash,
                                        size: CGSize(width: 32, height: 32))!)
                                        .resizable()
                                        .frame(width: 120, height: 180)
                                        .cornerRadius(10)
                                }
                                .contentMode(.aspectFill)
                                .frame(width: 120, height: 180)
                                .cornerRadius(10)
                            Spacer().frame(height: 4)
                            if fullItem.ProductionYear != 0 {
                                Text(String(fullItem.ProductionYear)).font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                if fullItem.Tagline != "" {
                                    Text(fullItem.Tagline).font(.body).italic().padding(.top, 3)
                                        .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                                        .padding(.trailing, 16)
                                }
                                if fullItem.Overview != "" {
                                    Text(fullItem.Overview).font(.footnote).padding(.top, 3)
                                        .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                                        .padding(.trailing, 16)
                                }
                                ForEach(episodes, id: \.Id) { episode in
                                    NavigationLink(destination: ItemView(item: episode.ResumeItem ?? ResumeItem())) {
                                        HStack {
                                            LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(episode.Id)/Images/Primary?maxWidth=300&quality=90&tag=\(episode.Poster)"))
                                                .placeholderAndFailure {
                                                    Image(uiImage: UIImage(blurHash: episode
                                                            .PosterBlurHash == "" ?
                                                            "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem
                                                            .PosterBlurHash,
                                                        size: CGSize(width: 32, height: 32))!)
                                                        .resizable()
                                                        .frame(width: 150, height: 90)
                                                        .cornerRadius(10)
                                                }
                                                .contentMode(.aspectFill)
                                                .shadow(radius: 5)
                                                .frame(width: 150, height: 90)
                                                .cornerRadius(10)
                                                .overlay(RoundedRectangle(cornerRadius: 10, style: .circular)
                                                    .fill(Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255)
                                                        .opacity(0.4))
                                                    .frame(width: CGFloat((episode.Progress / Double(episode.RuntimeTicks)) *
                                                               150),
                                                    height: 90)
                                                    .padding(0), alignment: .bottomLeading)
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text(episode.Name).font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .lineLimit(1)
                                                    Text(episode.Runtime).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    if episode.OfficialRating != "" {
                                                        Text(episode.OfficialRating).font(.subheadline)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                                            .overlay(RoundedRectangle(cornerRadius: 2)
                                                                .stroke(Color.secondary, lineWidth: 1))
                                                    }
                                                    if episode.CommunityRating != "" {
                                                        HStack {
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
                                                Text(episode.Overview).font(.footnote).foregroundColor(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                                Spacer()
                                            }.padding(.trailing, 20).offset(y: 2)
                                        }.offset(x: 12, y: 0)
                                    }
                                }
                                if !fullItem.Directors.isEmpty {
                                    HStack {
                                        Text("Directors:").font(.callout).fontWeight(.semibold)
                                        Text(fullItem.Directors.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                            .foregroundColor(Color.secondary)
                                    }.padding(.leading, 16).padding(.trailing, 16)
                                }
                                if !fullItem.Writers.isEmpty {
                                    HStack {
                                        Text("Writers:").font(.callout).fontWeight(.semibold)
                                        Text(fullItem.Writers.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                            .foregroundColor(Color.secondary)
                                    }.padding(.leading, 16).padding(.trailing, 16)
                                }
                                if !fullItem.Studios.isEmpty {
                                    HStack {
                                        Text("Studios:").font(.callout).fontWeight(.semibold)
                                        Text(fullItem.Studios.joined(separator: ", ")).font(.footnote).lineLimit(1)
                                            .foregroundColor(Color.secondary)
                                    }.padding(.leading, 16).padding(.trailing, 16)
                                }
                                Spacer().frame(height: 125)
                            }.frame(maxHeight: .infinity)
                        }.padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                    }.padding(.top, 16).padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 0)
                }
            }
        }
    }

    var body: some View {
        LoadingView(isShowing: $isLoading) {
            innerBody
        }
        .onAppear(perform: loadData)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("\(item.Name) - \(item.SeriesName ?? "")")
    }
}
