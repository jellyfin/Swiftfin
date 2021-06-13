/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import JellyfinAPI
import Nuke
import SwiftUI
import WidgetKit

enum WidgetError: String, Error {
    case unknown
    case emptyServer
    case emptyUser
    case emptyHeader
}

struct NextUpWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextUpEntry {
        NextUpEntry(date: Date(), items: [], error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextUpEntry) -> Void) {
        let currentDate = Date()
        guard let server = ServerEnvironment.shared.server else { return
            DispatchQueue.main.async {
                completion(NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyServer))
            }
        }
        guard let savedUser = SessionManager.shared.user else { return
            DispatchQueue.main.async {
                completion(NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyUser))
            }
        }
        guard let header = SessionManager.shared.authHeader else { return
            DispatchQueue.main.async {
                completion(NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyHeader))
            }
        }
        var tempCancellables = Set<AnyCancellable>()
        JellyfinAPI.basePath = server.baseURI ?? ""
        JellyfinAPI.customHeaders = ["X-Emby-Authorization": header]
        TvShowsAPI.getNextUp(userId: savedUser.user_id, limit: 3,
                             fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                             imageTypeLimit: 1, enableImageTypes: [.primary, .backdrop, .thumb])
            .subscribe(on: DispatchQueue.global(qos: .background))
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case let .failure(error):
                    completion(NextUpEntry(date: currentDate, items: [], error: error))
                }
            }, receiveValue: { response in
                let dispatchGroup = DispatchGroup()
                let items = response.items ?? []
                var downloadedItems = [(BaseItemDto, UIImage?)]()
                items.enumerated().forEach { _, item in
                    dispatchGroup.enter()
                    ImagePipeline.shared.loadImage(with: item.getBackdropImage(baseURL: server.baseURI ?? "", maxWidth: 320)) { result in
                        guard case let .success(image) = result else {
                            dispatchGroup.leave()
                            return
                        }
                        downloadedItems.append((item, image.image))
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(NextUpEntry(date: currentDate, items: downloadedItems, error: nil))
                }
            })
            .store(in: &tempCancellables)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        guard let server = ServerEnvironment.shared.server else { return
            DispatchQueue.main.async {
                completion(Timeline(entries: [NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyServer)],
                                    policy: .after(entryDate)))
            }
        }
        guard let savedUser = SessionManager.shared.user else { return
            DispatchQueue.main.async {
                completion(Timeline(entries: [NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyUser)],
                                    policy: .after(entryDate)))
            }
        }
        guard let header = SessionManager.shared.authHeader else { return
            DispatchQueue.main.async {
                completion(Timeline(entries: [NextUpEntry(date: currentDate, items: [], error: WidgetError.emptyHeader)],
                                    policy: .after(entryDate)))
            }
        }
        var tempCancellables = Set<AnyCancellable>()
        JellyfinAPI.basePath = server.baseURI ?? ""
        JellyfinAPI.customHeaders = ["X-Emby-Authorization": header]
        TvShowsAPI.getNextUp(userId: savedUser.user_id, limit: 3,
                             fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                             imageTypeLimit: 1, enableImageTypes: [.primary, .backdrop, .thumb])
            .subscribe(on: DispatchQueue.global(qos: .background))
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case let .failure(error):
                    completion(Timeline(entries: [NextUpEntry(date: currentDate, items: [], error: error)], policy: .after(entryDate)))
                }
            }, receiveValue: { response in
                let dispatchGroup = DispatchGroup()
                let items = response.items ?? []
                var downloadedItems = [(BaseItemDto, UIImage?)]()
                items.enumerated().forEach { _, item in
                    dispatchGroup.enter()
                    ImagePipeline.shared.loadImage(with: item.getBackdropImage(baseURL: server.baseURI ?? "", maxWidth: 320)) { result in
                        guard case let .success(image) = result else {
                            dispatchGroup.leave()
                            return
                        }
                        downloadedItems.append((item, image.image))
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(Timeline(entries: [NextUpEntry(date: currentDate, items: downloadedItems, error: nil)],
                                        policy: .after(entryDate)))
                }
            })
            .store(in: &tempCancellables)
    }
}

struct NextUpEntry: TimelineEntry {
    let date: Date
    let items: [(BaseItemDto, UIImage?)]
    let error: Error?
}

struct NextUpEntryView: View {
    var entry: NextUpWidgetProvider.Entry

    @Environment(\.widgetFamily)
    var family

    @ViewBuilder
    var body: some View {
        Group {
            if let error = entry.error {
                HStack {
                    Image(systemName: "exclamationmark.octagon")
                    Text((error as? WidgetError)?.rawValue ?? "")
                }
                .background(Color.blue)
            } else if entry.items.isEmpty {
                Text("Empty Next Up")
                    .font(.body)
                    .bold()
                    .foregroundColor(.primary)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            } else {
                switch family {
                    case .systemSmall:
                        small(item: entry.items.first)
                    case .systemMedium:
                        medium(items: entry.items)
                    case .systemLarge:
                        large(items: entry.items)
                    default:
                        EmptyView()
                }
            }
        }
        .background(Color(.secondarySystemBackground))
    }
}

