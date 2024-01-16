//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Better name
// TODO: don't use pushed to indicate a presented value

class UpdateViewProxy: ObservableObject {

    @Published
    private(set) var systemName: String? = nil
    @Published
    private(set) var iconSize: CGSize = .init(width: 25, height: 25)
    @Published
    private(set) var title: String = ""
    @Published
    private(set) var pushed: Bool = false

    func present(systemName: String, title: String, iconSize: CGSize = .init(width: 25, height: 25)) {
        self.systemName = systemName
        self.iconSize = iconSize
        self.title = title
        pushed.toggle()
    }
}

struct UpdateView: View {

    @ObservedObject
    private var proxy: UpdateViewProxy

    @State
    private var isPresenting: Bool = false
    @State
    private var workItem: DispatchWorkItem?

    init(proxy: UpdateViewProxy) {
        self.proxy = proxy
    }

    var body: some View {
        ZStack {
            if isPresenting {
                HStack {
                    if let systemName = proxy.systemName {
                        Image(systemName: systemName)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: proxy.iconSize.width, maxHeight: proxy.iconSize.height, alignment: .center)
                    }

                    Text(proxy.title)
                        .font(.body)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .frame(minHeight: 50)
                .background(BlurView())
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
                .compositingGroup()
                .transition(.opacity)
            }
        }
        .animation(.linear(duration: 0.1), value: proxy.systemName)
        .animation(.linear(duration: 0.1), value: proxy.iconSize)
        .onChange(of: proxy.pushed) { _ in

            if !isPresenting {
                withAnimation {
                    isPresenting = true
                }
            }

            workItem?.cancel()

            let task = DispatchWorkItem {
                withAnimation(.spring()) {
                    isPresenting = false
                }
            }
            workItem = task

            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: task)
        }
    }
}
