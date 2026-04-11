import UIKit

// MARK: - TaskSearchViewController

final class TaskSearchViewController: UIViewController {

    var onResultSelected: ((FocusTask) -> Void)?

    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .plain)

    private var allSections: [(dayKey: String, tasks: [FocusTask])] = []
    private var filteredSections: [(dayKey: String, tasks: [FocusTask])] = []
    private var currentQuery: String = ""

    private let persistence = PersistenceManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupTopBar()
        setupTableView()
        loadAllTasks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupTopBar() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false

        let backCfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backCfg), for: .normal)
        backButton.tintColor = AppTheme.primaryText
        backButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        searchField.placeholder = "Search tasks"
        searchField.font = .systemFont(ofSize: 17)
        searchField.textColor = AppTheme.primaryText
        searchField.tintColor = AppTheme.accent
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .never
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        let xCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        clearButton.setImage(UIImage(systemName: "xmark", withConfiguration: xCfg), for: .normal)
        clearButton.tintColor = AppTheme.secondaryText
        clearButton.addAction(UIAction { [weak self] _ in
            self?.searchField.text = ""
            self?.searchTextChanged()
        }, for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        topBarView.addSubview(backButton)
        topBarView.addSubview(searchField)
        topBarView.addSubview(clearButton)
        view.addSubview(topBarView)

        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 52),

            backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 32),

            clearButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
            clearButton.widthAnchor.constraint(equalToConstant: 32),

            searchField.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -10),
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Data

    private func loadAllTasks() {
        let tasksByDay = persistence.loadTasksByDay()
        allSections = tasksByDay
            .map { (dayKey: $0.key, tasks: $0.value.sorted { $0.startDate < $1.startDate }) }
            .sorted { $0.dayKey < $1.dayKey }
        applyFilter()
    }

    @objc private func searchTextChanged() {
        currentQuery = searchField.text ?? ""
        applyFilter()
    }

    private func applyFilter() {
        let q = currentQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            filteredSections = allSections
        } else {
            filteredSections = allSections.compactMap { section in
                let matching = section.tasks.filter { $0.title.lowercased().contains(q) }
                return matching.isEmpty ? nil : (dayKey: section.dayKey, tasks: matching)
            }
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension TaskSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { filteredSections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSections[section].tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = filteredSections[indexPath.section].tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as! SearchResultCell
        cell.configure(with: task, query: currentQuery)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        SearchSectionHeaderView(dayKey: filteredSections[section].dayKey)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = filteredSections[indexPath.section].tasks[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onResultSelected?(task)
        }
    }
}

// MARK: - SearchSectionHeaderView

private final class SearchSectionHeaderView: UIView {
    init(dayKey: String) {
        super.init(frame: .zero)
        backgroundColor = AppTheme.background

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let todayKey = DayKey.string(for: Date())
        if dayKey == todayKey {
            let badge = UIView()
            badge.backgroundColor = AppTheme.primaryText
            badge.layer.cornerRadius = 5
            badge.translatesAutoresizingMaskIntoConstraints = false

            let badgeLabel = UILabel()
            badgeLabel.text = "Today"
            badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            badgeLabel.textColor = AppTheme.background
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            badge.addSubview(badgeLabel)
            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 3),
                badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -3),
                badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 8),
                badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -8),
            ])
            stack.addArrangedSubview(badge)
        }

        let dateLabel = UILabel()
        if let date = DayKey.date(from: dayKey) {
            let df = DateFormatter()
            df.dateFormat = "EEE, MMM d"
            dateLabel.text = df.string(from: date)
        } else {
            dateLabel.text = dayKey
        }
        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = AppTheme.primaryText
        stack.addArrangedSubview(dateLabel)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - SearchResultCell

final class SearchResultCell: UITableViewCell {
    static let identifier = "SearchResultCell"

    private let card = UIView()
    private let leftBorder = UIView()
    private let timeLabel = UILabel()
    private let allDayIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildCard()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildCard() {
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        leftBorder.layer.cornerRadius = 2
        leftBorder.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        timeLabel.textColor = AppTheme.secondaryText
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        allDayIconView.image = UIImage(systemName: "calendar", withConfiguration: iconCfg)
        allDayIconView.tintColor = AppTheme.secondaryText
        allDayIconView.contentMode = .scaleAspectFit
        allDayIconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        card.addSubview(leftBorder)
        card.addSubview(timeLabel)
        card.addSubview(allDayIconView)
        card.addSubview(textStack)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            leftBorder.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            leftBorder.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            leftBorder.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            leftBorder.widthAnchor.constraint(equalToConstant: 4),

            timeLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 12),
            timeLabel.widthAnchor.constraint(equalToConstant: 40),

            allDayIconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            allDayIconView.centerXAnchor.constraint(equalTo: timeLabel.centerXAnchor),
            allDayIconView.widthAnchor.constraint(equalToConstant: 22),
            allDayIconView.heightAnchor.constraint(equalToConstant: 22),

            textStack.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),
        ])
    }

    func configure(with task: FocusTask, query: String) {
        let borderColor = priorityColor(task.priority)
        leftBorder.backgroundColor = borderColor
        card.backgroundColor = AppTheme.cardBackground

        if task.isAllDay {
            timeLabel.isHidden = true
            allDayIconView.isHidden = false
            subtitleLabel.text = "All day"
        } else {
            timeLabel.isHidden = false
            allDayIconView.isHidden = true
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm"
            timeLabel.text = fmt.string(from: task.startDate)
            let longFmt = DateFormatter()
            longFmt.dateFormat = "h:mm a"
            subtitleLabel.text = "\(longFmt.string(from: task.startDate)) — \(longFmt.string(from: task.endDate))"
        }

        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            titleLabel.attributedText = nil
            titleLabel.text = task.title
        } else {
            titleLabel.attributedText = highlighted(task.title, query: q)
        }
    }

    private func highlighted(_ text: String, query: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: AppTheme.primaryText,
        ])
        let lower = text.lowercased()
        let lowerQuery = query.lowercased()
        var searchStart = lower.startIndex
        while let range = lower.range(of: lowerQuery, range: searchStart..<lower.endIndex) {
            let nsRange = NSRange(range, in: text)
            result.addAttributes([
                .foregroundColor: AppTheme.accent,
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
            ], range: nsRange)
            searchStart = range.upperBound
        }
        return result
    }

    private func priorityColor(_ priority: TaskPriority) -> UIColor {
        switch priority {
        case .high:   return AppTheme.calendarStripeBlue
        case .medium: return AppTheme.priorityMedium
        case .low:    return AppTheme.calendarStripeGreen
        }
    }
}
