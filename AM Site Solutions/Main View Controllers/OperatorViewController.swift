//
//  OperatorViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import Firebase
import FirebaseStorage
import CoreLocation

class OperatorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
  
    var forms: [Form] = []
    var englishForms: [Form] = []
    var collectionView: UICollectionView!
    private let updateFarmButton = UIBarButtonItem()
    var shouldRedownloadImages = false
    private let storageRef = Storage.storage().reference()
    
//    var availableLanguages: [String] = ["en", "de", "pt-BR"]
    let pickerView = UIPickerView()
    let toolbar = UIToolbar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")
                
        // Setup the navigation bar
        setupNavigationBar()
        
        // Setup collection view
        setupCollectionView()
        
        setupLanguagePicker()
        
        NotificationCenter.default.addObserver(self, selector: #selector(translationsLoaded), name: .translationsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        checkDownloadImagesFlag()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure the navigation bar is visible
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc func translationsLoaded() {
        print("Translations loaded, setting up UI.")
        
    }
    
    @objc func reloadTranslations() {
        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")
        self.fetchForms()
    }
    
    private func setupLanguagePicker() {
        // Picker View
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.backgroundColor = .white
        pickerView.isHidden = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)

        // Toolbar
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = ColorScheme.amBlue
        toolbar.sizeToFit()
        toolbar.isHidden = true

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0

        // Layout
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: pickerView.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBarHeight),
            pickerView.heightAnchor.constraint(equalToConstant: 216)
        ])
    }
    
    @objc private func languageSelectorTapped() {
        toolbar.isHidden = false
        pickerView.isHidden = false
    }

    @objc private func doneButtonTapped() {
        toolbar.isHidden = true
        pickerView.isHidden = true
    }
    

   
    private func setupNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = ColorScheme.amBlue
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        }

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.prefersLargeTitles = false
                
        // Custom view for extending height
        let customView = UIView()
        customView.backgroundColor = ColorScheme.amBlue
        customView.translatesAutoresizingMaskIntoConstraints = false

        navigationController?.navigationBar.addSubview(customView)
        NSLayoutConstraint.activate([
            customView.leadingAnchor.constraint(equalTo: navigationController!.navigationBar.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: navigationController!.navigationBar.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: navigationController!.navigationBar.bottomAnchor),
            customView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        // Set the right bar button item
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"), style: .plain, target: self, action: #selector(menuButtonTapped))
        menuButton.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)], for: .normal)
        navigationItem.rightBarButtonItem = menuButton
    }
    
    
    // Check Firebase for the 'downloadImages' flag and compare with UserDefaults
    func checkDownloadImagesFlag() {
        let ref = Database.database().reference().child("staticData/downloadImages")
        let localDownloadImages = UserDefaults.standard.string(forKey: "downloadImages")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let firebaseDownloadImages = snapshot.value as? String {
                if firebaseDownloadImages != localDownloadImages {
                    // If the flag has changed, we should redownload the images
                    self.shouldRedownloadImages = true
                    // Store the new value in UserDefaults
                    UserDefaults.standard.set(firebaseDownloadImages, forKey: "downloadImages")
                }
            }
            // Proceed to fetch forms and icons
            self.fetchForms()
        } withCancel: { error in
            print("Failed to retrieve downloadImages flag from Firebase: \(error.localizedDescription)")
            // If fetching the flag fails, proceed with local logic
            self.fetchForms()
        }
    }
    


    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: 180)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FormCell.self, forCellWithReuseIdentifier: "FormCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
    }
    

    @objc func menuButtonTapped() {
        // Create the alert controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Dynamically fetch translations
        let toggleLocationAction = UIAlertAction(
            title: isLocationEnabled()
                ? TranslationManager.shared.getTranslation(for: "operatorTab.menuDisableLocation")
                : TranslationManager.shared.getTranslation(for: "operatorTab.menuEnableLocation"),
            style: .default
        ) { _ in
            self.toggleLocation()
        }
        
        let changeLanguageAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuChangeLanguage"),
            style: .default
        ) { _ in
            self.changeLanguage()
        }
        
        let logoutAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuLogout"),
            style: .destructive
        ) { _ in
            self.logoutUser()
        }

        let cancelAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.cancelButton"),
            style: .cancel,
            handler: nil
        )

        // Add actions to the alert
        alertController.addAction(toggleLocationAction)
        alertController.addAction(changeLanguageAction)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)

        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
//    private func logoutUser() {
//        do {
//            try Auth.auth().signOut()
//            let loginVC = LoginViewController()
//            navigationController?.setViewControllers([loginVC], animated: true)
//        } catch {
//            print("Error signing out: \(error)")
//        }
//    }
    
    private func logoutUser() {
        do {
            try Auth.auth().signOut()

            let loginViewController = LoginViewController()

            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                window.rootViewController = loginViewController
                window.makeKeyAndVisible()
            } else {
                print("Error: Unable to find SceneDelegate or UIWindow")
            }
        } catch {
            print("Error signing out: \(error)")
        }
    }

    private func toggleLocation() {
        if isLocationEnabled() {
            // Disable location
            if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettingsURL)
            }
        } else {
            // Request location permission
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }

    private func isLocationEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    
    private func changeLanguage() {
        toolbar.isHidden = false
        pickerView.isHidden = false
    }
    


   
    // Method to handle just English - different layout of the forms node in firebase.
