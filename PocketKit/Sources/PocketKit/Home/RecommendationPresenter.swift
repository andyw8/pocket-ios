import Sync
import Textile
import UIKit
import Kingfisher


private extension Style {
    static let title: Style = .header.sansSerif.h6.with { paragraph in
        paragraph.with(lineBreakMode: .byTruncatingTail)
    }

    static let miniTitle: Style = .header.sansSerif.h7.with { paragraph in
        paragraph.with(lineBreakMode: .byTruncatingTail)
    }

    static let subtitle: Style = .header.sansSerif.p4.with(color: .ui.grey5).with { paragraph in
        paragraph.with(lineBreakMode: .byTruncatingTail)
    }

    static let excerpt: Style = .header.sansSerif.p4.with(color: .ui.grey4).with { paragraph in
        paragraph.with(lineBreakMode: .byTruncatingTail)
    }
}

struct RecommendationPresenter {
    private let recommendation: Slate.Recommendation

    init(recommendation: Slate.Recommendation) {
        self.recommendation = recommendation
    }

    var attributedTitle: NSAttributedString {
        return NSAttributedString(recommendation.item.title ?? "", style: .title)
    }

    var attributedTitleForMeasurement: NSAttributedString {
        let style = Style.title.with { paragraph in
            paragraph.with(lineBreakMode: .none)
        }

        return NSAttributedString(recommendation.item.title ?? "", style: style)
    }

    var attributedDetail: NSAttributedString {
        return NSAttributedString(detail, style: .subtitle)
    }

    var attributedDetailForMeasurement: NSAttributedString {
        let style = Style.subtitle.with { paragraph in
            paragraph.with(lineBreakMode: .none)
        }

        return NSAttributedString(detail, style: style)
    }
    
    func loadImage(into imageView: UIImageView, cellWidth: CGFloat) {
        let imageWidth = cellWidth
        - RecommendationCell.layoutMargins.left
        - RecommendationCell.layoutMargins.right
        
        let imageSize = CGSize(
            width: imageWidth,
            height: imageWidth * RecommendationCell.imageAspectRatio
        )

        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: cachedTopImageURL,
            options: [
                .scaleFactor(UIScreen.main.scale),
                .processor(ResizingImageProcessor(
                    referenceSize: imageSize,
                    mode: .aspectFill
                ).append(
                    another: CroppingImageProcessor(size: imageSize)
                )),
            ]
        )
    }

    private var cachedTopImageURL: URL? {
        return imageCacheURL(for: recommendation.item.topImageURL)
    }

    private var detail: String {
        [domain, timeToRead].compactMap { $0 }.joined(separator: " • ")
    }

    var attributedExcerpt: NSAttributedString {
        return NSAttributedString(recommendation.item.excerpt ?? "", style: .excerpt)
    }

    var attributedExcerptForMeasurement: NSAttributedString {
        let style = Style.excerpt.with { paragraph in
            paragraph.with(lineBreakMode: .none)
        }

        return NSAttributedString(recommendation.item.excerpt ?? "", style: style)
    }

    private var domain: String? {
        recommendation.item.domainMetadata?.name ?? recommendation.item.domain
    }

    private var timeToRead: String? {
        guard let timeToRead = recommendation.item.timeToRead,
              timeToRead > 0 else {
            return nil
        }

        return "\(timeToRead) min"
    }
}
