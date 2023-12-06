import SwiftUI

public class UIPreferencesHostingController: UIHostingController<AnyView> {

    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        let box = Box()
        let rootView = AnyView(
            content()
                .onPreferenceChange(KeyCommandsPreferenceKey.self) {
                    box.value?._keyCommandActions = $0
                }
                .onPreferenceChange(PrefersHomeIndicatorAutoHiddenPreferenceKey.self) {
                    box.value?._prefersHomeIndicatorAutoHidden = $0
                }
                .onPreferenceChange(PreferredScreenEdgesDeferringSystemGesturesPreferenceKey.self) {
                    box.value?._preferredScreenEdgesDeferringSystemGestures = $0
                }
                .onPreferenceChange(SupportedOrientationsPreferenceKey.self) {
                    box.value?._orientations = $0
                }
        )
        
        super.init(rootView: rootView)
        
        box.value = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Defer Edges
    
    private var _preferredScreenEdgesDeferringSystemGestures: UIRectEdge = [.left, .right] {
        didSet { setNeedsUpdateOfScreenEdgesDeferringSystemGestures() }
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        _preferredScreenEdgesDeferringSystemGestures
    }

    // MARK: Home Indicator Auto Hidden

    private var _prefersHomeIndicatorAutoHidden = false {
        didSet { setNeedsUpdateOfHomeIndicatorAutoHidden() }
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }
    
    // MARK: Key Commands
    
    private var _keyCommandActions: [KeyCommandAction] = [] {
        willSet {
            _keyCommands = newValue.map { action in
                let keyCommand = UIKeyCommand(
                    title: action.title,
                    action: #selector(keyCommandHit),
                    input: String(action.input),
                    modifierFlags: action.modifierFlags
                )
                
                keyCommand.subtitle = action.subtitle
                keyCommand.wantsPriorityOverSystemBehavior = true
                
                return keyCommand
            }
        }
    }
    
    private var _keyCommands: [UIKeyCommand] = []

    public override var keyCommands: [UIKeyCommand]? {
        _keyCommands
    }

    @objc
    private func keyCommandHit(keyCommand: UIKeyCommand) {
        guard let action = _keyCommandActions.first(where: { $0.input == keyCommand.input && $0.modifierFlags == keyCommand.modifierFlags }) else { return }
        action.action()
    }
    
    // MARK: Orientation

    var _orientations: UIInterfaceOrientationMask = .all {
        didSet {
            if #available(iOS 16, *) {
                setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _orientations
    }
}
