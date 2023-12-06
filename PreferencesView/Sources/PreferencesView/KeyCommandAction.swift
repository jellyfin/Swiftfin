import UIKit

public struct KeyCommandAction {

    let title: String
    let subtitle: String?
    let input: Character
    let modifierFlags: UIKeyModifierFlags
    let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        input: Character,
        modifierFlags: UIKeyModifierFlags = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.input = input
        self.modifierFlags = modifierFlags
        self.action = action
    }
}

extension KeyCommandAction: Equatable {

    public static func == (lhs: KeyCommandAction, rhs: KeyCommandAction) -> Bool {
        lhs.input == rhs.input
    }
}
