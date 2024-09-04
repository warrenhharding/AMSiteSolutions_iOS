//
//  AppDelegate.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // 1. Create the window
        window = UIWindow(frame: UIScreen.main.bounds)

        // 2. Create an instance of LoginViewController
        let loginViewController = LoginViewController()
//        let loginViewController = OperatorVC()

        // 3. Embed it in a navigation controller (if needed)
        let navigationController = UINavigationController(rootViewController: loginViewController)

        // 4. Set the navigation controller as the rootViewController of the window
        window?.rootViewController = navigationController

        // 5. Make the window visible
        window?.makeKeyAndVisible()
        
//         Create your UIWindow
//        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // Load LoginViewController from storyboard
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        guard let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
//            fatalError("Unable to instantiate LoginViewController from storyboard")
//        }
        
//         Set as root view controller
//        window?.rootViewController = loginViewController
//        window?.makeKeyAndVisible()

        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

