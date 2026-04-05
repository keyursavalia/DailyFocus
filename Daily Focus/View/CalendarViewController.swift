import UIKit

/// Month grid with task stripes under each date, plus a day agenda panel below.
final class CalendarViewController: UIViewController {

    private let monthCalendarView = MonthCalendarView()
    private let dayPanel = UIView()
    private let dayTitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let bottomBar = UIStackView()
    private let quickAddButton = UIButton(type: .system)
    private let addFAB = UIButton(type: .system)

    private let sideToolsDrawer = SideToolsDrawerView()

    private var tasksByDay: [String: [FocusTask]] = [:]
    private var selectedDayKey: String = DayKey.string(for: Date())
    private var displayedMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()

    private let persistence = PersistenceManager.shared
    private let cal = Calendar.current

    private var displayedTasks: [FocusTask] {
        (tasksByDay[selectedDayKey] ?? []).sorted { $0.startDate < $1.startDate }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.calendarGridBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        configureMonthCalendar()
        configureDayPanel()
        configureTable()
        configureBottomBar()
        configureSideDrawer()
        layoutViews()

        reloadFromDisk()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSignificantTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFromDisk()
    }

    @objc private func onSignificantTimeChange() {
        let todayKey = DayKey.string(for: Date())
        selectedDayKey = todayKey
        displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? displayedMonth
        syncMonthViewState()
        reloadFromDisk()
    }

    private func configureMonthCalendar() {
        monthCalendarView.displayedMonth = displayedMonth
        monthCalendarView.selectedDayKey = selectedDayKey
        monthCalendarView.onDaySelected = { [weak self] key in
            self?.applySelectedDayKey(key)
        }
        monthCalendarView.onPrevMonth = { [weak self] in
            self?.shiftMonth(-1)
        }
        monthCalendarView.onNextMonth = { [weak self] in
            self?.shiftMonth(1)
        }
    }

    private func configureDayPanel() {
        dayPanel.backgroundColor = AppTheme.calendarPanelBackground
        dayPanel.translatesAutoresizingMaskIntoConstraints = false

        dayTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        dayTitleLabel.textColor = AppTheme.primaryText
        dayTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        updateDayTitle()
    }

