//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import Foundation
import JellyfinAPI
import SwiftUI

struct ContentGroupView<Provider: ContentGroupProvider>: View {

    private enum Focus: String {

        case content = "contentGroup-content"
    }

    @Environment(\.frameForParentView)
    private var frameForParentView

    @AdaptiveLayout
    private var viewLayout

    @Router
    private var router

    @State
    private var contentGroupOptions: ContentGroupParentOption = .init()

    @StateObject
    private var focusCoordinator = FocusCoordinator(waitingFor: Focus.content.rawValue, focusPlaceholder: true)
    @StateObject
    private var viewModel: ContentGroupViewModel<Provider>

    @TabItemSelected
    private var tabItemSelected

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    private var contentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")

                    ContentGroupVStack(groups: viewModel.groups)
                        .edgePadding(viewLayout.isLarge && !contentGroupOptions.contains(.ignoreSafeAreaTop) ? .vertical : .bottom)
                        .padding(
                            .top,
                            contentGroupOptions.contains(.ignoreSafeAreaTop) ? 0 : (frameForParentView[.tabView]?.safeAreaInsets.top ?? 0)
                        )
                        .onPreferenceChange(ContentGroupCustomizationKey.self) { value in
                            contentGroupOptions = value
                        }
                }
            }
            .trackingFrame(for: .scrollView)
            #if os(tvOS)
            .coordinatedFocus(Focus.content.rawValue)
            #endif
            .ignoresSafeArea(
                .container,
                edges: viewLayout
                    .scrollContentEdges(extendsTop: viewLayout.isLarge || contentGroupOptions.contains(.ignoreSafeAreaTop))
            )
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.background.refresh()
            }
            .onReceive(tabItemSelected) { event in
                if event.isRepeat, event.isRoot {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
    }

    private var groupContent: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        L10n.noResults.localizedCapitalized,
                        systemImage: "rectangle.on.rectangle.slash"
                    )
                    .focusable()
                    #if os(tvOS)
                    .coordinatedFocus(.fallback)
                    #endif
                } else {
                    contentView
                }

            case .error:
                viewModel.error.map(ErrorView.init)
                    #if os(tvOS)
                        .coordinatedFocus(.fallback)
                    #endif

            case .initial, .refreshing:
                ProgressView()
                    #if os(tvOS)
                        .coordinatedFocus(.placeholder)
                    #endif
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .all)
            }
        }
    }

    var body: some View {
        Group {
            #if os(tvOS)
            groupContent
            #else
            GeometryReader { geometry in
                let safeArea = frameForParentView[.navigationStack]?.safeAreaInsets ?? geometry.safeAreaInsets
                let horizontalInsets = EdgeInsets(
                    top: 0,
                    leading: safeArea.leading,
                    bottom: 0,
                    trailing: safeArea.trailing
                )

                groupContent
                    .layoutContainer(size: CGSize(
                        width: max(0, geometry.size.width - horizontalInsets.leading - horizontalInsets.trailing),
                        height: geometry.size.height
                    ))
                    .padding(horizontalInsets)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .animation(.smooth(duration: 0.35), value: horizontalInsets)
            }
            // Give the rows actual changing bounds instead of letting the tab's
            // safe-area update jump their origin and size in a single layout pass.
            .ignoresSafeArea(.container, edges: .horizontal)
            #endif
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .navigationTitle(viewModel.provider.displayTitle)
        #if os(iOS)
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        #elseif os(tvOS)
        .toolbar(router.isRootOfPath ? .hidden : .automatic, for: .navigationBar)
        #endif
        .onFirstAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
        .sinceLastDisappear { interval in
            viewModel.refreshIfNeeded(sinceLastDisappear: interval)
        }
        .onSceneWillEnterForeground {
            viewModel.refreshIfPendingChanges()
        }
        .topBarTrailing {
            if #unavailable(iOS 26.0) {
                if viewModel.background.is(.refreshing) {
                    ProgressView()
                }
            }
        }
        .environmentObject(focusCoordinator)
    }
}
