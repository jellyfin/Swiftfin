//
//  LibrarySearchViewModel.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/27.
//

import Combine
import CombineMoya
import Foundation
import Moya
import SwiftyJSON

final class LibrarySearchViewModel: ObservableObject {
    fileprivate var provider = MoyaProvider<JellyfinAPI>(plugins: [NetworkLoggerPlugin()])

    var filter: Filter

    @Published
    var items = [ResumeItem]()

    @Published
    var searchQuery = ""
    @Published
    var isLoading: Bool = true

    var page = 1

    var globalData = GlobalData() {
        didSet {
            injectEnvironmentData()
        }
    }

    fileprivate var cancellables = Set<AnyCancellable>()

    init(filter: Filter) {
        self.filter = filter
    }

    fileprivate func injectEnvironmentData() {
        cancellables.removeAll()

        $searchQuery
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink(receiveValue: requestSearch(query:))
            .store(in: &cancellables)
    }

    fileprivate func requestSearch(query: String) {
        isLoading = true
        provider.requestPublisher(.search(globalData: globalData, filter: filter, searchQuery: query, page: page))
            // .map(ResumeItem.self) TO DO
            .print()
            .sink(receiveCompletion: { _ in
                self.isLoading = false
            }, receiveValue: { response in
                let body = response.data
                self.items.removeAll()
                do {
                    let json = try JSON(data: body)
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
            })
            .store(in: &cancellables)
    }
}
