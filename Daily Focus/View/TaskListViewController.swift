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
        
        configureHeader()
        configureFooter()
        configureTableView()
        configureEmptyState()
        updateUI()
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
        
        // Update progress
        headerView.updateProgress(completed: completed, total: total)
        
        // Update footer message
        footerView.updateMessage(isEmpty: isEmpty)
    }
    
    // MARK: - Actions
    private func showAddTaskAlert() {
        // Check if limit is reached before showing the alert
        guard viewModel.canAddMoreTasks else {
            showErrorAlert(error: .limitReached)
            return
        }
        
        let alert = UIAlertController(
            title: "New Focus",
            message: "What is your priority?",
            preferredStyle: .alert
        )
        
        var taskTextField: UITextField?
        alert.addTextField { textField in
            textField.placeholder = "Enter task..."
            taskTextField = textField
        }
        
        // Add priority selection action
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = taskTextField?.text, !text.isEmpty else { return }
            
            // Show priority selection
            self.showPrioritySelection(for: text)
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showPrioritySelection(for title: String) {
        let alert = UIAlertController(
            title: "Select Priority",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "High Priority", style: .default) { [weak self] _ in
            let result = self?.viewModel.addTask(title: title, priority: .high)
            self?.handleAddTaskResult(result ?? .failure(.emptyTitle))
        })
        
        alert.addAction(UIAlertAction(title: "Medium Priority", style: .default) { [weak self] _ in
            let result = self?.viewModel.addTask(title: title, priority: .medium)
            self?.handleAddTaskResult(result ?? .failure(.emptyTitle))
        })
        
        alert.addAction(UIAlertAction(title: "Low Priority", style: .default) { [weak self] _ in
            let result = self?.viewModel.addTask(title: title, priority: .low)
            self?.handleAddTaskResult(result ?? .failure(.emptyTitle))
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
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
            title: "Limit Reached",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
