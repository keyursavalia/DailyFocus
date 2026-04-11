import UIKit

final class AppSettingsViewController: UIViewController {

    // Compact floating card: declare a fixed preferred size so the
    // presentation controller can size the frame exactly.
    override var preferredContentSize: CGSize {
        get { CGSize(width: 256, height: 118) }
        set { super.preferredContentSize = newValue }
    }

    private let titleLabel = UILabel()
    private let divider = UIView()
    private let appearanceLabel = UILabel()
    private let appearanceSwitch = UISwitch()
    private let moonIcon = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Card background — elevated surface, not plain background
        view.backgroundColor = AppTheme.elevatedBackground
        view.clipsToBounds = true   // keeps content clipped to the rounded corners
        setupViews()
    }

    private func setupViews() {
        // Title
        titleLabel.text = "Settings"
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = AppTheme.secondaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        divider.backgroundColor = AppTheme.border
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Moon icon
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        moonIcon.image = UIImage(systemName: "moon.fill", withConfiguration: iconCfg)
        moonIcon.tintColor = AppTheme.accent
        moonIcon.contentMode = .scaleAspectFit
        moonIcon.translatesAutoresizingMaskIntoConstraints = false

        // Label
        appearanceLabel.text = "Dark Mode"
        appearanceLabel.font = .systemFont(ofSize: 15, weight: .regular)
        appearanceLabel.textColor = AppTheme.primaryText
        appearanceLabel.translatesAutoresizingMaskIntoConstraints = false

        // Switch
        appearanceSwitch.isOn = AppearanceManager.shared.preference == .dark
        appearanceSwitch.onTintColor = AppTheme.accent
        appearanceSwitch.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        appearanceSwitch.addTarget(self, action: #selector(appearanceSwitchChanged), for: .valueChanged)
        appearanceSwitch.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(divider)
        view.addSubview(moonIcon)
        view.addSubview(appearanceLabel)
        view.addSubview(appearanceSwitch)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            moonIcon.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 18),
            moonIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            moonIcon.widthAnchor.constraint(equalToConstant: 18),
            moonIcon.heightAnchor.constraint(equalToConstant: 18),

            appearanceLabel.centerYAnchor.constraint(equalTo: moonIcon.centerYAnchor),
            appearanceLabel.leadingAnchor.constraint(equalTo: moonIcon.trailingAnchor, constant: 10),

            appearanceSwitch.centerYAnchor.constraint(equalTo: moonIcon.centerYAnchor),
            appearanceSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
        ])
    }

    @objc private func appearanceSwitchChanged() {
        AppearanceManager.shared.preference = appearanceSwitch.isOn ? .dark : .light
    }
}
