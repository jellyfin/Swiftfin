//
//  EpisodeItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/13/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import SDWebImageSwiftUI

struct EpisodeItemView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var isLoading: Bool = true;
    var item: ResumeItem;
    @EnvironmentObject var orientationInfo: OrientationInfo
    var fullItem: DetailItem;
    @State private var playing: Bool = false;

    @State private var progressString: String = "";
    @State private var viewDidLoad: Bool = false;
    
    @State private var watched: Bool = false {
        didSet {
            if(watched == true) {
                let date = Date()
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/PlayedItems/\(fullItem.Id)?DatePlayed=\(formatter.string(from: date).replacingOccurrences(of: ":", with: "%3A"))")
                request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                request.contentType = "application/json"
                request.acceptType = "application/json"
                
                request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                }
            } else {
                let request = RestRequest(method: .delete, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/PlayedItems/\(fullItem.Id)")
                request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                request.contentType = "application/json"
                request.acceptType = "application/json"
                
                request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                }
            }
        }
    };
    
    @State private var favorite: Bool = false {
        didSet {
            if(favorite == true) {
                let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/FavoriteItems/\(fullItem.Id)")
                request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                request.contentType = "application/json"
                request.acceptType = "application/json"
                
                request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                }
            } else {
                let request = RestRequest(method: .delete, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/FavoriteItems/\(fullItem.Id)")
                request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
                request.contentType = "application/json"
                request.acceptType = "application/json"
                
                request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
                }
            }
        }
    };
    
    init(item: ResumeItem) {
        self.item = item;
        fullItem = DetailItem();
    }
    
    func loadData() {
        if(_viewDidLoad.wrappedValue == true) {
            return
        }
        _viewDidLoad.wrappedValue = true;
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
                    fullItem.Poster = json["SeriesPrimaryImageTag"].string ?? ""
                    fullItem.PosterBlurHash = json["ImageBlurHashes"]["Primary"][fullItem.Poster].string ?? ""
                    fullItem.Backdrop = json["ParentBackdropImageTags"][0].string ?? ""
                    fullItem.BackdropBlurHash = json["ImageBlurHashes"]["Backdrop"][fullItem.Backdrop].string ?? ""
                    fullItem.Name = json["Name"].string ?? ""
                    fullItem.Type = json["Type"].string ?? ""
                    fullItem.IndexNumber = json["IndexNumber"].int ?? nil
                    fullItem.Id = json["Id"].string ?? ""
                    fullItem.ParentIndexNumber = json["ParentIndexNumber"].int ?? nil
                    fullItem.SeasonId = json["SeasonId"].string ?? nil
                    fullItem.SeriesId = json["SeriesId"].string ?? nil
                    fullItem.Overview = json["Overview"].string ?? ""
                    fullItem.Tagline = json["Taglines"][0].string ?? ""
                    fullItem.SeriesName = json["SeriesName"].string ?? nil
                    fullItem.Progress = Double(json["UserData"]["PlaybackPositionTicks"].int ?? 0)
                    fullItem.OfficialRating = json["OfficialRating"].string ?? "PG-13"
                    fullItem.Watched = json["UserData"]["Played"].bool ?? false;
                    fullItem.CommunityRating = String(json["CommunityRating"].float ?? 0.0);
                    fullItem.CriticRating = String(json["CriticRating"].int ?? 0);
                    fullItem.ParentId = json["ParentId"].string ?? ""
                    fullItem.ParentBackdropItemId = json["ParentBackdropItemId"].string ?? ""
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
                            cast.Image = URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(cast.Id)/Images/Primary?maxHeight=250&quality=85&tag=\(imageTag)")!
                            fullItem.Cast.append(cast);
                        }
                    }
                    
                    //Studios
                    for (_,studio):(String, JSON) in json["Studios"] {
                        fullItem.Studios.append(studio["Name"].string ?? "");
                    }
                    
                    //Genres
                    for (_,genre):(String, JSON) in json["GenreItems"] {
                        let tmpGenre = IVGenre()
                        tmpGenre.Id = genre["Id"].string ?? "";
                        tmpGenre.Name = genre["Name"].string ?? "";
                        fullItem.Genres.append(tmpGenre);
                    }
                    
                    _watched.wrappedValue = fullItem.Watched
                    _favorite.wrappedValue = json["UserData"]["IsFavorite"].bool ?? false;
                    
                    //Process runtime
                    let seconds: Int = ((json["RunTimeTicks"].int ?? 0)/10000000)
                    fullItem.RuntimeTicks = json["RunTimeTicks"].int ?? 0;
                    let hours = (seconds/3600)
                    let minutes = ((seconds - (hours * 3600))/60)
                    if(hours != 0) {
                        fullItem.Runtime = "\(hours):\(String(minutes).leftPad(toWidth: 2, withString: "0"))"
                    } else {
                        fullItem.Runtime = "\(String(minutes).leftPad(toWidth: 2, withString: "0"))m"
                    }
                    
                    if(fullItem.Progress != 0) {
                        let remainingSecs = (Double(json["RunTimeTicks"].int ?? 0) - fullItem.Progress)/10000000
                        let proghours = Int(remainingSecs/3600)
                        let progminutes = Int((Int(remainingSecs) - (proghours * 3600))/60)
                        if(proghours != 0) {
                            _progressString.wrappedValue = "\(proghours):\(String(progminutes).leftPad(toWidth: 2, withString: "0"))"
                        } else {
                            _progressString.wrappedValue = "\(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
                        }
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
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            VStack(alignment:.leading) {
                if(!isLoading) {
                    if(orientationInfo.orientation == .portrait) {
                        GeometryReader { geometry in
                            VStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.ParentBackdropItemId)/Images/Backdrop?maxWidth=450&quality=90&tag=\(fullItem.Backdrop)")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (fullItem.BackdropBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.BackdropBlurHash), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: UIDevice.current.userInterfaceIdiom == .pad ? 350 : (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    }
                                    
                                    .opacity(0.3)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: UIDevice.current.userInterfaceIdiom == .pad ? 350 : (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                    .shadow(radius: 5)
                                    .overlay(
                                        HStack() {
                                            WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)")!)
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
                                                    if(fullItem.CommunityRating != "0") {
                                                        HStack() {
                                                            Image(systemName: "star").foregroundColor(.secondary)
                                                            Text(fullItem.CommunityRating).font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .offset(x: -7, y: 0.7)
                                                        }
                                                    }
                                                }.frame(maxWidth: .infinity, alignment: .leading)
                                            }.frame(maxWidth: .infinity, alignment: .leading).offset(x: 0, y: UIDevice.current.userInterfaceIdiom == .pad ? -98 : -46).padding(.trailing, 16)
                                        }.offset(x: 16, y: UIDevice.current.userInterfaceIdiom == .pad ? 135 : 40)
                                        , alignment: .bottomLeading)
                                VStack(alignment: .leading) {
                                    HStack() {
                                        //Play button
                                        NavigationLink(destination: VideoPlayerViewRefactored()) {
                                            HStack() {
                                                Text(fullItem.Progress == 0 ? "Play" : "\(progressString) left").foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                                                Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                                            }
                                            .frame(width: 120, height: 35)
                                            .background(Color(red: 172/255, green: 92/255, blue: 195/255))
                                            .cornerRadius(10)
                                        }
                                        Spacer()
                                        HStack() {
                                            Button() {
                                                favorite.toggle()
                                            } label: {
                                                if(!favorite) {
                                                    Image(systemName: "heart").foregroundColor(Color.primary).font(.system(size: 20))
                                                } else {
                                                    Image(systemName: "heart.fill").foregroundColor(Color(UIColor.systemRed)).font(.system(size: 20))
                                                }
                                            }
                                            Button() {
                                                watched.toggle()
                                            } label: {
                                                if(watched) {
                                                    Image(systemName: "checkmark.rectangle.fill").foregroundColor(Color.primary).font(.system(size: 20))
                                                } else {
                                                    Image(systemName: "xmark.rectangle").foregroundColor(Color.primary).font(.system(size: 20))
                                                }
                                            }
                                        }
                                    }.padding(.leading, 16).padding(.trailing,16)
                                    ScrollView() {
                                        VStack(alignment: .leading) {
                                            if(fullItem.Tagline != "") {
                                                Text(fullItem.Tagline).font(.body).italic().padding(.top, 7).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing,16)
                                            }
                                            Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16).padding(.trailing,16)
                                            if(fullItem.Genres.count != 0) {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack() {
                                                        Text("Genres:").font(.callout).fontWeight(.semibold)
                                                        ForEach(fullItem.Genres, id: \.Id) {genre in
                                                            NavigationLink(destination: LibraryView(extraParams: "&Genres=\(genre.Name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")", title: genre.Name)) {
                                                                Text(genre.Name).font(.footnote)
                                                            }
                                                        }
                                                    }.padding(.leading, 16).padding(.trailing,16)
                                                }
                                            }
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
                                                                                Image(uiImage: UIImage(blurHash: (cast.ImageBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : cast.ImageBlurHash), size: CGSize(width: 4, height: 4))!)
                                                                                    .resizable()
                                                                                    .aspectRatio(contentMode: .fill)
                                                                                    .frame(width: 70, height: 70)
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
                                }.padding(EdgeInsets(top: UIDevice.current.userInterfaceIdiom == .pad ? 54 : 24, leading: 0, bottom: 0, trailing: 0))
                            }
                        }
                    } else {
                        GeometryReader { geometry in
                            ZStack() {
                                WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.ParentBackdropItemId)/Images/Backdrop?maxWidth=750&quality=90&tag=\(fullItem.Backdrop)")!)
                                    .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                    .placeholder {
                                        Image(uiImage: UIImage(blurHash: (fullItem.BackdropBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.BackdropBlurHash), size: CGSize(width: 32, height: 32))!)
                                            .resizable()
                                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                                    }
                                    
                                    .opacity(0.3)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                                    .edgesIgnoringSafeArea(.all)
                                HStack() {
                                    VStack() {
                                        WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.SeriesId ?? "")/Images/Primary?maxWidth=250&quality=90&tag=\(fullItem.Poster)")!)
                                            .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                            .placeholder {
                                                Image(uiImage: UIImage(blurHash: (fullItem.PosterBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.PosterBlurHash), size: CGSize(width: 32, height: 32))!)
                                                    .resizable()
                                                    .frame(width: 120, height: 180)
                                            }
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                        Spacer().frame(height: 15)
                                        NavigationLink(destination: VideoPlayerViewRefactored()) {
                                            HStack() {
                                                Text(fullItem.Progress == 0 ? "Play" : "\(progressString) left").foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                                                Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                                            }
                                            .frame(width: 120, height: 35)
                                            .background(Color(red: 172/255, green: 92/255, blue: 195/255))
                                            .cornerRadius(10)
                                        }
                                        Spacer()
                                    }
                                    ScrollView() {
                                        VStack(alignment: .leading) {
                                            HStack() {
                                                VStack(alignment: .leading) {
                                                    Text(fullItem.Name).font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .offset(x: 14, y: 0)
                                                    Spacer().frame(height: 1)
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
                                                        if(fullItem.CommunityRating != "0") {
                                                            HStack() {
                                                                Image(systemName: "star").foregroundColor(.secondary)
                                                                Text(fullItem.CommunityRating).font(.subheadline)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.secondary)
                                                                    .lineLimit(1)
                                                                    .offset(x: -7, y: 0.7)
                                                            }
                                                        }
                                                        Spacer()
                                                    }.frame(maxWidth: .infinity)
                                                    .offset(x: 14)
                                                }.frame(maxWidth: .infinity)
                                                Spacer()
                                                HStack() {
                                                    Button() {
                                                        favorite.toggle()
                                                    } label: {
                                                        if(!favorite) {
                                                            Image(systemName: "heart").foregroundColor(Color.primary).font(.system(size: 20))
                                                        } else {
                                                            Image(systemName: "heart.fill").foregroundColor(Color(UIColor.systemRed)).font(.system(size: 20))
                                                        }
                                                    }
                                                    Button() {
                                                        watched.toggle()
                                                    } label: {
                                                        if(watched) {
                                                            Image(systemName: "checkmark.rectangle.fill").foregroundColor(Color.primary).font(.system(size: 20))
                                                        } else {
                                                            Image(systemName: "xmark.rectangle").foregroundColor(Color.primary).font(.system(size: 20))
                                                        }
                                                    }
                                                }
                                            }.padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            if(fullItem.Tagline != "") {
                                                Text(fullItem.Tagline).font(.body).italic().padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            }
                                            Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            if(fullItem.Genres.count != 0) {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack() {
                                                        Text("Genres:").font(.callout).fontWeight(.semibold)
                                                        ForEach(fullItem.Genres, id: \.Id) {genre in
                                                            NavigationLink(destination: LibraryView(extraParams: "&Genres=\(genre.Name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")", title: genre.Name)) {
                                                                Text(genre.Name).font(.footnote)
                                                            }
                                                        }
                                                    }.padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                                }
                                            }
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
                                                            Spacer().frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                                        }
                                                    }
                                                }.padding(.top, -3)
                                            }
                                            if(fullItem.Directors.count != 0) {
                                                HStack() {
                                                    Text("Directors:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Directors.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            }
                                            if(fullItem.Writers.count != 0) {
                                                HStack() {
                                                    Text("Writers:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Writers.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            }
                                            if(fullItem.Studios.count != 0) {
                                                HStack() {
                                                    Text("Studios:").font(.callout).fontWeight(.semibold)
                                                    Text(fullItem.Studios.joined(separator: ", ")).font(.footnote).lineLimit(1).foregroundColor(Color.secondary)
                                                }.padding(.leading, 16).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                            }
                                            Spacer().frame(height: 100);
                                        }.frame(maxHeight: .infinity)
                                    }
                                }.padding(.top, 16).padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55).edgesIgnoringSafeArea(.leading)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("\(fullItem.Name) - S\(String(fullItem.ParentIndexNumber ?? 0)):E\(String(fullItem.IndexNumber ?? 0)) - \(fullItem.SeriesName ?? "")")
        }.onAppear(perform: loadData)
        .supportedOrientations(.allButUpsideDown)
        .overrideViewPreference(.unspecified)
        .preferredColorScheme(.none)
        .prefersHomeIndicatorAutoHidden(false)
    }
}
