//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: IMPLEMENT BUTTON OVERRIDES IN `PreferencesView` PACKAGE

// import SwiftUI
// import UIKit
//
//// MARK: PreferenceUIHostingController
//
// class PreferenceUIHostingController: UIHostingController<AnyView> {
//
//    init<V: View>(@ViewBuilder wrappedView: @escaping () -> V) {
//        let box = Box()
//        super.init(rootView: AnyView(
//            wrappedView()
//                .onPreferenceChange(ViewPreferenceKey.self) {
//                    box.value?._viewPreference = $0
//                }
//                .onPreferenceChange(DidPressMenuPreferenceKey.self) {
//                    box.value?.didPressMenuAction = $0
//                }
//                .onPreferenceChange(DidPressSelectPreferenceKey.self) {
//                    box.value?.didPressSelectAction = $0
//                }
//        ))
//        box.value = self
//
//        addButtonPressRecognizer(pressType: .menu, action: #selector(didPressMenuSelector))
//        addButtonPressRecognizer(pressType: .select, action: #selector(didPressSelectSelector))
//    }
//
//    @objc
//    dynamic required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        super.modalPresentationStyle = .fullScreen
//    }
//
//    private class Box {
//        weak var value: PreferenceUIHostingController?
//        init() {}
//    }
//
//    public var _viewPreference: UIUserInterfaceStyle = .unspecified {
//        didSet {
//            overrideUserInterfaceStyle = _viewPreference
//        }
//    }
//
//    var didPressMenuAction: ActionHolder = .init(action: {})
//    var didPressSelectAction: ActionHolder = .init(action: {})
//
//    private func addButtonPressRecognizer(pressType: UIPress.PressType, action: Selector) {
//        let pressRecognizer = UITapGestureRecognizer()
//        pressRecognizer.addTarget(self, action: action)
//        pressRecognizer.allowedPressTypes = [NSNumber(value: pressType.rawValue)]
//        view.addGestureRecognizer(pressRecognizer)
//    }
//
//    @objc
//    private func didPressMenuSelector() {
//        DispatchQueue.main.async {
//            self.didPressMenuAction.action()
//        }
//    }
//
//    @objc
//    private func didPressSelectSelector() {
//        DispatchQueue.main.async {
//            self.didPressSelectAction.action()
//        }
//    }
// }
//
// struct ActionHolder: Equatable {
//
//    static func == (lhs: ActionHolder, rhs: ActionHolder) -> Bool {
//        lhs.uuid == rhs.uuid
//    }
//
//    var action: () -> Void
//    let uuid = UUID().uuidString
// }
//
//// MARK: Preference Keys
//
// struct ViewPreferenceKey: PreferenceKey {
//    typealias Value = UIUserInterfaceStyle
//
//    static var defaultValue: UIUserInterfaceStyle = .unspecified
//
//    static func reduce(value: inout UIUserInterfaceStyle, nextValue: () -> UIUserInterfaceStyle) {
//        value = nextValue()
//    }
// }
//
// struct DidPressMenuPreferenceKey: PreferenceKey {
//
//    static var defaultValue: ActionHolder = .init(action: {})
//
//    static func reduce(value: inout ActionHolder, nextValue: () -> ActionHolder) {
//        value = nextValue()
//    }
// }
//
// struct DidPressSelectPreferenceKey: PreferenceKey {
//
//    static var defaultValue: ActionHolder = .init(action: {})
//
//    static func reduce(value: inout ActionHolder, nextValue: () -> ActionHolder) {
//        value = nextValue()
//    }
// }
//
//// MARK: Preference Key View Extension
//
// extension View {
//
//    func overrideViewPreference(_ viewPreference: UIUserInterfaceStyle) -> some View {
//        preference(key: ViewPreferenceKey.self, value: viewPreference)
//    }
//
//    func onMenuPressed(_ action: @escaping () -> Void) -> some View {
//        preference(key: DidPressMenuPreferenceKey.self, value: ActionHolder(action: action))
//    }
//
//    func onSelectPressed(_ action: @escaping () -> Void) -> some View {
//        preference(key: DidPressSelectPreferenceKey.self, value: ActionHolder(action: action))
//    }
// }
