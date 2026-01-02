//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FocusGuideModifier: ViewModifier {

    @FocusState
    var focusDirection: FocusDirection?
    @EnvironmentObject
    var focusGuide: FocusGuide

    let focusConstructor: FocusConstructor
    let onContentFocus: (() -> Void)?

    let debug = false

    func body(content: Content) -> some View {
        VStack(spacing: 0) {

            Color(debug ? .red : .clear)
                .frame(height: 1)
                .if(focusConstructor.topTarget != nil, transform: { boundary in
                    boundary.focusable()
                })
                .focused($focusDirection, equals: .top)

            HStack(spacing: 0) {
                Color(debug ? .red : .clear)
                    .frame(width: 1)
                    .if(focusConstructor.leftTarget != nil, transform: { boundary in
                        boundary.focusable()
                    })
                    .focused($focusDirection, equals: .left)

                content
                    .focused($focusDirection, equals: .content)

                Color(debug ? .red : .clear)
                    .frame(width: 1)
                    .if(focusConstructor.rightTarget != nil, transform: { boundary in
                        boundary.focusable()
                    })
                    .focused($focusDirection, equals: .right)
            }

            Color(debug ? .red : .clear)
                .frame(height: 1)
                .if(focusConstructor.bottomTarget != nil, transform: { boundary in
                    boundary.focusable()
                })
                .focused($focusDirection, equals: .bottom)
        }
        .onChange(of: focusDirection) { _, focusDirection in
            guard let focusDirection = focusDirection else { return }
            switch focusDirection {
            case .top:
                focusGuide.transition(to: focusConstructor.topTarget!)
            case .bottom:
                focusGuide.transition(to: focusConstructor.bottomTarget!)
            case .left:
                focusGuide.transition(to: focusConstructor.leftTarget!)
            case .right:
                focusGuide.transition(to: focusConstructor.rightTarget!)
            case .content: ()
            }
        }
        .onChange(of: focusGuide.focusedTag) { _, newTag in
            if newTag == focusConstructor.tag {
                if let onContentFocus {
                    onContentFocus()
                } else {
                    focusDirection = .content
                }
            }
        }
    }
}

extension View {
    func focusGuide(
        _ focusGuide: FocusGuide,
        tag: String,
        onContentFocus: (() -> Void)? = nil,
        top: String? = nil,
        bottom: String? = nil,
        left: String? = nil,
        right: String? = nil
    ) -> some View {
        let focusConstructor = FocusConstructor(
            tag: tag,
            topTarget: top,
            bottomTarget: bottom,
            leftTarget: left,
            rightTarget: right
        )
        return modifier(FocusGuideModifier(focusConstructor: focusConstructor, onContentFocus: onContentFocus))
            .environmentObject(focusGuide)
    }
}

enum FocusDirection: String {
    case top
    case bottom
    case content
    case left
    case right
}

struct FocusConstructor {

    let tag: String
    let topTarget: String?
    let bottomTarget: String?
    let leftTarget: String?
    let rightTarget: String?

    init(
        tag: String,
        topTarget: String?,
        bottomTarget: String?,
        leftTarget: String?,
        rightTarget: String?
    ) {
        self.tag = tag
        self.topTarget = topTarget
        self.bottomTarget = bottomTarget
        self.leftTarget = leftTarget
        self.rightTarget = rightTarget
    }
}

// TODO: generic focus values instead of strings
// TODO: keep mapping of all tag connections,
//       only add complete connections

class FocusGuide: ObservableObject {

    @Published
    private(set) var focusedTag: String?

    private(set) var lastFocusedTag: String?

    func transition(to tag: String?) {
        lastFocusedTag = focusedTag
        focusedTag = tag
    }
}
