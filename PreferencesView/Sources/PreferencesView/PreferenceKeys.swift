import SwiftUI

struct KeyCommandsPreferenceKey: PreferenceKey {

    static var defaultValue: [KeyCommandAction] = []

    static func reduce(value: inout [KeyCommandAction], nextValue: () -> [KeyCommandAction]) {
        value.append(contentsOf: nextValue())
    }
}

struct PreferredScreenEdgesDeferringSystemGesturesPreferenceKey: PreferenceKey {
    
    static var defaultValue: UIRectEdge = [.left, .right]
    
    static func reduce(value: inout UIRectEdge, nextValue: () -> UIRectEdge) { }
}

struct PrefersHomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {

    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue() || value
    }
}

struct SupportedOrientationsPreferenceKey: PreferenceKey {

    static var defaultValue: UIInterfaceOrientationMask = .allButUpsideDown

    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) { }
}
