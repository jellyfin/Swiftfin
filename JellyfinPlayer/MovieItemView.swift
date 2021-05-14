//
//  MovieItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/13/21.
//

import SwiftUI
import SwiftyRequest
import SwiftyJSON
import Introspect
import SDWebImageSwiftUI

class DetailItem: ObservableObject {
    @Published var Name: String = "";
    @Published var Id: String = "";
    @Published var IndexNumber: Int? = nil;
    @Published var ParentIndexNumber: Int? = nil;
    @Published var Poster: String = "";
    @Published var Backdrop: String = ""
    @Published var PosterBlurHash: String = "";
    @Published var BackdropBlurHash: String = "";
    @Published var `Type`: String = "";
    @Published var SeasonId: String? = nil;
    @Published var SeriesId: String? = nil;
    @Published var SeriesName: String? = nil;
    @Published var ItemProgress: Double = 0;
    @Published var ItemBadge: Int? = 0;
    @Published var ProductionYear: Int = 1999;
    @Published var Runtime: String = "";
    @Published var RuntimeTicks: Int = 0;
    @Published var Cast: [CastMember] = [];
    @Published var OfficialRating: String = "";
    @Published var Progress: Double = 0;
    @Published var Watched: Bool = false;
    @Published var Overview: String = "";
    @Published var Tagline: String = "";
}

class CastMember: ObservableObject {
    @Published var Name: String = "";
    @Published var Role: String = "";
    @Published var ImageBlurHash: String = "";
    @Published var Id: String = "";
    @Published var Image: URL = URL(string: "https://example.com")!;
}

struct MovieItemView: View {
    @EnvironmentObject var globalData: GlobalData
    @State private var isLoading: Bool = true;
    var item: ResumeItem;
    var fullItem: DetailItem;
    @State private var playing: Bool = false;
    @State private var vc: PreferenceUIHostingController? = nil;
    @State private var progressString: String = "";
    @State private var watched: Bool = false;
    @State private var favorite: Bool = false;
    
    init(item: ResumeItem) {
        self.item = item;
        self.fullItem = DetailItem();
    }
    
    func lockOrientations() {
        if(_vc.wrappedValue != nil) {
            _vc.wrappedValue?._prefersHomeIndicatorAutoHidden = true;
            _vc.wrappedValue?._orientations = .landscapeRight;
            _vc.wrappedValue?._viewPreference = .dark;
        }
    }
    
    func loadData() {
        if(_vc.wrappedValue != nil) {
            _vc.wrappedValue?._prefersHomeIndicatorAutoHidden = false;
            _vc.wrappedValue?._orientations = .allButUpsideDown;
            _vc.wrappedValue?._viewPreference = .unspecified;
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
        if(playing) {
            PlayerDemo(item: fullItem, playing: $playing).onAppear(perform: lockOrientations)
        } else {
            LoadingView(isShowing: $isLoading) {
                ScrollView() {
                    VStack(alignment:.leading) {
                        if(!isLoading) {
                            GeometryReader { geometry in
                                VStack() {
                                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(fullItem.Id)/Images/Backdrop?maxWidth=3840&quality=90&tag=\(fullItem.Backdrop)")!)
                                        .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                        .placeholder {
                                            Image(uiImage: UIImage(blurHash: (fullItem.BackdropBlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : fullItem.BackdropBlurHash), size: CGSize(width: 32, height: 32))!)
                                                .resizable()
                                                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing) * 0.5625)
                                        }
                                        .opacity(0.3)
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
                                                    }
                                                    .frame(width: 120, height: 180)
                                                    .cornerRadius(10)
                                                VStack(alignment: .leading) {
                                                    Spacer()
                                                    Text(fullItem.Name).font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
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
                                                    
                                                }.offset(x: 0, y: -46)
                                            }.offset(x: 16, y: 40)
                                            , alignment: .bottomLeading)
                                    VStack(alignment: .leading) {
                                        HStack() {
                                            //Play button
                                            Button() {
                                                playing = true;
                                            } label: {
                                                HStack() {
                                                    Text(fullItem.Progress == 0 ? "Play" : "\(progressString) left").foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                                                    Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                                                }
                                                .frame(width: 120, height: 35)
                                                .background(Color(UIColor.systemBlue))
                                                .cornerRadius(10)
                                            }.buttonStyle(PlainButtonStyle())
                                            .frame(width: 120, height: 25)
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
                                        }
                                        Text(fullItem.Tagline).font(.body).italic().padding(.top, 7).fixedSize(horizontal: false, vertical: true)
                                        Text(fullItem.Overview).font(.footnote).padding(.top, 3).fixedSize(horizontal: false, vertical: true)
                                    }.padding(EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16))
                                }
                            }
                        }
                    }
                }.navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Details")
                .supportedOrientations(.allButUpsideDown)
                .prefersHomeIndicatorAutoHidden(false)
                .withHostingWindow() { window in
                    let rootVC = window?.rootViewController;
                    let UIHostingcontroller: PreferenceUIHostingController = rootVC as! PreferenceUIHostingController;
                    vc = UIHostingcontroller;
                }
                .introspectTabBarController { (UITabBarController) in
                    UITabBarController.tabBar.isHidden = false
                }
            }.onAppear(perform: loadData)
        }
    }
}
