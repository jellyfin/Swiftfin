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

struct CustomShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let bls = CGPoint(x: rect.minX + radius, y: rect.maxY)
        let blc = CGPoint(x: rect.minX + radius, y: rect.maxY - radius)
        
        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: br)
        path.addLine(to: bls)
        path.addRelativeArc(center: blc, radius: radius,
          startAngle: Angle.degrees(90), delta: Angle.degrees(90))
        
        return path
    }
}
 

struct ContinueWatchingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State var resumeItems: [ResumeItem] = []
    @State private var viewDidLoad: Int = 0;
    @State private var isLoading: Bool = true;
    
    func onAppear() {
        if(globalData.server?.baseURI == "") {
            return
        }
        if(viewDidLoad == 1) {
            return
        }
        _viewDidLoad.wrappedValue = 1;
        let request = RestRequest(method: .get, url: (globalData.server?.baseURI ?? "") + "/Users/\(globalData.user?.user_id ?? "")/Items/Resume?Limit=12&Recursive=true&Fields=PrimaryImageAspectRatio%2CBasicSyncInfo&ImageTypeLimit=1&EnableImageTypes=Primary%2CBackdrop%2CThumb&MediaTypes=Video")
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
                        if(item["PrimaryImageAspectRatio"].double ?? 0.0 < 1.0) {
                            //portrait; use backdrop instead
                            itemObj.Image = item["BackdropImageTags"][0].string ?? ""
                            itemObj.ImageType = "Backdrop"
                            
                            if(itemObj.Image == "") {
                                itemObj.Image = item["ParentBackdropImageTags"][0].string ?? ""
                            }
                            
                            itemObj.BlurHash = item["ImageBlurHashes"]["Backdrop"][itemObj.Image].string ?? ""
                        } else {
                            itemObj.Image = item["ImageTags"]["Primary"].string ?? ""
                            itemObj.ImageType = "Primary"
                            itemObj.BlurHash = item["ImageBlurHashes"]["Primary"][itemObj.Image].string ?? ""
                        }
                        
                        itemObj.Name = item["Name"].string ?? ""
                        itemObj.Type = item["Type"].string ?? ""
                        itemObj.IndexNumber = item["IndexNumber"].int ?? nil
                        itemObj.Id = item["Id"].string ?? ""
                        itemObj.ParentIndexNumber = item["ParentIndexNumber"].int ?? nil
                        itemObj.SeasonId = item["SeasonId"].string ?? nil
                        itemObj.SeriesId = item["SeriesId"].string ?? nil
                        itemObj.SeriesName = item["SeriesName"].string ?? nil
                        itemObj.ItemProgress = item["UserData"]["PlayedPercentage"].double ?? 0.00
                        _resumeItems.wrappedValue.append(itemObj)
                    }
                    _isLoading.wrappedValue = false;
                } catch {
                    
                }
                break
            case .failure(let error):
                _viewDidLoad.wrappedValue = 0;
                debugPrint(error)
                break
            }
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if(_resumeItems.wrappedValue.count > 0) {
                LazyHStack() {
                    Spacer().frame(width:12)
                    ForEach(resumeItems, id: \.Id) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            VStack(alignment: .leading) {
                                Spacer().frame(height: 10)
                                if(item.Type == "Episode") {
                                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=550&quality=80&tag=\(item.Image)")!)
                                        .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                        .placeholder {
                                            Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 48, height: 32))!)
                                                .resizable()
                                                .frame(width: 320, height: 180)
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 320, height: 180)
                                        .cornerRadius(10)
                                        .overlay(
                                            ZStack {
                                                Text("S\(String(item.ParentIndexNumber ?? 0)):E\(String(item.IndexNumber ?? 0)) - \(item.Name)")
                                                    .font(.caption)
                                                    .padding(6)
                                                    .foregroundColor(.white)
                                            }.background(Color.black)
                                            .opacity(0.8)
                                            .cornerRadius(10.0)
                                            .padding(6), alignment: .topTrailing
                                        )
                                        .overlay(
                                            Rectangle()
                                                .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                                .mask(CustomShape(radius: 10))
                                                .frame(width: CGFloat((item.ItemProgress/100)*320), height: 7)
                                                .padding(0), alignment: .bottomLeading
                                        )
                                } else {
                                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=550&quality=80&tag=\(item.Image)")!)
                                        .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                                        .placeholder {
                                            Image(uiImage: UIImage(blurHash: (item.BlurHash == "" ?  "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item.BlurHash), size: CGSize(width: 48, height: 32))!)
                                                .resizable()
                                                .frame(width: 320, height: 180)
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 320, height: 180)
                                        .cornerRadius(10)
                                        .overlay(
                                            Rectangle()
                                                .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                                .mask(CustomShape(radius: 10))
                                                .frame(width: CGFloat((item.ItemProgress/100)*320), height: 7)
                                            .padding(0), alignment: .bottomLeading
                                        )
                                }
                                Text("\(item.Type == "Episode" ? item.SeriesName ?? "" : item.Name)")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 320, alignment: .leading)
                                Spacer().frame(height: 5)
                            }.padding(.trailing, 5)
                        }
                    }
                    Spacer().frame(width:12)
                }.frame(height: 215)
            } else {
                EmptyView()
            }
        }.onAppear(perform: onAppear)
        .padding(.bottom, 10)
    }
}

struct ContinueWatchingView_Previews: PreviewProvider {
    static var previews: some View {
        ContinueWatchingView()
    }
}
