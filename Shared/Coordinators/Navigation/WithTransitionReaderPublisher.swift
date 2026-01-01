//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import SwiftUI
import Transmission

// TODO: sometimes causes hangs?

struct WithTransitionReaderPublisher<Content: View>: View {

    @StateObject
    private var publishedBox: PublishedBox<LegacyEventPublisher<TransitionReaderProxy?>> = .init(initialValue: .init())

    let content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.transitionReader, publishedBox.value)
            .background {
                TransitionReader { proxy in
                    Color.clear
                        .onChange(of: proxy) { newValue in
                            publishedBox.value.send(newValue)
                        }
                }
            }
    }
}

@propertyWrapper
struct TransitionReaderObserver: DynamicProperty {

    @Environment(\.transitionReader)
    private var publisher

    var wrappedValue: LegacyEventPublisher<TransitionReaderProxy?> {
        publisher
    }
}

extension EnvironmentValues {

    @Entry
    var transitionReader: LegacyEventPublisher<TransitionReaderProxy?> = .init()
}
#endif