extension NextUpEntryView {
    var smallVideoPlaceholderView: some View {
        VStack(alignment: .leading) {
            Color(.systemGray)
                .aspectRatio(.init(width: 1, height: 0.5625), contentMode: .fill)
                .cornerRadius(8)
                .shadow(radius: 8)
            Color(.systemGray2)
                .frame(width: 100, height: 10)
            Color(.systemGray3)
                .frame(width: 80, height: 10)
        }
    }

    var largeVideoPlaceholderView: some View {
        HStack(spacing: 20) {
            Color(.systemGray)
                .aspectRatio(.init(width: 1, height: 0.5625), contentMode: .fill)
                .cornerRadius(8)
                .shadow(radius: 8)
            VStack(alignment: .leading, spacing: 8) {
                Color(.systemGray2)
                    .frame(width: 100, height: 10)
                Color(.systemGray3)
                    .frame(width: 80, height: 10)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension NextUpEntryView {
    var headerSymbol: some View {
        Image("WidgetHeaderSymbol")
            .resizable()
            .frame(width: 12, height: 12)
            .cornerRadius(4)
            .shadow(radius: 8)
    }

    func smallVideoView(item: (BaseItemDto, UIImage?)) -> some View {
        VStack(alignment: .leading) {
            if let image = item.1 {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(.init(width: 1, height: 0.5625), contentMode: .fill)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(radius: 8)
            }
            Text(item.0.seriesName ?? "")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(item.0.name ?? "") · S\(item.0.parentIndexNumber ?? 0):E\(item.0.indexNumber ?? 0)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    func largeVideoView(item: (BaseItemDto, UIImage?)) -> some View {
        HStack(spacing: 20) {
            if let image = item.1 {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(.init(width: 1, height: 0.5625), contentMode: .fill)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(radius: 8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(item.0.seriesName ?? "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text("\(item.0.name ?? "") · S\(item.0.parentIndexNumber ?? 0):E\(item.0.indexNumber ?? 0)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

extension NextUpEntryView {
    func small(item: (BaseItemDto, UIImage?)?) -> some View {
        VStack(alignment: .trailing) {
            headerSymbol
            if let item = item {
                smallVideoView(item: item)
            } else {
                smallVideoPlaceholderView
            }
        }
        .padding(12)
    }

    func medium(items: [(BaseItemDto, UIImage?)]) -> some View {
        VStack(alignment: .trailing) {
            headerSymbol
            HStack(spacing: 16) {
                if let firstItem = items[safe: 0] {
                    smallVideoView(item: firstItem)
                } else {
                    smallVideoPlaceholderView
                }
                if let secondItem = items[safe: 1] {
                    smallVideoView(item: secondItem)
                } else {
                    smallVideoPlaceholderView
                }
            }
        }
        .padding(12)
    }

    func large(items: [(BaseItemDto, UIImage?)]) -> some View {
        VStack(spacing: 0) {
            if let firstItem = items[safe: 0] {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomLeading) {
                        if let image = firstItem.1 {
                            Image(uiImage: image)
                                .centerCropped()
                                .innerShadow(color: Color.black.opacity(0.5), radius: 0.5)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(firstItem.0.seriesName ?? "")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            Text("\(firstItem.0.name ?? "") · S\(firstItem.0.parentIndexNumber ?? 0):E\(firstItem.0.indexNumber ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        }
                        .shadow(radius: 8)
                        .padding(12)
                    }
                    headerSymbol
                        .padding(12)
                }
                .clipped()
                .shadow(radius: 8)
            }
            VStack(spacing: 8) {
                if let secondItem = items[safe: 1] {
                    largeVideoView(item: secondItem)
                } else {
                    largeVideoPlaceholderView
                }
                Divider()
                if let thirdItem = items[safe: 2] {
                    largeVideoView(item: thirdItem)
                } else {
                    largeVideoPlaceholderView
                }
            }
            .padding(12)
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
        .description("Keep watching where you left off or see what's up next.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct NextUpWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [(.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                                  UIImage(named: "WidgetHeaderSymbol"))],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name1", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series1"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name1", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series1"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name2", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series2"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [(.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                                  UIImage(named: "WidgetHeaderSymbol"))],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .preferredColorScheme(.dark)
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name1", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series1"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .preferredColorScheme(.dark)
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name1", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series1"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name2", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series2"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .preferredColorScheme(.dark)
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .preferredColorScheme(.dark)
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .preferredColorScheme(.dark)
            NextUpEntryView(entry: .init(date: Date(),
                                         items: [
                                             (.init(name: "Name0", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series0"),
                                              UIImage(named: "WidgetHeaderSymbol")),
                                             (.init(name: "Name1", indexNumber: 10, parentIndexNumber: 0, seriesName: "Series1"),
                                              UIImage(named: "WidgetHeaderSymbol"))
                                         ],
                                         error: nil))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

private extension View {
    func innerShadow(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow(color: color, radius: min(max(0, radius), 1)))
    }
}

private struct InnerShadow: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                    .frame(height: self.radius * self.minSide(geo)),
                    alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                    .frame(height: self.radius * self.minSide(geo)),
                    alignment: .bottom)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
