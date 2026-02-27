import UIKit
import Combine

class TaskListViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private let headerView = TaskListHeaderView()
    private let footerView = TaskListFooterView()
    private let emptyStateView = EmptyStateView()
    private let viewModel: TaskViewModel
    private var cancellables = Set<AnyCancellable>()
    private let graffitiRainView = GraffitiRainView()
    private var hasShownGraffitiRain = false
    
    // MARK: - Initialization
    init(viewModel: TaskViewModel = TaskViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Dark theme background
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        
        // Hide navigation bar for cleaner look
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Add views to hierarchy first, then configure constraints
        view.addSubview(headerView)
        view.addSubview(footerView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(graffitiRainView)
        
        graffitiRainView.translatesAutoresizingMaskIntoConstraints = false
        graffitiRainView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            graffitiRainView.topAnchor.constraint(equalTo: view.topAnchor),
            graffitiRainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            graffitiRainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            graffitiRainView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        graffitiRainView.isHidden = true
        
        configureHeader()
        configureFooter()
        configureTableView()
        configureEmptyState()
        updateUI()
    }
    
    private func configureHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.onResetTapped = { [weak self] in
            self?.showResetConfirmation()
        }
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100)
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
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tasks in
                self?.tableView.reloadData()
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    private func updateUI() {
        let isEmpty = viewModel.taskCount == 0
        let completed = viewModel.tasks.filter { $0.isCompleted }.count
        let total = viewModel.taskCount
        
        // Show/hide empty state
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        headerView.updateProgress(completed: completed, total: total)
        headerView.updateResetButtonVisibility(hasTasks: !isEmpty)
        footerView.updateMessage(isEmpty: isEmpty)
        
        // Update progress
        headerView.updateProgress(completed: completed, total: total)
        
        // Update reset button visibility
        headerView.updateResetButtonVisibility(hasTasks: !isEmpty)
        
        // Update footer message
        footerView.updateMessage(isEmpty: isEmpty)
        
        // Graffiti rain when all tasks for the day are completed (1, 2, or 3)
        if total > 0 && completed == total && !hasShownGraffitiRain {
            hasShownGraffitiRain = true
            showGraffitiRain()
        } else if completed < total {
            hasShownGraffitiRain = false  // Reset if user uncompletes a task
        }
    }
    
    // MARK: - Actions
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
    
    private func showGraffitiRain() {
        graffitiRainView.isHidden = false
        graffitiRainView.startRain()
        
        // Auto-dismiss after ~8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.graffitiRainView.stopRain()
            UIView.animate(withDuration: 1) {
                self?.graffitiRainView.alpha = 0
            } completion: { _ in
                self?.graffitiRainView.isHidden = true
                self?.graffitiRainView.alpha = 1
            }
        }
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
        hasShownGraffitiRain = false
        graffitiRainView.stopRain()
        graffitiRainView.isHidden = true
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.taskCount
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

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
