import UIKit

/// Month grid with task stripes under each date, plus a day agenda panel below.
final class CalendarViewController: UIViewController {

    // Custom nav bar
    private let customNavBar = UIView()
    private let hamburgerButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let todayButton = UIButton(type: .system)

    private let monthCalendarView = MonthCalendarView()

    // Panel header
    private let panelHeaderRow = UIView()
    private let focusTitleLabel = UILabel()
    private let itemsBadgeView = UIView()
    private let itemsBadgeLabel = UILabel()

    private let tableView = UITableView(frame: .zero, style: .plain)

    // Floating add button
    private let fabButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        b.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        b.layer.cornerRadius = 25
        b.layer.cornerCurve = .continuous
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let sideToolsDrawer = SideToolsDrawerView()

    private var tasksByDay: [String: [FocusTask]] = [:]
    private var selectedDayKey: String = DayKey.string(for: Date())
    private var displayedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()

    private let persistence = PersistenceManager.shared
    private let cal = Calendar.current

    private var displayedTasks: [FocusTask] {
        (tasksByDay[selectedDayKey] ?? []).sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        navigationController?.setNavigationBarHidden(true, animated: false)

        configureCustomNavBar()
        configureMonthCalendar()
        configurePanelHeader()
        configureTable()
        configureFAB()
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

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFromDisk()
    }

