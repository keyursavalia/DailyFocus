import UIKit

final class CalendarEventCell: UITableViewCell {
    static let identifier = "CalendarEventCell"

    private let timeLabel = UILabel()
    private let accentBar = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textBlock = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        timeLabel.textColor = AppTheme.secondaryText
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        accentBar.layer.cornerRadius = 2
        accentBar.layer.cornerCurve = .continuous
        accentBar.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        textBlock.axis = .vertical
        textBlock.spacing = 4
        textBlock.translatesAutoresizingMaskIntoConstraints = false
        textBlock.addArrangedSubview(titleLabel)
        textBlock.addArrangedSubview(subtitleLabel)

        contentView.addSubview(timeLabel)
        contentView.addSubview(accentBar)
        contentView.addSubview(textBlock)

        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            timeLabel.widthAnchor.constraint(equalToConstant: 52),

            accentBar.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
            accentBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            accentBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            textBlock.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            textBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textBlock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with task: FocusTask) {
        titleLabel.text = task.title
        accentBar.backgroundColor = priorityColor(task.priority)

        let cal = Calendar.current
        let start = task.createdAt
        let end = cal.date(byAdding: .hour, value: 1, to: start) ?? start

        let shortFmt = DateFormatter()
        shortFmt.locale = Locale.current
        shortFmt.dateFormat = "h:mm"

        let longFmt = DateFormatter()
        longFmt.locale = Locale.current
        longFmt.dateFormat = "h:mm a"

        timeLabel.text = shortFmt.string(from: start)
        subtitleLabel.text = "\(longFmt.string(from: start)) – \(longFmt.string(from: end))"
    }

    private func priorityColor(_ priority: TaskPriority) -> UIColor {
        switch priority {
        case .high, .medium:
            return AppTheme.calendarStripeBlue
        case .low:
            return AppTheme.calendarStripeGreen
        }
    }
}
