import UIKit

class TaskListFooterView: UIView {
    
    // MARK: - UI Components
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "That's all for today. Stay focused."
        label.font = .italicSystemFont(ofSize: 15)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let reflectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add New Focus", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = AppTheme.elevatedBackground
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 22
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        if let img = UIImage(systemName: "pencil", withConfiguration: config)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(img, for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onReflectButtonTapped: (() -> Void)?

    private var reflectBelowMessage: NSLayoutConstraint!
    private var reflectBelowTop: NSLayoutConstraint!
    private var reflectHeightConstraint: NSLayoutConstraint!

    // MARK: - Initialization
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
        addSubview(reflectButton)
        
        reflectButton.addTarget(self, action: #selector(reflectButtonTapped), for: .touchUpInside)
        applyChrome()

        reflectBelowMessage = reflectButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16)
        reflectBelowTop = reflectButton.topAnchor.constraint(equalTo: topAnchor, constant: 6)
        reflectHeightConstraint = reflectButton.heightAnchor.constraint(equalToConstant: 44)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            reflectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            reflectButton.widthAnchor.constraint(equalToConstant: 220),
            reflectHeightConstraint,
            reflectButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            reflectBelowMessage
        ])
    }
    
    @objc private func reflectButtonTapped() {
        onReflectButtonTapped?()
    }
    
    func updateMessage(isEmpty: Bool) {
        messageLabel.isHidden = isEmpty
        reflectBelowMessage.isActive = !isEmpty
        reflectBelowTop.isActive = isEmpty
        if isEmpty {
            messageLabel.text = ""
        } else {
            messageLabel.text = "That's all for today. Stay focused."
        }
    }

    /// Show or hide the pencil Add button. Hidden when 0 tasks (empty state covers it)
    /// or when the daily limit of 3 is reached.
    func setAddButtonVisible(_ visible: Bool) {
        reflectButton.isHidden = !visible
        reflectHeightConstraint.constant = visible ? 44 : 0
    }
    
    private func applyChrome() {
        messageLabel.textColor = AppTheme.secondaryText
        reflectButton.setTitleColor(AppTheme.primaryText, for: .normal)
        reflectButton.tintColor = AppTheme.primaryText
        reflectButton.backgroundColor = AppTheme.elevatedBackground
        reflectButton.layer.borderColor = AppTheme.border.resolvedColor(with: traitCollection).cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyChrome()
    }
}

