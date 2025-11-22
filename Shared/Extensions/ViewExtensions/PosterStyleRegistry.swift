//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol WithDefaultValue: Equatable {
    static var `default`: Self { get }
}

struct VoidWithDefaultValue: WithDefaultValue {
    static var `default`: Self = .init()
}

// TODO: have layout values for `PosterHStack`?
//       - or be based on size/poster display value?

// TODO: rename `PosterButtonStyle`
struct PosterStyleEnvironment: Equatable, WithDefaultValue, Storable {

    var displayType: PosterDisplayType
    var label: AnyView
    var overlay: (PosterDisplayType) -> AnyView
//    var useParentImages: Bool
    var size: PosterDisplayType.Size

    enum CodingKeys: String, CodingKey {
        case displayType
        case size
    }

    init(
        displayType: PosterDisplayType = .portrait,
        label: some View = EmptyView(),
        @ViewBuilder overlay: @escaping (PosterDisplayType) -> some View = { _ in EmptyView() },
//        useParentImages: Bool = false,
        size: PosterDisplayType.Size = .small
    ) {
        self.displayType = displayType
        self.label = label.eraseToAnyView()
        self.overlay = { overlay($0).eraseToAnyView() }
//        self.useParentImages = useParentImages
        self.size = size
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.displayType = try container.decode(PosterDisplayType.self, forKey: .displayType)
        self.size = try container.decode(PosterDisplayType.Size.self, forKey: .size)

        self.label = EmptyView().eraseToAnyView()
        self.overlay = { _ in EmptyView().eraseToAnyView() }
//        self.useParentImages = false
    }

    static let `default`: PosterStyleEnvironment = .init()

    static func == (lhs: PosterStyleEnvironment, rhs: PosterStyleEnvironment) -> Bool {
        lhs.displayType == rhs.displayType && lhs.size == rhs.size
    }
}

struct AnyForPosterStyleEnvironment: Equatable, Identifiable {

    let action: (Any) -> PosterStyleEnvironment
    let id: String = UUID().uuidString

    func callAsFunction(_ value: Any) -> PosterStyleEnvironment {
        action(value)
    }

    static func == (lhs: AnyForPosterStyleEnvironment, rhs: AnyForPosterStyleEnvironment) -> Bool {
        lhs.id == rhs.id
    }
}

extension EnvironmentValues {

    @Entry
    var posterStyleRegistry: TypeKeyedDictionary<AnyForPosterStyleEnvironment> = .init()
}

extension View {

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: PosterStyleEnvironment
    ) -> some View {
        posterStyle(for: type) { _ in
            style
        }
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (P) -> PosterStyleEnvironment
    ) -> some View {
        posterStyle(for: type) { _, p in
            style(p)
        }
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (PosterStyleEnvironment, P) -> PosterStyleEnvironment
    ) -> some View {
        modifier(
            ForTypeInEnvironment<P, AnyForPosterStyleEnvironment>.SetValue(
                { existing in .init(action: { p in style(existing?(p as! P) ?? .default, p as! P) }) },
                for: \.posterStyleRegistry
            )
        )
    }
}

protocol CustomEnvironmentValue: WithDefaultValue {}

extension EnvironmentValues {

    @Entry
    var customEnvironmentValueRegistry: TypeKeyedDictionary<(Any) -> any CustomEnvironmentValue> = .init()
}

extension View {

    @ViewBuilder
    func customEnvironment<P: Poster>(
        for type: P.Type,
        value: P.Environment
    ) -> some View where P.Environment: CustomEnvironmentValue {
        modifier(
            ForTypeInEnvironment<P, (Any) -> any CustomEnvironmentValue>.SetValue(
                { _ in { _ in value } },
                for: \.customEnvironmentValueRegistry
            )
        )
    }
}
