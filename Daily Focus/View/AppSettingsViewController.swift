import UIKit

final class AppSettingsViewController: UIViewController {

    private let titleLabel = UILabel()
    private let appearanceRowView = UIView()
    private let appearanceLabel = UILabel()
    private let appearanceSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupViews()
    }

    private func setupViews() {
        titleLabel.text = "Settings"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        appearanceRowView.backgroundColor = AppTheme.cardBackground
        appearanceRowView.layer.cornerRadius = 14
        appearanceRowView.layer.cornerCurve = .continuous
        appearanceRowView.translatesAutoresizingMaskIntoConstraints = false

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "moon.fill", withConfiguration: iconCfg))
        iconView.tintColor = AppTheme.secondaryText
        iconView.translatesAutoresizingMaskIntoConstraints = false

        appearanceLabel.text = "Dark Mode"
        appearanceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        appearanceLabel.textColor = AppTheme.primaryText
        appearanceLabel.translatesAutoresizingMaskIntoConstraints = false

        appearanceSwitch.isOn = AppearanceManager.shared.preference == .dark
        appearanceSwitch.onTintColor = AppTheme.accent
        appearanceSwitch.addTarget(self, action: #selector(appearanceSwitchChanged), for: .valueChanged)
        appearanceSwitch.translatesAutoresizingMaskIntoConstraints = false

        appearanceRowView.addSubview(iconView)
        appearanceRowView.addSubview(appearanceLabel)
        appearanceRowView.addSubview(appearanceSwitch)

        view.addSubview(titleLabel)
        view.addSubview(appearanceRowView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            appearanceRowView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            appearanceRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            appearanceRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            appearanceRowView.heightAnchor.constraint(equalToConstant: 52),

            iconView.centerYAnchor.constraint(equalTo: appearanceRowView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: appearanceRowView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 20),

            appearanceLabel.centerYAnchor.constraint(equalTo: appearanceRowView.centerYAnchor),
            appearanceLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),

            appearanceSwitch.centerYAnchor.constraint(equalTo: appearanceRowView.centerYAnchor),
            appearanceSwitch.trailingAnchor.constraint(equalTo: appearanceRowView.trailingAnchor, constant: -16),
        ])
    }

    @objc private func appearanceSwitchChanged() {
        AppearanceManager.shared.preference = appearanceSwitch.isOn ? .dark : .light
    }
}
