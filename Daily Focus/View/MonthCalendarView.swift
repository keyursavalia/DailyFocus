import UIKit

/// Custom month grid with one horizontal stripe per task under each date (matches reference calendar style).
final class MonthCalendarView: UIView {

    var tasksByDay: [String: [FocusTask]] = [:] {
        didSet { collectionView.reloadData() }
    }

    var displayedMonth: Date = Date() {
        didSet { collectionView.reloadData(); updateMonthTitle() }
    }

    var selectedDayKey: String = DayKey.string(for: Date()) {
        didSet { collectionView.reloadData() }
    }

    var onDaySelected: ((String) -> Void)?
    var onPrevMonth: (() -> Void)?
    var onNextMonth: (() -> Void)?

    private let cal = Calendar.current

    private let monthTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let monthHeaderStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let prevMonthButton: UIButton = {
        let b = UIButton(type: .system)
        let c = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: c), for: .normal)
        b.tintColor = AppTheme.primaryText
        b.accessibilityLabel = "Previous month"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let nextMonthButton: UIButton = {
        let b = UIButton(type: .system)
        let c = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.right", withConfiguration: c), for: .normal)
        b.tintColor = AppTheme.primaryText
        b.accessibilityLabel = "Next month"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let weekdayStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(CalendarDayCell.self, forCellWithReuseIdentifier: CalendarDayCell.reuseId)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private var collectionHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.calendarGridBackground
        translatesAutoresizingMaskIntoConstraints = false

        configureWeekdayRow()
        configureMonthHeader()

        addSubview(monthHeaderStack)
        addSubview(weekdayStack)
        addSubview(collectionView)

        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 360)

        NSLayoutConstraint.activate([
            monthHeaderStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            monthHeaderStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            monthHeaderStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            monthHeaderStack.heightAnchor.constraint(equalToConstant: 36),

            weekdayStack.topAnchor.constraint(equalTo: monthHeaderStack.bottomAnchor, constant: 12),
            weekdayStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            weekdayStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            weekdayStack.heightAnchor.constraint(equalToConstant: 22),

            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            collectionHeightConstraint,
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        updateMonthTitle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureMonthHeader() {
        monthHeaderStack.addArrangedSubview(prevMonthButton)
        monthHeaderStack.addArrangedSubview(monthTitleLabel)
        monthHeaderStack.addArrangedSubview(nextMonthButton)
        monthHeaderStack.setCustomSpacing(8, after: prevMonthButton)
        monthHeaderStack.setCustomSpacing(8, after: monthTitleLabel)

        prevMonthButton.addAction(UIAction { [weak self] _ in self?.onPrevMonth?() }, for: .touchUpInside)
        nextMonthButton.addAction(UIAction { [weak self] _ in self?.onNextMonth?() }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            prevMonthButton.widthAnchor.constraint(equalToConstant: 40),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let w = collectionView.bounds.width
            let rows = CGFloat(max(1, gridDays().count / 7))
            let cellW = floor(w / 7)
            let cellH: CGFloat = 72
            layout.itemSize = CGSize(width: cellW, height: cellH)
            layout.invalidateLayout()
            collectionHeightConstraint.constant = rows * cellH
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.reloadData()
    }

    private func configureWeekdayRow() {
        let symbols = cal.shortWeekdaySymbols.map { String($0.prefix(1)).uppercased() }
        let ordered: [String] = (0..<7).map { i in
            let idx = (cal.firstWeekday - 1 + i) % 7
            return symbols[idx]
        }
        for sym in ordered {
            let l = UILabel()
            l.text = sym
            l.font = .systemFont(ofSize: 12, weight: .medium)
            l.textColor = AppTheme.secondaryText
            l.textAlignment = .center
            weekdayStack.addArrangedSubview(l)
        }
    }

    private func updateMonthTitle() {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "LLLL"
        monthTitleLabel.text = df.string(from: displayedMonth).uppercased()
        monthTitleLabel.textColor = AppTheme.primaryText
    }

    private func firstOfMonth(for date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    private func gridDays() -> [CalendarDayItem] {
        let monthStart = firstOfMonth(for: displayedMonth)
        guard
            let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count,
            let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthStart))
        else { return [] }

        let weekday = cal.component(.weekday, from: firstOfMonth)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        guard let gridStart = cal.date(byAdding: .day, value: -leading, to: firstOfMonth) else { return [] }

        let totalCells = leading + daysInMonth
        let rows = (totalCells + 6) / 7
        let cellCount = rows * 7

        var items: [CalendarDayItem] = []
        for i in 0..<cellCount {
            guard let date = cal.date(byAdding: .day, value: i, to: gridStart) else { continue }
            let inMonth = cal.isDate(date, equalTo: monthStart, toGranularity: .month)
            let key = DayKey.string(for: date)
            let dayNum = cal.component(.day, from: date)
            items.append(CalendarDayItem(dayKey: key, dayNumber: dayNum, isInDisplayedMonth: inMonth))
        }
        return items
    }
}

// MARK: - Grid item

private struct CalendarDayItem {
    let dayKey: String
    let dayNumber: Int
    let isInDisplayedMonth: Bool
}

// MARK: - Collection

extension MonthCalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        gridDays().count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDayCell.reuseId, for: indexPath) as! CalendarDayCell
        let days = gridDays()
        guard indexPath.item < days.count else { return cell }
        let item = days[indexPath.item]
        let tasks = (tasksByDay[item.dayKey] ?? []).sorted { $0.createdAt < $1.createdAt }
        let isSelected = item.dayKey == selectedDayKey
        cell.configure(
            dayNumber: item.dayNumber,
            isInDisplayedMonth: item.isInDisplayedMonth,
            isSelected: isSelected,
            tasks: tasks
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let days = gridDays()
        guard indexPath.item < days.count else { return }
        onDaySelected?(days[indexPath.item].dayKey)
    }
}

