import UIKit
import SharedPocketKit
import Combine


class LoggedOutViewModel {
    private let dismissTimer: Timer.TimerPublisher

    private var dismissTimerCancellable: AnyCancellable? = nil

    lazy var presenter: LoggedOutViewPresenter = {
        LoggedOutViewPresenter()
    }()

    init(dismissTimer: Timer.TimerPublisher) {
        self.dismissTimer = dismissTimer
    }

    func viewDidAppear(context: ExtensionContext?) {
        autodismiss(from: context)
    }

    func canRespond(from origin: Any) -> Bool {
        return responder(from: origin) != nil
    }

    func finish(context: ExtensionContext?, completionHandler: ((Bool) -> Void)? = nil) {
        context?.completeRequest(returningItems: nil, completionHandler: completionHandler)
    }

    func logIn(from context: ExtensionContext?, origin: Any) {
        guard let responder = responder(from: origin) else {
            return
        }

        finish(context: context) { [weak self] _ in
            self?.open(url: URL(string: "pocket-next:")!, using: responder)
        }
    }
}

extension LoggedOutViewModel {
    private func responder(from origin: Any) -> UIResponder? {
        guard let origin = origin as? UIResponder else {
            return nil
        }

        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = origin
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }

        return responder
    }

    private func open(url: URL, using responder: UIResponder) {
        let selector = sel_registerName("openURL:")
        responder.perform(selector, with: url)
    }

    private func autodismiss(from context: ExtensionContext?) {
        dismissTimerCancellable = dismissTimer.autoconnect().first().sink(receiveCompletion:{ [weak self] _ in
            self?.finish(context: context)
        }, receiveValue: { _ in })
    }

    private func handleLoggedOut(context: ExtensionContext?, origin: Any) {
        logIn(from: context, origin: origin)
    }
}
