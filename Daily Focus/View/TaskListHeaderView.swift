import UIKit

class TaskListHeaderView: UIView {
    
    // MARK: - UI Components
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
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    private let appearanceButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: AppearanceManager.shared.preference.symbolName, withConfiguration: config), for: .normal)
        button.tintColor = AppTheme.chromeTint
        button.accessibilityLabel = AppearanceManager.shared.preference.accessibilityLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: config), for: .normal)
        button.tintColor = AppTheme.chromeTint
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onResetTapped: (() -> Void)?
    var onAppearanceTapped: (() -> Void)?
    
    // MARK: - Constraints
    private var progressViewTrailingToAppearanceButton: NSLayoutConstraint?
    private var appearanceButtonTrailingToResetButton: NSLayoutConstraint?
    private var appearanceButtonTrailingToSuperview: NSLayoutConstraint?
    private var todayLabelToProgressConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(blueDot)
        addSubview(todayLabel)
        addSubview(progressView)
        addSubview(appearanceButton)
        addSubview(resetButton)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        appearanceButton.addTarget(self, action: #selector(appearanceButtonTapped), for: .touchUpInside)
        
        progressViewTrailingToAppearanceButton = progressView.trailingAnchor.constraint(equalTo: appearanceButton.leadingAnchor, constant: -16)
        appearanceButtonTrailingToResetButton = appearanceButton.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -16)
        appearanceButtonTrailingToSuperview = appearanceButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        todayLabelToProgressConstraint = todayLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressView.leadingAnchor, constant: -12)
        
        NSLayoutConstraint.activate([
            // Blue Dot
            blueDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            blueDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            blueDot.widthAnchor.constraint(equalToConstant: 12),
            blueDot.heightAnchor.constraint(equalToConstant: 12),
            
            // Today Label — stays left of progress ring (prevents overlap)
            todayLabel.leadingAnchor.constraint(equalTo: blueDot.trailingAnchor, constant: 12),
            todayLabel.centerYAnchor.constraint(equalTo: blueDot.centerYAnchor),
            todayLabelToProgressConstraint!,
            
            // Progress View
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 60),
            progressView.heightAnchor.constraint(equalToConstant: 60),
            
            // Appearance Button
            appearanceButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            appearanceButton.widthAnchor.constraint(equalToConstant: 44),
            appearanceButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Reset Button
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            resetButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        progressViewTrailingToAppearanceButton?.isActive = true
        appearanceButtonTrailingToSuperview?.isActive = true
        appearanceButtonTrailingToResetButton?.isActive = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(syncAppearanceButton), name: .appearancePreferenceDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func syncAppearanceButton() {
        updateAppearanceButtonIcon()
    }
    
    func updateAppearanceButtonIcon() {
        let pref = AppearanceManager.shared.preference
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        appearanceButton.setImage(UIImage(systemName: pref.symbolName, withConfiguration: config), for: .normal)
        appearanceButton.accessibilityLabel = pref.accessibilityLabel
    }
    
    @objc private func resetButtonTapped() {
        onResetTapped?()
    }
    
    @objc private func appearanceButtonTapped() {
        onAppearanceTapped?()
    }
    
    func updateResetButtonVisibility(hasTasks: Bool) {
        let wasHidden = resetButton.isHidden
        resetButton.isHidden = !hasTasks
        
        if hasTasks {
            appearanceButtonTrailingToSuperview?.isActive = false
            appearanceButtonTrailingToResetButton?.isActive = true
        } else {
            appearanceButtonTrailingToResetButton?.isActive = false
            appearanceButtonTrailingToSuperview?.isActive = true
        }
        
        if wasHidden != resetButton.isHidden {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    func updateProgress(completed: Int, total: Int) {
        progressView.updateProgress(completed: completed, total: total)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        todayLabel.textColor = AppTheme.primaryText
        appearanceButton.tintColor = AppTheme.chromeTint
        resetButton.tintColor = AppTheme.chromeTint
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
        progressLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textAlignment = .center
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
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 4
        backgroundLayer.path = path.cgPath
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4
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
