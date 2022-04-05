import UIKit


class LoggedOutViewController: UIViewController {
    private let imageView = UIImageView(image: UIImage(asset: .logo))

    private let infoView = InfoView()

    private let dismissLabel = UILabel()

    private let viewModel: LoggedOutViewModel

    init(viewModel: LoggedOutViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(.ui.white1)

        view.addSubview(imageView)
        view.addSubview(infoView)
        view.addSubview(dismissLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        infoView.translatesAutoresizingMaskIntoConstraints = false
        dismissLabel.translatesAutoresizingMaskIntoConstraints = false

        let capsuleTopConstraint = NSLayoutConstraint(
            item: infoView,
            attribute: .top,
            relatedBy: .equal,
            toItem: view,
            attribute: .bottom,
            multiplier: 0.35,
            constant: 0
        )

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 36),

            capsuleTopConstraint,
            infoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            infoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            dismissLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        infoView.model = viewModel.infoViewModel
        dismissLabel.attributedText = viewModel.dismissAttributedText

        let tap = UITapGestureRecognizer(target: self, action: #selector(finish))
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if viewModel.canRespond(from: self) {
            let actionButton = UIButton(
                configuration:.borderless(),
                primaryAction: UIAction { [weak self] _ in
                    self?.logIn()
                }
            )
            actionButton.accessibilityIdentifier = "log-in"

            actionButton.configuration = viewModel.actionButtonConfiguration

            view.addSubview(actionButton)

            actionButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                actionButton.bottomAnchor.constraint(equalTo: dismissLabel.topAnchor, constant: -16),
                actionButton.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                actionButton.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            ])
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear(context: extensionContext)
    }
}

private extension LoggedOutViewController {
    @objc
    private func finish() {
        viewModel.finish(context: extensionContext)
    }

    private func logIn() {
        viewModel.logIn(from: extensionContext, origin: self)
    }
}
