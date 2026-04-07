import UIKit

enum TaskDisplayState {
    case completed
    case inFocus
    case nextUp
}

class TaskCardCell: UITableViewCell {
    static let identifier = "TaskCardCell"

    private static let green = UIColor(red: 71 / 255, green: 226 / 255, blue: 102 / 255, alpha: 1)

    // MARK: - Card container

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Status chip (top-left)

    private let statusChip: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let statusChipLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Action icon (top-right, tappable)

    private let actionButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Title

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Priority row

    private let priorityIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let priorityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let priorityStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 5
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Carried-over tag (kept from original)

    private let carriedOverTag: UIView = {
        let v = UIView()
        v.backgroundColor = AppTheme.carriedOverOrange
        v.layer.cornerRadius = 8
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let carriedOverLabel: UILabel = {
        let l = UILabel()
        l.text = "CARRIED OVER"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let clockIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "clock.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Properties

    var onCheckmarkTapped: (() -> Void)?
    private var currentTask: FocusTask?
    private var currentState: TaskDisplayState = .nextUp

    // MARK: - Init

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

        statusChip.addSubview(statusChipLabel)
        carriedOverTag.addSubview(clockIcon)
        carriedOverTag.addSubview(carriedOverLabel)
        priorityStack.addArrangedSubview(priorityIcon)
        priorityStack.addArrangedSubview(priorityLabel)

        contentView.addSubview(cardView)
        cardView.addSubview(statusChip)
        cardView.addSubview(actionButton)
        cardView.addSubview(titleLabel)
        cardView.addSubview(priorityStack)
        cardView.addSubview(carriedOverTag)

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Status chip
            statusChip.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            statusChip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            statusChipLabel.topAnchor.constraint(equalTo: statusChip.topAnchor, constant: 4),
            statusChipLabel.bottomAnchor.constraint(equalTo: statusChip.bottomAnchor, constant: -4),
            statusChipLabel.leadingAnchor.constraint(equalTo: statusChip.leadingAnchor, constant: 10),
            statusChipLabel.trailingAnchor.constraint(equalTo: statusChip.trailingAnchor, constant: -10),

            // Action button top-right
            actionButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 13),
            actionButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            actionButton.widthAnchor.constraint(equalToConstant: 28),
            actionButton.heightAnchor.constraint(equalToConstant: 28),

            // Title
            titleLabel.topAnchor.constraint(equalTo: statusChip.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            // Priority stack
            priorityStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priorityStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            priorityStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            priorityIcon.widthAnchor.constraint(equalToConstant: 14),
            priorityIcon.heightAnchor.constraint(equalToConstant: 14),

            // Carried-over tag (overlays priority row)
            carriedOverTag.centerYAnchor.constraint(equalTo: priorityStack.centerYAnchor),
            carriedOverTag.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            carriedOverTag.heightAnchor.constraint(equalToConstant: 22),

            clockIcon.leadingAnchor.constraint(equalTo: carriedOverTag.leadingAnchor, constant: 6),
            clockIcon.centerYAnchor.constraint(equalTo: carriedOverTag.centerYAnchor),
            clockIcon.widthAnchor.constraint(equalToConstant: 12),
            clockIcon.heightAnchor.constraint(equalToConstant: 12),

            carriedOverLabel.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 4),
            carriedOverLabel.trailingAnchor.constraint(equalTo: carriedOverTag.trailingAnchor, constant: -6),
            carriedOverLabel.centerYAnchor.constraint(equalTo: carriedOverTag.centerYAnchor),
        ])
    }

    // MARK: - Configure

    func configure(with task: FocusTask, state: TaskDisplayState) {
        currentTask = task
        currentState = state

        let green = TaskCardCell.green
        let blue = AppTheme.accent
        let tc = traitCollection

        // Card background & border
        cardView.backgroundColor = AppTheme.cardBackground
        switch state {
        case .completed:
            cardView.alpha = 0.6
            cardView.layer.borderWidth = 0
        case .inFocus:
            cardView.alpha = 1.0
            cardView.layer.borderWidth = 1.5
            cardView.layer.borderColor = blue.withAlphaComponent(0.35).cgColor
        case .nextUp:
            cardView.alpha = 1.0
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = AppTheme.border.resolvedColor(with: tc).withAlphaComponent(0.2).cgColor
        }

        // Status chip
        switch state {
        case .completed:
            statusChip.backgroundColor = green.withAlphaComponent(0.12)
            statusChipLabel.text = "COMPLETED"
            statusChipLabel.textColor = green
        case .inFocus:
            statusChip.backgroundColor = blue.withAlphaComponent(0.12)
            statusChipLabel.text = "IN FOCUS"
            statusChipLabel.textColor = blue
        case .nextUp:
            statusChip.backgroundColor = AppTheme.fieldBackground
            statusChipLabel.text = "NEXT UP"
            statusChipLabel.textColor = AppTheme.secondaryText
        }

        // Title
        let attributed = NSMutableAttributedString(string: task.title)
        if task.isCompleted {
            attributed.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue,
                                    range: NSRange(location: 0, length: task.title.count))
            titleLabel.textColor = AppTheme.tertiaryText
        } else {
            titleLabel.textColor = AppTheme.primaryText
        }
        titleLabel.attributedText = attributed

        // Action icon
        let symCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
        switch state {
        case .completed:
            actionButton.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: symCfg), for: .normal)
            actionButton.tintColor = green
        case .inFocus:
            actionButton.setImage(UIImage(systemName: "dot.circle", withConfiguration: symCfg), for: .normal)
            actionButton.tintColor = blue
        case .nextUp:
            actionButton.setImage(UIImage(systemName: "clock", withConfiguration: symCfg), for: .normal)
            actionButton.tintColor = AppTheme.secondaryText
        }

        // Priority
        priorityStack.isHidden = task.isCarriedOver
        carriedOverTag.isHidden = !task.isCarriedOver

        if !task.isCarriedOver {
            let symSmall = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            switch task.priority {
            case .high:
                priorityIcon.image = UIImage(systemName: "arrowshape.up.fill", withConfiguration: symSmall)
                priorityIcon.tintColor = AppTheme.priorityHigh
            case .medium:
                priorityIcon.image = UIImage(systemName: "minus", withConfiguration: symSmall)
                priorityIcon.tintColor = AppTheme.secondaryText
            case .low:
                priorityIcon.image = UIImage(systemName: "arrowshape.down.fill", withConfiguration: symSmall)
                priorityIcon.tintColor = AppTheme.priorityLow
            }
            priorityLabel.text = task.priority.rawValue
            priorityLabel.textColor = AppTheme.secondaryText
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let task = currentTask {
            configure(with: task, state: currentState)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask = nil
        cardView.alpha = 1.0
        cardView.layer.borderWidth = 0
    }

    @objc private func actionTapped() {
        onCheckmarkTapped?()
    }
}
