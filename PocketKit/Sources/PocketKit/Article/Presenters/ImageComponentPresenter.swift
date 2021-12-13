import Sync
import UIKit
import Kingfisher
import Textile


private extension Style {
    static let imageCredit: Self = .body.sansSerif
        .with(size: .p4)
        .with(color: .ui.grey3)
        .with(slant: .italic)

    static let imageCaption: Self = .body.sansSerif.with(size: .p3)
}

class ImageComponentPresenter: ArticleComponentPresenter {
    private let component: ImageComponent
    
    private let readerSettings: ReaderSettings
    
    private var availableWidth: CGFloat
    
    private let dequeue: (IndexPath) -> ImageComponentCell
    
    private let onUpdate: () -> Void
    
    private var lastImageSize: CGSize?
    
    private lazy var caption: NSAttributedString? = {
        component.caption.flatMap { NSAttributedString(string: $0, style: .imageCaption.modified(by: readerSettings)) }
    }()
    
    private lazy var credit: NSAttributedString? = {
        component.credit.flatMap { NSAttributedString(string: $0, style: .imageCredit.modified(by: readerSettings)) }
    }()
    
    lazy var size: CGSize = {
        var height = lastImageSize?.height ?? availableWidth * 9 / 16
        
        if let caption = caption {
            height += caption.sizeFitting(availableWidth: availableWidth).height + 8
        }
        
        if let credit = credit {
            height += credit.sizeFitting(availableWidth: availableWidth).height + 8
        }
        
        return CGSize(width: availableWidth, height: height)
    }()
    
    func cell(for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeue(indexPath)
        
        cell.attributedCaption = caption
        cell.attributedCredit = credit
        
        let size = CGSize(
            width: availableWidth,
            height: .greatestFiniteMagnitude
        )

        let cachedSource = imageCacheURL(for: component.source)
        cell.imageView.kf.indicatorType = .activity
        cell.imageView.kf.setImage(
            with: cachedSource,
            options: [
                .scaleFactor(UIScreen.main.scale),
                .processor(
                    OnlyResizeDownProcessor(
                        resizingProcessor: ResizingImageProcessor(
                            referenceSize: size,
                            mode: .aspectFit
                        )
                     )
                )
            ]
        ) { [weak self] result in
            switch result {
            case .success(let result):
                self?.lastImageSize = result.image.size
                self?.onUpdate()
            case .failure:
                break
            }
        }
        
        return cell
    }
    
    required init(component: ImageComponent,
                  readerSettings: ReaderSettings,
                  availableWidth: CGFloat,
                  onUpdate: @escaping () -> Void,
                  dequeue: @escaping (IndexPath) -> ImageComponentCell
    ) {
        self.component = component
        self.readerSettings = readerSettings
        self.availableWidth = availableWidth
        self.onUpdate = onUpdate
        self.dequeue = dequeue
    }
}

private class OnlyResizeDownProcessor: ImageProcessor {
    let identifier = "com.getpocket.image-processor.only-resize-down"

    let resizingProcessor: ResizingImageProcessor

    init(resizingProcessor: ResizingImageProcessor) {
        self.resizingProcessor = resizingProcessor
    }

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            guard image.size.height > resizingProcessor.referenceSize.height
                    || image.size.width > resizingProcessor.referenceSize.width else {
                        return image
                    }

            return resizingProcessor.process(item: item, options: options)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}
