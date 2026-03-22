//
  // Swiftfin is subject to the terms of the Mozilla Public
  // License, v2.0. If a copy of the MPL was not distributed with this
  // file, you can obtain one at https://mozilla.org/MPL/2.0/.
  //
  // Copyright (c) 2026 Jellyfin & Jellyfin Contributors
  //
                  
  import SwiftUI

  struct ScrollIfLargerThanContainerModifier: ViewModifier {
   
      @State
      private var contentSize: CGSize = .zero

      let axes: Axis.Set
      let padding: CGFloat

<<<<<<< HEAD
      func body(content: Content) -> some View {
          AlternateLayoutView {
              Color.clear
          } content: { layoutSize in
                                                                                                                                            
              let isHorizontallyLarger: Bool = (contentSize.width + padding >= layoutSize.width) && axes.contains(.horizontal)
              let isVerticallyLarger: Bool = (contentSize.height + padding >= layoutSize.height) && axes.contains(.vertical)
                                                                                                                                            
              ScrollView(axes) {
                  content
                      .trackingSize($contentSize)
              }
              .frame(
                  maxWidth: axes.contains(.horizontal) ? (isHorizontallyLarger ? .infinity : contentSize.width) : nil,
                  maxHeight: axes.contains(.vertical) ? (isVerticallyLarger ? .infinity : contentSize.height) : nil
              )
              .backport // iOS 17
              .scrollClipDisabled()
              .scrollDisabled((axes.contains(.horizontal) && !isHorizontallyLarger) || (axes.contains(.vertical) && !isVerticallyLarger))
              .scrollIndicators(.never)
          }
      }
  }   
=======
struct ScrollIfLargerThanContainerModifier: ViewModifier {

    let padding: CGFloat

    func body(content: Content) -> some View {
        ViewThatFits(in: .vertical) {
            // if content is small
            content

            // if content too tall
            ScrollView {
                content
            }
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollIndicators(.never)
        }
    }
}
>>>>>>> 5d546e03 (Add auto-scrolling Ticker to LearnMoreModal on tvOS)
