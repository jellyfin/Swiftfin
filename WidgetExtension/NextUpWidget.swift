/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import JellyfinAPI
import KeychainSwift
import SwiftUI
import WidgetKit

enum WidgetError: String, Error {
    case unknown
    case emptyServer
    case emptyUser
    case emptyToken
}

struct NextUpWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextUpEntry {
        NextUpEntry(date: Date(), items: [], error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextUpEntry) -> Void) {
        let entry = NextUpEntry(date: Date(), items: [], error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let servers = FetchRequest<Server>(entity: Server.entity(),
                                           sortDescriptors: [NSSortDescriptor(keyPath: \Server.name, ascending: true)])
        print("써버")
        print(servers.wrappedValue)
        let savedUsers = FetchRequest<SignedInUser>(entity: SignedInUser.entity(),
                                                    sortDescriptors: [NSSortDescriptor(keyPath: \SignedInUser.username, ascending: true)])
        guard let server = servers.wrappedValue.first else { return
            completion(Timeline(entries: [NextUpEntry(date: entryDate, items: [], error: WidgetError.emptyServer)],
                                policy: .after(entryDate)))
        }
        guard let savedUser = savedUsers.wrappedValue.first else { return
            completion(Timeline(entries: [NextUpEntry(date: entryDate, items: [], error: WidgetError.emptyUser)],
                                policy: .after(entryDate)))
        }

        let keychain = KeychainSwift()
        // need prefix
        keychain.accessGroup = "4BHXT8RHFR.dev.pangmo5.swiftfin.keychainGroup"

        guard let authToken = keychain.get("AccessToken_\(savedUser.user_id ?? "")") else { return
            completion(Timeline(entries: [NextUpEntry(date: entryDate, items: [], error: WidgetError.emptyToken)],
                                policy: .after(entryDate)))
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

        var header = "MediaBrowser "
        header.append("Client=\"SwiftFin\", ")
        header.append("Device=\"\(deviceName)\", ")
        header.append("DeviceId=\"\(savedUser.device_uuid ?? "")\", ")
        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
        header.append("Token=\"\(authToken)\"")

        JellyfinAPI.basePath = server.baseURI ?? ""
        JellyfinAPI.customHeaders = ["X-Emby-Authorization": header]
        _ = TvShowsAPI.getNextUp(userId: savedUser.user_id, limit: 3)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case let .failure(error):
                    completion(Timeline(entries: [NextUpEntry(date: entryDate, items: [], error: error)], policy: .after(entryDate)))
                }
            }, receiveValue: { response in
                completion(Timeline(entries: [NextUpEntry(date: entryDate, items: response.items ?? [], error: nil)],
                                    policy: .after(entryDate)))
            })
    }
}

struct NextUpEntry: TimelineEntry {
    let date: Date
    let items: [BaseItemDto]
    let error: Error?
}

struct NextUpEntryView: View {
    var entry: NextUpWidgetProvider.Entry

    @Environment(\.widgetFamily)
    var family

    var body: some View {
        if let error = entry.error {
            HStack {
                Image(systemName: "exclamationmark.octagon")
                Text((error as? WidgetError)?.rawValue ?? "")
            }
        } else {
            Text(entry.items.first?.seriesName ?? "")
        }
    }
}

struct NextUpWidget: Widget {
    let kind: String = "NextUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: NextUpWidgetProvider()) { entry in
            NextUpEntryView(entry: entry)
        }
        .configurationDisplayName("Next Up")
        .description("Keep watching where you left off or see what's on next.")
        .supportedFamilies([.systemSmall])
    }
}
