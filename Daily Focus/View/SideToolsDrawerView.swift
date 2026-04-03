import UIKit

/// Compact edge drawer: stays on the left or right screen edge only; user can drag vertically
/// and swipe the handle horizontally (when closed) to move between edges — never rests in the center.
final class SideToolsDrawerView: UIView {

    enum HorizontalEdge: Int {
        case right = 0
        case left = 1
    }

    private let backdropView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.alpha = 0
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let panelView: UIView = {
        let v = UIView()
        v.backgroundColor = AppTheme.elevatedBackground
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowOffset = CGSize(width: -1, height: 0)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let handleGlyph: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        iv.tintColor = AppTheme.chromeTint
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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

    private let buttonColumn = UIStackView()

    /// Right edge: panel.leading = superview.trailing + constant (negative pulls panel left from right).
    private var rightEdgeConstraint: NSLayoutConstraint!
    /// Left edge: panel.trailing = superview.leading + constant (positive pulls panel right from left).
    private var leftEdgeConstraint: NSLayoutConstraint!

    private var panelCenterYConstraint: NSLayoutConstraint!
    private var backdropLeadingConstraint: NSLayoutConstraint!

    private var handleToContentLeading: NSLayoutConstraint?
    private var handleToContentTrailing: NSLayoutConstraint?
    private var handlePinToPanel: NSLayoutConstraint?

    private let panelWidth: CGFloat = 118
    private let handleWidth: CGFloat = 22
    private let panelContentHeight: CGFloat = 112

    private var openConstant: CGFloat { -panelWidth }
    private var closedConstant: CGFloat { -handleWidth }

    private var openConstantLeft: CGFloat { panelWidth }
    private var closedConstantLeft: CGFloat { handleWidth }

    private(set) var attachedEdge: HorizontalEdge = .right

    /// Offset from safe-area vertical center (positive = lower on screen).
    private var verticalOffset: CGFloat = 0 {
        didSet { panelCenterYConstraint.constant = verticalOffset }
    }

    private var isOpen = false

    /// Pan axis: nil until first significant movement.
    private var panelPanAxis: PanelPanAxis?
    private enum PanelPanAxis { case horizontalOpen; case verticalMove }

    private var panStartEdgeConstant: CGFloat = 0
    private var panStartVerticalOffset: CGFloat = 0

    private let defaultsVerticalKey = "sideDrawerVerticalOffset"
    private let defaultsEdgeKey = "sideDrawerHorizontalEdge"

    var onResetTapped: (() -> Void)?
    var onAppearanceTapped: (() -> Void)?

    private var edgePanRight: UIScreenEdgePanGestureRecognizer?
    private var edgePanLeft: UIScreenEdgePanGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func persistPosition() {
        UserDefaults.standard.set(Double(verticalOffset), forKey: defaultsVerticalKey)
        UserDefaults.standard.set(attachedEdge.rawValue, forKey: defaultsEdgeKey)
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(backdropView)
        addSubview(panelView)

        panelView.addSubview(handleView)
        handleView.addSubview(handleGlyph)

        buttonColumn.axis = .vertical
        buttonColumn.spacing = 10
        buttonColumn.alignment = .center
        buttonColumn.distribution = .equalSpacing
        buttonColumn.translatesAutoresizingMaskIntoConstraints = false
        buttonColumn.addArrangedSubview(appearanceButton)
        buttonColumn.addArrangedSubview(resetButton)
        panelView.addSubview(buttonColumn)

        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        appearanceButton.addTarget(self, action: #selector(appearanceTapped), for: .touchUpInside)

        let tapBackdrop = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
        backdropView.addGestureRecognizer(tapBackdrop)

        let tapHandle = UITapGestureRecognizer(target: self, action: #selector(handleTapped))
        handleView.addGestureRecognizer(tapHandle)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanelPan(_:)))
        pan.delegate = self
        panelView.addGestureRecognizer(pan)

        rightEdgeConstraint = panelView.leadingAnchor.constraint(equalTo: trailingAnchor, constant: closedConstant)
        leftEdgeConstraint = panelView.trailingAnchor.constraint(equalTo: leadingAnchor, constant: closedConstantLeft)

        panelCenterYConstraint = panelView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: verticalOffset)
        backdropLeadingConstraint = backdropView.leadingAnchor.constraint(equalTo: leadingAnchor)

        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: topAnchor),
            backdropView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backdropLeadingConstraint,

