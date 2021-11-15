import Sync
import UIKit
import Kingfisher
import Textile
import Down


private extension Style {
    static let imageCredit: Self = .body.sansSerif
        .with(size: .p4)
        .with(color: .ui.grey3)
        .with(slant: .italic)

    static let imageCaption: Self = .body.sansSerif.with(size: .p3)
    
    static let codeBlock: Self = .body.monospace
    static let prefix: Self = .body.monospace
}

class ArticleComponentPresenter {
    private let readerSettings: ReaderSettings
    
    let component: ArticleComponent
    var isEmpty: Bool = false
    var knownSize: CGSize?

    init(component: ArticleComponent, readerSettings: ReaderSettings) {
        self.component = component
        self.readerSettings = readerSettings
        isEmpty = component.isEmpty || size(fittingWidth: .greatestFiniteMagnitude).height <= 0
    }

    func size(fittingWidth availableWidth: CGFloat) -> CGSize {
        guard !isEmpty else {
            return .zero
        }

        switch component {
        case .heading(let heading):
            return componentSize(of: heading, availableWidth: availableWidth)
        case .text(let text):
            return componentSize(of: text, availableWidth: availableWidth)
        case .image(let image):
            return componentSize(of: image, availableWidth: availableWidth)
        case .divider:
            return CGSize(width: availableWidth, height: 16)
        case .codeBlock(let codeBlock):
            return CGSize(width: availableWidth, height: componentSize(of: codeBlock).height)
        case .bulletedList(let bulletedList):
            return componentSize(of: bulletedList, availableWidth: availableWidth)
        default:
            return .zero
        }
    }
    
    func present(component: MarkdownComponent, in cell: MarkdownComponentCell) {
        cell.attributedContent = attributedContent(for: component)
    }
    
    func present(component: ImageComponent, in cell: ImageComponentCell, availableWidth: CGFloat, onSuccess: @escaping () -> Void) {
        cell.attributedCaption = attributedCaption(for: component.caption)
        cell.attributedCredit = attributedCredit(for: component.credit)
        
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
            case .success(let retrieveResult):
                self?.knownSize = retrieveResult.image.size
                onSuccess()
            case .failure:
                break
            }
        }
    }
    
    func present(component: CodeBlockComponent, in cell: CodeBlockComponentCell) {
        cell.textView.attributedText = attributedCodeBlock(for: component)
    }
    
    func present(component: BulletedListComponent, in cell: MarkdownComponentCell) {
        cell.attributedContent = attributedContent(for: component)
    }
}

private extension ArticleComponentPresenter {
    static func size(of attributedString: NSAttributedString, availableWidth: CGFloat = .infinity, availableHeight: CGFloat = .infinity) -> CGSize {
        guard !attributedString.string.isEmpty else {
            return .zero
        }

        let rect = attributedString.boundingRect(
            with: CGSize(width: availableWidth, height: availableHeight),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            context: nil
        )

        return CGSize(width: min(rect.width.rounded(.up), availableWidth), height: min(rect.height.rounded(.up), availableHeight))
    }
    
    func attributedContent(for component: MarkdownComponent) -> NSAttributedString? {
        NSAttributedString.styled(
            markdown: component.content,
            styler: NSMutableAttributedString.defaultStyler(with: readerSettings)
        )
    }
    
    func attributedCaption(for string: String?) -> NSAttributedString? {
        string.flatMap { NSAttributedString(string: $0, style: .imageCaption.modified(by: readerSettings)) }
    }

    func attributedCredit(for string: String?) -> NSAttributedString? {
        string.flatMap { NSAttributedString(string: $0, style: .imageCredit.modified(by: readerSettings)) }
    }
    
    func attributedCodeBlock(for component: CodeBlockComponent) -> NSAttributedString? {
        NSAttributedString(string: component.text, style: .codeBlock.adjustingSize(by: readerSettings.fontSizeAdjustment))
    }
    
    func attributedContent(for component: BulletedListComponent) -> NSAttributedString? {
        let attributedContent = NSMutableAttributedString()
        for row in component.rows {
            // Clamp a list element's depth to 0...3 (i.e max-depth of 4) as to allow for
            // enough room for rendering content in a readable fashion, and add the appropriate indents.
            let depth = CGFloat(min(row.level, 3))
            
            let bullet: String
            switch depth {
            case 0:
                bullet = "\u{2022} "
            case 1:
                bullet = "\u{25e6} "
            default:
                bullet = "\u{25AA}\u{fe0e} "
            }
            let prefix = NSAttributedString(string: bullet, style: .prefix.adjustingSize(by: readerSettings.fontSizeAdjustment))
            
            guard let markdown = NSAttributedString.styled(
                markdown: row.content,
                styler: NSMutableAttributedString.defaultStyler(with: readerSettings)
            ) else {
                continue
            }
            
            let content = NSMutableAttributedString(attributedString: prefix)
            content.append(markdown)
            
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = depth * 16
            style.headIndent = depth * 16 + Self.size(of: prefix).width
            
            content.addAttribute(
                .paragraphStyle,
                value: style,
                range: NSRange(location: 0, length: content.length)
            )

            attributedContent.append(NSAttributedString("\n"))
            attributedContent.append(content)
        }
        return attributedContent
    }
}

private extension ArticleComponentPresenter {
    func componentSize(of component: MarkdownComponent, availableWidth: CGFloat) -> CGSize {
        guard !component.isEmpty, let text = attributedContent(for: component) else {
            return .zero
        }

        let height = Self.size(
            of: text,
            availableWidth: availableWidth
        ).height

        return CGSize(
            width: availableWidth,
            height: height
        )
    }
    
    func componentSize(of component: ImageComponent, availableWidth: CGFloat) -> CGSize {
        var cellHeight = knownSize?.height ?? availableWidth * 9/16

        if let caption = attributedCaption(for: component.caption) {
            cellHeight += Self.size(of: caption, availableWidth: availableWidth).height + 8
        }

        if let credit = attributedCredit(for: component.credit) {
            cellHeight += Self.size(of: credit, availableWidth: availableWidth).height + 8
        }

        return CGSize(width: availableWidth, height: cellHeight)
    }
    
    func componentSize(of component: CodeBlockComponent) -> CGSize {
        guard !component.text.isEmpty, let codeBlock = attributedCodeBlock(for: component) else {
            return .zero
        }

        var size = Self.size(of: codeBlock)
        size.height += CodeBlockComponentCell.Constants.contentInset.top
        + CodeBlockComponentCell.Constants.contentInset.top
        
        return size
    }
    
    func componentSize(of component: BulletedListComponent, availableWidth: CGFloat) -> CGSize {
        guard let content = attributedContent(for: component), !content.string.isEmpty else {
            return .zero
        }

        return Self.size(of: content, availableWidth: availableWidth)
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
