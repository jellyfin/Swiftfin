//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentViewEditorView: View {

    @State
    private var editMode: EditMode = .inactive

    @State
    private var draft: LayoutDraft

    private var view: ContentViewConfiguration {
        get { draft.configuration.views[0] }
        nonmutating set { draft.configuration.views[0] = newValue }
    }

    private var viewBinding: Binding<ContentViewConfiguration> {
        draft.binding(for: view, in: \.views)
    }

    @Router
    private var router

    private let onSave: (ContentViewConfiguration) -> Void

    init(
        view: ContentViewConfiguration = .init(),
        onSave: @escaping (ContentViewConfiguration) -> Void
    ) {
        let draft = LayoutDraft(configuration: .init(views: [view]))
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    private var iconChoices: [TabIcon.Choice] {
        guard !TabIcon.choices.contains(where: { $0.systemImage == view.icon }) else { return TabIcon.choices }

        return [.init(title: L10n.userView, systemImage: view.icon)] + TabIcon.choices
    }

    private func add(_ group: ContentGroupConfiguration) {
        view.groups.append(group)
        routeToGroup(group)
    }

    private func routeToGroup(_ group: ContentGroupConfiguration) {
        router.route(
            to: NavigationRoute(id: "layout-group-\(group.id)") {
                ContentGroupEditorView(group: draft.binding(for: group, in: view.id))
            }
        )
    }

    private func preview() {
        let previewConfiguration = view
        router.route(
            to: NavigationRoute(id: "layout-preview-\(view.id)") {
                ContentGroupView(
                    provider: ContentViewGroupProvider(configuration: previewConfiguration)
                )
                .environment(\.router, .init(navigationCoordinator: nil, isRootOfPath: false))
            }
        )
    }

    @ContentBuilder
    private var addGroupMenu: some View {
        Menu {
            Button(L10n.libraries, systemImage: "rectangle.stack.fill") {
                add(.library(reference: nil))
            }

            Button(L10n.continue, systemImage: "play.circle") {
                add(.resume())
            }

            Button(L10n.nextUp, systemImage: "text.badge.plus") {
                add(.nextUp())
            }

            Menu(L10n.liveTV, systemImage: "play.tv") {
                Button(L10n.liveTV, systemImage: "rectangle.grid.2x2.fill") {
                    add(.liveTV(element: .quickLinks))
                }

                Button(L10n.onNow, systemImage: "play.tv.fill") {
                    add(.liveTV(element: .onNow))
                }

                Button(L10n.recordings, systemImage: "record.circle") {
                    add(.liveTV(element: .recordings))
                }

                ForEach(
                    [
                        ProgramSection.series,
                        .movies,
                        .kids,
                        .sports,
                        .news,
                    ],
                    id: \.self
                ) { section in
                    Button(section.displayTitle, systemImage: "tv") {
                        add(.liveTV(
                            element: .programCategory(section)
                        ))
                    }
                }
            }

            Button(L10n.genres, systemImage: "theatermasks.fill") {
                add(.genres())
            }
        } label: {
            Label(L10n.addGroup, systemImage: "plus")
        }
    }

    @ContentBuilder
    private var saveButton: some View {
        Button(L10n.save) {
            guard view.hasValidName else { return }

            onSave(view)
            router.dismiss()
        }
        .disabled(!view.hasValidName || isEditing)
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "rectangle.3.group") {
            Section {
                TextField(L10n.name, text: viewBinding.name)
                Picker(L10n.icon, selection: viewBinding.icon) {
                    ForEach(iconChoices) { choice in
                        Label(choice.title, systemImage: choice.systemImage)
                            .tag(choice.systemImage)
                    }
                }
            }

            Section {
                ChevronButton(action: preview) {
                    Label(L10n.preview, systemImage: "play.rectangle.fill")
                }
                .disabled(view.groups.isEmpty || isEditing)
            } footer: {
                Text(L10n.previewDescription)
            }

            Section {
                ForEach(view.groups) { group in
                    if isEditing {
                        Label(group.displayTitle, systemImage: group.systemImage)
                    } else {
                        ChevronButton {
                            routeToGroup(group)
                        } label: {
                            Label(group.displayTitle, systemImage: group.systemImage)
                        }
                    }
                }
                .onMove { view.groups.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { view.groups.remove(atOffsets: $0) }

                addGroupMenu
                    .disabled(isEditing)
            } header: {
                HStack {
                    Text(L10n.groups)

                    Spacer()

                    if view.groups.isNotEmpty {
                        Button(isEditing ? L10n.done : L10n.edit) {
                            withAnimation {
                                editMode = isEditing ? .inactive : .active
                            }
                        }
                    }
                }
            } footer: {
                Text(L10n.groupsDescription)
            }
        }
        .environment(\.editMode, $editMode)
        .onChange(of: view.groups.isEmpty) { _, isEmpty in
            if isEmpty {
                editMode = .inactive
            }
        }
        .navigationTitle(view.displayTitle)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton { router.dismiss() }
        .topBarTrailing { saveButton }
    }
}
