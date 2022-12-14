//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct QuickConnectView: View {

    @EnvironmentObject
    private var router: QuickConnectCoordinator.Router

    @ObservedObject
    var viewModel: UserSignInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            L10n.quickConnectStep1.text

            L10n.quickConnectStep2.text

            L10n.quickConnectStep3.text
                .padding(.bottom)

            Text(viewModel.quickConnectCode ?? "------")
                .tracking(10)
                .font(.largeTitle)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle(L10n.quickConnect)
        .onAppear {
            Task {
                for await result in viewModel.startQuickConnect() {
                    guard let secret = result.secret else { continue }
                    try? await viewModel.signIn(quickConnectSecret: secret)
                    router.dismissCoordinator()
                }
            }
        }
        .onDisappear {
            viewModel.stopQuickConnectAuthCheck()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    router.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
    }
}

// public static func updates<Value: Serializable>(
//    _ key: Key<Value>,
//    initial: Bool = true
// ) -> AsyncStream<Value> { // TODO: Make this `some AsyncSequence<Value>` when Swift 6 is out.
//    .init { continuation in
//        let observation = UserDefaultsKeyObservation(object: key.suite, key: key.name) { change in
//            // TODO: Use the `.deserialize` method directly.
//            let value = KeyChange(change: change, defaultValue: key.defaultValue).newValue
//            continuation.yield(value)
//        }
//
//        observation.start(options: initial ? [.initial] : [])
//
//        continuation.onTermination = { _ in
//            observation.invalidate()
//        }
//    }
// }

// for await newValue in Defaults.updates(.accentColor) {