//    func fetchForms() {
//        let ref = Database.database().reference().child("forms")
//        ref.observeSingleEvent(of: .value, with: { snapshot in
//            self.forms.removeAll()
//            for child in snapshot.children {
//                if let snapshot = child as? DataSnapshot,
//                   let dict = snapshot.value as? [String: Any] {
//                    
//                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
//                    
//                    if let name = dict["name"] as? String,
//                       let iconName = dict["iconName"] as? String,
//                       let questionsArray = dict["questions"] as? [[String: Any]] {
//                        
//                        var questions: [Question] = []
//                        for questionDict in questionsArray {
//                            if let id = questionDict["id"] as? String,
//                               let text = questionDict["text"] as? String,
//                               let typeString = questionDict["type"] as? String,
//                               let type = QuestionType(rawValue: typeString) {
//                                let question = Question(id: id, text: text, type: type)
//                                questions.append(question)
//                            }
//                        }
//                        
//                        let form = Form(id: snapshot.key, name: name, iconName: iconName, questions: questions)
//                        
//                        if isDisplayed {
//                            self.forms.append(form)
//                        }
//                    }
//                }
//            }
//            self.collectionView.reloadData()
//            self.fetchAllIcons() // Fetch icons after forms are loaded
//        })
//    }
    
    
    // Method to handle multiple languages.
//    func fetchForms() {
//        let ref = Database.database().reference().child("forms_new")
//        let selectedLanguage = TranslationManager.shared.getSelectedLanguage() // Retrieve selected language
//        print("selectedLanguage = \(selectedLanguage)")
//
//        ref.observeSingleEvent(of: .value, with: { snapshot in
//            self.forms.removeAll()
//
//            for child in snapshot.children {
//                if let snapshot = child as? DataSnapshot,
//                   let dict = snapshot.value as? [String: Any] {
//
//                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
//
//                    if let nameDict = dict["name"] as? [String: String],
//                       let formName = nameDict[selectedLanguage],
//                       let iconName = dict["iconName"] as? String,
//                       let questionsArray = dict["questions"] as? [[String: Any]] {
//
//                        var questions: [Question] = []
//                        for questionDict in questionsArray {
//                            if let id = questionDict["id"] as? String,
//                               let translations = questionDict["translations"] as? [String: String],
//                               let text = translations[selectedLanguage], // Fetch the question text in the selected language
//                               let typeString = questionDict["type"] as? String,
//                               let type = QuestionType(rawValue: typeString) {
//                                let question = Question(id: id, text: text, type: type)
//                                questions.append(question)
//                            }
//                        }
//
//                        let form = Form(id: snapshot.key, name: formName, iconName: iconName, questions: questions)
//                        print("form: \(form)")
//
//                        if isDisplayed {
//                            self.forms.append(form)
//                        }
//                    }
//                }
//            }
//            self.collectionView.reloadData()
//            self.fetchAllIcons() // Fetch icons after forms are loaded
//        })
//    }
    
    func fetchForms() {
        let ref = Database.database().reference().child("forms_new")
        let selectedLanguage = TranslationManager.shared.getSelectedLanguage()
        print("selectedLanguage = \(selectedLanguage)")

        ref.observeSingleEvent(of: .value, with: { snapshot in
            self.forms.removeAll()
            self.englishForms.removeAll() // Clear the English forms array

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    
                    print("dict: \(dict)")

                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true

                    if let nameDict = dict["name"] as? [String: String],
                       let formName = nameDict[selectedLanguage],
                       let englishName = nameDict["en"], // Get English name
                       let iconName = dict["iconName"] as? String,
                       let questionsArray = dict["questions"] as? [[String: Any]] {

                        var questions: [Question] = []
                        var englishQuestions: [Question] = [] // Initialize englishQuestions here
                        
                        print("formName: \(formName)")

                        for questionDict in questionsArray {
                            if let id = questionDict["id"] as? String,
                               let translations = questionDict["translations"] as? [String: String],
                               let text = translations[selectedLanguage],
                               let englishText = translations["en"], // Get English question text
                               let typeString = questionDict["type"] as? String,
                               let type = QuestionType(rawValue: typeString) {

                                let question = Question(id: id, text: text, type: type)
                                questions.append(question)

                                // Create English question
                                let englishQuestion = Question(id: id, text: englishText, type: type)

                                // Add to English questions array
                                englishQuestions.append(englishQuestion)
                            }
                        }

                        let form = Form(id: snapshot.key, name: formName, iconName: iconName, questions: questions)
//                        print("form: \(form)")
                        if isDisplayed {
                            self.forms.append(form)
                        }

                        // Create English form
                        let englishForm = Form(id: snapshot.key, name: englishName, iconName: iconName, questions: englishQuestions)
//                        print("englishForm: \(englishForm)")
                        if isDisplayed {
                            self.englishForms.append(englishForm)
                        }
                    }
                }
            }
            self.collectionView.reloadData()
            self.fetchAllIcons()
        })
    }



    // Fetch all icons for forms
    func fetchAllIcons() {
        for form in forms {
            fetchIcon(iconName: form.iconName)
        }
    }


    // Fetch individual icons, force redownload if required
    func fetchIcon(iconName: String) {
        let localFileURL = getDocumentsDirectory().appendingPathComponent(iconName)
        
        // Check if the icon exists and if we should redownload
        if !FileManager.default.fileExists(atPath: localFileURL.path) || shouldRedownloadImages {
            // Download the icon from Firebase Storage
            let iconRef = storageRef.child("icons/\(iconName)")
            iconRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Failed to download icon: \(error.localizedDescription)")
                    return
                }
                if let data = data {
                    do {
                        // Save the icon to local storage
                        try data.write(to: localFileURL)
                        print("Downloaded and saved icon: \(iconName)")
                        
                        // Reload the collection view to display the new icon
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                        
                    } catch {
                        print("Failed to save icon: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Icon already exists locally and no need to redownload
            print("Icon \(iconName) already exists in local storage")
        }
    }

    // Helper method to get the documents directory
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }


    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return forms.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormCell", for: indexPath) as! FormCell
        let form = forms[indexPath.item]
        cell.form = form
        
        let localFileURL = getDocumentsDirectory().appendingPathComponent(form.iconName)
        
        // Check if the icon exists locally, otherwise use the placeholder
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            // Load the icon from local storage
            if let imageData = try? Data(contentsOf: localFileURL) {
                cell.iconImageView.image = UIImage(data: imageData)
            }
        } else {
            // Use the placeholder image
            cell.iconImageView.image = UIImage(named: "form_placeholder")
        }

        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let form = forms[indexPath.item]
        let englishForm = englishForms[indexPath.item]
        let formVC = FormViewController()
        formVC.form = form
        formVC.englishForm = englishForm
        navigationController?.pushViewController(formVC, animated: true)
    }
}


