//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI

struct ItemNotificationHandler: NotificationHandler {

    // MARK: - Registration

    func register(with handler: NotificationHandlers) {
        Notifications[.doesItemRequireRefresh].publisher
            .sink { itemID, refreshType in
                handler.logger.debug("BaseItemDto Notification: \(refreshType) - \(itemID)")
                Task { @MainActor in
                    await handler.handleItemRefresh(itemID: itemID, refreshType: refreshType)
                }
            }
            .store(in: &handler.cancellables)
    }
}

extension NotificationHandlers {

    // MARK: - Notification Handlers

    func handleItemRefresh(itemID: String, refreshType: ItemRefreshType) async {
        let operationKey = "BaseItemDto-\(refreshType)-\(itemID)"

        await executeOperation(key: operationKey) {
            switch refreshType {
            case .metadata:
                let item = try await getItemMetadata(itemID: itemID)
                logger.debug("BaseItemDto Refreshed Metadata: \(itemID)")
                Notifications[.didItemMetadataChange].post(item)

            case .userData:
                let userData = try await getItemUserData(itemID: itemID)
                logger.debug("BaseItemDto Refreshed UserData: \(itemID)")
                Notifications[.didItemUserDataChange].post((itemID, userData))

            case .childMetadata:
                let children = try await getChildrenMetadata(parentID: itemID)
                logger.info("BaseItemDto Refreshed Metadata For \(children.count) Children: \(itemID)")
                for child in children {
                    Notifications[.didItemMetadataChange].post(child)
                }

            case .childUserData:
                let childrenUserData = try await getChildrenUserData(parentID: itemID)
                logger.info("BaseItemDto Refreshed UserData For \(childrenUserData.count) Children: \(itemID)")
                for (childID, userData) in childrenUserData {
                    Notifications[.didItemUserDataChange].post((childID, userData))
                }
            }
        }
    }

    // MARK: - Item Metadata

    private func getItemMetadata(itemID: String) async throws -> BaseItemDto {
        guard let userSession = Container.shared.currentUserSession() else {
            throw JellyfinAPIError("No user session available")
        }

        logger.debug("BaseItemDto Getting Metadata: \(itemID)")

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.ids = [itemID]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let item = response.value.items?.first else {
            logger.error("BaseItemDto Item Not Found: \(itemID)")
            throw JellyfinAPIError("Item not found")
        }

        logger.debug("BaseItemDto Received Metadata: \(itemID)")
        return item
    }

    // MARK: - Item UserData

    private func getItemUserData(itemID: String) async throws -> UserItemDataDto {
        guard let userSession = Container.shared.currentUserSession() else {
            throw JellyfinAPIError("No user session available")
        }

        logger.debug("BaseItemDto Getting UserData: \(itemID)")

        let request = Paths.getItemUserData(itemID: itemID, userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        logger.debug("BaseItemDto Received UserData: \(itemID)")
        return response.value
    }

    // MARK: - Children Metadata

    private func getChildrenMetadata(parentID: String) async throws -> [BaseItemDto] {
        guard let userSession = Container.shared.currentUserSession() else {
            throw JellyfinAPIError("No user session available")
        }

        logger.debug("BaseItemDto Getting Child Metadata: \(parentID)")

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.parentID = parentID

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        let children = response.value.items ?? []

        logger.debug("BaseItemDto Received \(children.count) Children's Metadata: \(parentID)")
        return children
    }

    // MARK: - Children UserData

    private func getChildrenUserData(parentID: String) async throws -> [(String, UserItemDataDto)] {
        let children = try await getChildrenMetadata(parentID: parentID)
        var allChildrenUserData: [(String, UserItemDataDto)] = []

        logger.debug("BaseItemDto Getting Child UserData: \(parentID)")

        for child in children {
            guard let childID = child.id else { continue }

            do {
                let userData = try await getItemUserData(itemID: childID)
                allChildrenUserData.append((childID, userData))
            } catch {
                logger.error("BaseItemDto UserData Failed: \(childID) - \(error.localizedDescription)")
            }
        }

        logger.debug("BaseItemDto Received \(allChildrenUserData.count) Children's UserData: \(parentID)")
        return allChildrenUserData
    }
}
