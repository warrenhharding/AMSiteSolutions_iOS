//
//  MainTabBarController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit


class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create instance of OperatorViewController and embed it in a UINavigationController
//        let operatorVC = OperatorViewController()
        let operatorVC = OperatorViewController()
        let operatorNav = UINavigationController(rootViewController: operatorVC)
        operatorNav.tabBarItem = UITabBarItem(title: "Operator", image: UIImage(systemName: "person"), tag: 0)

        // Create instance of SettingsViewController and embed it in a UINavigationController
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)

        // Add the navigation controllers to the tab bar
        viewControllers = [operatorNav, settingsNav]
        
        // Set the delegate to self
        self.delegate = self
        
        // Customize Tab Bar
        tabBar.backgroundColor = .systemGray6
        tabBar.tintColor = ColorScheme.amBlue
        tabBar.unselectedItemTintColor = ColorScheme.amPink

        // Debugging prints
        print("Operator VC is embedded in Navigation Controller: \(operatorVC.navigationController != nil)")
        print("Settings VC is embedded in Navigation Controller: \(settingsVC.navigationController != nil)")
    }
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navController = viewController as? UINavigationController,
           navController.viewControllers.first is OperatorVC {
            navController.popToRootViewController(animated: false)
        }
        return true
    }
    
    // Ensuring the Dashboard is shown every time it is selected
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0, let dashboardNavController = viewControllers?.first as? UINavigationController {
            dashboardNavController.popToRootViewController(animated: false)
        }
    }
}


