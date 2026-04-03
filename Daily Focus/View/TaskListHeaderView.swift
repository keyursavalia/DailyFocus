import UIKit

class TaskListHeaderView: UIView {

    private let todayLabel: UILabel = {
        let label = UILabel()
        label.text = "TODAY'S FOCUS"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = AppTheme.primaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let blueDot: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.blueDot
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressView: CircularProgressView = {
        let v = CircularProgressView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(blueDot)
        addSubview(todayLabel)
        addSubview(progressView)

        NSLayoutConstraint.activate([
            blueDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            blueDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            blueDot.widthAnchor.constraint(equalToConstant: 12),
            blueDot.heightAnchor.constraint(equalToConstant: 12),

            todayLabel.leadingAnchor.constraint(equalTo: blueDot.trailingAnchor, constant: 12),
            todayLabel.centerYAnchor.constraint(equalTo: blueDot.centerYAnchor),
            todayLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressView.leadingAnchor, constant: -12),

            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 56),
            progressView.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func updateProgress(completed: Int, total: Int) {
        progressView.updateProgress(completed: completed, total: total)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        todayLabel.textColor = AppTheme.primaryText
    }
}

// MARK: - Circular Progress View
class CircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let progressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)

        progressLabel.textColor = AppTheme.primaryText
        progressLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        progressLabel.textAlignment = .center
        progressLabel.adjustsFontSizeToFitWidth = true
        progressLabel.minimumScaleFactor = 0.7
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressLabel)

        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        applyProgressColors()
        progressLayer.strokeEnd = 0
    }

    private func applyProgressColors() {
        let tc = traitCollection
        backgroundLayer.strokeColor = AppTheme.progressTrack.resolvedColor(with: tc).cgColor
        progressLayer.strokeColor = AppTheme.accentBright.resolvedColor(with: tc).cgColor
        progressLabel.textColor = AppTheme.primaryText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyProgressColors()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 3
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)

        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 3
        backgroundLayer.path = path.cgPath

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 3
        progressLayer.lineCap = .round
        progressLayer.path = path.cgPath
    }

    func updateProgress(completed: Int, total: Int) {
        let progress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        progressLabel.text = "\(completed)/\(total)"

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = progress
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.strokeEnd = progress
        progressLayer.add(animation, forKey: "progress")
    }
}
