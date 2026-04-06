import UIKit

/// Shared form: title → priority → timing (optional all-day). Used by add sheet and task detail.
final class TaskFormView: UIView {

    private let referenceDay: Date
    private let cal = Calendar.current

    private let titleField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 17, weight: .regular)
        field.textColor = AppTheme.primaryText
        field.backgroundColor = AppTheme.fieldBackground
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let priorityStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var priorityButtons: [UIButton] = []
    private var selectedPriority: TaskPriority = .medium

    private let allDayRow = UIView()
    private let allDayIcon = UIImageView()
    private let allDayLabel = UILabel()
    private let allDaySwitch = UISwitch()

    private let timingContainer = UIView()

    /// Split date / time so compact controls stay readable full-width without inline month grids.
    private let startDayPicker = UIDatePicker()
    private let startTimePicker = UIDatePicker()
    private let endDayPicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()

    /// Full-width vertical stack: Starts → date + time, Ends → date + time.
    private let timingStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    init(referenceDay: Date) {
        self.referenceDay = cal.startOfDay(for: referenceDay)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupPriorityButtons()
        setupAllDayRow()
        setupTiming()
        layoutForm()
        applyTheme()
        setDefaultTimes()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPriorityButtons() {
        let items: [(String, TaskPriority)] = [("High", .high), ("Medium", .medium), ("Low", .low)]
        for (title, p) in items {
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            b.layer.cornerRadius = 10
            b.tag = items.firstIndex(where: { $0.1 == p }) ?? 0
            b.addAction(UIAction { [weak self] _ in self?.selectPriority(p) }, for: .touchUpInside)
            priorityButtons.append(b)
            priorityStack.addArrangedSubview(b)
        }
        selectPriority(.medium)
    }

    private func setupAllDayRow() {
        allDayRow.translatesAutoresizingMaskIntoConstraints = false
        allDayIcon.image = UIImage(systemName: "clock")
        allDayIcon.tintColor = AppTheme.primaryText
        allDayIcon.translatesAutoresizingMaskIntoConstraints = false
        allDayIcon.contentMode = .scaleAspectFit

        allDayLabel.text = "All day"
        allDayLabel.font = .systemFont(ofSize: 17, weight: .regular)
        allDayLabel.textColor = AppTheme.primaryText
        allDayLabel.translatesAutoresizingMaskIntoConstraints = false

        allDaySwitch.translatesAutoresizingMaskIntoConstraints = false
        allDaySwitch.addAction(UIAction { [weak self] _ in self?.allDayChanged() }, for: .valueChanged)

        allDayRow.addSubview(allDayIcon)
        allDayRow.addSubview(allDayLabel)
        allDayRow.addSubview(allDaySwitch)

        NSLayoutConstraint.activate([
            allDayIcon.leadingAnchor.constraint(equalTo: allDayRow.leadingAnchor),
            allDayIcon.centerYAnchor.constraint(equalTo: allDayRow.centerYAnchor),
            allDayIcon.widthAnchor.constraint(equalToConstant: 22),
            allDayIcon.heightAnchor.constraint(equalToConstant: 22),

            allDayLabel.leadingAnchor.constraint(equalTo: allDayIcon.trailingAnchor, constant: 12),
            allDayLabel.centerYAnchor.constraint(equalTo: allDayRow.centerYAnchor),

            allDaySwitch.trailingAnchor.constraint(equalTo: allDayRow.trailingAnchor),
            allDaySwitch.centerYAnchor.constraint(equalTo: allDayRow.centerYAnchor),
            allDaySwitch.leadingAnchor.constraint(greaterThanOrEqualTo: allDayLabel.trailingAnchor, constant: 12),

            allDayRow.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupTiming() {
        timingContainer.translatesAutoresizingMaskIntoConstraints = false

        for p in [startDayPicker, startTimePicker, endDayPicker, endTimePicker] {
            p.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 14.0, *) { p.preferredDatePickerStyle = .compact }
        }
        startDayPicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endDayPicker.datePickerMode = .date
        endTimePicker.datePickerMode = .time
        startDayPicker.addAction(UIAction { [weak self] _ in self?.startInputsChanged() }, for: .valueChanged)
        startTimePicker.addAction(UIAction { [weak self] _ in self?.startInputsChanged() }, for: .valueChanged)
        endDayPicker.addAction(UIAction { [weak self] _ in self?.endInputsChanged() }, for: .valueChanged)
        endTimePicker.addAction(UIAction { [weak self] _ in self?.endInputsChanged() }, for: .valueChanged)

        let startCard = makePickerCard(caption: "Starts", dayPicker: startDayPicker, timePicker: startTimePicker)
        let endCard = makePickerCard(caption: "Ends", dayPicker: endDayPicker, timePicker: endTimePicker)
        timingStack.addArrangedSubview(startCard)
        timingStack.addArrangedSubview(endCard)

        timingContainer.addSubview(timingStack)
        NSLayoutConstraint.activate([
            timingStack.topAnchor.constraint(equalTo: timingContainer.topAnchor),
            timingStack.leadingAnchor.constraint(equalTo: timingContainer.leadingAnchor),
            timingStack.trailingAnchor.constraint(equalTo: timingContainer.trailingAnchor),
            timingStack.bottomAnchor.constraint(equalTo: timingContainer.bottomAnchor)
        ])
    }

    private func makePickerCard(caption: String, dayPicker: UIDatePicker, timePicker: UIDatePicker) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AppTheme.fieldBackground
        card.layer.cornerRadius = 12

        let cap = UILabel()
        cap.text = caption.uppercased()
        cap.font = .systemFont(ofSize: 11, weight: .semibold)
        cap.textColor = AppTheme.tertiaryText
        cap.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [dayPicker, timePicker])
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(cap)
        card.addSubview(row)
        NSLayoutConstraint.activate([
            cap.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            cap.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            cap.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            row.topAnchor.constraint(equalTo: cap.bottomAnchor, constant: 8),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        return card
    }

    private func layoutForm() {
        addSubview(titleField)
        addSubview(priorityStack)
        addSubview(allDayRow)
        addSubview(timingContainer)

        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: topAnchor),
            titleField.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleField.heightAnchor.constraint(equalToConstant: 48),

            priorityStack.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            priorityStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            priorityStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            priorityStack.heightAnchor.constraint(equalToConstant: 44),

            allDayRow.topAnchor.constraint(equalTo: priorityStack.bottomAnchor, constant: 20),
            allDayRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            allDayRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            timingContainer.topAnchor.constraint(equalTo: allDayRow.bottomAnchor, constant: 16),
            timingContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            timingContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            timingContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyTheme() {
        titleField.backgroundColor = AppTheme.fieldBackground
        titleField.textColor = AppTheme.primaryText
        titleField.attributedPlaceholder = NSAttributedString(
            string: "Task name",
            attributes: [.foregroundColor: AppTheme.secondaryText]
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
        refreshPriorityButtonStyles()
    }

    private func selectPriority(_ p: TaskPriority) {
        selectedPriority = p
        refreshPriorityButtonStyles()
    }

    private func refreshPriorityButtonStyles() {
        let items: [TaskPriority] = [.high, .medium, .low]
        for (idx, b) in priorityButtons.enumerated() {
            let p = items[idx]
            let on = p == selectedPriority
            b.layer.borderWidth = on ? 2 : 0
            b.layer.borderColor = (traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.label).cgColor
            switch p {
            case .high: b.backgroundColor = AppTheme.priorityHigh
            case .medium: b.backgroundColor = AppTheme.priorityMedium
            case .low: b.backgroundColor = AppTheme.priorityLow
            }
        }
    }

    private func combine(day daySource: Date, time timeSource: Date) -> Date {
        let dc = cal.dateComponents([.year, .month, .day], from: cal.startOfDay(for: daySource))
        let tc = cal.dateComponents([.hour, .minute, .second], from: timeSource)
        var merged = DateComponents()
        merged.year = dc.year
        merged.month = dc.month
        merged.day = dc.day
        merged.hour = tc.hour
        merged.minute = tc.minute
        merged.second = tc.second
        return cal.date(from: merged) ?? daySource
    }

    private func combinedStart() -> Date {
        combine(day: startDayPicker.date, time: startTimePicker.date)
    }

    private func combinedEnd() -> Date {
        combine(day: endDayPicker.date, time: endTimePicker.date)
    }

    private func applyStartToPickers(_ date: Date) {
        startDayPicker.date = cal.startOfDay(for: date)
        startTimePicker.date = date
    }

    private func applyEndToPickers(_ date: Date) {
        endDayPicker.date = cal.startOfDay(for: date)
        endTimePicker.date = date
    }

    private func setDefaultTimes() {
        let now = Date()
        if cal.isDate(now, inSameDayAs: referenceDay) {
            let end = cal.date(byAdding: .hour, value: 1, to: now) ?? now
            applyStartToPickers(now)
            applyEndToPickers(end)
        } else {
            var c = cal.dateComponents([.year, .month, .day], from: referenceDay)
            c.hour = 10
            c.minute = 0
            let start = cal.date(from: c) ?? referenceDay
            let end = cal.date(byAdding: .hour, value: 1, to: start) ?? start
            applyStartToPickers(start)
            applyEndToPickers(end)
        }
    }

    private func allDayChanged() {
        let on = allDaySwitch.isOn
        timingContainer.isHidden = on
        if on {
            applyAllDayBounds()
        }
    }

    private func applyAllDayBounds() {
        let sod = cal.startOfDay(for: referenceDay)
        let eod = cal.date(byAdding: DateComponents(day: 1, second: -1), to: sod) ?? sod
        applyStartToPickers(sod)
        applyEndToPickers(eod)
    }

    private func startInputsChanged() {
        guard !allDaySwitch.isOn else { return }
        let start = combinedStart()
        var end = combinedEnd()
        if end <= start {
            end = cal.date(byAdding: .hour, value: 1, to: start) ?? start
            applyEndToPickers(end)
        }
    }

    private func endInputsChanged() {
        guard !allDaySwitch.isOn else { return }
        let end = combinedEnd()
        var start = combinedStart()
        if end <= start {
            start = cal.date(byAdding: .hour, value: -1, to: end) ?? end
            applyStartToPickers(start)
        }
    }

    /// Prefill for editing or add context.
    func apply(task: FocusTask?) {
        guard let task else {
            setDefaultTimes()
            return
        }
        titleField.text = task.title
        selectPriority(task.priority)
        allDaySwitch.isOn = task.isAllDay
        applyStartToPickers(task.startDate)
        applyEndToPickers(task.endDate)
        timingContainer.isHidden = task.isAllDay
        if task.isAllDay {
            applyAllDayBounds()
        }
    }

    func collectPayload() -> TaskFormPayload? {
        let raw = titleField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !raw.isEmpty else { return nil }
        let allDay = allDaySwitch.isOn
        var start = combinedStart()
        var end = combinedEnd()
        if allDay {
            let sod = cal.startOfDay(for: referenceDay)
            start = sod
            end = cal.date(byAdding: DateComponents(day: 1, second: -1), to: sod) ?? sod
        } else {
            if end <= start {
                end = cal.date(byAdding: .hour, value: 1, to: start) ?? start
            }
        }
        return TaskFormPayload(title: raw, priority: selectedPriority, isAllDay: allDay, startDate: start, endDate: end)
    }

    func focusTitleField() {
        titleField.becomeFirstResponder()
    }
}
