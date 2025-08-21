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
import FirebaseAuth
import FirebaseDatabase


class OperatorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
  
    var forms: [Form] = []
    var englishForms: [Form] = []
    var collectionView: UICollectionView!
    private let updateFarmButton = UIBarButtonItem()
    var shouldRedownloadImages = false
    private let storageRef = Storage.storage().reference()
    private var favouriteFormIds = Set<String>()
    
    private let scanQRCodeButton = UIButton(type: .system)
    private var activityIndicator: UIActivityIndicatorView!
    
    let pickerView = UIPickerView()
    let toolbar = UIToolbar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")

//        Crashlytics.crashlytics().log("This is a test log message.")
//        fatalError("Test Crash")
                
        // Setup the navigation bar
        setupNavigationBar()
        
        // Setup collection view
        setupCollectionView()
        
        setupLanguagePicker()
        checkForUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(translationsLoaded), name: .translationsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
        
        setupScanButton()
        setupActivityIndicator()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Constraints for the new button
            scanQRCodeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scanQRCodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scanQRCodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scanQRCodeButton.heightAnchor.constraint(equalToConstant: 50),

            // Update collection view to be below the button
            collectionView.topAnchor.constraint(equalTo: scanQRCodeButton.bottomAnchor, constant: 10),
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
    
    func checkForUpdate() {
        guard let infoDictionary = Bundle.main.infoDictionary,
                  let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String,
                  let bundleId = Bundle.main.bundleIdentifier else {
                print("checkForUpdate: Failed to retrieve version info.")
                return
            }
        
        // Determine country code from user's locale. Default to "us" if not available.
        let countryCode = Locale.current.regionCode?.lowercased() ?? "ie"
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=\(countryCode)") else {
            print("checkForUpdate: Failed to construct URL.")
            return
        }
        
        print("checkForUpdate: Current version = \(currentVersion), Bundle ID = \(bundleId)")
        print("checkForUpdate: Query URL = \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("checkForUpdate: Error fetching update info: \(error.localizedDescription)")
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  results.count > 0,
                  let appStoreVersion = results[0]["version"] as? String else {
                print("checkForUpdate: Unable to parse JSON or no results found.")
                return
            }
            
            print("checkForUpdate: App Store version = \(appStoreVersion)")
            
            if currentVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending {
                print("checkForUpdate: New version available!")
                DispatchQueue.main.async {
                    self.showUpdateAlert(appStoreVersion: appStoreVersion)
                }
            } else {
                print("checkForUpdate: The app is up-to-date.")
            }
        }.resume()
    }

    func showUpdateAlert(appStoreVersion: String) {
        let title = "Update Available"
        let message = "A new version (\(appStoreVersion)) is available on the App Store. Would you like to update now?"
        print("showUpdateAlert: Preparing to show alert for version \(appStoreVersion)")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") {
                print("showUpdateAlert: Opening URL: \(url.absoluteString)")
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    print("showUpdateAlert: URL open completion success: \(success)")
                })
            } else {
                print("showUpdateAlert: Failed to create update URL.")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { _ in
            print("showUpdateAlert: User chose not to update at this time.")
        }))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: {
                print("showUpdateAlert: Alert presented successfully.")
            })
        }
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
    
    
    // MARK: - QR Code Scanning

    private func setupScanButton() {
        // Note: You will need to add this translation key
        scanQRCodeButton.setTitle(TranslationManager.shared.getTranslation(for: "operatorTab.scanQrCode"), for: .normal)
        scanQRCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scanQRCodeButton.setTitleColor(.white, for: .normal)
        scanQRCodeButton.backgroundColor = ColorScheme.amPink
        scanQRCodeButton.layer.cornerRadius = 26
        scanQRCodeButton.addTarget(self, action: #selector(scanQRCodeTapped), for: .touchUpInside)
        scanQRCodeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanQRCodeButton)
    }

    @objc private func scanQRCodeTapped() {
        let scannerVC = QRCodeScannerViewController()
        scannerVC.delegate = self
        scannerVC.modalPresentationStyle = .fullScreen
        present(scannerVC, animated: true, completion: nil)
    }

    private func handleDetectedQrCode(qrCodeData: String) {
        showLoading(true)

        guard let url = URL(string: qrCodeData),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let qrCodeId = components.queryItems?.first(where: { $0.name == "qrCodeId" })?.value else {
            showLoading(false)
            showAlert(
                title: TranslationManager.shared.getTranslation(for: "operatorTab.invalidQrCode"),
                message: TranslationManager.shared.getTranslation(for: "operatorTab.qrCodeIdMissing")
            )
            return
        }

        lookupMachineIdFromQrCode(qrCodeId: qrCodeId)
    }

    private func lookupMachineIdFromQrCode(qrCodeId: String) {
        let qrCodeRef = Database.database().reference()
            .child("qrCodes")
            .child(qrCodeId)
            .child("machineId")

        qrCodeRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let machineId = snapshot.value as? String, !machineId.isEmpty else {
                self?.showLoading(false)
                self?.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "operatorTab.qrCodeNotFound"),
                    message: TranslationManager.shared.getTranslation(for: "operatorTab.noMachineAssociated")
                )
                return
            }
            self?.getMachineDetails(machineId: machineId)
        } withCancel: { [weak self] error in
            self?.showLoading(false)
            self?.showAlert(
                title: TranslationManager.shared.getTranslation(for: "operatorTab.error"),
                message: TranslationManager.shared.getTranslation(for: "operatorTab.databaseError") + ": \(error.localizedDescription)"
            )
        }
    }

    private func getMachineDetails(machineId: String) {
        let machineRef = Database.database().reference().child("machines").child(machineId)

        machineRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, snapshot.exists(), let machineData = snapshot.value as? [String: Any] else {
                self?.showLoading(false)
                self?.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "operatorTab.machineNotFound"),
                    message: TranslationManager.shared.getTranslation(for: "operatorTab.machineNotInDatabase")
                )
                return
            }

            let appCustomerId = machineData["appCustomerId"] as? String
            let plantEquipmentNumber = machineData["plantEquipmentNumber"] as? String ?? ""
            let machineType = machineData["type"] as? String

            guard let userParent = UserSession.shared.userParent else {
                self.showLoading(false)
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "operatorTab.error"),
                    message: "User session not found."
                )
                return
            }

            if appCustomerId != userParent {
                self.showLoading(false)
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "operatorTab.noAccessPermission"),
                    message: TranslationManager.shared.getTranslation(for: "operatorTab.contactAdmin")
                )
                return
            }

            guard let formId = machineType, !formId.isEmpty else {
                self.showLoading(false)
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "operatorTab.invalidMachineType"),
                    message: TranslationManager.shared.getTranslation(for: "operatorTab.machineTypeNotSet")
                )
                return
            }

            self.loadFormAndOpenActivity(formId: formId, plantEquipmentNumber: plantEquipmentNumber, machineId: machineId)

        } withCancel: { [weak self] error in
            self?.showLoading(false)
            self?.showAlert(
                title: TranslationManager.shared.getTranslation(for: "operatorTab.error"),
                message: TranslationManager.shared.getTranslation(for: "operatorTab.databaseError") + ": \(error.localizedDescription)"
            )
        }
    }

    private func loadFormAndOpenActivity(formId: String, plantEquipmentNumber: String, machineId: String) {
        // The app's forms are already loaded into the 'forms' and 'englishForms' arrays.
        // We just need to find the correct one by its ID.
        guard let form = self.forms.first(where: { $0.id == formId }),
              let englishForm = self.englishForms.first(where: { $0.id == formId }) else {
            
            showLoading(false)
            showAlert(
                title: TranslationManager.shared.getTranslation(for: "operatorTab.formNotFound"),
                message: TranslationManager.shared.getTranslation(for: "operatorTab.formNotAvailable") + ": \(formId)"
            )
            return
        }
        
        openFormViewController(form: form, englishForm: englishForm, plantEquipmentNumber: plantEquipmentNumber, machineId: machineId)
    }

    private func openFormViewController(form: Form, englishForm: Form, plantEquipmentNumber: String, machineId: String) {
        showLoading(false)
        let formVC = FormViewController()
        formVC.form = form
        formVC.englishForm = englishForm
        
        // IMPORTANT: You will need to add these properties to your FormViewController.swift file
        // so it can receive the machine details. For example:
        //
        // var plantEquipmentNumber: String?
        // var machineId: String?
        //
        formVC.plantEquipmentNumber = plantEquipmentNumber
        formVC.machineId = machineId
        
        navigationController?.pushViewController(formVC, animated: true)
    }

    // MARK: - UI Helpers

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func showLoading(_ show: Bool) {
        DispatchQueue.main.async {
            if show {
                self.activityIndicator.startAnimating()
                // Disable interaction to prevent user from tapping anything else
                self.view.isUserInteractionEnabled = false
            } else {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    
    
    
    
    
    
    
    

    @objc func menuButtonTapped() {
        // Create the alert controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let myFolderAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuMyFolder"),
            style: .default
        ) { _ in
            self.openMyFolder()
        }
        
        let myCardsAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuMyCards"),
            style: .default
        ) { _ in
            self.openMyCards()
        }
        
        let mechanicReportsAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.mechanicReport"),
            style: .default
        ) { _ in
            self.openMechanicReports()
        }
        
        let ga1CertsAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.viewGa1Certs"),
            style: .default
        ) { _ in
            self.openGa1Certs()
        }
        
        let changeLanguageAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuChangeLanguage"),
            style: .default
        ) { _ in
            self.changeLanguage()
        }

        // Dynamically fetch translations
        let toggleLocationAction = UIAlertAction(
            title: isLocationEnabled()
                ? TranslationManager.shared.getTranslation(for: "operatorTab.menuDisableLocation")
                : TranslationManager.shared.getTranslation(for: "operatorTab.menuEnableLocation"),
            style: .default
        ) { _ in
            self.toggleLocation()
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
        alertController.addAction(myFolderAction)
        alertController.addAction(myCardsAction)
        alertController.addAction(mechanicReportsAction)
        alertController.addAction(ga1CertsAction)
        alertController.addAction(changeLanguageAction)
        alertController.addAction(toggleLocationAction)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)

        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
    
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
    
    
    
    
    private func openMyFolder() {
        let myFolderVC = MyFolderViewController()
        navigationController?.pushViewController(myFolderVC, animated: true)
    }
    
    private func openMyCards() {
        let myCardsVC = CardsListViewController()
        navigationController?.pushViewController(myCardsVC, animated: true)
    }
    
    private func openMechanicReports() {
        let mechanicReportsVC = MechanicReportsListViewController()
        navigationController?.pushViewController(mechanicReportsVC, animated: true)
    }
    
    
    private func openGa1Certs() {
        let ga1CertsVC = CertificatesViewController()
        navigationController?.pushViewController(ga1CertsVC, animated: true)
    }
    
    
    
    private func fetchUserFavourites(completion: @escaping ()->Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("OperatorVC: no user, skipping favourites load")
            completion()
            return
        }
        let favRef = Database.database()
            .reference()
            .child("users")
            .child(uid)
            .child("favourites")

        print("OperatorVC: loading favourites for \(uid)…")
        favRef.observeSingleEvent(of: .value) { snapshot in
            self.favouriteFormIds.removeAll()
            for case let child as DataSnapshot in snapshot.children {
                if self.forms.map({ $0.id }).contains(child.key) {
                    self.favouriteFormIds.insert(child.key)
                }
            }
            print("OperatorVC: fetched favourites = \(self.favouriteFormIds)")
            completion()
        }
    }
    
    
    private func reorderForms() {
        let favs  = forms.filter  { favouriteFormIds.contains($0.id) }
        let others = forms.filter { !favouriteFormIds.contains($0.id) }
        forms = favs + others

        let favEng  = englishForms.filter  { favouriteFormIds.contains($0.id) }
        let othEng  = englishForms.filter { !favouriteFormIds.contains($0.id) }
        englishForms = favEng + othEng

        print("OperatorVC: reordered forms, favourites first")
    }
    
    
    
    private func toggleFavourite(formId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let wasFav = favouriteFormIds.contains(formId)
        let favRef = Database.database()
            .reference()
            .child("users")
            .child(uid)
            .child("favourites")
            .child(formId)

        if wasFav {
            print("OperatorVC: removing \(formId) from favourites")
            favRef.removeValue { err, _ in
                if let e = err { print("…error removing: \(e.localizedDescription)") }
            }
            favouriteFormIds.remove(formId)
        } else {
            print("OperatorVC: adding \(formId) to favourites")
            favRef.setValue(true) { err, _ in
                if let e = err { print("…error adding: \(e.localizedDescription)") }
            }
            favouriteFormIds.insert(formId)
        }

        // reorder + refresh + scroll if new
        reorderForms()
        collectionView.reloadData()
        if !wasFav {
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(
                    at: IndexPath(item: 0, section: 0),
                    at: .top,
                    animated: true
                )
            }
        }
    }




    
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
//            self.collectionView.reloadData()
//            self.fetchAllIcons()
            self.fetchUserFavourites {
                self.reorderForms()
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                self.fetchAllIcons()
            }
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
        
    
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "FormCell", for: ip) as! FormCell
        let form = forms[ip.item]
        cell.form = form
        cell.isFavourite = favouriteFormIds.contains(form.id)

        // on heart tap
        cell.onFavouriteTap = { [weak self] in
            self?.toggleFavourite(formId: form.id)
        }

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

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return LanguageManager.shared.availableLanguages[row].name
    }


    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedLanguage = LanguageManager.shared.availableLanguages[row].code
        let selectedLanguageName = LanguageManager.shared.availableLanguages[row].name
        
        print("selectedLanguage: \(selectedLanguage)")
        print("selectedLanguageName: \(selectedLanguageName)")
        
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