extension OperatorViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return LanguageManager.shared.availableLanguages.count
    }

//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        switch availableLanguages[row] {
//        case "en": return "English"
//        case "de": return "Deutsch"
//        case "pt-BR": return "Português (Brasil)"
//        default: return availableLanguages[row]
//        }
//    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return LanguageManager.shared.availableLanguages[row].name
    }

//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        // Get the selected language code
//        let selectedLanguage = availableLanguages[row]
//        
//        // Update the language label with the corresponding name
//        switch selectedLanguage {
//        case "en":
//            updateDoneButtonTitle("Done")
//        case "de":
//            updateDoneButtonTitle("Fertig") // German for "Done"
//        case "pt-BR":
//            updateDoneButtonTitle("Concluído") // Brazilian Portuguese for "Done"
//        default:
//            updateDoneButtonTitle("Done")
//        }
//
//        // Change the app's language
//        TranslationManager.shared.changeLanguage(to: selectedLanguage) { success in
//            if success {
//                NotificationCenter.default.post(name: .languageChanged, object: nil)
//            }
//        }
//    }
    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        let selectedLanguage = LanguageManager.shared.availableLanguages[row].code
//        let selectedLanguageName = LanguageManager.shared.availableLanguages[row].name
//
//        // Update the Done button title based on the selected language
//        switch selectedLanguage {
//        case "en":
//            updateDoneButtonTitle("Done")
//        case "de":
//            updateDoneButtonTitle("Fertig") // German for "Done"
//        case "pt-BR":
//            updateDoneButtonTitle("Concluído") // Brazilian Portuguese for "Done"
//        default:
//            updateDoneButtonTitle("Done")
//        }
//
//        // Change the app's language
//        TranslationManager.shared.changeLanguage(to: selectedLanguage) { success in
//            if success {
//                NotificationCenter.default.post(name: .languageChanged, object: nil)
//            }
//        }
//    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedLanguage = LanguageManager.shared.availableLanguages[row].code
        let selectedLanguageName = LanguageManager.shared.availableLanguages[row].name

        // Update the label immediately
//        languageLabel.text = selectedLanguageName
        
        print("selectedLanguage: \(selectedLanguage)")
        print("selectedLanguageName: \(selectedLanguageName)")
//        print("languageLabel.text: \(languageLabel.text)")
        
        // Change the app's language asynchronously
        TranslationManager.shared.changeLanguage(to: selectedLanguage) { success in
            if success {
                // Fetch the updated translation for "Done" after the language change is complete
                let doneLabel = TranslationManager.shared.getTranslation(for: "common.done")
                self.updateDoneButtonTitle(doneLabel)
                
                print("Updated Done label: \(doneLabel)")
                
                // Notify observers that the language has changed
                NotificationCenter.default.post(name: .languageChanged, object: nil)
            }
        }
    }

    // Helper method to update the "Done" button's title
    private func updateDoneButtonTitle(_ title: String) {
        if let doneButton = toolbar.items?.last {
            doneButton.title = title
        }
    }
}
