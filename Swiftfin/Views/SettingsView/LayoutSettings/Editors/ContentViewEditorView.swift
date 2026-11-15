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
    private var view: ContentViewConfiguration

    @State
    private var isIconPickerPresented = false

    @Router
    private var router

    private let onSave: (ContentViewConfiguration) -> Void

    init(
        view: ContentViewConfiguration = .init(),
        onSave: @escaping (ContentViewConfiguration) -> Void
    ) {
        _view = State(initialValue: view)
        self.onSave = onSave
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    private func add(_ source: ContentGroupSource) {
        let group = ContentGroupConfiguration(source: source)
        view.groups.append(group)
        routeToGroup(group)
    }

    private func routeToGroup(_ group: ContentGroupConfiguration) {
        guard let index = view.groups.firstIndex(where: { $0.id == group.id }) else { return }

        router.route(
            to: NavigationRoute(id: "layout-group-\(group.id)") {
                ContentGroupEditorView(group: $view.groups[index])
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
        Menu(L10n.add, systemImage: "plus") {
            Button(L10n.libraries, systemImage: "rectangle.stack.fill") {
                add(.library(.init()))
            }

            Button(L10n.continue, systemImage: "play.circle") {
                add(.resume(.init()))
            }

            Button(L10n.nextUp, systemImage: "text.badge.plus") {
                add(.nextUp(.init()))
            }

            Menu(L10n.liveTV, systemImage: "play.tv") {
                ForEach(LiveTVElement.allCases, id: \.self) { element in
                    Button(element.displayTitle, systemImage: element.systemImage) {
                        add(.liveTV(.init(element: element)))
                    }
                }
            }

            Button(L10n.genres, systemImage: "theatermasks.fill") {
                add(.genres(.init()))
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private func save() {
        guard view.hasValidName else { return }

        onSave(view)
        router.dismiss()
    }

    @ContentBuilder
    private var saveButton: some View {
        Group {
            if #available(iOS 26, *) {
                Button(role: .confirm, action: save)
            } else {
                Button(L10n.save, systemImage: "checkmark", action: save)
                    .labelStyle(.iconOnly)
                    .backport
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
            }
        }
        .disabled(!view.hasValidName || isEditing)
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "rectangle.3.group") {
            Section {
                TextField(L10n.name, text: $view.name)
                ChevronButton {
                    isIconPickerPresented = true
                } label: {
                    Label(L10n.icon, systemImage: view.icon)
                }
                .accessibilityValue(TabIcon.choices.first { $0.systemImage == view.icon }?.title ?? L10n.icon)
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
        .labelStyle(.listRow)
        .environment(\.editMode, $editMode)
        .onChange(of: view.groups.isEmpty) { _, isEmpty in
            if isEmpty {
                editMode = .inactive
            }
        }
        .navigationTitle(view.displayTitle)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton { router.dismiss() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                saveButton
            }
        }
        .sheet(isPresented: $isIconPickerPresented) {
            TabIconPicker(selection: $view.icon)
        }
    }
}
