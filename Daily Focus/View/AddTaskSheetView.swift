import UIKit

class AddTaskSheetView: UIView {

    private let dimmedBackground: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.dimmedOverlay
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.elevatedBackground
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .interactive
        // UIScrollView has no intrinsic height; without this, Auto Layout can compress
        // the scroll area to 0 when the card is only vertically centered with max height.
        s.setContentCompressionResistancePriority(.required, for: .vertical)
        return s
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: "New ", attributes: [
            .font: UIFont.systemFont(ofSize: 26, weight: .heavy),
            .foregroundColor: AppTheme.accent
        ]))
        str.append(NSAttributedString(string: "Focus", attributes: [
            .font: UIFont.systemFont(ofSize: 26, weight: .heavy),
            .foregroundColor: AppTheme.primaryText
        ]))
        label.attributedText = str
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Name it · set priority · schedule it"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppTheme.tertiaryText
        label.numberOfLines = 1
        return label
    }()

    private let formView: TaskFormView
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = AppTheme.accent
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let referenceDay: Date

    var onSave: ((TaskFormPayload) -> Void)?
    var onCancelTapped: (() -> Void)?

    init(referenceDay: Date) {
        self.referenceDay = referenceDay
        self.formView = TaskFormView(referenceDay: referenceDay)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(dimmedBackground)
        addSubview(cardView)
        cardView.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(formView)

        cardView.addSubview(addButton)
        cardView.addSubview(cancelButton)

        dimmedBackground.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmedTapped)))
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dimmedBackground.topAnchor.constraint(equalTo: topAnchor),
            dimmedBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmedBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmedBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.heightAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.heightAnchor, constant: -48),

            // Reserve real space for the form; otherwise the scroll view collapses vertically.
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),

            scrollView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            addButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -12),
            addButton.heightAnchor.constraint(equalToConstant: 48),

            cancelButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    func applyPrefill(_ task: FocusTask?) {
        formView.apply(task: task)
    }

    @objc private func addTapped() {
        guard let payload = formView.collectPayload() else { return }
        onSave?(payload)
    }

    @objc private func cancelTapped() {
        onCancelTapped?()
    }

    @objc private func dimmedTapped() {
        onCancelTapped?()
    }

    func show(in view: UIView) {
        view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        alpha = 0
        UIView.animate(withDuration: 0.25) { self.alpha = 1 }
        layoutIfNeeded()
        formView.focusTitleField()
    }

    func dismiss() {
        formView.endEditing(true)
        UIView.animate(withDuration: 0.25, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
