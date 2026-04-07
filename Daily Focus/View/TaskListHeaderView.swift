import UIKit

class TaskListHeaderView: UIView {

    private static let green = UIColor(red: 71 / 255, green: 226 / 255, blue: 102 / 255, alpha: 1)

    // MARK: - Card container

    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Left column

    private let overviewLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "TODAY'S FOCUS"
        l.font = .systemFont(ofSize: 26, weight: .bold)
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.8
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let leftStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 6
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Right: progress ring

    private let progressView: CircularProgressView = {
        let v = CircularProgressView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        v.setContentHuggingPriority(.required, for: .horizontal)
        return v
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        applyColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        leftStack.addArrangedSubview(overviewLabel)
        leftStack.addArrangedSubview(titleLabel)
        leftStack.addArrangedSubview(descriptionLabel)

        card.addSubview(leftStack)
        card.addSubview(progressView)
        addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            leftStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            leftStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            leftStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            leftStack.trailingAnchor.constraint(lessThanOrEqualTo: progressView.leadingAnchor, constant: -12),

            progressView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            progressView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            progressView.widthAnchor.constraint(equalToConstant: 90),
            progressView.heightAnchor.constraint(equalToConstant: 90),
        ])
    }

    private func applyColors() {
        card.backgroundColor = AppTheme.cardBackground
        overviewLabel.textColor = AppTheme.secondaryText
        titleLabel.textColor = AppTheme.primaryText
        // seed a blank description so intrinsic height is stable before first data arrives
        descriptionLabel.text = " "
    }

    // MARK: - Public API

    func updateProgress(completed: Int, total: Int) {
        progressView.updateProgress(completed: completed, total: total)

        let green = TaskListHeaderView.green
        let secondary = AppTheme.secondaryText

        let overviewAttr = NSAttributedString(
            string: "OVERVIEW",
            attributes: [.kern: 2.0, .foregroundColor: secondary,
                         .font: UIFont.systemFont(ofSize: 11, weight: .semibold)]
        )
        overviewLabel.attributedText = overviewAttr

        let body = NSMutableAttributedString(
            string: "You've completed ",
            attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: secondary]
        )
        body.append(NSAttributedString(
            string: "\(completed) of \(total)",
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: green]
        ))
        body.append(NSAttributedString(
            string: " focus tasks today.",
            attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: secondary]
        ))
        descriptionLabel.attributedText = body
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColors()
    }
}

// MARK: - Circular Progress View

class CircularProgressView: UIView {

    private static let green = UIColor(red: 71 / 255, green: 226 / 255, blue: 102 / 255, alpha: 1)

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let completeLabel: UILabel = {
        let l = UILabel()
        l.text = "COMPLETE"
        l.font = .systemFont(ofSize: 8, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)

        addSubview(countLabel)
        addSubview(completeLabel)

        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),

            completeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            completeLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 2),
        ])

        applyColors()
        progressLayer.strokeEnd = 0
    }

    private func applyColors() {
        let tc = traitCollection
        backgroundLayer.strokeColor = AppTheme.progressTrack.resolvedColor(with: tc).cgColor
        progressLayer.strokeColor = CircularProgressView.green.cgColor
        countLabel.textColor = AppTheme.primaryText
        completeLabel.textColor = AppTheme.secondaryText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyColors()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 5
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)

        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 7
        backgroundLayer.path = path.cgPath

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 7
        progressLayer.lineCap = .round
        progressLayer.path = path.cgPath
    }

    func updateProgress(completed: Int, total: Int) {
        let progress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        countLabel.text = "\(completed)/\(total)"

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = progress
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.strokeEnd = progress
        progressLayer.add(animation, forKey: "progress")
    }
}
