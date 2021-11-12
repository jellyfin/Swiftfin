//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import TVServices
import JellyfinAPI
import CoreData

class ContentProvider: TVTopShelfContentProvider {
    
    func getResumeWatching(completion: @escaping ([BaseItemDto]?) -> Void) {
        guard let currentLogin = SessionManager.main.currentLogin else {
            LogManager.shared.log.debug("No current login")
            completion(nil)
            return
        }
        
        let userID = currentLogin.user.id
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
                    completion(nil)
                }
            }, receiveValue: { response in
                DispatchGroup().notify(queue: .main) {
                    completion(response.items)
                }
            })
            .store(in: &cancellables)
        
    }
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        var contentItems = [TVTopShelfSectionedItem]()
        
        LogManager.shared.log.debug("Fetching top shelf content")
        getResumeWatching { items in
            
            guard let items = items else {
                completionHandler(nil)
                return
            }
            
            // Create the content item
            for item in items {
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
                
                contentItems.append(itemContent)
            }
            
            let collection = TVTopShelfItemCollection(items: contentItems)
            collection.title = "Continue Watching"
            
            let content = TVTopShelfSectionedContent(sections: [collection])
            
            completionHandler(content)
            
        }
    }
    
}
