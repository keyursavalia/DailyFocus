import UIKit

class AddTaskSheetView: UIView {
    
    // MARK: - UI Components
    private let dimmedBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "New Focus"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your task and choose a priority."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(white: 0.7, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let taskTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter task..."
        field.font = .systemFont(ofSize: 17, weight: .regular)
        field.textColor = .white
        field.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let priorityStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor(white: 0.7, alpha: 1.0), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    var onAddTapped: ((String, TaskPriority) -> Void)?
    var onCancelTapped: (() -> Void)?
    
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
        addSubview(dimmedBackground)
        addSubview(cardView)
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(messageLabel)
        cardView.addSubview(taskTextField)
        cardView.addSubview(priorityStackView)
        cardView.addSubview(cancelButton)
        
        let priorities: [(String, TaskPriority)] = [
            ("High", .high),
            ("Medium", .medium),
            ("Low", .low)
        ]
        
        for (title, priority) in priorities {
            let button = createPriorityButton(title: title, priority: priority)
            priorityStackView.addArrangedSubview(button)
        }
        
        dimmedBackground.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmedTapped)))
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            dimmedBackground.topAnchor.constraint(equalTo: topAnchor),
            dimmedBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmedBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmedBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            taskTextField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            taskTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            taskTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            taskTextField.heightAnchor.constraint(equalToConstant: 48),
            
            priorityStackView.topAnchor.constraint(equalTo: taskTextField.bottomAnchor, constant: 20),
            priorityStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            priorityStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            priorityStackView.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: priorityStackView.bottomAnchor, constant: 24),
            cancelButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }
    
    private func createPriorityButton(title: String, priority: TaskPriority) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        switch priority {
        case .high:
            button.backgroundColor = UIColor(red: 0.75, green: 0.35, blue: 0.35, alpha: 1.0)
        case .medium:
            button.backgroundColor = UIColor(red: 0.75, green: 0.65, blue: 0.25, alpha: 1.0)
        case .low:
            button.backgroundColor = UIColor(red: 0.35, green: 0.6, blue: 0.4, alpha: 1.0)
        }
        button.layer.cornerRadius = 10
        button.tag = priority == .high ? 0 : (priority == .medium ? 1 : 2)
        button.addTarget(self, action: #selector(priorityButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    @objc private func priorityButtonTapped(_ sender: UIButton) {
        let priority: TaskPriority = sender.tag == 0 ? .high : (sender.tag == 1 ? .medium : .low)
        let text = taskTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        onAddTapped?(text, priority)
    }
    
    @objc private func cancelTapped() {
        onCancelTapped?()
    }
    
    @objc private func dimmedTapped() {
        onCancelTapped?()
    }
    
    // MARK: - Public
    func show(in view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
        taskTextField.becomeFirstResponder()
    }
    
    func dismiss() {
        taskTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
