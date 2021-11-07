//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import MessageUI

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    
    public static let shared = EmailHelper()
    
    override private init() { }

    func sendLogs(logURL: URL) {
        if !MFMailComposeViewController.canSendMail() {
            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
            return // EXIT
        }

        let picker = MFMailComposeViewController()

        let fileManager = FileManager()
        let data = fileManager.contents(atPath: logURL.path)

        picker.setSubject("[DEV-BUG] SwiftFin")
        picker
            .setMessageBody("Please don't edit this email.\n Please don't change the subject. \nUDID: \(UIDevice.current.identifierForVendor?.uuidString ?? "NIL")\n",
                            isHTML: false)
        picker.setToRecipients(["SwiftFin Bug Reports <swiftfin-bugs@jellyfin.org>"])
        picker.addAttachmentData(data!, mimeType: "text/plain", fileName: logURL.lastPathComponent)
        picker.mailComposeDelegate = self

        EmailHelper.getRootViewController()?.present(picker, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        EmailHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
    }

    static func getRootViewController() -> UIViewController? {
        UIApplication.shared.windows.first?.rootViewController
    }
}

// A view modifier that detects shaking and calls a function of our choosing.
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Self.Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

// A View extension to make the modifier easier to use.
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
}

// The notification we'll send when a shake gesture happens.
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

//  Override the default behavior of shake gestures to send our notification instead.
extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
