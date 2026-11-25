//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterHStackLibrarySection<Library: PagingLibrary>: View
where Library.Element: LibraryElement, Library.Element: Poster {

    private enum FocusSection {

        case header
        case content
    }

    private struct HeaderButtonStyle: ButtonStyle {

        @AdaptiveLayout
        private var viewLayout

        @Environment(\.controlSize)
        private var controlSize

        @Environment(\.isFocused)
        private var isFocused

        private var metrics: CapsuleButtonStyle.CapsuleControlMetrics {
            CapsuleButtonStyle.CapsuleControlMetrics(controlSize, layout: viewLayout)
        }

        private var foregroundStyle: AnyShapeStyle {
            isFocused ? AnyShapeStyle(Color.white.overlayColor) : AnyShapeStyle(HierarchicalShapeStyle.primary)
        }

        @ContentBuilder
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(foregroundStyle)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.vertical, metrics.verticalPadding)
                .background {
                    Capsule()
                        .fill(.white)
                        .opacity(isFocused ? 1 : 0)
                }
                .contentShape(.capsule)
                .scaleEffect(isFocused ? 1.05 : 1)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .animation(.linear(duration: 0.1), value: isFocused)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
                .padding(.leading, -metrics.horizontalPadding)
        }
    }

    @AdaptiveLayout
    private var viewLayout

    @FocusState
    private var focusedSection: FocusSection?

    @Router
    private var router

    let group: PosterGroup<Library>
    let viewModel: PagingLibraryViewModel<Library>

    private func routeToLibrary() {
        router.route(to: .library(library: viewModel.library, displayTitle: group.displayTitle))
    }

    @ContentBuilder
    private var headerTitle: some View {
        Text(group.displayTitle)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
    }

    @ContentBuilder
    private var header: some View {
        if group.environment.isHeaderButtonEnabled {
            Button(action: routeToLibrary) {
                HStack(spacing: 3) {
                    headerTitle

                    Image(systemName: "chevron.forward")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary, .secondary)
            .accessibilityAction(named: Text(L10n.openLibrary), routeToLibrary)
            .if(viewLayout.isLarge) { $0.buttonStyle(HeaderButtonStyle()) }
        } else {
            headerTitle
                .foregroundStyle(.primary)
        }
    }

    @ContentBuilder
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

    @ContentBuilder
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
            .defaultFocus(
                $focusedSection,
                .content,
                priority: .userInitiated
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(group.displayTitle)
        }
    }
}
