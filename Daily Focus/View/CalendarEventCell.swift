import UIKit

final class CalendarEventCell: UITableViewCell {
    static let identifier = "CalendarEventCell"

    private let accentBar = UIView()
    private let cardBackground = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardBackground.layer.cornerRadius = 10
        cardBackground.layer.cornerCurve = .continuous
        cardBackground.backgroundColor = AppTheme.cardBackground
        cardBackground.translatesAutoresizingMaskIntoConstraints = false

        accentBar.layer.cornerRadius = 2
        accentBar.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardBackground)
        cardBackground.addSubview(accentBar)
        cardBackground.addSubview(titleLabel)
        cardBackground.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            cardBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            accentBar.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: 0),
            accentBar.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: 8),
            accentBar.bottomAnchor.constraint(equalTo: cardBackground.bottomAnchor, constant: -8),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            titleLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardBackground.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with task: FocusTask) {
        titleLabel.text = task.title
        let status = task.isCompleted ? "Completed" : "Not completed"
        subtitleLabel.text = "All-day · \(task.priority.rawValue) · \(status)"
        accentBar.backgroundColor = priorityColor(task.priority)
    }

    private func priorityColor(_ priority: TaskPriority) -> UIColor {
        switch priority {
        case .high: return AppTheme.priorityHigh
        case .medium: return AppTheme.priorityMedium
        case .low: return AppTheme.priorityLow
        }
    }
}
