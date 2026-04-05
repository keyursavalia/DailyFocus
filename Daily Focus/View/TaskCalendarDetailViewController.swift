import UIKit

/// Edit task details (same fields as add sheet) and save to storage.
final class TaskCalendarDetailViewController: UIViewController {

    private let dayKey: String
    private var task: FocusTask
    private let onSave: (FocusTask) -> Void

    private let scrollView = UIScrollView()
    private let formView: TaskFormView

    init(dayKey: String, task: FocusTask, onSave: @escaping (FocusTask) -> Void) {
        self.dayKey = dayKey
        self.task = task
        self.onSave = onSave
        guard let dayDate = DayKey.date(from: dayKey) else {
            fatalError("Invalid dayKey")
        }
        self.formView = TaskFormView(referenceDay: dayDate)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.elevatedBackground

        navigationItem.title = "Task"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        formView.apply(task: task)

        view.addSubview(scrollView)
        scrollView.addSubview(formView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            formView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            formView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            formView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            formView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            formView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let payload = formView.collectPayload() else { return }
        var updated = task
        updated.title = payload.title
        updated.priority = payload.priority
        updated.isAllDay = payload.isAllDay
        updated.startDate = payload.startDate
        updated.endDate = payload.endDate
        onSave(updated)
        dismiss(animated: true)
    }
}
