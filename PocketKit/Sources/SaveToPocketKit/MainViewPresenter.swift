import UIKit
import Textile


protocol MainViewPresenter {
    var additionalView: UIView? { get }
    func update(infoView: MainInfoView)
}

class SavedViewPresenter: MainViewPresenter {
    let additionalView: UIView? = nil

    func update(infoView: MainInfoView) {
        infoView.style = .default
        infoView.attributedText = NSAttributedString(
            string: "Saved to Pocket",
            style: .mainText
        )
        infoView.attributedDetailText = nil
    }
}

class LoggedOutViewPresenter: MainViewPresenter {
    private let action: () -> Void

    lazy var additionalView: UIView? = {
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

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    func update(infoView: MainInfoView) {
        infoView.style = .error
        infoView.attributedText = NSAttributedString(
            string: "Log in to Pocket to save",
            style: .mainTextError
        )
        infoView.attributedDetailText = NSAttributedString(
            string: "Pocket couldn't save the link. Log in to the Pocket app and try saving again.",
            style: .detailText
        )
    }
}

private extension Style {
    static let logIn: Self = .header.sansSerif.h7.with(color: .ui.white)

    static func coloredMainText(color: ColorAsset) -> Style {
        .header.sansSerif.h2.with(color: color).with { $0.with(lineSpacing: 4) }
    }
    static let mainText: Self = coloredMainText(color: .ui.teal2)
    static let mainTextError: Self = coloredMainText(color: .ui.coral2)

    static let detailText: Self = .header.sansSerif.p2.with { $0.with(lineHeight: .explicit(28)).with(alignment: .center) }
}
