//
//  TranslationManager.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/12/2024.
//

import Foundation
import FirebaseDatabase
import FirebaseFunctions

class TranslationManager {
    static let shared = TranslationManager()
    private lazy var functions = Functions.functions()
    
    private var translations: [String: Any] = [:]
    private(set) var isTranslationsLoaded: Bool = false
    
    private let databaseRef = Database.database().reference()
    private let userDefaults = UserDefaults.standard
    private let fallbackLanguage = "en"
    private let selectedLanguageKey = "selectedLanguage"
//    let availableLanguages: [String] = ["en", "de", "pt-BR"]
    
    private init() {}
    
    // Fetch translations for the selected language
//    func loadTranslations(completion: @escaping (Bool) -> Void) {
//        let selectedLanguage = userDefaults.string(forKey: selectedLanguageKey) ?? fallbackLanguage
//        databaseRef.child("translations").child(selectedLanguage).observeSingleEvent(of: .value) { snapshot in
//            if let data = snapshot.value as? [String: Any] {
//                self.translations = data
//                completion(true)
//            } else {
//                self.loadFallbackTranslations(completion: completion)
//            }
//        }
//    }
//    
//    // Load fallback translations
//    private func loadFallbackTranslations(completion: @escaping (Bool) -> Void) {
//        databaseRef.child("translations").child(fallbackLanguage).observeSingleEvent(of: .value) { snapshot in
//            if let data = snapshot.value as? [String: Any] {
//                self.translations = data
//                completion(true)
//            } else {
//                completion(false)
//            }
//        }
//    }
    
    func loadTranslations(completion: @escaping (Bool) -> Void) {
            let selectedLanguage = userDefaults.string(forKey: selectedLanguageKey) ?? fallbackLanguage
            databaseRef.child("translations").child(selectedLanguage).observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any] {
                    self.translations = data
                    self.isTranslationsLoaded = true
                    print("Translations loaded successfully for \(selectedLanguage).")
                    completion(true)
                } else {
                    self.loadFallbackTranslations(completion: completion)
                }
            } withCancel: { error in
                print("Error loading translations: \(error.localizedDescription)")
                self.loadFallbackTranslations(completion: completion)
            }
        }

        /// Load fallback translations if the selected language fails
        private func loadFallbackTranslations(completion: @escaping (Bool) -> Void) {
            print("Loading fallback translations for \(fallbackLanguage).")
            databaseRef.child("translations").child(fallbackLanguage).observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any] {
                    self.translations = data
                    self.isTranslationsLoaded = true
                    print("Fallback translations loaded successfully.")
                    completion(true)
                } else {
                    print("Failed to load fallback translations. Falling back to defaults.")
                    self.translations = [:] // Reset translations if fallback also fails
                    self.isTranslationsLoaded = false
                    completion(false)
                }
            }
        }
    
    // Get translation for a specific key
    func getTranslation(for keyPath: String) -> String {
        let keys = keyPath.split(separator: ".").map(String.init)
        var current: Any? = translations
        for key in keys {
            if let dict = current as? [String: Any], let next = dict[key] {
                current = next
            } else {
                return keyPath // Fallback to the keyPath if not found
            }
        }
        return current as? String ?? keyPath
    }
    
    // Change language
    func changeLanguage(to language: String, completion: @escaping (Bool) -> Void) {
        // Set the language and load translations
        userDefaults.set(language, forKey: selectedLanguageKey)
        loadTranslations { success in
            if success {
                NotificationCenter.default.post(name: .languageChanged, object: nil)
            }
            completion(success)
        }
    }
    
    // Get the currently selected language
    func getSelectedLanguage() -> String {
        return userDefaults.string(forKey: selectedLanguageKey) ?? fallbackLanguage
    }
    
    // Translate text using the cloud function
    func translateTextUsingCloudFunction(_ text: String, sourceLanguage: String, targetLanguage: String, completion: @escaping (String) -> Void) {
        let functions = Functions.functions()
        let data: [String: Any] = [
            "text": text,
            "sourceLanguage": sourceLanguage,
            "targetLanguage": targetLanguage
        ]
        
        functions.httpsCallable("translateCommentText").call(data) { result, error in
            if let error = error {
                print("Error calling translateText function: \(error.localizedDescription)")
                completion(text) // Fallback to original text
                return
            }
            
            if let resultData = result?.data as? [String: Any],
               let translatedText = resultData["translatedText"] as? String {
                print("Cloud function returned translated text: \(translatedText)")
                completion(translatedText)
            } else {
                print("Unexpected response from cloud function.")
                completion(text) // Fallback to original text
            }
        }
    }
}


extension Notification.Name {
    static let translationsLoaded = Notification.Name("translationsLoaded")
    static let languageChanged = Notification.Name("languageChanged")
}
