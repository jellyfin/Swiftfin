//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import JellyfinAPI
import PulseUI
import SwiftUI

typealias GuamaFlixAppLoadingView = AppLoadingView
typealias GuamaFlixHomeView = HomeView
typealias GuamaFlixLogsView = ConsoleView
typealias LiveTVGuideView = ProgramsView
typealias NativeConnectToServerView = ConnectToServerView
typealias NativeEditLocalServerView = EditLocalServerView
typealias NativeEditServerConnectionView = EditServerConnectionView
typealias NativeFontPickerView = FontPickerView
typealias NativeLocalUserSecurityView = LocalUserSecurityView
typealias NativeLocalUserSettingsView = LocalUserSettingsView
typealias NativeMediaView = MediaView
typealias NativePagingLibraryView<Element: Poster> = PagingLibraryView<Element>
typealias NativeSearchView = SearchView
typealias NativeSelectUserView = SelectUserView
typealias NativeServerConnectionsView = ServerConnectionsView
typealias NativeSettingsView = SettingsView
typealias NativeUserSignInView = UserSignInView
typealias NativeVideoPlayerSettingsView = VideoPlayerSettingsView

struct GuamaFlixItemView: View {

    let item: BaseItemDto

    var body: some View {
        ItemView(item: item)
    }
}

struct NativeOrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    let title: String
    let selection: Binding<[Element]>
    let sources: [Element]
    let removable: [Element]?

    init(
        title: String,
        selection: Binding<[Element]>,
        sources: [Element],
        removable: [Element]? = nil
    ) {
        self.title = title
        self.selection = selection
        self.sources = sources
        self.removable = removable
    }

    var body: some View {
        OrderedSectionSelectorView(
            selection: selection,
            sources: sources,
            removable: removable
        )
        .navigationTitle(title)
    }
}

struct NativeRequestsView: View {

    var body: some View {
        ContentUnavailableView(
            L10n.notImplementedYetWithType(String.emptyDash),
            systemImage: "rectangle.stack.badge.plus"
        )
    }
}

final class GuamaFlixItemFocusBridge: ObservableObject {

    @Published
    var focusFirstRowToken = 0

    func focusFirstRow() {
        focusFirstRowToken += 1
    }
}

struct PosterYearLabel: View {

    let item: BaseItemDto

    var body: some View {
        if let year = item.yearRangeLabel {
            Text(year)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
        }
    }
}

struct SyncPlayNotificationBanner: View {

    var body: some View {
        EmptyView()
    }
}

struct SyncPlayActiveBorder: View {

    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(.white.opacity(0.7), lineWidth: lineWidth)
            .padding(lineWidth / 2)
    }
}

struct GuamaFlixSkipSegmentButton: View {

    var body: some View {
        EmptyView()
    }
}

final class SyncPlayManager: ObservableObject {

    enum State {
        case inactive
        case inGroup
    }

    @Published
    private(set) var state: State = .inactive

    func userDidSeek(toTicks ticks: Int) -> Bool {
        false
    }

    func userDidRequestPlayPause(playing: Bool) -> Bool {
        false
    }
}

final class SkipSegmentState: ObservableObject {

    static let shared = SkipSegmentState()

    @Published
    private(set) var isShowing = false

    @Published
    private(set) var shouldSwallowWakePress = false

    func skip() {
        dismiss()
    }

    func dismiss() {
        isShowing = false
        shouldSwallowWakePress = false
    }
}

struct TabBarReselectCatcher: View {

    let action: () -> Void

    var body: some View {
        EmptyView()
    }
}

struct TabBarBackCatcher: View {

    let canGoBack: () -> Bool
    let goBack: () -> Void

    var body: some View {
        EmptyView()
    }
}

final class SessionPlumbingReset {

    func begin() {}
}

extension Container {

    var sessionPlumbingReset: Factory<SessionPlumbingReset> {
        self { SessionPlumbingReset() }
            .scope(.session)
    }

    var syncPlayManager: Factory<SyncPlayManager> {
        self { SyncPlayManager() }
            .scope(.session)
    }
}

extension View {

    func posterLabelShadow() -> some View {
        shadow(
            color: .black.opacity(0.72),
            radius: 4,
            y: 2
        )
    }

    func syncPlayActiveBorder() -> some View {
        self
    }
}
