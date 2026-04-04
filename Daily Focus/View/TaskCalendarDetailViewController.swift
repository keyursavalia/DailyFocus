import UIKit

/// Presents read-only details for a focus task in a sheet, similar to Calendar’s event inspector.
final class TaskCalendarDetailViewController: UIViewController {

    private let task: FocusTask
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(task: FocusTask) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.elevatedBackground

        navigationItem.title = "Task"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        stack.addArrangedSubview(makeRow(title: "Title", value: task.title))
        stack.addArrangedSubview(makeRow(title: "Day", value: task.dayKey))
        stack.addArrangedSubview(makeRow(title: "Priority", value: task.priority.rawValue))
        stack.addArrangedSubview(makeRow(title: "Status", value: task.isCompleted ? "Completed" : "Open"))
        stack.addArrangedSubview(makeRow(title: "Added", value: df.string(from: task.createdAt)))
        if task.isCarriedOver {
            stack.addArrangedSubview(makeRow(title: "Note", value: "Marked as carried over"))
        }
    }

    private func makeRow(title: String, value: String) -> UIView {
        let v = UIView()
        let t = UILabel()
        t.text = title.uppercased()
        t.font = .systemFont(ofSize: 12, weight: .semibold)
        t.textColor = AppTheme.tertiaryText
        let body = UILabel()
        body.text = value
        body.font = .systemFont(ofSize: 17, weight: .regular)
        body.textColor = AppTheme.primaryText
        body.numberOfLines = 0

        t.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(t)
        v.addSubview(body)

        NSLayoutConstraint.activate([
            t.topAnchor.constraint(equalTo: v.topAnchor),
            t.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            t.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            body.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 6),
            body.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: v.bottomAnchor)
        ])
        return v
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
