import UIKit

/// Month grid with task stripes under each date, plus a day agenda panel below.
final class CalendarViewController: UIViewController {

    private let monthCalendarView = MonthCalendarView()
    private let dayPanel = UIView()
    private let dayTitleRow = UIStackView()
    private let dayTitleLabel = UILabel()
    private let moodButton = UIButton(type: .system)
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
        (tasksByDay[selectedDayKey] ?? []).sorted { $0.createdAt < $1.createdAt }
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
        monthCalendarView.onSearchTapped = { [weak self] in
            self?.presentSearchFilter()
        }
        monthCalendarView.setMenuAction(UIAction { [weak self] _ in
            self?.sideToolsDrawer.setOpen(true, animated: true)
        })
    }

    private func configureDayPanel() {
        dayPanel.backgroundColor = AppTheme.calendarPanelBackground
        dayPanel.translatesAutoresizingMaskIntoConstraints = false

        dayTitleRow.axis = .horizontal
        dayTitleRow.alignment = .center
        dayTitleRow.distribution = .equalSpacing
        dayTitleRow.translatesAutoresizingMaskIntoConstraints = false

        dayTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        dayTitleLabel.textColor = AppTheme.primaryText

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        moodButton.setImage(UIImage(systemName: "face.smiling", withConfiguration: config), for: .normal)
        moodButton.tintColor = AppTheme.secondaryText
        moodButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.moodButton.alpha = 0.5
            UIView.animate(withDuration: 0.2) { self?.moodButton.alpha = 1 }
        }, for: .touchUpInside)

        dayTitleRow.addArrangedSubview(dayTitleLabel)
        dayTitleRow.addArrangedSubview(moodButton)

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

        addFAB.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)), for: .normal)
        addFAB.tintColor = AppTheme.primaryText
        addFAB.backgroundColor = AppTheme.calendarFABBackground
        addFAB.layer.cornerRadius = 28
        addFAB.addAction(UIAction { [weak self] _ in self?.presentAddTask() }, for: .touchUpInside)
        addFAB.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addFAB.widthAnchor.constraint(equalToConstant: 56),
            addFAB.heightAnchor.constraint(equalToConstant: 56)
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
        dayPanel.addSubview(dayTitleRow)
        dayPanel.addSubview(tableView)
        view.addSubview(bottomBar)

        monthCalendarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            monthCalendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            monthCalendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            monthCalendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dayPanel.topAnchor.constraint(equalTo: monthCalendarView.bottomAnchor),
            dayPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayPanel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),

            dayTitleRow.topAnchor.constraint(equalTo: dayPanel.safeAreaLayoutGuide.topAnchor, constant: 12),
            dayTitleRow.leadingAnchor.constraint(equalTo: dayPanel.leadingAnchor, constant: 20),
            dayTitleRow.trailingAnchor.constraint(equalTo: dayPanel.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: dayTitleRow.bottomAnchor, constant: 8),
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
        taskFilter = ""
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
        taskFilter = ""
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
        let dayNum = cal.component(.day, from: d)
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEE"
        let wd = df.string(from: d).uppercased()
        dayTitleLabel.text = "\(dayNum) \(wd)"
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
        sideToolsDrawer.updateResetButtonVisibility(hasTasks: !tasksByDay.values.flatMap { $0 }.isEmpty)
        syncMonthViewState()
        updateDayTitle()
        updateQuickAddTitle()
        tableView.reloadData()
    }

    private func presentDetail(for task: FocusTask) {
        let detail = TaskCalendarDetailViewController(task: task)
        let nav = UINavigationController(rootViewController: detail)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func presentAddTask() {
        let dayTasks = tasksByDay[selectedDayKey] ?? []
        guard dayTasks.count < 3 else {
            showErrorAlert(error: .limitReached)
            return
        }

        let addTaskSheet = AddTaskSheetView()
        addTaskSheet.onAddTapped = { [weak self] text, priority in
            guard let self else { return }
            guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                addTaskSheet.dismiss()
                self.showErrorAlert(error: .emptyTitle)
                return
            }
            addTaskSheet.dismiss()
            self.addTask(title: text, priority: priority, dayKey: self.selectedDayKey)
        }
        addTaskSheet.onCancelTapped = {
            addTaskSheet.dismiss()
        }
        addTaskSheet.show(in: view)
    }

    private func addTask(title: String, priority: TaskPriority, dayKey: String) {
        var map = persistence.loadTasksByDay()
        var list = map[dayKey] ?? []
        guard list.count < 3 else {
            showErrorAlert(error: .limitReached)
            return
        }
        let task = FocusTask(
            title: title.trimmingCharacters(in: .whitespaces),
            isCompleted: false,
            priority: priority,
            isCarriedOver: false,
            createdAt: Date(),
            dayKey: dayKey
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
            title: "Reset All Tasks",
            message: "Are you sure you want to delete all tasks? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            PersistenceManager.shared.clearAllTasks()
            self?.reloadFromDisk()
        })
        present(alert, animated: true)
    }

    private var taskFilter: String = ""

    private func presentSearchFilter() {
        let alert = UIAlertController(title: "Filter tasks", message: "Search titles for the selected day.", preferredStyle: .alert)
        alert.addTextField { [weak self] field in
            field.placeholder = "Search"
            field.text = self?.taskFilter
        }
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.taskFilter = ""
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { [weak self] _ in
            self?.taskFilter = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            self?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func filteredTasks() -> [FocusTask] {
        let base = displayedTasks
        let q = taskFilter.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let n = filteredTasks().count
        return max(n, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tasks = filteredTasks()
        if tasks.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            cell.textLabel?.text = taskFilter.isEmpty ? "No tasks" : "No matches"
            cell.textLabel?.textColor = AppTheme.secondaryText
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            cell.detailTextLabel?.text = taskFilter.isEmpty
                ? "Add a focus task for this day using the bar below."
                : "Try a different search."
            cell.detailTextLabel?.textColor = AppTheme.tertiaryText
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCell.identifier, for: indexPath) as! CalendarEventCell
        cell.configure(with: tasks[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tasks = filteredTasks()
        guard !tasks.isEmpty else { return }
        presentDetail(for: tasks[indexPath.row])
    }
}
