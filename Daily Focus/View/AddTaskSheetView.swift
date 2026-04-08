import UIKit

class AddTaskSheetView: UIView {

    // MARK: - Subviews

    private let dimmedBackground: UIView = {
        let v = UIView()
        v.backgroundColor = AppTheme.dimmedOverlay
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Header row (title + X button) – sits above the scroll view
    private let headerRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "New Focus"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        b.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Scroll + form
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .interactive
        s.setContentCompressionResistancePriority(.required, for: .vertical)
        return s
    }()

    private let formView: TaskFormView

    // Gradient pill button
    private let addButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("  Add Focus", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        b.layer.cornerRadius = 26
        b.layer.cornerCurve = .continuous
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        b.setImage(UIImage(systemName: "bolt.fill", withConfiguration: cfg), for: .normal)
        return b
    }()

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.678, green: 0.776, blue: 1.0, alpha: 1).cgColor,
            UIColor(red: 0.294, green: 0.557, blue: 1.0, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()

    // MARK: - Callbacks & State

    private let referenceDay: Date
    var onSave: ((TaskFormPayload) -> Void)?
    var onCancelTapped: (() -> Void)?

    // MARK: - Init

    init(referenceDay: Date) {
        self.referenceDay = referenceDay
        self.formView = TaskFormView(referenceDay: referenceDay)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        applyColors()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        addSubview(dimmedBackground)
        addSubview(cardView)

        // Header
        headerRow.addSubview(titleLabel)
        headerRow.addSubview(closeButton)
        cardView.addSubview(headerRow)

        // Scroll
        scrollView.addSubview(formView)
        cardView.addSubview(scrollView)

        // Add button (gradient layer inserted in layoutSubviews)
        addButton.layer.insertSublayer(gradientLayer, at: 0)
        cardView.addSubview(addButton)

        dimmedBackground.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        )
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Dimmed overlay
            dimmedBackground.topAnchor.constraint(equalTo: topAnchor),
            dimmedBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmedBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmedBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Card
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.heightAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.heightAnchor, constant: -48),

            // Header row
            headerRow.topAnchor.constraint(equalTo: cardView.topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            headerRow.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor, constant: 24),
            titleLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: headerRow.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),

            // Form inside scroll
            formView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            formView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            formView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            formView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Add button
            addButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    private func applyColors() {
        cardView.backgroundColor = AppTheme.elevatedBackground
        titleLabel.textColor = AppTheme.primaryText
        closeButton.tintColor = AppTheme.secondaryText
        let buttonTextColor = UIColor(red: 0, green: 0.18, blue: 0.41, alpha: 1)
        addButton.setTitleColor(buttonTextColor, for: .normal)
        addButton.tintColor = buttonTextColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = addButton.bounds
        gradientLayer.cornerRadius = addButton.layer.cornerRadius
    }

    // MARK: - Public API

    func applyPrefill(_ task: FocusTask?) {
        formView.apply(task: task)
    }

    func show(in view: UIView) {
        view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        alpha = 0
        UIView.animate(withDuration: 0.22) { self.alpha = 1 }
        layoutIfNeeded()
        formView.focusTitleField()
    }

    func dismiss() {
        formView.endEditing(true)
        UIView.animate(withDuration: 0.22, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Actions

    @objc private func addTapped() {
        guard let payload = formView.collectPayload() else { return }
        onSave?(payload)
    }

    @objc private func cancelTapped() {
        onCancelTapped?()
    }
}
