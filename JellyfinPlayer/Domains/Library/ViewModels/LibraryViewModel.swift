//
//  LibraryViewModel.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/27.
//

import Combine
import CombineMoya
import Foundation
import Moya
import SwiftyJSON

final class LibraryViewModel: ObservableObject {
    fileprivate var provider = MoyaProvider<JellyfinAPI>(plugins: [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(logOptions: .verbose))])

    var prefillID: String
    @Published
    var filter: Filter

    @Published
    var items = [ResumeItem]()

    @Published
    var isLoading: Bool = true

    @Published
    var isHiddenPreviousButton = true
    @Published
    var isHiddenNextButton = true

    var page = 1

    var globalData = GlobalData()

    fileprivate var cancellables = Set<AnyCancellable>()

    init(prefillID: String,
         filter: Filter? = nil)
    {
        self.prefillID = prefillID

        if let unwrappedFilter = filter {
            self.filter = unwrappedFilter
        } else {
            self.filter = Filter(imageTypes: [.primary, .backdrop, .thumb, .banner],
                                 fields: [.primaryImageAspectRatio, .basicSyncInfo],
                                 itemTypes: [.movie, .series],
                                 sort: .dateCreated,
                                 asc: .descending,
                                 parentID: prefillID,
                                 imageTypeLimit: 1,
                                 recursive: true)
        }
    }

    func requestNextPage() {
        page += 1
        requestItems()
    }

    func requestPreviousPage() {
        page -= 1
        requestItems()
    }
    
    func requestInitItems() {
        page = 1
        requestItems()
    }

    fileprivate func requestItems() {
        print(globalData.server?.baseURI)
        print(globalData.authHeader)
        print(filter)
        isLoading = true
        provider.requestPublisher(.items(globalData: globalData, filter: filter, page: page))
            // .map(ResumeItem.self) TO DO
            .print()
            .sink(receiveCompletion: { _ in
                self.isLoading = false
            }, receiveValue: { response in
                self.items.removeAll()
                let body = response.data
                var totalCount = 0
                do {
                    let json = try JSON(data: body)
                    totalCount = json["TotalRecordCount"].int ?? 0
                    for (_, item): (String, JSON) in json["Items"] {
                        // Do something you want
                        let itemObj = ResumeItem()
                        itemObj.Type = item["Type"].string ?? ""
                        if itemObj.Type == "Series" {
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

                        self.items.append(itemObj)
                    }
                } catch {}

                if totalCount > 100 {
                    if self.page > 1 {
                        self.isHiddenPreviousButton = false
                    }
                    if totalCount > (self.page * 100) {
                        self.isHiddenNextButton = false
                    }
                } else {
                    self.isHiddenNextButton = true
                    self.isHiddenPreviousButton = true
                }
            })
            .store(in: &cancellables)
    }
}
