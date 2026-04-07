import UIKit

final class CalendarEventCell: UITableViewCell {
    static let identifier = "CalendarEventCell"

    var onCompletionTapped: (() -> Void)?

    // MARK: - Subviews

    private let card = UIView()
    private let leftBorder = UIView()
    private let iconBox = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let completeButton = UIButton(type: .custom)

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        buildCard()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildCard() {
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        leftBorder.layer.cornerRadius = 2
        leftBorder.translatesAutoresizingMaskIntoConstraints = false

        iconBox.layer.cornerRadius = 10
        iconBox.layer.cornerCurve = .continuous
        iconBox.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        completeButton.layer.cornerRadius = 14
        completeButton.layer.borderWidth = 1.5
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.addAction(UIAction { [weak self] _ in self?.onCompletionTapped?() }, for: .touchUpInside)

        iconBox.addSubview(iconImageView)
        card.addSubview(leftBorder)
        card.addSubview(iconBox)
        card.addSubview(textStack)
        card.addSubview(completeButton)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            leftBorder.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            leftBorder.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            leftBorder.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            leftBorder.widthAnchor.constraint(equalToConstant: 4),

            iconBox.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 14),
            iconBox.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBox.widthAnchor.constraint(equalToConstant: 40),
            iconBox.heightAnchor.constraint(equalToConstant: 40),

            iconImageView.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconBox.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: -10),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            completeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            completeButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 28),
            completeButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    // MARK: - Configure

    func configure(with task: FocusTask) {
        titleLabel.text = task.title

        let borderColor = priorityColor(task.priority)
        leftBorder.backgroundColor = borderColor
        iconBox.backgroundColor = borderColor.withAlphaComponent(0.15)

        let iconName = task.isCompleted ? "checkmark.circle.fill" : priorityIconName(task.priority)
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: iconCfg)
        iconImageView.tintColor = task.isCompleted ? AppTheme.calendarStripeGreen : borderColor

        if task.isCompleted {
            card.alpha = 0.6
            let attrs: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: AppTheme.tertiaryText
            ]
            titleLabel.attributedText = NSAttributedString(string: task.title, attributes: attrs)
            completeButton.layer.borderColor = AppTheme.calendarStripeGreen.cgColor
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            completeButton.setImage(UIImage(systemName: "checkmark", withConfiguration: cfg), for: .normal)
            completeButton.tintColor = AppTheme.calendarStripeGreen
            completeButton.backgroundColor = AppTheme.calendarStripeGreen.withAlphaComponent(0.15)
        } else {
            card.alpha = 1
            titleLabel.attributedText = nil
            titleLabel.text = task.title
            titleLabel.textColor = AppTheme.primaryText
            completeButton.layer.borderColor = AppTheme.secondaryText.withAlphaComponent(0.3).cgColor
            completeButton.setImage(nil, for: .normal)
            completeButton.backgroundColor = .clear
        }

        card.backgroundColor = AppTheme.cardBackground

        let longFmt = DateFormatter()
        longFmt.locale = Locale.current
        longFmt.dateFormat = "h:mm a"

        if task.isAllDay {
            subtitleLabel.text = "All day"
        } else {
            subtitleLabel.text = "\(longFmt.string(from: task.startDate)) — \(longFmt.string(from: task.endDate))"
        }
    }

    // MARK: - Helpers

    private func priorityColor(_ priority: TaskPriority) -> UIColor {
        switch priority {
        case .high:   return AppTheme.calendarStripeBlue
        case .medium: return AppTheme.priorityMedium
        case .low:    return AppTheme.calendarStripeGreen
        }
    }

    private func priorityIconName(_ priority: TaskPriority) -> String {
        switch priority {
        case .high:   return "bolt.fill"
        case .medium: return "minus.circle.fill"
        case .low:    return "leaf.fill"
        }
    }
}
