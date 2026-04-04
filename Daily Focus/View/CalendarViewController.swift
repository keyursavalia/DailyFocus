import UIKit

/// Month grid + agenda list in the style of Apple Calendar (all-day style rows).
final class CalendarViewController: UIViewController {

    private let calendarView = UICalendarView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var selection: UICalendarSelectionSingleDate!
    private var tasksByDay: [String: [FocusTask]] = [:]
    private var selectedDayKey: String = DayKey.string(for: Date())
    private let persistence = PersistenceManager.shared

    private var displayedTasks: [FocusTask] {
        (tasksByDay[selectedDayKey] ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    private let dayHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = AppTheme.primaryText
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        title = "Calendar"

        configureCalendarView()
        configureTableView()
        layoutViews()
        updateDayHeader()
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
        if let comp = DayKey.components(from: todayKey) {
            selection.setSelected(comp, animated: true)
        }
        updateDayHeader()
        reloadFromDisk()
    }

    private func configureCalendarView() {
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.tintColor = AppTheme.accent
        calendarView.backgroundColor = AppTheme.background
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        calendarView.fontDesign = .rounded

        selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection

        if let comp = DayKey.components(from: selectedDayKey) {
            selection.setSelected(comp, animated: false)
        }
    }

    private func configureTableView() {
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CalendarEventCell.self, forCellReuseIdentifier: CalendarEventCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.sectionHeaderHeight = 0
        tableView.estimatedRowHeight = 88
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func layoutViews() {
        dayHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(calendarView)
        view.addSubview(dayHeaderLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dayHeaderLabel.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 12),
            dayHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dayHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: dayHeaderLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateDayHeader() {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        if let d = DayKey.date(from: selectedDayKey) {
            dayHeaderLabel.text = df.string(from: d)
        } else {
            dayHeaderLabel.text = selectedDayKey
        }
    }

    private func reloadFromDisk() {
        tasksByDay = persistence.loadTasksByDay()
        var keys = Set<String>()
        for (key, list) in tasksByDay where !list.isEmpty {
            keys.insert(key)
        }
        keys.insert(selectedDayKey)
        let components = keys.compactMap { DayKey.components(from: $0) }
        calendarView.reloadDecorations(forDateComponents: components, animated: false)
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
}

extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let key = DayKey.string(for: date)
        guard let list = tasksByDay[key], !list.isEmpty else { return nil }
        return .default(color: AppTheme.blueDot, size: .small)
    }
}

extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dc = dateComponents, let date = Calendar.current.date(from: dc) else { return }
        selectedDayKey = DayKey.string(for: date)
        updateDayHeader()
        tableView.reloadData()
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(displayedTasks.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if displayedTasks.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.backgroundColor = AppTheme.cardBackground
            cell.textLabel?.text = "No tasks"
            cell.textLabel?.textColor = AppTheme.secondaryText
            cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            cell.detailTextLabel?.text = "Add up to three focus tasks on the Focus tab for this day."
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
