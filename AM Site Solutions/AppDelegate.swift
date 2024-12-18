//
//  AppDelegate.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import Firebase
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let selectedLanguageKey = "selectedLanguage"
//    var availableLanguages: [Language] = []
    

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
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if
         granted {
                print("Notification permission granted.")
                // You can register for remote notifications here if needed
            } else {
                print("Notification permission denied.")
                // Handle the case where the user denies permission
            }
        }
        
        let userDefaults = UserDefaults.standard
        if userDefaults.string(forKey: selectedLanguageKey) == nil {
            userDefaults.set("en", forKey: selectedLanguageKey)
        }
        
        
        // Load translations based on the selected language
        TranslationManager.shared.loadTranslations { success in
            if success {
                print("Translations loaded successfully for the selected language.")
                NotificationCenter.default.post(name: .translationsLoaded, object: nil)
            } else {
                print("Failed to load translations. Falling back to hardcoded defaults.")
            }
        }

        fetchSupportedLanguages()
                
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Messaging.messaging().apnsToken = deviceToken
      print("APNs token received: \(deviceToken)") // Add this line
    }
    
    func fetchSupportedLanguages() {
            let ref = Database.database().reference(withPath: "supportedLanguages")
            ref.observeSingleEvent(of: .value) { snapshot in
                guard let languagesArray = snapshot.value as? [[String: String]] else {
                    print("Invalid data format for supportedLanguages")
                    return
                }
                
                LanguageManager.shared.availableLanguages = languagesArray.compactMap { dict in
                    if let code = dict["code"], let name = dict["name"] {
                        return Language(code: code, name: name)
                    }
                    return nil
                }
                
                // Notify the app that languages have been loaded
                NotificationCenter.default.post(name: .languagesLoaded, object: nil)
            } withCancel: { error in
                print("Failed to fetch supportedLanguages: \(error.localizedDescription)")
            }
        }


}

extension Notification.Name {
    static let languagesLoaded = Notification.Name("languagesLoaded")
}

