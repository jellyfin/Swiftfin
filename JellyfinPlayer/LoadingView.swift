import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isShowing: Bool  // should the modal be visible?
    var content: () -> Content
    var text: String?  // the text to display under the ProgressView - defaults to "Loading..."

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // the content to display - if the modal is showing, we'll blur it
                content()
                    .disabled(isShowing)
                    .blur(radius: isShowing ? 2 : 0)
                
                // all contents inside here will only be shown when isShowing is true
                if isShowing {
                    // this Rectangle is a semi-transparent black overlay
                    Rectangle()
                        .fill(Color.black).opacity(isShowing ? 0.6 : 0)
                        .edgesIgnoringSafeArea(.all)

                    // the magic bit - our ProgressView just displays an activity
                    // indicator, with some text underneath showing what we are doing
                    HStack() {
                        ProgressView()
                        Text(text ?? "Loading").fontWeight(.semibold).font(.callout).offset(x: 60)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 10))
                    .frame(width: 250)
                    .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                }
            }
        }
    }
}
