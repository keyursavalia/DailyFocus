import UIKit

class TaskListFooterView: UIView {
    
    // MARK: - UI Components
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "That's all for today. Stay focused."
        label.font = .italicSystemFont(ofSize: 15)
        label.textColor = UIColor(white: 0.6, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let reflectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(white: 0.3, alpha: 1.0).cgColor
        button.layer.cornerRadius = 12
        
        // Add calendar icon
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let calendarImage = UIImage(systemName: "pencil", withConfiguration: config)
        
        if let calendarImage = calendarImage {
            let combinedImage = calendarImage.withTintColor(.white, renderingMode: .alwaysOriginal)
            button.setImage(combinedImage, for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onReflectButtonTapped: (() -> Void)?
    
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
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            reflectButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            reflectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            reflectButton.widthAnchor.constraint(equalToConstant: 160),
            reflectButton.heightAnchor.constraint(equalToConstant: 44),
            reflectButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func reflectButtonTapped() {
        onReflectButtonTapped?()
    }
    
    func updateMessage(isEmpty: Bool) {
        if isEmpty {
            messageLabel.text = "Ready to focus? Let's get started!"
        } else {
            messageLabel.text = "That's all for today. Stay focused."
        }
    }
}

