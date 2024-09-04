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
        
        fetchForms()
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
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(menuButtonTapped))
        menuButton.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)], for: .normal)
        navigationItem.rightBarButtonItem = menuButton
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

    
    func fetchForms() {
        let ref = Database.database().reference().child("forms")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    
                    // Retrieve 'isDisplayed' value, defaulting to true if not present
                    let isDisplayed = dict["isDisplayed"] as? Bool ?? true
//                    print("isDisplayed: \(isDisplayed)")
                    
                    // Extract the other values as before
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
        })
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return forms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormCell", for: indexPath) as! FormCell
        cell.form = forms[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let form = forms[indexPath.item]
        let formVC = FormViewController()
        formVC.form = form
        navigationController?.pushViewController(formVC, animated: true)
    }
}

