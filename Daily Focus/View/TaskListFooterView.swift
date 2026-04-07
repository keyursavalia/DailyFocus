import UIKit

class TaskListFooterView: UIView {

    // MARK: - UI Components

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = "That's all for today. Stay focused."
        l.font = .italicSystemFont(ofSize: 15)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Pill button: blue circle "+" icon + "Add New Focus" text, matching the Stitch design.
    private let addButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Add New Focus", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        b.layer.cornerRadius = 26
        b.layer.cornerCurve = .continuous
        b.layer.borderWidth = 1
        b.translatesAutoresizingMaskIntoConstraints = false

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let icon = UIImage(systemName: "plus.circle.fill", withConfiguration: iconCfg)
        b.setImage(icon, for: .normal)

        // Space between icon and text
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        return b
    }()

    // MARK: - Callbacks

    var onReflectButtonTapped: (() -> Void)?

    // MARK: - Constraints toggled by state

    private var addBelowMessage: NSLayoutConstraint!
    private var addBelowTop: NSLayoutConstraint!
    private var addHeightConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(messageLabel)
        addSubview(addButton)

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        applyChrome()

        addBelowMessage = addButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16)
        addBelowTop = addButton.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        addHeightConstraint = addButton.heightAnchor.constraint(equalToConstant: 52)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            addButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 230),
            addHeightConstraint,
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            addBelowMessage,
        ])
    }

    private func applyChrome() {
        messageLabel.textColor = AppTheme.secondaryText

        addButton.backgroundColor = AppTheme.cardBackground
        addButton.setTitleColor(AppTheme.primaryText, for: .normal)
        // Icon gets accent color (blue circle); title color is set above
        addButton.tintColor = AppTheme.accent
        addButton.layer.borderColor = AppTheme.border.resolvedColor(with: traitCollection).withAlphaComponent(0.25).cgColor
    }

    // MARK: - Public API (same interface as before)

    func updateMessage(isEmpty: Bool) {
        messageLabel.isHidden = isEmpty
        addBelowMessage.isActive = !isEmpty
        addBelowTop.isActive = isEmpty
        messageLabel.text = isEmpty ? "" : "That's all for today. Stay focused."
    }

    func setAddButtonVisible(_ visible: Bool) {
        addButton.isHidden = !visible
        addHeightConstraint.constant = visible ? 52 : 0
    }

    @objc private func addTapped() {
        onReflectButtonTapped?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyChrome()
    }
}
