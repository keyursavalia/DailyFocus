import UIKit

/// Shared form: title → priority → timing (optional all-day). Used by add sheet and task detail.
final class TaskFormView: UIView {

    private let referenceDay: Date
    private let cal = Calendar.current

    // MARK: - Section labels

    private let focusSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "WHAT IS YOUR FOCUS?"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let prioritySectionLabel: UILabel = {
        let l = UILabel()
        l.text = "PRIORITY LEVEL"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Title field

    private let titleField: UITextField = {
        let f = UITextField()
        f.font = .systemFont(ofSize: 17, weight: .regular)
        f.layer.cornerRadius = 12
        f.layer.cornerCurve = .continuous
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftViewMode = .always
        f.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.rightViewMode = .always
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    // MARK: - Priority

    private let priorityStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var priorityButtons: [UIButton] = []
    private var selectedPriority: TaskPriority = .medium

    // MARK: - All Day row

    private let allDayRow = UIView()

    private let allDayTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "All Day"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let allDaySubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Set as a persistent daily goal"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let allDaySwitch = UISwitch()

    // MARK: - Timing

    private let timingContainer = UIView()

    private let startDayPicker = UIDatePicker()
    private let startTimePicker = UIDatePicker()
    private let endDayPicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()

    // MARK: - Init

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

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupPriorityButtons() {
        // Order: Low | Medium | High  (matching reference design)
        let items: [(String, TaskPriority)] = [("Low", .low), ("Medium", .medium), ("High", .high)]
        for (title, p) in items {
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            b.layer.cornerRadius = 10
            b.layer.cornerCurve = .continuous
            b.layer.borderWidth = 0
            b.addAction(UIAction { [weak self] _ in self?.selectPriority(p) }, for: .touchUpInside)
            priorityButtons.append(b)
            priorityStack.addArrangedSubview(b)
        }
        selectPriority(.medium)
    }

    private func setupAllDayRow() {
        allDayRow.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [allDayTitleLabel, allDaySubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        allDaySwitch.translatesAutoresizingMaskIntoConstraints = false
        allDaySwitch.addAction(UIAction { [weak self] _ in self?.allDayChanged() }, for: .valueChanged)

        allDayRow.addSubview(textStack)
        allDayRow.addSubview(allDaySwitch)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: allDayRow.leadingAnchor),
            textStack.topAnchor.constraint(equalTo: allDayRow.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: allDayRow.bottomAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: allDaySwitch.leadingAnchor, constant: -12),

            allDaySwitch.trailingAnchor.constraint(equalTo: allDayRow.trailingAnchor),
            allDaySwitch.centerYAnchor.constraint(equalTo: allDayRow.centerYAnchor),
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

        let startColumn = makeTimeColumn(label: "START TIME", dayPicker: startDayPicker, timePicker: startTimePicker)
        let endColumn = makeTimeColumn(label: "END TIME", dayPicker: endDayPicker, timePicker: endTimePicker)

        let columnsStack = UIStackView(arrangedSubviews: [startColumn, endColumn])
        columnsStack.axis = .horizontal
        columnsStack.distribution = .fillEqually
        columnsStack.spacing = 12
        columnsStack.translatesAutoresizingMaskIntoConstraints = false

        timingContainer.addSubview(columnsStack)
        NSLayoutConstraint.activate([
            columnsStack.topAnchor.constraint(equalTo: timingContainer.topAnchor),
            columnsStack.leadingAnchor.constraint(equalTo: timingContainer.leadingAnchor),
            columnsStack.trailingAnchor.constraint(equalTo: timingContainer.trailingAnchor),
            columnsStack.bottomAnchor.constraint(equalTo: timingContainer.bottomAnchor),
        ])
    }

    private func makeTimeColumn(label text: String, dayPicker: UIDatePicker, timePicker: UIDatePicker) -> UIView {
        let col = UIView()
        col.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        let box = UIView()
        box.layer.cornerRadius = 10
        box.layer.cornerCurve = .continuous
        box.backgroundColor = AppTheme.fieldBackground
        box.translatesAutoresizingMaskIntoConstraints = false

        let pickerStack = UIStackView(arrangedSubviews: [dayPicker, timePicker])
        pickerStack.axis = .vertical
        pickerStack.spacing = 4
        pickerStack.alignment = .leading
        pickerStack.translatesAutoresizingMaskIntoConstraints = false

        box.addSubview(pickerStack)
        col.addSubview(label)
        col.addSubview(box)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: col.topAnchor),
            label.leadingAnchor.constraint(equalTo: col.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: col.trailingAnchor),

            box.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            box.leadingAnchor.constraint(equalTo: col.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: col.trailingAnchor),
            box.bottomAnchor.constraint(equalTo: col.bottomAnchor),

            pickerStack.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            pickerStack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            pickerStack.trailingAnchor.constraint(lessThanOrEqualTo: box.trailingAnchor, constant: -12),
            pickerStack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
        ])

