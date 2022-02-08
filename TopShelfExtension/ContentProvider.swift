//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import TVServices
import JellyfinAPI
import CoreData
import CoreStore
import Defaults
import Foundation

class ContentProvider: TVTopShelfContentProvider {

    func getResumeWatching(userID: String, completion: @escaping ([BaseItemDto]?) -> Void) {
        var cancellables = Set<AnyCancellable>()

        ItemsAPI.getResumeItems(userId: userID, limit: 5,
                                fields: [.primaryImageAspectRatio, .seriesPrimaryImage],
                                mediaTypes: ["Video"], imageTypeLimit: 1, enableImageTypes: [.primary, .backdrop, .thumb])
            .subscribe(on: DispatchQueue.global(qos: .background))
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure:
                    LogManager.shared.log.debug("Error fetching content")
                    completion(nil)
                }
            }, receiveValue: { response in
                DispatchGroup().notify(queue: .main) {
                    completion(response.items)
                }
            })
            .store(in: &cancellables)
    }
    
    func itemContentFrom(_ item: BaseItemDto) -> TVTopShelfSectionedItem {
        LogManager.shared.log.debug("Item: \(item.name ?? "")")
        
        var name : String
        var imageUrl : URL
        
        if item.type == "Episode" {
            name = "\(item.getEpisodeLocator() ?? "") - \(item.name!) - \(item.seriesName!)"
            imageUrl = item.getSeriesPrimaryImage(maxWidth: 600)
        }
        else {
            name = item.name ?? "Item"
            imageUrl = item.getPrimaryImage(maxWidth: 600)
        }
        
        let itemContent = TVTopShelfSectionedItem(identifier: item.id!)
        itemContent.imageShape = .poster
        itemContent.title = name
        itemContent.playbackProgress = (item.userData?.playedPercentage ?? 0) / 100
        itemContent.setImageURL(imageUrl, for: .screenScale2x)
        
        return itemContent
    }

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        var contentItems = [TVTopShelfSectionedItem]()
        
        DispatchQueue.main.async {
            assert(Thread.isMainThread)
            guard let currentLogin = SessionManager.main.currentLogin else {
                LogManager.shared.log.debug("No current login")
                completionHandler(nil)
                return
            }
            
            LogManager.shared.log.debug("Fetching top shelf content")
            self.getResumeWatching(userID: currentLogin.user.id) { items in
                
                guard let items = items, items.count > 0 else {
                    LogManager.shared.log.debug("No items")
                    completionHandler(nil)
                    return
                }
                
                for item in items {
                    let itemContent = self.itemContentFrom(item)
                    contentItems.append(itemContent)
                }
                
                let collection = TVTopShelfItemCollection(items: contentItems)
                collection.title = "Continue Watching"
                
                let content = TVTopShelfSectionedContent(sections: [collection])
                
                completionHandler(content)
                LogManager.shared.log.debug("Completed")
                
            }
        }
    }
}
