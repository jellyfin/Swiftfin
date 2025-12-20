//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct ItemEditorView: View {

    @Injected(\.currentUserSession)
    private var userSession: UserSession!

    // MARK: - Router

    @Router
    private var router

    // MARK: - ViewModel

    let item: BaseItemDto

    // MARK: - Can Edit Metadata

    private var canEditMetadata: Bool {
        userSession.user.permissions.items.canEditMetadata(item: item) == true
    }

    // MARK: - Can Manage Subtitles

    private var canManageSubtitles: Bool {
        userSession.user.permissions.items.canManageSubtitles(item: item) == true
    }

    // MARK: - Can Manage Lyrics

    private var canManageLyrics: Bool {
        userSession.user.permissions.items.canManageLyrics(item: item) == true
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.metadata)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            ListTitleSection(
                item.name ?? L10n.unknown,
                description: item.path
            )

            /// Hide metadata options to Lyric/Subtitle only users
            if canEditMetadata {

                refreshButtonView

                Section(L10n.edit) {
                    editMetadataView
                    editTextView
                }

                if item.hasComponents {
                    editComponentsView
                }
            } /*  else if canManageSubtitles || canManageLyrics {

                 // TODO: Enable when Subtitle / Lyric Editing is added
                 Section(L10n.edit) {
                     editTextView
                 }
             }*/
        }
    }

    // MARK: - Refresh Menu Button

    @ViewBuilder
    private var refreshButtonView: some View {
        Section {
            RefreshMetadataButton(item: item)
        } footer: {
            LearnMoreButton(L10n.metadata) {
                LabeledContent(
                    L10n.findMissing,
                    value: L10n.findMissingDescription
                )
                LabeledContent(
                    L10n.replaceMetadata,
                    value: L10n.replaceMetadataDescription
                )
                LabeledContent(
                    L10n.replaceImages,
                    value: L10n.replaceImagesDescription
                )
                LabeledContent(
                    L10n.replaceAll,
                    value: L10n.replaceAllDescription
                )
            }
        }
    }

    // MARK: - Editable Metadata Routing Buttons

    @ViewBuilder
    private var editMetadataView: some View {

        if item.isIdentifiable {
            ChevronButton(L10n.identify) {
                router.route(to: .identifyItem(item: item))
            }
        }
        ChevronButton(L10n.images) {
            router.route(to: .itemImages(viewModel: ItemImagesViewModel(item: item)))
        }
        ChevronButton(L10n.metadata) {
            router.route(to: .editMetadata(item: item))
        }
    }

    // MARK: - Editable Text Routing Buttons

    @ViewBuilder
    private var editTextView: some View {
        if canManageSubtitles {
            ChevronButton(L10n.subtitles) {
                router.route(to: .editSubtitles(item: item))
            }
        }
        if canManageLyrics {
//          ChevronButton(L10n.lyrics) {
//              router.route(to: \.editLyrics, item)
//          }
        }
    }

    // MARK: - Editable Metadata Components Routing Buttons

    @ViewBuilder
    private var editComponentsView: some View {
        Section {
            ChevronButton(L10n.genres) {
                router.route(to: .editGenres(item: item))
            }
            ChevronButton(L10n.people) {
                router.route(to: .editPeople(item: item))
            }
            ChevronButton(L10n.tags) {
                router.route(to: .editTags(item: item))
            }
            ChevronButton(L10n.studios) {
                router.route(to: .editStudios(item: item))
            }
        }
    }
}
