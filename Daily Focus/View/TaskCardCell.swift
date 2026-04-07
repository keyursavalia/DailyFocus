import UIKit

class TaskCardCell: UITableViewCell {
    static let identifier = "TaskCardCell"
    
    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.cardBackground
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = AppTheme.primaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priorityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppTheme.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let carriedOverTag: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0)
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let carriedOverLabel: UILabel = {
        let label = UILabel()
        label.text = "CARRIED OVER"
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let clockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let checkmarkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 12
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    var onCheckmarkTapped: (() -> Void)?
    private var currentTask: FocusTask?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(priorityLabel)
        cardView.addSubview(carriedOverTag)
        cardView.addSubview(checkmarkButton)
        
        carriedOverTag.addSubview(clockIcon)
        carriedOverTag.addSubview(carriedOverLabel)
        
        checkmarkButton.addTarget(self, action: #selector(checkmarkTapped), for: .touchUpInside)
        applyCheckmarkBorderColor()
        
        NSLayoutConstraint.activate([
            // Card View
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: checkmarkButton.leadingAnchor, constant: -16),
            
            // Priority Label
            priorityLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priorityLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            priorityLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            // Carried Over Tag
            carriedOverTag.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            carriedOverTag.leadingAnchor.constraint(equalTo: priorityLabel.trailingAnchor, constant: 8),
            carriedOverTag.heightAnchor.constraint(equalToConstant: 20),
            
            // Clock Icon
            clockIcon.leadingAnchor.constraint(equalTo: carriedOverTag.leadingAnchor, constant: 6),
            clockIcon.centerYAnchor.constraint(equalTo: carriedOverTag.centerYAnchor),
            clockIcon.widthAnchor.constraint(equalToConstant: 12),
            clockIcon.heightAnchor.constraint(equalToConstant: 12),
            
            // Carried Over Label
            carriedOverLabel.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 4),
            carriedOverLabel.trailingAnchor.constraint(equalTo: carriedOverTag.trailingAnchor, constant: -6),
            carriedOverLabel.centerYAnchor.constraint(equalTo: carriedOverTag.centerYAnchor),
            
            // Checkmark Button
            checkmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            checkmarkButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            checkmarkButton.widthAnchor.constraint(equalToConstant: 24),
            checkmarkButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    func configure(with task: FocusTask) {
        currentTask = task
        let primary = AppTheme.primaryText
        let muted = AppTheme.tertiaryText
        let accent = AppTheme.accent
        
        // Configure title with strikethrough if completed
        let attributedTitle = NSMutableAttributedString(string: task.title)
        if task.isCompleted {
            attributedTitle.addAttribute(
                .strikethroughStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: NSRange(location: 0, length: task.title.count)
            )
            titleLabel.textColor = muted
        } else {
            titleLabel.textColor = primary
        }
        titleLabel.attributedText = attributedTitle
        
        // Configure priority
        priorityLabel.text = task.priority.rawValue
        priorityLabel.isHidden = task.isCarriedOver
        
        // Configure carried over tag
        carriedOverTag.isHidden = !task.isCarriedOver
        
        // Configure checkmark
        if task.isCompleted {
            cardView.alpha = 0.55
            cardView.backgroundColor = AppTheme.cardBackground.withAlphaComponent(0.9)
        } else {
            cardView.alpha = 1.0
            cardView.backgroundColor = AppTheme.cardBackground
        }

        if task.isCompleted {
            checkmarkButton.backgroundColor = accent
            checkmarkButton.layer.borderColor = accent.resolvedColor(with: traitCollection).cgColor
            checkmarkButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            checkmarkButton.tintColor = .white
        } else {
            checkmarkButton.backgroundColor = .clear
            applyCheckmarkBorderColor()
            checkmarkButton.setImage(nil, for: .normal)
        }
    }
    
    private func applyCheckmarkBorderColor() {
        checkmarkButton.layer.borderColor = AppTheme.primaryText.resolvedColor(with: traitCollection).cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let task = currentTask {
            configure(with: task)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask = nil
    }
    
    // MARK: - Actions
    @objc private func checkmarkTapped() {
        onCheckmarkTapped?()
    }
}