// MARK: - Day cell

private final class CalendarDayCell: UICollectionViewCell {
    static let reuseId = "CalendarDayCell"
    /// Space reserved for day number and selection ring; task stripes start below this so they never overlap.
    static let dayChromeHeight: CGFloat = 42

    private let numberLabel = UILabel()
    private let selectionBox = UIView()
    private let selectionCircle = UIView()
    private let circleLabel = UILabel()
    private let linesStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        numberLabel.font = .systemFont(ofSize: 16, weight: .medium)
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        selectionBox.layer.borderWidth = 1.5
        selectionBox.layer.cornerRadius = 8
        selectionBox.layer.cornerCurve = .continuous
        selectionBox.isHidden = true
        selectionBox.translatesAutoresizingMaskIntoConstraints = false

        selectionCircle.backgroundColor = .white
        selectionCircle.layer.cornerRadius = 14
        selectionCircle.isHidden = true
        selectionCircle.translatesAutoresizingMaskIntoConstraints = false

        circleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        circleLabel.textColor = .black
        circleLabel.textAlignment = .center
        circleLabel.translatesAutoresizingMaskIntoConstraints = false

        linesStack.axis = .vertical
        linesStack.spacing = 2
        linesStack.alignment = .fill
        linesStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(linesStack)
        contentView.addSubview(selectionBox)
        selectionBox.addSubview(selectionCircle)
        selectionCircle.addSubview(circleLabel)
        contentView.addSubview(numberLabel)

        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),

            selectionBox.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionBox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            selectionBox.widthAnchor.constraint(equalToConstant: 40),
            selectionBox.heightAnchor.constraint(equalToConstant: 40),

            selectionCircle.centerXAnchor.constraint(equalTo: selectionBox.centerXAnchor),
            selectionCircle.centerYAnchor.constraint(equalTo: selectionBox.centerYAnchor),
            selectionCircle.widthAnchor.constraint(equalToConstant: 28),
            selectionCircle.heightAnchor.constraint(equalToConstant: 28),

            circleLabel.centerXAnchor.constraint(equalTo: selectionCircle.centerXAnchor),
            circleLabel.centerYAnchor.constraint(equalTo: selectionCircle.centerYAnchor),

            linesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            linesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            linesStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CalendarDayCell.dayChromeHeight),
            linesStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(dayNumber: Int, isInDisplayedMonth: Bool, isSelected: Bool, tasks: [FocusTask]) {
        numberLabel.text = "\(dayNumber)"
        circleLabel.text = "\(dayNumber)"

        if isSelected {
            numberLabel.isHidden = true
            selectionBox.isHidden = false
            selectionCircle.isHidden = false
            if traitCollection.userInterfaceStyle == .dark {
                selectionBox.layer.borderColor = UIColor.white.cgColor
                selectionCircle.backgroundColor = .white
                circleLabel.textColor = .black
            } else {
                selectionBox.layer.borderColor = UIColor.label.cgColor
                selectionCircle.backgroundColor = .label
                circleLabel.textColor = .systemBackground
            }
            selectionBox.backgroundColor = .clear
        } else {
            numberLabel.isHidden = false
            selectionBox.isHidden = true
            selectionCircle.isHidden = true
            numberLabel.textColor = isInDisplayedMonth ? AppTheme.primaryText : AppTheme.calendarDayDimmed
        }

        linesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let lines = tasks.prefix(3)
        for task in lines {
            let line = UIView()
            line.layer.cornerRadius = 1
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: 3).isActive = true
            line.backgroundColor = stripeColor(for: task.priority)
            linesStack.addArrangedSubview(line)
        }
    }

    private func stripeColor(for priority: TaskPriority) -> UIColor {
        switch priority {
        case .high, .medium:
            return AppTheme.calendarStripeBlue
        case .low:
            return AppTheme.calendarStripeGreen
        }
    }
}
