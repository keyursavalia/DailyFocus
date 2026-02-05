import UIKit

class EmptyStateView: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .light)
        imageView.image = UIImage(systemName: "checkmark.circle", withConfiguration: config)
        imageView.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to Daily Focus"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Focus on what matters most. Add up to 3 tasks for today and stay on track."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(white: 0.7, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let instructionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let getStartedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get Started", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onGetStartedTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(instructionStackView)
        containerView.addSubview(getStartedButton)
        
        setupInstructions()
        
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Instructions Stack
            instructionStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            instructionStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            instructionStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Get Started Button
            getStartedButton.topAnchor.constraint(equalTo: instructionStackView.bottomAnchor, constant: 32),
            getStartedButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            getStartedButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            getStartedButton.heightAnchor.constraint(equalToConstant: 50),
            getStartedButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupInstructions() {
        let instructions = [
            ("1", "Tap the 'Add' button below to create your first task"),
            ("2", "Choose a priority level (High, Medium, or Low)"),
            ("3", "Tap the circle to mark tasks as complete"),
            ("4", "Focus on up to 3 tasks per day for maximum productivity")
        ]
        
        for (number, text) in instructions {
            let instructionView = createInstructionView(number: number, text: text)
            instructionStackView.addArrangedSubview(instructionView)
        }
    }
    
    private func createInstructionView(number: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let numberLabel = UILabel()
        numberLabel.text = number
        numberLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        numberLabel.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(numberLabel)
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            numberLabel.topAnchor.constraint(equalTo: container.topAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 24),
            
            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func getStartedTapped() {
        onGetStartedTapped?()
    }
}