    private func configureTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CalendarEventCell.self, forCellReuseIdentifier: CalendarEventCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
    }

    private func configureBottomBar() {
        bottomBar.axis = .horizontal
        bottomBar.spacing = 12
        bottomBar.alignment = .center
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        quickAddButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        quickAddButton.setTitleColor(AppTheme.secondaryText, for: .normal)
        quickAddButton.backgroundColor = AppTheme.cardBackground
        quickAddButton.layer.cornerRadius = 22
        quickAddButton.layer.cornerCurve = .continuous
        quickAddButton.contentHorizontalAlignment = .leading
        quickAddButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        quickAddButton.addAction(UIAction { [weak self] _ in self?.presentAddTask() }, for: .touchUpInside)

        let addIcon = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        addFAB.setImage(UIImage(systemName: "plus", withConfiguration: addIcon), for: .normal)
        addFAB.tintColor = AppTheme.primaryText
        addFAB.backgroundColor = AppTheme.cardBackground
        addFAB.layer.cornerRadius = 22
        addFAB.layer.cornerCurve = .continuous
        addFAB.addAction(UIAction { [weak self] _ in self?.presentAddTask() }, for: .touchUpInside)
        addFAB.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addFAB.widthAnchor.constraint(equalToConstant: 44),
            addFAB.heightAnchor.constraint(equalToConstant: 44)
        ])

        bottomBar.addArrangedSubview(quickAddButton)
        bottomBar.addArrangedSubview(addFAB)
        quickAddButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        updateQuickAddTitle()
    }

    private func configureSideDrawer() {
        sideToolsDrawer.translatesAutoresizingMaskIntoConstraints = false
        sideToolsDrawer.onResetTapped = { [weak self] in
            self?.sideToolsDrawer.setOpen(false, animated: true)
            self?.showResetConfirmation()
        }
        sideToolsDrawer.onAppearanceTapped = { [weak self] in
            AppearanceManager.shared.cyclePreference()
            self?.sideToolsDrawer.updateAppearanceButtonIcon()
        }
        sideToolsDrawer.updateAppearanceButtonIcon()
        view.addSubview(sideToolsDrawer)
        sideToolsDrawer.attachScreenEdgePan(to: view)

        NSLayoutConstraint.activate([
            sideToolsDrawer.topAnchor.constraint(equalTo: view.topAnchor),
            sideToolsDrawer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sideToolsDrawer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sideToolsDrawer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func layoutViews() {
        view.addSubview(monthCalendarView)
        view.addSubview(dayPanel)
        dayPanel.addSubview(dayTitleLabel)
        dayPanel.addSubview(tableView)
        view.addSubview(bottomBar)

        monthCalendarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            monthCalendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            monthCalendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            monthCalendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dayPanel.topAnchor.constraint(equalTo: monthCalendarView.bottomAnchor, constant: 0),
            dayPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayPanel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),

            dayTitleLabel.topAnchor.constraint(equalTo: dayPanel.safeAreaLayoutGuide.topAnchor, constant: 8),
            dayTitleLabel.leadingAnchor.constraint(equalTo: dayPanel.leadingAnchor, constant: 20),
            dayTitleLabel.trailingAnchor.constraint(equalTo: dayPanel.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: dayTitleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: dayPanel.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: dayPanel.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: dayPanel.bottomAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            quickAddButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        view.bringSubviewToFront(sideToolsDrawer)
    }

    private func applySelectedDayKey(_ key: String) {
        selectedDayKey = key
        if let d = DayKey.date(from: key) {
            let m = cal.component(.month, from: d)
            let y = cal.component(.year, from: d)
            let curM = cal.component(.month, from: displayedMonth)
            let curY = cal.component(.year, from: displayedMonth)
            if m != curM || y != curY {
                displayedMonth = cal.date(from: DateComponents(year: y, month: m, day: 1)) ?? displayedMonth
            }
        }
        syncMonthViewState()
        updateDayTitle()
        updateQuickAddTitle()
        tableView.reloadData()
    }

    private func firstOfMonth(_ date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    private func shiftMonth(_ delta: Int) {
        guard
            let nextMonth = cal.date(byAdding: .month, value: delta, to: firstOfMonth(displayedMonth)),
            let first = cal.date(from: cal.dateComponents([.year, .month], from: nextMonth))
        else { return }
        displayedMonth = first
        selectedDayKey = DayKey.string(for: first)
        syncMonthViewState()
        updateDayTitle()
        updateQuickAddTitle()
        tableView.reloadData()
    }

    private func syncMonthViewState() {
        monthCalendarView.tasksByDay = tasksByDay
        monthCalendarView.displayedMonth = displayedMonth
        monthCalendarView.selectedDayKey = selectedDayKey
    }

    private func updateDayTitle() {
        guard let d = DayKey.date(from: selectedDayKey) else { return }
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMMM d · EEE"
        dayTitleLabel.text = df.string(from: d)
    }

    private func updateQuickAddTitle() {
        guard let d = DayKey.date(from: selectedDayKey) else { return }
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMM d"
        let suffix = df.string(from: d)
        quickAddButton.setTitle("Add event on \(suffix)", for: .normal)
    }

    private func reloadFromDisk() {
        tasksByDay = persistence.loadTasksByDay()
        let todayKey = DayKey.string(for: Date())
        let todayOnly = tasksByDay[todayKey] ?? []
        sideToolsDrawer.updateResetButtonVisibility(hasTasks: !todayOnly.isEmpty)
        syncMonthViewState()
        updateDayTitle()
        updateQuickAddTitle()
        tableView.reloadData()
    }

    private func presentDetail(for task: FocusTask) {
        let key = selectedDayKey
        let detail = TaskCalendarDetailViewController(dayKey: key, task: task) { [weak self] updated in
            self?.replaceTask(updated, dayKey: key)
        }
        let nav = UINavigationController(rootViewController: detail)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func replaceTask(_ task: FocusTask, dayKey: String) {
        var map = persistence.loadTasksByDay()
        guard var list = map[dayKey], let i = list.firstIndex(where: { $0.id == task.id }) else {
            reloadFromDisk()
            return
        }
        list[i] = task
        map[dayKey] = list
        persistence.saveTasksByDay(map)
        reloadFromDisk()
    }

    private func presentAddTask() {
        let dayTasks = tasksByDay[selectedDayKey] ?? []
        guard dayTasks.count < 3 else {
            showErrorAlert(error: .limitReached)
            return
        }

        guard let dayDate = DayKey.date(from: selectedDayKey) else { return }
        let addTaskSheet = AddTaskSheetView(referenceDay: dayDate)
        addTaskSheet.onSave = { [weak self] payload in
            guard let self else { return }
            addTaskSheet.dismiss()
            self.addTask(payload: payload, dayKey: self.selectedDayKey)
        }
        addTaskSheet.onCancelTapped = {
            addTaskSheet.dismiss()
        }
        addTaskSheet.show(in: view)
    }

    private func addTask(payload: TaskFormPayload, dayKey: String) {
        var map = persistence.loadTasksByDay()
        var list = map[dayKey] ?? []
        guard list.count < 3 else {
            showErrorAlert(error: .limitReached)
            return
        }
        let task = FocusTask(
            title: payload.title.trimmingCharacters(in: .whitespaces),
            isCompleted: false,
            priority: payload.priority,
            isCarriedOver: false,
            createdAt: Date(),
            dayKey: dayKey,
            isAllDay: payload.isAllDay,
            startDate: payload.startDate,
            endDate: payload.endDate
        )
        list.append(task)
        map[dayKey] = list
        persistence.saveTasksByDay(map)
        reloadFromDisk()
    }

    private func showErrorAlert(error: TaskError) {
        let alert = UIAlertController(title: error.alertTitle, message: error.errorDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showResetConfirmation() {
        let alert = UIAlertController(
            title: "Reset Today’s Tasks",
            message: "This removes every focus task scheduled for today only. Tasks on other days are kept.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            guard let self else { return }
            var map = self.persistence.loadTasksByDay()
            let todayKey = DayKey.string(for: Date())
            map[todayKey] = []
            self.persistence.saveTasksByDay(map)
            self.reloadFromDisk()
        })
        present(alert, animated: true)
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(displayedTasks.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if displayedTasks.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            cell.textLabel?.text = "No tasks"
            cell.textLabel?.textColor = AppTheme.secondaryText
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            cell.detailTextLabel?.text = "Add a focus task for this day using the bar below."
            cell.detailTextLabel?.textColor = AppTheme.tertiaryText
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCell.identifier, for: indexPath) as! CalendarEventCell
        cell.configure(with: displayedTasks[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !displayedTasks.isEmpty else { return }
        presentDetail(for: displayedTasks[indexPath.row])
    }
}
