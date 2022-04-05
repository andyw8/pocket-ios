import UIKit
import Textile


class SavedItemPresenter {
    func configure(infoView: InfoView) {
        infoView.style = .default
        infoView.attributedText = NSAttributedString(
            string: "Saved to Pocket",
            style: .mainText
        )
        infoView.attributedDetailText = nil
    }

    func configure(dismissLabel: UILabel) {
        dismissLabel.attributedText = NSAttributedString(string: "Tap to Dismiss", style: .dismiss)
    }
}

private extension Style {
    static func coloredMainText(color: ColorAsset) -> Style {
        .header.sansSerif.h2.with(color: color).with { $0.with(lineSpacing: 4) }
    }
    static let mainText: Self = coloredMainText(color: .ui.teal2)
    static let mainTextError: Self = coloredMainText(color: .ui.coral2)

    static let dismiss: Self = .header.sansSerif.p4.with(color: .ui.grey5).with { $0.with(lineHeight: .explicit(22)) }
}

