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

    @ViewBuilder
    private var header: some View {
        Button(action: routeToLibrary) {
            #if os(tvOS)
            HStack(spacing: 3) {
                Text(viewModel.library.parent.displayTitle)
                    .font(.title3)
                    .lineLimit(1)

                if isHeaderFocused {
                    Image(systemName: "chevron.forward")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .fontWeight(.semibold)
            .padding(.horizontal, isHeaderFocused ? 16 : 0)
            .padding(.vertical, 8)
            .materialShapeAppearance(
                isHeaderFocused ? .regular : .identity,
                in: Capsule()
            )
            .animation(.easeInOut(duration: 0.15), value: isHeaderFocused)
            #else
            HStack(spacing: 3) {
                Text(viewModel.library.parent.displayTitle)
                    .font(.title3)
                    .lineLimit(1)

                Image(systemName: "chevron.forward")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.semibold)
            #endif
        }
        .foregroundStyle(.primary, .secondary)
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction(named: Text(L10n.openLibrary), routeToLibrary)
        #if os(tvOS)
            .buttonStyle(HeaderButtonStyle())
        #endif
            .edgePadding(.horizontal)
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
                header
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .focusSection()
                    .focused($focusedSection, equals: .header)
            }
            .focusSection()
            .backport
            .defaultFocus(
                $focusedSection,
                .content,
                priority: .userInitiated
            )
        }
    }
}
