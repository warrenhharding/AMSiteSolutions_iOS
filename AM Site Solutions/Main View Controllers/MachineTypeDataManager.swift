//
//  MachineTypeDataManager.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 06/08/2025.
//


import Foundation
import FirebaseDatabase

class MachineTypeDataManager {
    static let shared = MachineTypeDataManager()
    
    // MARK: - Properties
    private var machineTypes: [(id: String, name: String)] = []
    private var englishMachineTypes: [(id: String, name: String)] = []
    private var isLoading = false
    private var lastLoadTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load machine types if needed (cached or expired)
    func loadMachineTypesIfNeeded(completion: @escaping (Bool) -> Void) {
        // Check if we have cached data that's still valid
        if !machineTypes.isEmpty,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheExpirationTime {
            completion(true)
            return
        }
        
        // Prevent multiple simultaneous loads
        if isLoading {
            // Wait for current load to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadMachineTypesIfNeeded(completion: completion)
            }
            return
        }
        
        loadMachineTypes(completion: completion)
    }
    
    /// Force reload machine types from Firebase
    func reloadMachineTypes(completion: @escaping (Bool) -> Void) {
        loadMachineTypes(completion: completion)
    }
    
    /// Get cached machine types for current language
    func getMachineTypes() -> [(id: String, name: String)] {
        return machineTypes
    }
    
    /// Get cached English machine types
    func getEnglishMachineTypes() -> [(id: String, name: String)] {
        return englishMachineTypes
    }
    
    /// Check if machine types are loaded
    var isLoaded: Bool {
        return !machineTypes.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func loadMachineTypes(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        let ref = Database.database().reference().child("forms_new")
        let selectedLanguage = TranslationManager.shared.getSelectedLanguage()
        
        print("MachineTypeDataManager: Loading machine types for language: \(selectedLanguage)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else {
                completion(false)
                return
            }
            
            var currentLanguageTypes: [(id: String, name: String)] = []
            var englishTypes: [(id: String, name: String)] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    
                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
                    
                    if let nameDict = dict["name"] as? [String: String],
                       let currentLanguageName = nameDict[selectedLanguage],
                       let englishName = nameDict["en"],
                       isDisplayed {
                        
                        let machineType = (id: snapshot.key, name: currentLanguageName)
                        let englishMachineType = (id: snapshot.key, name: englishName)
                        
                        currentLanguageTypes.append(machineType)
                        englishTypes.append(englishMachineType)
                    }
                }
            }
            
            // Sort alphabetically by name
            currentLanguageTypes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            englishTypes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.machineTypes = currentLanguageTypes
                self.englishMachineTypes = englishTypes
                self.lastLoadTime = Date()
                self.isLoading = false
                
                print("MachineTypeDataManager: Loaded \(currentLanguageTypes.count) machine types")
                completion(true)
            }
        } withCancel: { [weak self] error in
            print("MachineTypeDataManager: Error loading machine types: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.isLoading = false
                completion(false)
            }
        }
    }
}
