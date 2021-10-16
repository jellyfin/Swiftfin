//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI

final class MainTabViewModel: ViewModel {
    @Published var backgroundURL: URL?
    @Published var lastBackgroundURL: URL?
    @Published var backgroundBlurHash: String = "001fC^"
    @Published var libraries = [BaseItemDto]()

    override init() {
        super.init()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(backgroundDidChange), name: Notification.Name("backgroundDidChange"), object: nil)
        
        #if os(tvOS)
        requestLibraries()
        #endif
    }

    @objc func backgroundDidChange() {
        self.lastBackgroundURL = self.backgroundURL
        self.backgroundURL = BackgroundManager.current.backgroundURL
        self.backgroundBlurHash = BackgroundManager.current.blurhash
    }
  
  func requestLibraries() {
      UserViewsAPI.getUserViews(userId: SessionManager.current.user.user_id ?? "val was nil")
          .trackActivity(loading)
          .sink(receiveCompletion: { completion in
              self.handleAPIRequestError(completion: completion)
          }, receiveValue: { response in
              self.libraries.append(contentsOf: response.items ?? [])
          })
          .store(in: &cancellables)
  }
}
