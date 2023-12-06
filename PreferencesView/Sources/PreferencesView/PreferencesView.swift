import SwiftUI
import SwizzleSwift
import UIKit

public struct PreferencesView<Content: View>: UIViewControllerRepresentable {

    private var content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        _ = UIViewController.swizzlePreferences
        self.content = content
    }

    public func makeUIViewController(context: Context) -> UIPreferencesHostingController {
        UIPreferencesHostingController(content: content)
    }

    public func updateUIViewController(_ uiViewController: UIPreferencesHostingController, context: Context) {}
}
