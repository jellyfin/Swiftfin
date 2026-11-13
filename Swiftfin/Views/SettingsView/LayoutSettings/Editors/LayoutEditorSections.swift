//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

struct LayoutEditorSections: View {

    @Binding
    var configuration: LayoutConfiguration

    @State
    private var editMode: EditMode = .inactive
    @State
    private var isResetPresented = false
    @State
    private var pendingViewDeletion: ContentViewConfiguration?

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    private func editView(_ view: ContentViewConfiguration = .init()) {
        router.route(to: NavigationRoute(id: "layout-view-\(view.id)", style: .sheet) {
            ContentViewEditorView(view: view) { savedView in
                configuration.saveView(savedView)
            }
        })
    }

    private func addTab() {
        router.route(to: NavigationRoute(id: "layout-add-tab", style: .sheet) {
            AddTabView(
                configuration: $configuration,
                isAdministrator: userSession?.userData.policy?.isAdministrator == true
            )
        })
    }

    @ContentBuilder
    var body: some View {
        Group {
            Section {
                ForEach(configuration.tabs) { tab in
                    if !editMode.isEditing,
                       case let .contentView(id) = tab.destination,
                       let view = configuration.view(withID: id) {
                        ChevronButton {
                            editView(view)
                        } label: {
                            Label(view.displayTitle, systemImage: view.systemImage)
                        }
                    } else {
                        Label(configuration.title(for: tab), systemImage: configuration.icon(for: tab))
                    }
                }
                .onMove {
                    configuration.tabs.move(fromOffsets: $0, toOffset: $1)
                }
                .onDelete { indices in
                    guard configuration.tabs.count > indices.count else { return }

                    configuration.tabs.remove(atOffsets: indices)
                }
                .deleteDisabled(configuration.tabs.count == 1)

                ChevronButton(L10n.addTab, systemName: "plus", action: addTab)
                    .disabled(!configuration.canAddTab || editMode.isEditing)
            } header: {
                HStack {
                    Text(L10n.tabs)
                    Spacer()
                    Button(editMode.isEditing ? L10n.done : L10n.edit) {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                }
            } footer: {
                if !configuration.canAddTab {
                    Text(L10n.tabLimit)
                }
            }

            Section(L10n.userViews) {
                ForEach(configuration.views) { view in
                    ChevronButton(view.displayTitle) { editView(view) }
                        .swipeActions {
                            Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                pendingViewDeletion = view
                            }
                        }
                }
                ChevronButton(L10n.addView, systemName: "plus") { editView() }
            }
            .disabled(editMode.isEditing)

            Section {
                Button(L10n.reset, role: .destructive) {
                    isResetPresented = true
                }
                .disabled(editMode.isEditing)
            }
        }
        .environment(\.editMode, $editMode)
        .confirmationDialog(L10n.reset, isPresented: $isResetPresented, titleVisibility: .visible) {
            Button(L10n.reset, role: .destructive) {
                configuration.tabs = LayoutConfiguration.defaultTabs
            }
        } message: {
            Text(L10n.resetConfirmation)
        }
        .confirmationDialog(
            L10n.deleteItemConfirmation,
            isPresented: Binding(
                get: { pendingViewDeletion != nil },
                set: {
                    if !$0 {
                        pendingViewDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let pendingViewDeletion {
                Button(L10n.delete, role: .destructive) {
                    configuration.removeView(id: pendingViewDeletion.id)
                    self.pendingViewDeletion = nil
                }
            }
        }
    }
}
