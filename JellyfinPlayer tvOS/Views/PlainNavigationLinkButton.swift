import SwiftUI

struct PlainNavigationLinkButtonStyle: ButtonStyle {
      func makeBody(configuration: Self.Configuration) -> some View {
          PlainNavigationLinkButton(configuration: configuration)
      }
}

struct PlainNavigationLinkButton: View {
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
    }
}
