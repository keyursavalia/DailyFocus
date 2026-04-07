import UIKit

/// Onboarding / empty state from Stitch `onboarding_dark/code.html`: logo, headline, body, three bento cards,
/// gradient Get Started, and secondary “Log in” line. Matches dark palette; adapts for light mode.
final class EmptyStateView: UIView {

    // MARK: - Stitch tokens (dark reference from HTML)
    private enum Stitch {
        static let primary = UIColor(red: 173 / 255, green: 198 / 255, blue: 1, alpha: 1)
        static let primaryContainer = UIColor(red: 75 / 255, green: 142 / 255, blue: 1, alpha: 1)
        static let onPrimaryContainerText = UIColor(red: 0 / 255, green: 40 / 255, blue: 92 / 255, alpha: 1)
        static let surfaceContainerLow = UIColor(red: 27 / 255, green: 27 / 255, blue: 27 / 255, alpha: 1)
        static let surfaceContainer = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 1)
        static let onSurface = UIColor(red: 226 / 255, green: 226 / 255, blue: 226 / 255, alpha: 1)
        static let onSurfaceVariant = UIColor(red: 193 / 255, green: 198 / 255, blue: 215 / 255, alpha: 1)
        static let outlineVariant = UIColor(red: 65 / 255, green: 71 / 255, blue: 85 / 255, alpha: 1)
    }

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let logoBox: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.layer.masksToBounds = false
        return v
    }()

    private let logoIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        iv.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: cfg)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let brandLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let headlineLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stepsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let actionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let ctaWrapper: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerCurve = .continuous
        return v
    }()

    private let ctaGradient = CAGradientLayer()

    private let getStartedButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Get Started", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let loginButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Already have an account? Log in", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.titleLabel?.numberOfLines = 1
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    var onGetStartedTapped: (() -> Void)?
    /// Optional — when nil, the “Log in” line is hidden (set when you add sign-in).
    var onLogInTapped: (() -> Void)? {
        didSet { loginButton.isHidden = (onLogInTapped == nil) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        applyTypography()
        applyChrome()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ctaGradient.frame = ctaWrapper.bounds
        let r = ctaWrapper.bounds
        if r.width > 0, r.height > 0 {
            ctaWrapper.layer.shadowPath = UIBezierPath(roundedRect: r, cornerRadius: 26).cgPath
        }
    }

    private func setupUI() {
        addSubview(contentView)

        logoBox.addSubview(logoIcon)
        contentView.addSubview(logoBox)
        contentView.addSubview(brandLabel)
        contentView.addSubview(headlineLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(stepsStack)
        contentView.addSubview(actionsStack)
        actionsStack.addArrangedSubview(ctaWrapper)
        actionsStack.addArrangedSubview(loginButton)

        ctaWrapper.layer.cornerRadius = 26
        ctaGradient.masksToBounds = true
        ctaGradient.cornerRadius = 26
        ctaGradient.startPoint = CGPoint(x: 0, y: 0.5)
        ctaGradient.endPoint = CGPoint(x: 1, y: 0.5)
        ctaWrapper.layer.addSublayer(ctaGradient)
        ctaWrapper.addSubview(getStartedButton)

        stepsStack.addArrangedSubview(makeStepCard(number: "01", title: "Plan", emphasized: false))
        stepsStack.addArrangedSubview(makeStepCard(number: "02", title: "Focus", emphasized: true))
        stepsStack.addArrangedSubview(makeStepCard(number: "03", title: "Done", emphasized: false))

        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        loginButton.isHidden = true

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            logoBox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            logoBox.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoBox.widthAnchor.constraint(equalToConstant: 58),
            logoBox.heightAnchor.constraint(equalToConstant: 58),

            logoIcon.centerXAnchor.constraint(equalTo: logoBox.centerXAnchor),
            logoIcon.centerYAnchor.constraint(equalTo: logoBox.centerYAnchor),

            brandLabel.topAnchor.constraint(equalTo: logoBox.bottomAnchor, constant: 12),
            brandLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            brandLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            headlineLabel.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 18),
            headlineLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 14),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            stepsStack.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 18),
            stepsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            actionsStack.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 18),
            actionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            ctaWrapper.heightAnchor.constraint(equalToConstant: 54),

            getStartedButton.topAnchor.constraint(equalTo: ctaWrapper.topAnchor),
            getStartedButton.leadingAnchor.constraint(equalTo: ctaWrapper.leadingAnchor),
            getStartedButton.trailingAnchor.constraint(equalTo: ctaWrapper.trailingAnchor),
            getStartedButton.bottomAnchor.constraint(equalTo: ctaWrapper.bottomAnchor)
        ])
    }

    private func roundedHeadlineFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let desc = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: desc, size: size)
        }
        return base
    }

    private func makeStepCard(number: String, title: String, emphasized: Bool) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.tag = emphasized ? 1 : 0

        let num = UILabel()
        num.text = number
        num.font = roundedHeadlineFont(size: 30, weight: .bold)
        num.textAlignment = .natural
        num.translatesAutoresizingMaskIntoConstraints = false

        let lab = UILabel()
        lab.text = title.uppercased()
        lab.font = .systemFont(ofSize: 13, weight: .medium)
        lab.textAlignment = .natural
        lab.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [num, lab])
        col.axis = .vertical
        col.spacing = 8
        col.alignment = .leading
        col.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            col.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -20)
        ])

        if emphasized {
            card.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.35
            card.layer.shadowRadius = 20
            card.layer.shadowOffset = CGSize(width: 0, height: 14)
            card.layer.masksToBounds = false
        }
        return card
    }

    private func applyTypography() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let primary = isDark ? Stitch.onSurface : AppTheme.primaryText
        let accent = isDark ? Stitch.primary : AppTheme.accent
        let variant = isDark ? Stitch.onSurfaceVariant : AppTheme.secondaryText

        let brand = NSAttributedString(
            string: "DAILY FOCUS",
            attributes: [
                .font: roundedHeadlineFont(size: 17, weight: .bold),
                .foregroundColor: primary,
                .kern: 3.2
            ]
        )
        brandLabel.attributedText = brand

        let headlineSize: CGFloat = 36
        let headlineStyle = NSMutableParagraphStyle()
        headlineStyle.alignment = .center
        headlineStyle.lineSpacing = 3

        let baseHead: [NSAttributedString.Key: Any] = [
            .font: roundedHeadlineFont(size: headlineSize, weight: .bold),
            .foregroundColor: primary,
            .paragraphStyle: headlineStyle
        ]

        let head = NSMutableAttributedString()
        head.append(NSAttributedString(string: "Focus on what", attributes: baseHead))
        head.append(NSAttributedString(string: "\n", attributes: baseHead))
        head.append(NSAttributedString(string: "matters", attributes: [
            .font: roundedHeadlineFont(size: headlineSize, weight: .bold).italicized(),
            .foregroundColor: accent,
            .paragraphStyle: headlineStyle
        ]))
        head.append(NSAttributedString(string: " most.", attributes: baseHead))
        headlineLabel.attributedText = head

        let bodyFont: CGFloat = 17
        let body = NSMutableAttributedString(
            string: "Eliminate the noise. Our editorial approach helps you master your day with only ",
            attributes: [
                .font: UIFont.systemFont(ofSize: bodyFont, weight: .regular),
                .foregroundColor: variant
            ]
        )
        body.append(NSAttributedString(string: "3 tasks", attributes: [
            .font: UIFont.systemFont(ofSize: bodyFont, weight: .semibold),
            .foregroundColor: primary
        ]))
        body.append(NSAttributedString(string: " a day.", attributes: [
            .font: UIFont.systemFont(ofSize: bodyFont, weight: .regular),
            .foregroundColor: variant
        ]))
        let bodyPara = NSMutableParagraphStyle()
        bodyPara.alignment = .center
        bodyPara.lineSpacing = 4
        body.addAttribute(.paragraphStyle, value: bodyPara, range: NSRange(location: 0, length: body.length))
        bodyLabel.attributedText = body
    }

    private func applyChrome() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        backgroundColor = AppTheme.background

        if isDark {
            ctaWrapper.layer.shadowColor = Stitch.primary.cgColor
            ctaWrapper.layer.shadowOpacity = 0.22
            ctaWrapper.layer.shadowRadius = 22
            ctaWrapper.layer.shadowOffset = CGSize(width: 0, height: 16)
            ctaWrapper.layer.masksToBounds = false

            logoBox.backgroundColor = Stitch.surfaceContainer
            logoBox.layer.shadowColor = UIColor.black.cgColor
            logoBox.layer.shadowOpacity = 0.45
            logoBox.layer.shadowRadius = 24
            logoBox.layer.shadowOffset = CGSize(width: 0, height: 12)
            logoIcon.tintColor = Stitch.primary
            ctaGradient.colors = [Stitch.primary.cgColor, Stitch.primaryContainer.cgColor]
            getStartedButton.setTitleColor(Stitch.onPrimaryContainerText, for: .normal)
            loginButton.setTitleColor(Stitch.onSurfaceVariant, for: .normal)
        } else {
            ctaWrapper.layer.shadowColor = AppTheme.accent.cgColor
            ctaWrapper.layer.shadowOpacity = 0.18
            ctaWrapper.layer.shadowRadius = 16
            ctaWrapper.layer.shadowOffset = CGSize(width: 0, height: 12)
            ctaWrapper.layer.masksToBounds = false

            logoBox.backgroundColor = AppTheme.cardBackground
            logoBox.layer.shadowOpacity = 0.12
            logoBox.layer.shadowRadius = 16
            logoBox.layer.shadowOffset = CGSize(width: 0, height: 8)
            logoBox.layer.shadowColor = UIColor.black.cgColor
            logoIcon.tintColor = AppTheme.accent
            ctaGradient.colors = [
                AppTheme.accentBright.cgColor,
                AppTheme.accent.cgColor
            ]
            getStartedButton.setTitleColor(.white, for: .normal)
            loginButton.setTitleColor(AppTheme.secondaryText, for: .normal)
        }

        let borderSubtle = isDark
            ? Stitch.outlineVariant.withAlphaComponent(0.1)
            : AppTheme.border.withAlphaComponent(0.35)
        let borderEmphasis = isDark
            ? Stitch.primary.withAlphaComponent(0.35)
            : AppTheme.accent.withAlphaComponent(0.45)

        for card in stepsStack.arrangedSubviews {
            let emphasized = card.tag == 1
            if isDark {
                card.backgroundColor = emphasized ? Stitch.surfaceContainer : Stitch.surfaceContainerLow
            } else {
                card.backgroundColor = emphasized ? AppTheme.elevatedBackground : AppTheme.cardBackground
            }
            card.layer.borderWidth = emphasized ? 1.5 : 1
            card.layer.borderColor = emphasized ? borderEmphasis.cgColor : borderSubtle.cgColor

            let labels = card.subviews.compactMap { $0 as? UIStackView }.first?
                .arrangedSubviews.compactMap { $0 as? UILabel } ?? []
            if labels.count >= 2 {
                labels[0].textColor = isDark ? Stitch.primary : AppTheme.accent
                labels[1].textColor = isDark ? Stitch.onSurfaceVariant : AppTheme.secondaryText
            }
        }
    }

    @objc private func getStartedTapped() {
        onGetStartedTapped?()
    }

    @objc private func loginTapped() {
        onLogInTapped?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTypography()
        applyChrome()
        setNeedsLayout()
    }
}

// MARK: - UIFont
private extension UIFont {
    func italicized() -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(.traitItalic) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }
}
