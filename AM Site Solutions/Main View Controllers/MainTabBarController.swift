//
//  MainTabBarController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit


class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private var userType: String

    // Custom initializer to accept userType
    init(userType: String) {
        self.userType = userType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar appearance for all UINavigationControllers
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = ColorScheme.amBlue // Replace with your actual primary color
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Customize title color if needed
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white // Customize the tint color for back button, etc.


        // Create instance of OperatorViewController
        let operatorVC = OperatorViewController()
        let operatorNav = UINavigationController(rootViewController: operatorVC)
        operatorNav.tabBarItem = UITabBarItem(title: TranslationManager.shared.getTranslation(for: "operatorTab.opTabTitle"), image: UIImage(systemName: "person"), tag: 0)

        // Create instance of TimesheetViewController
        let timesheetVC = TimesheetViewController()
        let timesheetNav = UINavigationController(rootViewController: timesheetVC)
        timesheetNav.tabBarItem = UITabBarItem(title: TranslationManager.shared.getTranslation(for: "timesheetTab.timeTabTitle"), image: UIImage(systemName: "clock"), tag: 1)

        // Add the Operator and Timesheet tabs to the Tab Bar
        var viewControllers = [operatorNav, timesheetNav]

        // If user is admin, add the Settings tab
        if userType == "admin" || userType == "amAdmin" {
            let settingsVC = SettingsViewController()
            let settingsNav = UINavigationController(rootViewController: settingsVC)
            settingsNav.tabBarItem = UITabBarItem(title: TranslationManager.shared.getTranslation(for: "adminTab.adminTabTitle"), image: UIImage(systemName: "gear"), tag: 2)
            viewControllers.append(settingsNav)
        }

        // Set the view controllers
        self.viewControllers = viewControllers

        // Customize Tab Bar appearance
        tabBar.backgroundColor = .systemGray6
        tabBar.tintColor = ColorScheme.amBlue
        tabBar.unselectedItemTintColor = ColorScheme.amPink

        self.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
    }
    
    
    @objc func reloadTranslations() {
        // Update the tab bar item titles with the latest translations
        if let viewControllers = self.viewControllers {
            for (index, viewController) in viewControllers.enumerated() {
                if let navController = viewController as? UINavigationController {
                    switch index {
                    case 0: // Operator Tab
                        navController.tabBarItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opTabTitle")
                    case 1: // Timesheet Tab
                        navController.tabBarItem.title = TranslationManager.shared.getTranslation(for: "timesheetTab.timeTabTitle")
                    case 2: // Admin Tab (if present)
                        if userType == "admin" || userType == "amAdmin" {
                            navController.tabBarItem.title = TranslationManager.shared.getTranslation(for: "adminTab.adminTabTitle")
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

}
