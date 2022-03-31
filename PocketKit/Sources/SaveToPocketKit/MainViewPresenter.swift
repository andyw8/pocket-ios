import UIKit
import Textile


protocol MainViewPresenter {
    var view: UIView? { get }
}

class SavedViewPresenter: MainViewPresenter {
    let view: UIView? = nil
}

class LoggedOutViewPresenter: MainViewPresenter {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    lazy var view: UIView? = {
        var configuration: UIButton.Configuration = .filled()
        configuration.background.backgroundColor = UIColor(.ui.teal2)
        configuration.background.cornerRadius = 13
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 0, bottom: 13, trailing: 0)
        configuration.attributedTitle = AttributedString(NSAttributedString(string: "Log in to Pocket", style: .logIn))

        let action = UIAction { [weak self] _ in
            self?.action()
        }

        let button = UIButton(configuration: configuration, primaryAction: action)
        button.accessibilityIdentifier = "log-in"

        return button
    }()
}

private extension Style {
    static let logIn: Self = .header.sansSerif.h7.with(color: .ui.white)
}
