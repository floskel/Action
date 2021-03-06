import UIKit
import RxSwift
import RxCocoa

public extension UIAlertAction {

    public static func Action(_ title: String?, style: UIAlertActionStyle) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: { action in
            action.rx.action?.execute()
            return
        })
    }
}

public extension Reactive where Base: UIAlertAction {

    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, set the rx_action to nil or another action.
    public var action: CocoaAction? {
        get {
            var action: CocoaAction?
            doLocked {
                action = objc_getAssociatedObject(base, &AssociatedKeys.Action) as? Action
            }
            return action
        }

        set {
            doLocked {
                // Store new value.
                objc_setAssociatedObject(base, &AssociatedKeys.Action, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // This effectively disposes of any existing subscriptions.
                self.base.resetActionDisposeBag()

                // Set up new bindings, if applicable.
                if let action = newValue {
                    action
                        .enabled
                        .bindTo(self.enabled)
                        .addDisposableTo(self.base.actionDisposeBag)
                }
            }
        }
    }
	
	public var enabled: AnyObserver<Bool> {
		return AnyObserver { [weak base] event in
			MainScheduler.ensureExecutingOnScheduler()
			
			switch event {
			case .next(let value):
				base?.isEnabled = value
			case .error(let error):
				let error = "Binding error to UI: \(error)"
				#if DEBUG
					rxFatalError(error)
				#else
					print(error)
				#endif
				break
			case .completed:
				break
			}
		}
	}
}
