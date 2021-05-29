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
    fileprivate var provider =
        MoyaProvider<JellyfinAPI>()

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

    var globalData = GlobalData() {
        didSet {
            injectEnvironmentData()
        }
    }

    fileprivate var cancellables = Set<AnyCancellable>()

    init(filter: Filter = Filter()) {
        self.filter = filter
    }

    fileprivate func injectEnvironmentData() {
        cancellables.removeAll()

        $filter
            .sink(receiveValue: requestInitItems(_:))
            .store(in: &cancellables)
    }

    func requestNextPage() {
        page += 1
        requestItems(filter)
    }

    func requestPreviousPage() {
        page -= 1
        requestItems(filter)
    }

    func requestInitItems(_ filter: Filter) {
        page = 1
        requestItems(filter)
    }

    fileprivate func requestItems(_ filter: Filter) {
        isLoading = true
        provider.requestPublisher(.items(globalData: globalData, filter: filter, page: page))
            .receive(on: DispatchQueue.main)
            .map { response -> ([ResumeItem], Int) in
                let body = response.data
                var totalCount = 0
                var innerItems = [ResumeItem]()
                do {
                    let json = try JSON(data: body)
                    totalCount = json["TotalRecordCount"].int ?? 0
                    for (_, item): (String, JSON) in json["Items"] {
                        // Do something you want
                        var itemObj = ResumeItem()
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

                        innerItems.append(itemObj)
                    }
                } catch {}
                return (innerItems, totalCount)
            }
            .sink(receiveCompletion: { [weak self] _ in
                guard let self = self else { return }
                self.isLoading = false
            }, receiveValue: { [weak self] items, count in
                guard let self = self else { return }
                print(count)
                print(items.count)
                print(self.page)
                
                if(count > 100) {
                    self.isHiddenPreviousButton = true
                    self.isHiddenNextButton = true
                    
                    if(self.page > 1) {
                        self.isHiddenPreviousButton = false
                    }
                    
                    if(self.page * 100 < count) {
                        self.isHiddenNextButton = false
                    }
                } else {
                    self.isHiddenPreviousButton = true
                    self.isHiddenNextButton = true
                }
                
                print(self.isHiddenPreviousButton)
                print(self.isHiddenNextButton)

                self.items = items
            })
            .store(in: &cancellables)
    }
}