// MARK: - QRCodeScannerDelegate

extension OperatorViewController: QRCodeScannerDelegate {
    
    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String) {
        // Dismiss the scanner first, then handle the code
        scanner.dismiss(animated: true) { [weak self] in
            self?.handleDetectedQrCode(qrCodeData: code)
        }
    }
    
    func qrCodeScannerDidCancel(_ scanner: QRCodeScannerViewController) {
        scanner.dismiss(animated: true, completion: nil)
    }
}
























//class OperatorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
//  
//    var forms: [Form] = []
//    var englishForms: [Form] = []
//    var collectionView: UICollectionView!
//    private let updateFarmButton = UIBarButtonItem()
//    var shouldRedownloadImages = false
//    private let storageRef = Storage.storage().reference()
//    private var favouriteFormIds = Set<String>()
//    
//    let pickerView = UIPickerView()
//    let toolbar = UIToolbar()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.backgroundColor = .white
//        
//        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")
//
////        Crashlytics.crashlytics().log("This is a test log message.")
////        fatalError("Test Crash")
//                
//        // Setup the navigation bar
//        setupNavigationBar()
//        
//        // Setup collection view
//        setupCollectionView()
//        
//        setupLanguagePicker()
//        checkForUpdate()
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(translationsLoaded), name: .translationsLoaded, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
//        
//        // Layout constraints
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//        
//        checkDownloadImagesFlag()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        // Ensure the navigation bar is visible
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//    }
//    
//    func checkForUpdate() {
//        guard let infoDictionary = Bundle.main.infoDictionary,
//                  let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String,
//                  let bundleId = Bundle.main.bundleIdentifier else {
//                print("checkForUpdate: Failed to retrieve version info.")
//                return
//            }
//        
//        // Determine country code from user's locale. Default to "us" if not available.
//        let countryCode = Locale.current.regionCode?.lowercased() ?? "ie"
//        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=\(countryCode)") else {
//            print("checkForUpdate: Failed to construct URL.")
//            return
//        }
//        
//        print("checkForUpdate: Current version = \(currentVersion), Bundle ID = \(bundleId)")
//        print("checkForUpdate: Query URL = \(url.absoluteString)")
//        
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("checkForUpdate: Error fetching update info: \(error.localizedDescription)")
//                return
//            }
//
//            guard let data = data,
//                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                  let results = json["results"] as? [[String: Any]],
//                  results.count > 0,
//                  let appStoreVersion = results[0]["version"] as? String else {
//                print("checkForUpdate: Unable to parse JSON or no results found.")
//                return
//            }
//            
//            print("checkForUpdate: App Store version = \(appStoreVersion)")
//            
//            if currentVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending {
//                print("checkForUpdate: New version available!")
//                DispatchQueue.main.async {
//                    self.showUpdateAlert(appStoreVersion: appStoreVersion)
//                }
//            } else {
//                print("checkForUpdate: The app is up-to-date.")
//            }
//        }.resume()
//    }
//
//    func showUpdateAlert(appStoreVersion: String) {
//        let title = "Update Available"
//        let message = "A new version (\(appStoreVersion)) is available on the App Store. Would you like to update now?"
//        print("showUpdateAlert: Preparing to show alert for version \(appStoreVersion)")
//        
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        
//        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
//            if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") {
//                print("showUpdateAlert: Opening URL: \(url.absoluteString)")
//                UIApplication.shared.open(url, options: [:], completionHandler: { success in
//                    print("showUpdateAlert: URL open completion success: \(success)")
//                })
//            } else {
//                print("showUpdateAlert: Failed to create update URL.")
//            }
//        }))
//        
//        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { _ in
//            print("showUpdateAlert: User chose not to update at this time.")
//        }))
//        
//        DispatchQueue.main.async {
//            self.present(alert, animated: true, completion: {
//                print("showUpdateAlert: Alert presented successfully.")
//            })
//        }
//    }
//
//    
//    @objc func translationsLoaded() {
//        print("Translations loaded, setting up UI.")
//        
//    }
//    
//    @objc func reloadTranslations() {
//        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")
//        self.fetchForms()
//    }
//    
//    private func setupLanguagePicker() {
//        // Picker View
//        pickerView.dataSource = self
//        pickerView.delegate = self
//        pickerView.backgroundColor = .white
//        pickerView.isHidden = true
//        pickerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(pickerView)
//
//        // Toolbar
//        toolbar.barStyle = .default
//        toolbar.isTranslucent = true
//        toolbar.tintColor = ColorScheme.amBlue
//        toolbar.sizeToFit()
//        toolbar.isHidden = true
//
//        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
//        toolbar.setItems([flexibleSpace, doneButton], animated: false)
//        toolbar.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(toolbar)
//        
//        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
//
//        // Layout
//        NSLayoutConstraint.activate([
//            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            toolbar.bottomAnchor.constraint(equalTo: pickerView.topAnchor),
//            toolbar.heightAnchor.constraint(equalToConstant: 44),
//
//            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBarHeight),
//            pickerView.heightAnchor.constraint(equalToConstant: 216)
//        ])
//    }
//    
//    @objc private func languageSelectorTapped() {
//        toolbar.isHidden = false
//        pickerView.isHidden = false
//    }
//
//    @objc private func doneButtonTapped() {
//        toolbar.isHidden = true
//        pickerView.isHidden = true
//    }
//    
//
//   
//    private func setupNavigationBar() {
//        if #available(iOS 13.0, *) {
//            let appearance = UINavigationBarAppearance()
//            appearance.configureWithOpaqueBackground()
//            appearance.backgroundColor = ColorScheme.amBlue
//            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
//            
//            navigationController?.navigationBar.standardAppearance = appearance
//            navigationController?.navigationBar.scrollEdgeAppearance = appearance
//            navigationController?.navigationBar.compactAppearance = appearance
//        } else {
//            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
//            navigationController?.navigationBar.isTranslucent = false
//            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
//        }
//
//        navigationController?.navigationBar.tintColor = .white
//        navigationController?.navigationBar.prefersLargeTitles = false
//                
//        // Custom view for extending height
//        let customView = UIView()
//        customView.backgroundColor = ColorScheme.amBlue
//        customView.translatesAutoresizingMaskIntoConstraints = false
//
//        navigationController?.navigationBar.addSubview(customView)
//        NSLayoutConstraint.activate([
//            customView.leadingAnchor.constraint(equalTo: navigationController!.navigationBar.leadingAnchor),
//            customView.trailingAnchor.constraint(equalTo: navigationController!.navigationBar.trailingAnchor),
//            customView.bottomAnchor.constraint(equalTo: navigationController!.navigationBar.bottomAnchor),
//            customView.heightAnchor.constraint(equalToConstant: 10)
//        ])
//        
//        // Set the right bar button item
//        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"), style: .plain, target: self, action: #selector(menuButtonTapped))
//        menuButton.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)], for: .normal)
//        navigationItem.rightBarButtonItem = menuButton
//    }
//    
//    
//    // Check Firebase for the 'downloadImages' flag and compare with UserDefaults
//    func checkDownloadImagesFlag() {
//        let ref = Database.database().reference().child("staticData/downloadImages")
//        let localDownloadImages = UserDefaults.standard.string(forKey: "downloadImages")
//        
//        ref.observeSingleEvent(of: .value) { snapshot in
//            if let firebaseDownloadImages = snapshot.value as? String {
//                if firebaseDownloadImages != localDownloadImages {
//                    // If the flag has changed, we should redownload the images
//                    self.shouldRedownloadImages = true
//                    // Store the new value in UserDefaults
//                    UserDefaults.standard.set(firebaseDownloadImages, forKey: "downloadImages")
//                }
//            }
//            // Proceed to fetch forms and icons
//            self.fetchForms()
//        } withCancel: { error in
//            print("Failed to retrieve downloadImages flag from Firebase: \(error.localizedDescription)")
//            // If fetching the flag fails, proceed with local logic
//            self.fetchForms()
//        }
//    }
//    
//
//
//    
//    func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: 180)
//        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        layout.minimumInteritemSpacing = 10
//        layout.minimumLineSpacing = 10
//        
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.register(FormCell.self, forCellWithReuseIdentifier: "FormCell")
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.alwaysBounceVertical = true
//        collectionView.backgroundColor = .white
//        view.addSubview(collectionView)
//    }
//    
//
//    @objc func menuButtonTapped() {
//        // Create the alert controller
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        
//        let myFolderAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuMyFolder"),
//            style: .default
//        ) { _ in
//            self.openMyFolder()
//        }
//        
//        let myCardsAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuMyCards"),
//            style: .default
//        ) { _ in
//            self.openMyCards()
//        }
//        
//        let mechanicReportsAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.mechanicReport"),
//            style: .default
//        ) { _ in
//            self.openMechanicReports()
//        }
//        
//        let ga1CertsAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.viewGa1Certs"),
//            style: .default
//        ) { _ in
//            self.openGa1Certs()
//        }
//        
//        let changeLanguageAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuChangeLanguage"),
//            style: .default
//        ) { _ in
//            self.changeLanguage()
//        }
//
//        // Dynamically fetch translations
//        let toggleLocationAction = UIAlertAction(
//            title: isLocationEnabled()
//                ? TranslationManager.shared.getTranslation(for: "operatorTab.menuDisableLocation")
//                : TranslationManager.shared.getTranslation(for: "operatorTab.menuEnableLocation"),
//            style: .default
//        ) { _ in
//            self.toggleLocation()
//        }
//        
//        
//        
//        let logoutAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "operatorTab.menuLogout"),
//            style: .destructive
//        ) { _ in
//            self.logoutUser()
//        }
//
//        let cancelAction = UIAlertAction(
//            title: TranslationManager.shared.getTranslation(for: "common.cancelButton"),
//            style: .cancel,
//            handler: nil
//        )
//
//        // Add actions to the alert
//        alertController.addAction(myFolderAction)
//        alertController.addAction(myCardsAction)
//        alertController.addAction(mechanicReportsAction)
//        alertController.addAction(ga1CertsAction)
//        alertController.addAction(changeLanguageAction)
//        alertController.addAction(toggleLocationAction)
//        alertController.addAction(logoutAction)
//        alertController.addAction(cancelAction)
//
//        // Present the alert
//        present(alertController, animated: true, completion: nil)
//    }
//    
//    
//    private func logoutUser() {
//        do {
//            try Auth.auth().signOut()
//
//            let loginViewController = LoginViewController()
//
//            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
//               let window = sceneDelegate.window {
//                window.rootViewController = loginViewController
//                window.makeKeyAndVisible()
//            } else {
//                print("Error: Unable to find SceneDelegate or UIWindow")
//            }
//        } catch {
//            print("Error signing out: \(error)")
//        }
//    }
//
//    private func toggleLocation() {
//        if isLocationEnabled() {
//            // Disable location
//            if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
//                UIApplication.shared.open(appSettingsURL)
//            }
//        } else {
//            // Request location permission
//            CLLocationManager().requestWhenInUseAuthorization()
//        }
//    }
//
//    private func isLocationEnabled() -> Bool {
//        return CLLocationManager.locationServicesEnabled()
//    }
//    
//    
//    private func changeLanguage() {
//        toolbar.isHidden = false
//        pickerView.isHidden = false
//    }
//    
//    
//    
//    
//    private func openMyFolder() {
//        let myFolderVC = MyFolderViewController()
//        navigationController?.pushViewController(myFolderVC, animated: true)
//    }
//    
//    private func openMyCards() {
//        let myCardsVC = CardsListViewController()
//        navigationController?.pushViewController(myCardsVC, animated: true)
//    }
//    
//    private func openMechanicReports() {
//        let mechanicReportsVC = MechanicReportsListViewController()
//        navigationController?.pushViewController(mechanicReportsVC, animated: true)
//    }
//    
//    
//    private func openGa1Certs() {
//        let ga1CertsVC = CertificatesViewController()
//        navigationController?.pushViewController(ga1CertsVC, animated: true)
//    }
//    
//    
//    
//    private func fetchUserFavourites(completion: @escaping ()->Void) {
//        guard let uid = Auth.auth().currentUser?.uid else {
//            print("OperatorVC: no user, skipping favourites load")
//            completion()
//            return
//        }
//        let favRef = Database.database()
//            .reference()
//            .child("users")
//            .child(uid)
//            .child("favourites")
//
//        print("OperatorVC: loading favourites for \(uid)…")
//        favRef.observeSingleEvent(of: .value) { snapshot in
//            self.favouriteFormIds.removeAll()
//            for case let child as DataSnapshot in snapshot.children {
//                if self.forms.map({ $0.id }).contains(child.key) {
//                    self.favouriteFormIds.insert(child.key)
//                }
//            }
//            print("OperatorVC: fetched favourites = \(self.favouriteFormIds)")
//            completion()
//        }
//    }
//    
//    
//    private func reorderForms() {
//        let favs  = forms.filter  { favouriteFormIds.contains($0.id) }
//        let others = forms.filter { !favouriteFormIds.contains($0.id) }
//        forms = favs + others
//
//        let favEng  = englishForms.filter  { favouriteFormIds.contains($0.id) }
//        let othEng  = englishForms.filter { !favouriteFormIds.contains($0.id) }
//        englishForms = favEng + othEng
//
//        print("OperatorVC: reordered forms, favourites first")
//    }
//    
//    
//    
//    private func toggleFavourite(formId: String) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let wasFav = favouriteFormIds.contains(formId)
//        let favRef = Database.database()
//            .reference()
//            .child("users")
//            .child(uid)
//            .child("favourites")
//            .child(formId)
//
//        if wasFav {
//            print("OperatorVC: removing \(formId) from favourites")
//            favRef.removeValue { err, _ in
//                if let e = err { print("…error removing: \(e.localizedDescription)") }
//            }
//            favouriteFormIds.remove(formId)
//        } else {
//            print("OperatorVC: adding \(formId) to favourites")
//            favRef.setValue(true) { err, _ in
//                if let e = err { print("…error adding: \(e.localizedDescription)") }
//            }
//            favouriteFormIds.insert(formId)
//        }
//
//        // reorder + refresh + scroll if new
//        reorderForms()
//        collectionView.reloadData()
//        if !wasFav {
//            DispatchQueue.main.async {
//                self.collectionView.scrollToItem(
//                    at: IndexPath(item: 0, section: 0),
//                    at: .top,
//                    animated: true
//                )
//            }
//        }
//    }
//
//
//
//
//    
//    func fetchForms() {
//        let ref = Database.database().reference().child("forms_new")
//        let selectedLanguage = TranslationManager.shared.getSelectedLanguage()
//        print("selectedLanguage = \(selectedLanguage)")
//
//        ref.observeSingleEvent(of: .value, with: { snapshot in
//            self.forms.removeAll()
//            self.englishForms.removeAll() // Clear the English forms array
//
//            for child in snapshot.children {
//                if let snapshot = child as? DataSnapshot,
//                   let dict = snapshot.value as? [String: Any] {
//                    
//                    print("dict: \(dict)")
//
//                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
//
//                    if let nameDict = dict["name"] as? [String: String],
//                       let formName = nameDict[selectedLanguage],
//                       let englishName = nameDict["en"], // Get English name
//                       let iconName = dict["iconName"] as? String,
//                       let questionsArray = dict["questions"] as? [[String: Any]] {
//
//                        var questions: [Question] = []
//                        var englishQuestions: [Question] = [] // Initialize englishQuestions here
//                        
//                        print("formName: \(formName)")
//
//                        for questionDict in questionsArray {
//                            if let id = questionDict["id"] as? String,
//                               let translations = questionDict["translations"] as? [String: String],
//                               let text = translations[selectedLanguage],
//                               let englishText = translations["en"], // Get English question text
//                               let typeString = questionDict["type"] as? String,
//                               let type = QuestionType(rawValue: typeString) {
//
//                                let question = Question(id: id, text: text, type: type)
//                                questions.append(question)
//
//                                // Create English question
//                                let englishQuestion = Question(id: id, text: englishText, type: type)
//
//                                // Add to English questions array
//                                englishQuestions.append(englishQuestion)
//                            }
//                        }
//
//                        let form = Form(id: snapshot.key, name: formName, iconName: iconName, questions: questions)
////                        print("form: \(form)")
//                        if isDisplayed {
//                            self.forms.append(form)
//                        }
//
//                        // Create English form
//                        let englishForm = Form(id: snapshot.key, name: englishName, iconName: iconName, questions: englishQuestions)
////                        print("englishForm: \(englishForm)")
//                        if isDisplayed {
//                            self.englishForms.append(englishForm)
//                        }
//                    }
//                }
//            }
////            self.collectionView.reloadData()
////            self.fetchAllIcons()
//            self.fetchUserFavourites {
//                self.reorderForms()
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//                self.fetchAllIcons()
//            }
//        })
//    }
//
//
//
//    // Fetch all icons for forms
//    func fetchAllIcons() {
//        for form in forms {
//            fetchIcon(iconName: form.iconName)
//        }
//    }
//
//
//    // Fetch individual icons, force redownload if required
//    func fetchIcon(iconName: String) {
//        let localFileURL = getDocumentsDirectory().appendingPathComponent(iconName)
//        
//        // Check if the icon exists and if we should redownload
//        if !FileManager.default.fileExists(atPath: localFileURL.path) || shouldRedownloadImages {
//            // Download the icon from Firebase Storage
//            let iconRef = storageRef.child("icons/\(iconName)")
//            iconRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
//                if let error = error {
//                    print("Failed to download icon: \(error.localizedDescription)")
//                    return
//                }
//                if let data = data {
//                    do {
//                        // Save the icon to local storage
//                        try data.write(to: localFileURL)
//                        print("Downloaded and saved icon: \(iconName)")
//                        
//                        // Reload the collection view to display the new icon
//                        DispatchQueue.main.async {
//                            self.collectionView.reloadData()
//                        }
//                        
//                    } catch {
//                        print("Failed to save icon: \(error.localizedDescription)")
//                    }
//                }
//            }
//        } else {
//            // Icon already exists locally and no need to redownload
//            print("Icon \(iconName) already exists in local storage")
//        }
//    }
//
//    // Helper method to get the documents directory
//    func getDocumentsDirectory() -> URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//
//
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return forms.count
//    }
//        
//    
//    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
//        let cell = cv.dequeueReusableCell(withReuseIdentifier: "FormCell", for: ip) as! FormCell
//        let form = forms[ip.item]
//        cell.form = form
//        cell.isFavourite = favouriteFormIds.contains(form.id)
//
//        // on heart tap
//        cell.onFavouriteTap = { [weak self] in
//            self?.toggleFavourite(formId: form.id)
//        }
//
//        let localFileURL = getDocumentsDirectory().appendingPathComponent(form.iconName)
//        
//        // Check if the icon exists locally, otherwise use the placeholder
//        if FileManager.default.fileExists(atPath: localFileURL.path) {
//            // Load the icon from local storage
//            if let imageData = try? Data(contentsOf: localFileURL) {
//                cell.iconImageView.image = UIImage(data: imageData)
//            }
//        } else {
//            // Use the placeholder image
//            cell.iconImageView.image = UIImage(named: "form_placeholder")
//        }
//
//        return cell
//    }
//
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let form = forms[indexPath.item]
//        let englishForm = englishForms[indexPath.item]
//        let formVC = FormViewController()
//        formVC.form = form
//        formVC.englishForm = englishForm
//        navigationController?.pushViewController(formVC, animated: true)
//    }
//}
//
//
//extension OperatorViewController: UIPickerViewDataSource, UIPickerViewDelegate {
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return LanguageManager.shared.availableLanguages.count
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return LanguageManager.shared.availableLanguages[row].name
//    }
//
//
//    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        let selectedLanguage = LanguageManager.shared.availableLanguages[row].code
//        let selectedLanguageName = LanguageManager.shared.availableLanguages[row].name
//        
//        print("selectedLanguage: \(selectedLanguage)")
//        print("selectedLanguageName: \(selectedLanguageName)")
//        
//        // Change the app's language asynchronously
//        TranslationManager.shared.changeLanguage(to: selectedLanguage) { success in
//            if success {
//                // Fetch the updated translation for "Done" after the language change is complete
//                let doneLabel = TranslationManager.shared.getTranslation(for: "common.done")
//                self.updateDoneButtonTitle(doneLabel)
//                
//                print("Updated Done label: \(doneLabel)")
//                
//                // Notify observers that the language has changed
//                NotificationCenter.default.post(name: .languageChanged, object: nil)
//            }
//        }
//    }
//
//    // Helper method to update the "Done" button's title
//    private func updateDoneButtonTitle(_ title: String) {
//        if let doneButton = toolbar.items?.last {
//            doneButton.title = title
//        }
//    }
//}