            panelCenterYConstraint,
            panelView.widthAnchor.constraint(equalToConstant: panelWidth),
            panelView.heightAnchor.constraint(equalToConstant: panelContentHeight),

            handleView.topAnchor.constraint(equalTo: panelView.topAnchor),
            handleView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),
            handleView.widthAnchor.constraint(equalToConstant: handleWidth),

            handleGlyph.centerXAnchor.constraint(equalTo: handleView.centerXAnchor),
            handleGlyph.centerYAnchor.constraint(equalTo: handleView.centerYAnchor),
            handleGlyph.widthAnchor.constraint(equalToConstant: 16),
            handleGlyph.heightAnchor.constraint(equalToConstant: 16),

            buttonColumn.centerYAnchor.constraint(equalTo: panelView.centerYAnchor),

            appearanceButton.widthAnchor.constraint(equalToConstant: 44),
            appearanceButton.heightAnchor.constraint(equalToConstant: 44),
            resetButton.widthAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        applyEdgeConstraints(active: true)
        applyHandleAndContentConstraints()

        verticalOffset = CGFloat(UserDefaults.standard.double(forKey: defaultsVerticalKey))
        if let raw = UserDefaults.standard.object(forKey: defaultsEdgeKey) as? Int,
           let e = HorizontalEdge(rawValue: raw) {
            attachedEdge = e
        }
        applyEdgeAppearance()

        NotificationCenter.default.addObserver(self, selector: #selector(syncAppearanceButton), name: .appearancePreferenceDidChange, object: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        verticalOffset = clampedVerticalOffset(verticalOffset)
        panelCenterYConstraint.constant = verticalOffset
    }

    private func applyEdgeConstraints(active: Bool) {
        switch attachedEdge {
        case .right:
            leftEdgeConstraint.isActive = false
            rightEdgeConstraint.isActive = active
        case .left:
            rightEdgeConstraint.isActive = false
            leftEdgeConstraint.isActive = active
        }
    }

    private func applyHandleAndContentConstraints() {
        handleToContentLeading?.isActive = false
        handleToContentTrailing?.isActive = false
        handlePinToPanel?.isActive = false

        switch attachedEdge {
        case .right:
            handlePinToPanel = handleView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor)
            handleToContentLeading = buttonColumn.leadingAnchor.constraint(equalTo: handleView.trailingAnchor, constant: 6)
            handleToContentTrailing = buttonColumn.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -8)
        case .left:
            handlePinToPanel = handleView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor)
            handleToContentLeading = buttonColumn.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 8)
            handleToContentTrailing = buttonColumn.trailingAnchor.constraint(equalTo: handleView.leadingAnchor, constant: -6)
        }
        handlePinToPanel?.isActive = true
        handleToContentLeading?.isActive = true
        handleToContentTrailing?.isActive = true
    }

    private func applyEdgeAppearance() {
        panelView.layer.maskedCorners = attachedEdge == .right
            ? [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        panelView.layer.shadowOffset = CGSize(width: attachedEdge == .right ? -1 : 1, height: 0)

        applyEdgeConstraints(active: true)
        applyHandleAndContentConstraints()

        if isOpen {
            rightEdgeConstraint.constant = openConstant
            leftEdgeConstraint.constant = openConstantLeft
        } else {
            rightEdgeConstraint.constant = closedConstant
            leftEdgeConstraint.constant = closedConstantLeft
        }
        setNeedsLayout()
    }

    private func activeEdgeConstant() -> CGFloat {
        attachedEdge == .right ? rightEdgeConstraint.constant : leftEdgeConstraint.constant
    }

    private func setActiveEdgeConstant(_ value: CGFloat) {
        if attachedEdge == .right {
            rightEdgeConstraint.constant = value
        } else {
            leftEdgeConstraint.constant = value
        }
    }

    private func clampedVerticalOffset(_ offset: CGFloat) -> CGFloat {
        let safe = safeAreaLayoutGuide.layoutFrame
        guard safe.height > panelContentHeight + 16 else { return 0 }
        let half = panelContentHeight / 2
        let minCenterY = safe.minY + half + 8
        let maxCenterY = safe.maxY - half - 8
        let midY = safe.midY
        let minDelta = minCenterY - midY
        let maxDelta = maxCenterY - midY
        return min(max(offset, minDelta), maxDelta)
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

    func updateResetButtonVisibility(hasTasks: Bool) {
        resetButton.isHidden = !hasTasks
    }

    func attachScreenEdgePan(to view: UIView) {
        let r = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgePanRight(_:)))
        r.edges = .right
        view.addGestureRecognizer(r)
        edgePanRight = r

        let l = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgePanLeft(_:)))
        l.edges = .left
        view.addGestureRecognizer(l)
        edgePanLeft = l
    }

    @objc private func screenEdgePanRight(_ g: UIScreenEdgePanGestureRecognizer) {
        guard attachedEdge == .right else { return }
        screenEdgePanShared(g, translationX: { $0.translation(in: $1).x })
    }

    @objc private func screenEdgePanLeft(_ g: UIScreenEdgePanGestureRecognizer) {
        guard attachedEdge == .left else { return }
        screenEdgePanShared(g, translationX: { $0.translation(in: $1).x })
    }

    private func screenEdgePanShared(_ g: UIScreenEdgePanGestureRecognizer, translationX: (UIScreenEdgePanGestureRecognizer, UIView) -> CGFloat) {
        guard let host = superview else { return }
        let x = translationX(g, host)
        switch g.state {
        case .changed:
            if !isOpen {
                if attachedEdge == .right {
                    let drag = min(0, x)
                    rightEdgeConstraint.constant = closedConstant + drag
                } else {
                    let drag = max(0, x)
                    leftEdgeConstraint.constant = closedConstantLeft + drag
                }
                backdropView.alpha = min(0.85, abs(x) / 120 * 0.85)
            }
        case .ended, .cancelled:
            if !isOpen {
                let v = g.velocity(in: host).x
                if attachedEdge == .right {
                    if x < -50 || v < -280 {
                        setOpen(true, animated: true)
                    } else {
                        setOpen(false, animated: true)
                    }
                } else {
                    if x > 50 || v > 280 {
                        setOpen(true, animated: true)
                    } else {
                        setOpen(false, animated: true)
                    }
                }
            }
        default:
            break
        }
    }

    @objc private func backdropTapped() {
        setOpen(false, animated: true)
    }

    @objc private func handleTapped() {
        setOpen(!isOpen, animated: true)
    }

    @objc private func resetTapped() {
        onResetTapped?()
    }

    @objc private func appearanceTapped() {
        onAppearanceTapped?()
    }

    @objc private func handlePanelPan(_ g: UIPanGestureRecognizer) {
        let tx = g.translation(in: self)
        switch g.state {
        case .began:
            panelPanAxis = nil
            panStartEdgeConstant = activeEdgeConstant()
            panStartVerticalOffset = verticalOffset

        case .changed:
            if panelPanAxis == nil {
                if hypot(tx.x, tx.y) < 10 { return }
                if abs(tx.y) >= abs(tx.x) {
                    panelPanAxis = .verticalMove
                } else {
                    panelPanAxis = .horizontalOpen
                }
            }

            switch panelPanAxis {
            case .verticalMove:
                let next = panStartVerticalOffset + tx.y
                verticalOffset = clampedVerticalOffset(next)
            case .horizontalOpen:
                if attachedEdge == .right {
                    let next = panStartEdgeConstant + tx.x
                    let clamped = max(openConstant, min(closedConstant, next))
                    rightEdgeConstraint.constant = clamped
                } else {
                    let next = panStartEdgeConstant + tx.x
                    let clamped = min(openConstantLeft, max(closedConstantLeft, next))
                    leftEdgeConstraint.constant = clamped
                }
                let t: CGFloat
                if attachedEdge == .right {
                    t = 1 - (rightEdgeConstraint.constant - openConstant) / (closedConstant - openConstant)
                } else {
                    t = (leftEdgeConstraint.constant - closedConstantLeft) / (openConstantLeft - closedConstantLeft)
                }
                backdropView.alpha = CGFloat(t) * 0.85
            case .none:
                break
            }

        case .ended, .cancelled:
            let finishedAxis = panelPanAxis
            if panelPanAxis == .verticalMove {
                persistPosition()
            } else if panelPanAxis == .horizontalOpen {
                let v = g.velocity(in: self).x
                if attachedEdge == .right {
                    let mid = (openConstant + closedConstant) / 2
                    if rightEdgeConstraint.constant < mid || v < -100 {
                        setOpen(true, animated: true)
                    } else {
                        setOpen(false, animated: true)
                    }
                } else {
                    let mid = (openConstantLeft + closedConstantLeft) / 2
                    if leftEdgeConstraint.constant > mid || v > 100 {
                        setOpen(true, animated: true)
                    } else {
                        setOpen(false, animated: true)
                    }
                }
            }
            panelPanAxis = nil
            if !isOpen, finishedAxis == .horizontalOpen {
                attemptEdgeSwitch(translation: tx, velocity: g.velocity(in: self))
            }

        default:
            break
        }
    }

    private func attemptEdgeSwitch(translation: CGPoint, velocity: CGPoint) {
        guard abs(translation.x) >= abs(translation.y) * 0.65 else { return }
        if attachedEdge == .right, translation.x < -48 || velocity.x < -350 {
            switchToEdge(.left)
        } else if attachedEdge == .left, translation.x > 48 || velocity.x > 350 {
            switchToEdge(.right)
        }
    }

    private func switchToEdge(_ edge: HorizontalEdge) {
        guard edge != attachedEdge else { return }
        let wasOpen = isOpen
        attachedEdge = edge
        isOpen = false
        applyEdgeAppearance()
        rightEdgeConstraint.constant = closedConstant
        leftEdgeConstraint.constant = closedConstantLeft
        backdropView.alpha = 0
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4, options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
        if wasOpen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.setOpen(true, animated: true)
            }
        }
        persistPosition()
    }

    func setOpen(_ open: Bool, animated: Bool) {
        isOpen = open
        if attachedEdge == .right {
            rightEdgeConstraint.constant = open ? openConstant : closedConstant
        } else {
            leftEdgeConstraint.constant = open ? openConstantLeft : closedConstantLeft
        }
        let animations = {
            self.backdropView.alpha = open ? 0.85 : 0
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.35, options: [.curveEaseOut], animations: animations)
        } else {
            animations()
        }
        backdropView.isUserInteractionEnabled = open
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isOpen {
            return super.hitTest(point, with: event)
        }
        let handleRect = handleView.convert(handleView.bounds, to: self)
        if handleRect.contains(point) {
            return super.hitTest(point, with: event)
        }
        return nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        panelView.backgroundColor = AppTheme.elevatedBackground
        handleGlyph.tintColor = AppTheme.chromeTint
        appearanceButton.tintColor = AppTheme.chromeTint
        resetButton.tintColor = AppTheme.chromeTint
    }
}

extension SideToolsDrawerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
