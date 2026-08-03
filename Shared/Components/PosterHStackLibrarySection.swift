//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterHStackLibrarySection<Library: PagingLibrary>: View
    where Library.Element: LibraryElement, Library.Element: Poster
{

    private enum FocusSection {
        case header
        case content
    }

    #if os(tvOS)
    private struct HeaderButtonStyle: ButtonStyle {

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    #endif

    @FocusState
    private var focusedSection: FocusSection?

    @ObservedObject
    var viewModel: PagingLibraryViewModel<Library>

    @Router
    private var router

    let group: PosterGroup<Library>

    private func routeToLibrary() {
        router.route(to: .library(library: viewModel.library))
    }

    private var isHeaderFocused: Bool {
        focusedSection == .header
    }

    private var headerTitle: some View {
        Text(viewModel.library.parent.displayTitle)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
    }

    @ViewBuilder
    private var header: some View {
        if group.environment.isHeaderButtonEnabled {
            Button(action: routeToLibrary) {
                #if os(tvOS)
                HStack(spacing: 3) {
                    headerTitle

                    if isHeaderFocused {
                        Image(systemName: "chevron.forward")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .backport
                .glassEffect(
                    isHeaderFocused ? .regular : .identity,
                    in: .capsule
                )
                .animation(.easeInOut(duration: 0.15), value: isHeaderFocused)
                .offset(x: -16)
                #else
                HStack(spacing: 3) {
                    headerTitle

                    Image(systemName: "chevron.forward")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .foregroundStyle(.primary, .secondary)
            .accessibilityAction(named: Text(L10n.openLibrary), routeToLibrary)
            #if os(tvOS)
                .buttonStyle(HeaderButtonStyle())
            #endif
        } else {
            headerTitle
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var sectionHeader: some View {
        if group.environment.isHeaderButtonEnabled {
            header
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSection()
                .focused($focusedSection, equals: .header)
        } else {
            header
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            ContentGroupSection {
                PosterHStack(
                    elements: viewModel.elements.elements,
                    displayType: group.posterDisplayType,
                    size: group.posterSize
                ) { element, namespace in
                    element.libraryDidSelectElement(router: router, in: namespace)
                }
                .withViewContext(.isThumb)
                .focusSection()
                .focused($focusedSection, equals: .content)
            } header: {
                sectionHeader
                    .edgePadding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
            }
            .focusSection()
            .backport
            .defaultFocus(
                $focusedSection,
                .content,
                priority: .userInitiated
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(viewModel.library.parent.displayTitle)
        }
    }
}