    @objc private func onSignificantTimeChange() {
        selectedDayKey = DayKey.string(for: Date())
        displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? displayedMonth
        let day = Calendar.current.component(.day, from: Date())
        todayButton.setTitle("\(day)", for: .normal)
        syncMonthViewState()
        reloadFromDisk()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            todayButton.layer.borderColor = AppTheme.primaryText.resolvedColor(with: traitCollection).cgColor
        }
    }

    // MARK: - Configuration

    private func configureCustomNavBar() {
        customNavBar.translatesAutoresizingMaskIntoConstraints = false

        let symCfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)

        hamburgerButton.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: symCfg), for: .normal)
        hamburgerButton.tintColor = AppTheme.primaryText
        hamburgerButton.addAction(UIAction { [weak self] _ in self?.openSettings() }, for: .touchUpInside)
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false

        searchButton.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: symCfg), for: .normal)
        searchButton.tintColor = AppTheme.primaryText
        searchButton.addAction(UIAction { [weak self] _ in self?.openSearch() }, for: .touchUpInside)
        searchButton.translatesAutoresizingMaskIntoConstraints = false

        let day = Calendar.current.component(.day, from: Date())
        todayButton.setTitle("\(day)", for: .normal)
        todayButton.setTitleColor(AppTheme.primaryText, for: .normal)
        todayButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        todayButton.layer.borderWidth = 1.5
        todayButton.layer.cornerRadius = 6
        todayButton.layer.borderColor = AppTheme.primaryText.resolvedColor(with: traitCollection).cgColor
        todayButton.addAction(UIAction { [weak self] _ in self?.scrollToToday() }, for: .touchUpInside)
        todayButton.translatesAutoresizingMaskIntoConstraints = false

        customNavBar.addSubview(hamburgerButton)
        customNavBar.addSubview(searchButton)
        customNavBar.addSubview(todayButton)

        NSLayoutConstraint.activate([
            hamburgerButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            hamburgerButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 36),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 36),

            todayButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            todayButton.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor, constant: -16),
            todayButton.widthAnchor.constraint(equalToConstant: 32),
            todayButton.heightAnchor.constraint(equalToConstant: 28),

            searchButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: todayButton.leadingAnchor, constant: -10),
            searchButton.widthAnchor.constraint(equalToConstant: 36),
            searchButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func configureMonthCalendar() {
        monthCalendarView.displayedMonth = displayedMonth
        monthCalendarView.selectedDayKey = selectedDayKey
        monthCalendarView.onDaySelected = { [weak self] key in self?.applySelectedDayKey(key) }
        monthCalendarView.onPrevMonth = { [weak self] in self?.shiftMonth(-1) }
        monthCalendarView.onNextMonth = { [weak self] in self?.shiftMonth(1) }
    }

    private func configurePanelHeader() {
        panelHeaderRow.translatesAutoresizingMaskIntoConstraints = false

        focusTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        focusTitleLabel.textColor = AppTheme.primaryText
        focusTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        itemsBadgeView.layer.cornerRadius = 12
        itemsBadgeView.layer.cornerCurve = .continuous
        itemsBadgeView.backgroundColor = AppTheme.cardBackground
        itemsBadgeView.translatesAutoresizingMaskIntoConstraints = false

        itemsBadgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        itemsBadgeLabel.textColor = AppTheme.secondaryText
        itemsBadgeLabel.translatesAutoresizingMaskIntoConstraints = false

        itemsBadgeView.addSubview(itemsBadgeLabel)
        panelHeaderRow.addSubview(focusTitleLabel)
        panelHeaderRow.addSubview(itemsBadgeView)

        NSLayoutConstraint.activate([
            itemsBadgeLabel.topAnchor.constraint(equalTo: itemsBadgeView.topAnchor, constant: 5),
            itemsBadgeLabel.bottomAnchor.constraint(equalTo: itemsBadgeView.bottomAnchor, constant: -5),
            itemsBadgeLabel.leadingAnchor.constraint(equalTo: itemsBadgeView.leadingAnchor, constant: 10),
            itemsBadgeLabel.trailingAnchor.constraint(equalTo: itemsBadgeView.trailingAnchor, constant: -10),

            focusTitleLabel.centerYAnchor.constraint(equalTo: panelHeaderRow.centerYAnchor),
            focusTitleLabel.leadingAnchor.constraint(equalTo: panelHeaderRow.leadingAnchor, constant: 16),
            focusTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: itemsBadgeView.leadingAnchor, constant: -8),

            itemsBadgeView.centerYAnchor.constraint(equalTo: panelHeaderRow.centerYAnchor),
            itemsBadgeView.trailingAnchor.constraint(equalTo: panelHeaderRow.trailingAnchor, constant: -16),
        ])
    }

    private func configureTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(CalendarEventCell.self, forCellReuseIdentifier: CalendarEventCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }

    private func configureFAB() {
        fabButton.tintColor = .white
        fabButton.backgroundColor = AppTheme.accent
        fabButton.addAction(UIAction { [weak self] _ in self?.presentAddTask() }, for: .touchUpInside)
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
            sideToolsDrawer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func layoutViews() {
        view.addSubview(customNavBar)
        view.addSubview(monthCalendarView)
        view.addSubview(panelHeaderRow)
        view.addSubview(tableView)
        view.addSubview(fabButton)

        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: 44),

            monthCalendarView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor, constant: 6),
            monthCalendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            monthCalendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            panelHeaderRow.topAnchor.constraint(equalTo: monthCalendarView.bottomAnchor, constant: 18),
            panelHeaderRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panelHeaderRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelHeaderRow.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: panelHeaderRow.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            fabButton.widthAnchor.constraint(equalToConstant: 50),
            fabButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        view.bringSubviewToFront(sideToolsDrawer)
    }

    // MARK: - Nav bar actions

    private func openSettings() {
        let vc = AppSettingsViewController()
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    private func openSearch() {
        let vc = TaskSearchViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.onResultSelected = { [weak self] task in
            self?.applySelectedDayKey(task.dayKey)
        }
        present(vc, animated: true)
    }

    private func scrollToToday() {
        let today = Date()
        let todayKey = DayKey.string(for: today)
        displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? displayedMonth
        applySelectedDayKey(todayKey)
    }

    // MARK: - State

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
        updatePanelHeader()
        tableView.reloadData()
    }

    private func shiftMonth(_ delta: Int) {
        guard
            let next = cal.date(byAdding: .month, value: delta, to: firstOfMonth(displayedMonth)),
            let first = cal.date(from: cal.dateComponents([.year, .month], from: next))
        else { return }
        displayedMonth = first
        selectedDayKey = DayKey.string(for: first)
        syncMonthViewState()
        updatePanelHeader()
        tableView.reloadData()
    }

    private func syncMonthViewState() {
        monthCalendarView.tasksByDay = tasksByDay
        monthCalendarView.displayedMonth = displayedMonth
        monthCalendarView.selectedDayKey = selectedDayKey
    }

    private func updatePanelHeader() {
        guard let d = DayKey.date(from: selectedDayKey) else { return }
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMMM d"
        focusTitleLabel.text = "Focus for \(df.string(from: d))"

        let count = displayedTasks.count
        itemsBadgeLabel.text = "\(count) ITEM\(count == 1 ? "" : "S")"
        fabButton.isHidden = count >= 3
    }

    private func firstOfMonth(_ date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    // MARK: - Data

    private func reloadFromDisk() {
        tasksByDay = persistence.loadTasksByDay()
        let todayKey = DayKey.string(for: Date())
        let todayOnly = tasksByDay[todayKey] ?? []
        sideToolsDrawer.updateResetButtonVisibility(hasTasks: !todayOnly.isEmpty)
        syncMonthViewState()
        updatePanelHeader()
        tableView.reloadData()
    }

    // MARK: - Task actions

    private func presentDetail(for task: FocusTask) {
        let key = selectedDayKey
        let detail = TaskCalendarDetailViewController(
            dayKey: key,
            task: task,
            onSave: { [weak self] updated in self?.replaceTask(updated, dayKey: key) },
            onDelete: { [weak self] in self?.deleteTask(task, dayKey: key) }
        )
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
            reloadFromDisk(); return
        }
        list[i] = task
        map[dayKey] = list
        persistence.saveTasksByDay(map)
        reloadFromDisk()
    }

    private func toggleCompletion(for task: FocusTask) {
        var map = persistence.loadTasksByDay()
        guard var list = map[selectedDayKey], let i = list.firstIndex(where: { $0.id == task.id }) else { return }
        list[i].isCompleted.toggle()
        map[selectedDayKey] = list
        persistence.saveTasksByDay(map)
        reloadFromDisk()
    }

    private func deleteTask(_ task: FocusTask, dayKey: String) {
        var map = persistence.loadTasksByDay()
        guard var list = map[dayKey] else { return }
        list.removeAll { $0.id == task.id }
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
        let sheet = AddTaskSheetView(referenceDay: dayDate)
        sheet.onSave = { [weak self] payload in
            guard let self else { return }
            sheet.dismiss()
            self.addTask(payload: payload, dayKey: self.selectedDayKey)
        }
        sheet.onCancelTapped = { sheet.dismiss() }
        sheet.show(in: view)
    }

    private func addTask(payload: TaskFormPayload, dayKey: String) {
        var map = persistence.loadTasksByDay()
        var list = map[dayKey] ?? []
        guard list.count < 3 else { showErrorAlert(error: .limitReached); return }
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
            title: "Reset Today's Tasks",
            message: "This removes every focus task scheduled for today only. Tasks on other days are kept.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            guard let self else { return }
            var map = self.persistence.loadTasksByDay()
            map[DayKey.string(for: Date())] = []
            self.persistence.saveTasksByDay(map)
            self.reloadFromDisk()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

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
            cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            cell.detailTextLabel?.text = "Tap + to add a focus task for this day."
            cell.detailTextLabel?.textColor = AppTheme.tertiaryText
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }

        let task = displayedTasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCell.identifier, for: indexPath) as! CalendarEventCell
        cell.configure(with: task)
        cell.onCompletionTapped = { [weak self] in
            self?.toggleCompletion(for: task)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !displayedTasks.isEmpty else { return }
        presentDetail(for: displayedTasks[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !displayedTasks.isEmpty else { return nil }
        let task = displayedTasks[indexPath.row]
        let dayKey = selectedDayKey
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteTask(task, dayKey: dayKey)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
