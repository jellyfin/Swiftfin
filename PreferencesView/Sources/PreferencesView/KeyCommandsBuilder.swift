import Foundation

@resultBuilder
public struct KeyCommandsBuilder {

    public static func buildBlock(_ components: [KeyCommandAction]...) -> [KeyCommandAction] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: KeyCommandAction) -> [KeyCommandAction] {
        [expression]
    }

    public static func buildOptional(_ component: [KeyCommandAction]?) -> [KeyCommandAction] {
        component ?? []
    }

    public static func buildEither(first component: [KeyCommandAction]) -> [KeyCommandAction] {
        component
    }

    public static func buildEither(second component: [KeyCommandAction]) -> [KeyCommandAction] {
        component
    }

    public static func buildArray(_ components: [[KeyCommandAction]]) -> [KeyCommandAction] {
        components.flatMap { $0 }
    }
}