        return col
    }

    private func layoutForm() {
        addSubview(focusSectionLabel)
        addSubview(titleField)
        addSubview(prioritySectionLabel)
        addSubview(priorityStack)
        addSubview(allDayRow)
        addSubview(timingContainer)

        NSLayoutConstraint.activate([
            focusSectionLabel.topAnchor.constraint(equalTo: topAnchor),
            focusSectionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            focusSectionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleField.topAnchor.constraint(equalTo: focusSectionLabel.bottomAnchor, constant: 8),
            titleField.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleField.heightAnchor.constraint(equalToConstant: 52),

            prioritySectionLabel.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 24),
            prioritySectionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            prioritySectionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            priorityStack.topAnchor.constraint(equalTo: prioritySectionLabel.bottomAnchor, constant: 8),
            priorityStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            priorityStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            priorityStack.heightAnchor.constraint(equalToConstant: 46),

            allDayRow.topAnchor.constraint(equalTo: priorityStack.bottomAnchor, constant: 24),
            allDayRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            allDayRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            timingContainer.topAnchor.constraint(equalTo: allDayRow.bottomAnchor, constant: 20),
            timingContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            timingContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            timingContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func applyTheme() {
        focusSectionLabel.textColor = AppTheme.accent
        prioritySectionLabel.textColor = AppTheme.secondaryText
        allDayTitleLabel.textColor = AppTheme.primaryText
        allDaySubtitleLabel.textColor = AppTheme.secondaryText

        titleField.backgroundColor = AppTheme.fieldBackground
        titleField.textColor = AppTheme.primaryText
        titleField.attributedPlaceholder = NSAttributedString(
            string: "Deep work on Project X...",
            attributes: [.foregroundColor: AppTheme.secondaryText]
        )

        refreshPriorityButtonStyles()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    // MARK: - Priority

    private func selectPriority(_ p: TaskPriority) {
        selectedPriority = p
        refreshPriorityButtonStyles()
    }

    private func refreshPriorityButtonStyles() {
        let priorities: [TaskPriority] = [.low, .medium, .high]
        for (idx, b) in priorityButtons.enumerated() {
            let p = priorities[idx]
            let selected = p == selectedPriority
            b.backgroundColor = AppTheme.fieldBackground
            if selected {
                b.setTitleColor(AppTheme.accent, for: .normal)
                b.layer.borderWidth = 1.5
                b.layer.borderColor = AppTheme.accent.withAlphaComponent(0.5).cgColor
            } else {
                b.setTitleColor(AppTheme.secondaryText, for: .normal)
                b.layer.borderWidth = 0
                b.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }

    // MARK: - All Day

    private func allDayChanged() {
        let on = allDaySwitch.isOn
        timingContainer.isHidden = on
        if on { applyAllDayBounds() }
    }

    private func applyAllDayBounds() {
        let sod = cal.startOfDay(for: referenceDay)
        let eod = cal.date(byAdding: DateComponents(day: 1, second: -1), to: sod) ?? sod
        applyStartToPickers(sod)
        applyEndToPickers(eod)
    }

    // MARK: - Timing helpers

    private func combine(day daySource: Date, time timeSource: Date) -> Date {
        let dc = cal.dateComponents([.year, .month, .day], from: cal.startOfDay(for: daySource))
        let tc = cal.dateComponents([.hour, .minute, .second], from: timeSource)
        var merged = DateComponents()
        merged.year = dc.year; merged.month = dc.month; merged.day = dc.day
        merged.hour = tc.hour; merged.minute = tc.minute; merged.second = tc.second
        return cal.date(from: merged) ?? daySource
    }

    private func combinedStart() -> Date { combine(day: startDayPicker.date, time: startTimePicker.date) }
    private func combinedEnd()   -> Date { combine(day: endDayPicker.date,   time: endTimePicker.date) }

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
            c.hour = 9; c.minute = 0
            let start = cal.date(from: c) ?? referenceDay
            let end = cal.date(byAdding: .hour, value: 2, to: start) ?? start
            applyStartToPickers(start)
            applyEndToPickers(end)
        }
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

    // MARK: - Public API

    func apply(task: FocusTask?) {
        guard let task else { setDefaultTimes(); return }
        titleField.text = task.title
        selectPriority(task.priority)
        allDaySwitch.isOn = task.isAllDay
        applyStartToPickers(task.startDate)
        applyEndToPickers(task.endDate)
        timingContainer.isHidden = task.isAllDay
        if task.isAllDay { applyAllDayBounds() }
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
        } else if end <= start {
            end = cal.date(byAdding: .hour, value: 1, to: start) ?? start
        }
        return TaskFormPayload(title: raw, priority: selectedPriority, isAllDay: allDay, startDate: start, endDate: end)
    }

    func focusTitleField() {
        titleField.becomeFirstResponder()
    }
}
