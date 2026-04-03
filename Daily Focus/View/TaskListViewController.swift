import UIKit
import Combine

class TaskListViewController: UIViewController {

    private let tableView = UITableView()
    private let headerView = TaskListHeaderView()
    private let footerView = TaskListFooterView()
    private let emptyStateView = EmptyStateView()
    private let sideToolsDrawer = SideToolsDrawerView()
    private let completionCelebrationView = CompletionCelebrationView()
    private let viewModel: TaskViewModel
    private var cancellables = Set<AnyCancellable>()
    private var hasShownCompletionCelebration = false

    init(viewModel: TaskViewModel = TaskViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = AppTheme.background
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(headerView)
        view.addSubview(footerView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(sideToolsDrawer)
        view.addSubview(completionCelebrationView)

        completionCelebrationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            completionCelebrationView.topAnchor.constraint(equalTo: view.topAnchor),
            completionCelebrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            completionCelebrationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            completionCelebrationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        configureHeader()
        configureSideDrawer()
        configureFooter()
        configureTableView()
        configureEmptyState()
        updateUI()

        view.bringSubviewToFront(sideToolsDrawer)
        view.bringSubviewToFront(completionCelebrationView)
    }

    private func configureHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100)
        ])
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
        sideToolsDrawer.attachScreenEdgePan(to: view)

        NSLayoutConstraint.activate([
            sideToolsDrawer.topAnchor.constraint(equalTo: view.topAnchor),
            sideToolsDrawer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sideToolsDrawer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sideToolsDrawer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaskCardCell.self, forCellReuseIdentifier: TaskCardCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])
    }

    private func configureFooter() {
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.onReflectButtonTapped = { [weak self] in
            self?.showAddTaskAlert()
        }

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.onGetStartedTapped = { [weak self] in
            self?.showAddTaskAlert()
        }

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])
    }

    private func setupBindings() {
        viewModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateUI()
            }
            .store(in: &cancellables)
    }

    private func updateUI() {
        let isEmpty = viewModel.taskCount == 0
        let completed = viewModel.tasks.filter { $0.isCompleted }.count
        let total = viewModel.taskCount

        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        headerView.updateProgress(completed: completed, total: total)
        sideToolsDrawer.updateResetButtonVisibility(hasTasks: !isEmpty)
        footerView.updateMessage(isEmpty: isEmpty)

        if total > 0 && completed == total && !hasShownCompletionCelebration {
            hasShownCompletionCelebration = true
            showCompletionCelebration()
        } else if completed < total {
            hasShownCompletionCelebration = false
        }
    }

    private func showCompletionCelebration() {
        completionCelebrationView.playCelebration()
    }

    private func showAddTaskAlert() {
        guard viewModel.canAddMoreTasks else {
            showErrorAlert(error: .limitReached)
            return
        }

        let addTaskSheet = AddTaskSheetView()
        addTaskSheet.onAddTapped = { [weak self] text, priority in
            guard let self = self else { return }
            guard !text.isEmpty else {
                addTaskSheet.dismiss()
                self.showErrorAlert(error: .emptyTitle)
                return
            }
            let result = self.viewModel.addTask(title: text, priority: priority)
            addTaskSheet.dismiss()
            self.handleAddTaskResult(result)
        }
        addTaskSheet.onCancelTapped = {
            addTaskSheet.dismiss()
        }
        addTaskSheet.show(in: view)
    }

    private func handleAddTaskResult(_ result: Result<Void, TaskError>) {
        switch result {
        case .success:
            break
        case .failure(let error):
            showErrorAlert(error: error)
        }
    }

    private func showErrorAlert(error: TaskError) {
        let alert = UIAlertController(
            title: error.alertTitle,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
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
            self?.resetAllTasks()
        })

        present(alert, animated: true)
    }

    private func resetAllTasks() {
        viewModel.resetAllTasks()
        hasShownCompletionCelebration = false
        completionCelebrationView.stopAndHide()
    }
}

extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.taskCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskCardCell.identifier, for: indexPath) as! TaskCardCell

        guard let task = viewModel.task(at: indexPath.row) else {
            return cell
        }

        cell.configure(with: task)
        cell.onCheckmarkTapped = { [weak self] in
            self?.viewModel.toggleTaskCompletion(at: indexPath.row)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteTask(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
