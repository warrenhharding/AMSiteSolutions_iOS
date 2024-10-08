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
    var collectionView: UICollectionView!
    private let updateFarmButton = UIBarButtonItem()
    var shouldRedownloadImages = false
    private let storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
//        navigationController?.title = "Select Your Equipment"
//        title = "Select Your Equipment"
        navigationItem.title = "Select Your Equipment"
                
        // Setup the navigation bar
        setupNavigationBar()
        
        // Setup collection view
        setupCollectionView()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
//        fetchForms()
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
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let toggleLocationAction = UIAlertAction(title: isLocationEnabled() ? "Disable Location" : "Enable Location", style: .default) { _ in
            self.toggleLocation()
        }

        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.logoutUser()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(toggleLocationAction)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            let loginVC = LoginViewController()
            navigationController?.setViewControllers([loginVC], animated: true)
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

   
    
//    // Fetch forms from Firebase
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
//            self.fetchAllIcons()
//        })
//    }
    
    func fetchForms() {
        let ref = Database.database().reference().child("forms")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            self.forms.removeAll()
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    
                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
                    
                    if let name = dict["name"] as? String,
                       let iconName = dict["iconName"] as? String,
                       let questionsArray = dict["questions"] as? [[String: Any]] {
                        
                        var questions: [Question] = []
                        for questionDict in questionsArray {
                            if let id = questionDict["id"] as? String,
                               let text = questionDict["text"] as? String,
                               let typeString = questionDict["type"] as? String,
                               let type = QuestionType(rawValue: typeString) {
                                let question = Question(id: id, text: text, type: type)
                                questions.append(question)
                            }
                        }
                        
                        let form = Form(id: snapshot.key, name: name, iconName: iconName, questions: questions)
                        
                        if isDisplayed {
                            self.forms.append(form)
                        }
                    }
                }
            }
            self.collectionView.reloadData()
            self.fetchAllIcons() // Fetch icons after forms are loaded
        })
    }


    // Fetch all icons for forms
    func fetchAllIcons() {
        for form in forms {
            fetchIcon(iconName: form.iconName)
        }
    }

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
    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormCell", for: indexPath) as! FormCell
//        cell.form = forms[indexPath.item]
//        return cell
//    }
    
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
        let formVC = FormViewController()
        formVC.form = form
        navigationController?.pushViewController(formVC, animated: true)
    }
}

