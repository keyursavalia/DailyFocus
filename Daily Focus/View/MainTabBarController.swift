import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let focusNav = UINavigationController(rootViewController: TaskListViewController())
        focusNav.tabBarItem = UITabBarItem(
            title: "Focus",
            image: UIImage(systemName: "list.bullet.rectangle"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.fill")
        )

        let calendarNav = UINavigationController(rootViewController: CalendarViewController())
        calendarNav.tabBarItem = UITabBarItem(
            title: "Calendar",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.circle.fill")
        )

        viewControllers = [focusNav, calendarNav]
        applyTabBarAppearance()
    }

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = AppTheme.elevatedBackground

        let item = UITabBarItemAppearance()
        item.normal.iconColor = AppTheme.secondaryText
        item.normal.titleTextAttributes = [.foregroundColor: AppTheme.secondaryText]
        item.selected.iconColor = AppTheme.accent
        item.selected.titleTextAttributes = [.foregroundColor: AppTheme.accent]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = AppTheme.accent
    }
}
