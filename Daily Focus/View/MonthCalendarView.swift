import UIKit

/// Month grid with task stripes under each date, plus a Stitch-style header.
final class MonthCalendarView: UIView {

    var tasksByDay: [String: [FocusTask]] = [:] {
        didSet { collectionView.reloadData(); updateSubtitle() }
    }

    var displayedMonth: Date = Date() {
        didSet { collectionView.reloadData(); updateMonthTitle(); updateSubtitle() }
    }

    var selectedDayKey: String = DayKey.string(for: Date()) {
        didSet { collectionView.reloadData() }
    }

    var onDaySelected: ((String) -> Void)?
    var onPrevMonth: (() -> Void)?
    var onNextMonth: (() -> Void)?

    private let cal = Calendar.current

    // MARK: - Header: left column

    private let monthLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let leftStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 3
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Header: nav container (right)

    private let prevMonthButton: UIButton = {
        let b = UIButton(type: .system)
        let c = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: c), for: .normal)
        b.tintColor = AppTheme.secondaryText
        b.accessibilityLabel = "Previous month"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let nextMonthButton: UIButton = {
        let b = UIButton(type: .system)
        let c = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.right", withConfiguration: c), for: .normal)
        b.tintColor = AppTheme.secondaryText
        b.accessibilityLabel = "Next month"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let navContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Calendar card

    private let calendarCard: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        buildHeader()
        buildCalendarCard()
        buildWeekdayRow()
        applyColors()
        updateMonthTitle()
        updateSubtitle()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildHeader() {
        leftStack.addArrangedSubview(monthLabel)
        leftStack.addArrangedSubview(subtitleLabel)

        navContainer.addSubview(prevMonthButton)
        navContainer.addSubview(nextMonthButton)

        addSubview(leftStack)
        addSubview(navContainer)

        prevMonthButton.addAction(UIAction { [weak self] _ in self?.onPrevMonth?() }, for: .touchUpInside)
        nextMonthButton.addAction(UIAction { [weak self] _ in self?.onNextMonth?() }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            leftStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),

            navContainer.centerYAnchor.constraint(equalTo: leftStack.centerYAnchor),
            navContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            prevMonthButton.topAnchor.constraint(equalTo: navContainer.topAnchor, constant: 4),
            prevMonthButton.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor, constant: -4),
            prevMonthButton.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor, constant: 4),
            prevMonthButton.widthAnchor.constraint(equalToConstant: 36),
            prevMonthButton.heightAnchor.constraint(equalToConstant: 36),

            nextMonthButton.topAnchor.constraint(equalTo: navContainer.topAnchor, constant: 4),
            nextMonthButton.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor, constant: -4),
            nextMonthButton.leadingAnchor.constraint(equalTo: prevMonthButton.trailingAnchor, constant: 2),
            nextMonthButton.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor, constant: -4),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 36),
            nextMonthButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func buildCalendarCard() {
        calendarCard.addSubview(weekdayStack)
        calendarCard.addSubview(collectionView)
        addSubview(calendarCard)

        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 228)

        NSLayoutConstraint.activate([
            calendarCard.topAnchor.constraint(equalTo: leftStack.bottomAnchor, constant: 14),
            calendarCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarCard.bottomAnchor.constraint(equalTo: bottomAnchor),

            weekdayStack.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 14),
            weekdayStack.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 6),
            weekdayStack.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -6),
            weekdayStack.heightAnchor.constraint(equalToConstant: 18),

            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 6),
            collectionView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -6),
            collectionHeightConstraint,
            collectionView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -10),
        ])
    }

    private func buildWeekdayRow() {
        let symbols = cal.shortWeekdaySymbols   // ["Sun", "Mon", "Tue", ...]
        let ordered: [String] = (0..<7).map { i in
            let idx = (cal.firstWeekday - 1 + i) % 7
            return symbols[idx]
        }
        for sym in ordered {
            let l = UILabel()
            l.text = sym.uppercased()
            l.font = .systemFont(ofSize: 9, weight: .bold)
            l.textColor = AppTheme.secondaryText.withAlphaComponent(0.5)
            l.textAlignment = .center
            weekdayStack.addArrangedSubview(l)
        }
    }

    private func applyColors() {
        monthLabel.textColor = AppTheme.primaryText
        subtitleLabel.textColor = AppTheme.secondaryText
        navContainer.backgroundColor = AppTheme.cardBackground
        calendarCard.backgroundColor = AppTheme.cardBackground
    }

    // MARK: - Update

    private func updateMonthTitle() {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "LLLL"
        monthLabel.text = df.string(from: displayedMonth).capitalized
    }

    private func updateSubtitle() {
        let year = cal.component(.year, from: displayedMonth)
        let ym = cal.dateComponents([.year, .month], from: displayedMonth)
        let completed = tasksByDay.filter { key, _ in
            guard let d = DayKey.date(from: key) else { return false }
            let kym = cal.dateComponents([.year, .month], from: d)
            return kym.year == ym.year && kym.month == ym.month
        }.values.flatMap { $0 }.filter { $0.isCompleted }.count
        subtitleLabel.text = "\(year)  •  \(completed) Task\(completed == 1 ? "" : "s") Completed"
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let w = collectionView.bounds.width
            guard w > 0 else { return }
            let rows = CGFloat(max(1, gridDays().count / 7))
            let cellW = floor(w / 7)
            let cellH: CGFloat = 40
            layout.itemSize = CGSize(width: cellW, height: cellH)
            layout.invalidateLayout()
            collectionHeightConstraint.constant = rows * cellH
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColors()
        collectionView.reloadData()
    }

    // MARK: - Grid helpers

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
        let isToday = item.dayKey == DayKey.string(for: Date())
        cell.configure(
            dayNumber: item.dayNumber,
            isInDisplayedMonth: item.isInDisplayedMonth,
            isSelected: isSelected,
            isToday: isToday,
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

    private static let stripeHeight: CGFloat = 3
    private static let stripeSpacing: CGFloat = 2
    private static let maxStripes = 3
    static var linesSlotHeight: CGFloat {
        CGFloat(maxStripes) * stripeHeight + CGFloat(maxStripes - 1) * stripeSpacing
    }
    private static let innerPad: CGFloat = 4

    /// Filled background for selected day.
    private let selectionBg = UIView()
    private let numberLabel = UILabel()
    private let linesSlotContainer = UIView()
    private let linesStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        selectionBg.layer.cornerRadius = 8
        selectionBg.layer.cornerCurve = .continuous
        selectionBg.translatesAutoresizingMaskIntoConstraints = false

        numberLabel.font = .systemFont(ofSize: 14, weight: .medium)
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        linesSlotContainer.translatesAutoresizingMaskIntoConstraints = false
        linesSlotContainer.backgroundColor = .clear

        linesStack.axis = .vertical
        linesStack.spacing = CalendarDayCell.stripeSpacing
        linesStack.alignment = .fill
        linesStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(selectionBg)
        contentView.addSubview(numberLabel)
        contentView.addSubview(linesSlotContainer)
        linesSlotContainer.addSubview(linesStack)

        let pad = CalendarDayCell.innerPad
        let slotHeight = linesSlotContainer.heightAnchor.constraint(equalToConstant: CalendarDayCell.linesSlotHeight)
        slotHeight.priority = .required
        let slotBottomMax = linesSlotContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -2)
        slotBottomMax.priority = .required
        NSLayoutConstraint.activate([
            selectionBg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            selectionBg.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionBg.widthAnchor.constraint(equalToConstant: 30),
            selectionBg.heightAnchor.constraint(equalToConstant: 26),

            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: selectionBg.centerYAnchor),

            linesSlotContainer.topAnchor.constraint(equalTo: selectionBg.bottomAnchor, constant: 3),
            linesSlotContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            linesSlotContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            slotHeight,
            slotBottomMax,

            linesStack.topAnchor.constraint(equalTo: linesSlotContainer.topAnchor),
            linesStack.leadingAnchor.constraint(equalTo: linesSlotContainer.leadingAnchor),
            linesStack.trailingAnchor.constraint(equalTo: linesSlotContainer.trailingAnchor),
            linesStack.bottomAnchor.constraint(lessThanOrEqualTo: linesSlotContainer.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(dayNumber: Int, isInDisplayedMonth: Bool, isSelected: Bool, isToday: Bool, tasks: [FocusTask]) {
        numberLabel.text = "\(dayNumber)"

        if isSelected {
            selectionBg.backgroundColor = AppTheme.accent
            numberLabel.textColor = .white
            numberLabel.font = .systemFont(ofSize: 14, weight: .bold)
        } else if isToday {
            selectionBg.backgroundColor = .clear
            numberLabel.textColor = AppTheme.accent
            numberLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        } else {
            selectionBg.backgroundColor = .clear
            numberLabel.textColor = isInDisplayedMonth ? AppTheme.primaryText : AppTheme.calendarDayDimmed
            numberLabel.font = .systemFont(ofSize: 14, weight: .medium)
        }

        // Task stripes — unchanged as per user requirement
        linesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for task in tasks.prefix(CalendarDayCell.maxStripes) {
            let line = UIView()
            line.layer.cornerRadius = 1
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: CalendarDayCell.stripeHeight).isActive = true
            line.backgroundColor = stripeColor(for: task.priority)
            linesStack.addArrangedSubview(line)
        }
    }

    private func stripeColor(for priority: TaskPriority) -> UIColor {
        switch priority {
        case .high:   return AppTheme.calendarStripeBlue
        case .medium: return AppTheme.priorityMedium
        case .low:    return AppTheme.calendarStripeGreen
        }
    }
}
