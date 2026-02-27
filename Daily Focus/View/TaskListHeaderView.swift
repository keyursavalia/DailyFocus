import UIKit

class TaskListHeaderView: UIView {
    
    // MARK: - UI Components
    private let todayLabel: UILabel = {
        let label = UILabel()
        label.text = "TODAY'S FOCUS"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let blueDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(white: 0.6, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onResetTapped: (() -> Void)?
    
    // MARK: - Constraints
    private var progressViewTrailingToResetButton: NSLayoutConstraint?
    private var progressViewTrailingToSuperview: NSLayoutConstraint?
    
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
        addSubview(resetButton)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        // Create constraints for progress view positioning
        progressViewTrailingToResetButton = progressView.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -16)
        progressViewTrailingToSuperview = progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            // Blue Dot
            blueDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            blueDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            blueDot.widthAnchor.constraint(equalToConstant: 12),
            blueDot.heightAnchor.constraint(equalToConstant: 12),
            
            // Today Label
            todayLabel.leadingAnchor.constraint(equalTo: blueDot.trailingAnchor, constant: 12),
            todayLabel.centerYAnchor.constraint(equalTo: blueDot.centerYAnchor),
            
            // Progress View (common constraints)
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 60),
            progressView.heightAnchor.constraint(equalToConstant: 60),
            
            // Reset Button
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            resetButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Initially, reset button is hidden, so use superview constraint
        progressViewTrailingToSuperview?.isActive = true
        progressViewTrailingToResetButton?.isActive = false
    }
    
    @objc private func resetButtonTapped() {
        onResetTapped?()
    }
    
    func updateResetButtonVisibility(hasTasks: Bool) {
        let wasHidden = resetButton.isHidden
        resetButton.isHidden = !hasTasks
        
        // Update constraints based on visibility
        if hasTasks {
            // Show reset button - position progress view relative to reset button
            progressViewTrailingToSuperview?.isActive = false
            progressViewTrailingToResetButton?.isActive = true
        } else {
            // Hide reset button - return progress view to original position
            progressViewTrailingToResetButton?.isActive = false
            progressViewTrailingToSuperview?.isActive = true
        }
        
        // Animate layout change if visibility changed
        if wasHidden != resetButton.isHidden {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    func updateProgress(completed: Int, total: Int) {
        progressView.updateProgress(completed: completed, total: total)
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
        
        // Background circle
        backgroundLayer.strokeColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 4
        layer.addSublayer(backgroundLayer)
        
        // Progress circle
        progressLayer.strokeColor = UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        // Progress label
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        
        backgroundLayer.path = path.cgPath
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

