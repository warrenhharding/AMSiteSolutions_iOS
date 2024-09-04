//
//  OperatorVC.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase

class OperatorVC: UIViewController, UITabBarControllerDelegate {

    private let farmDetailsView = UIView()
    private let updateFarmButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Dashboard"
        
        setupNavigationBar()
        setupFarmDetailsView()
        loadFarmDetails()
        
        tabBarController?.delegate = self
    }

    private func setupNavigationBar() {
        updateFarmButton.title = "Update Farm"
        updateFarmButton.style = .plain
        updateFarmButton.target = self
        updateFarmButton.action = #selector(updateFarmTapped)
        navigationItem.rightBarButtonItem = updateFarmButton

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = ColorScheme.amBlue
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        }
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupFarmDetailsView() {
        // Card Design with subtle background color and padding
        farmDetailsView.layer.cornerRadius = 10
        farmDetailsView.layer.shadowColor = UIColor.black.cgColor
        farmDetailsView.layer.shadowOpacity = 0.1
        farmDetailsView.layer.shadowOffset = CGSize(width: 0, height: 2)
        farmDetailsView.layer.shadowRadius = 4
        farmDetailsView.backgroundColor = UIColor.systemGray6 // Subtle background color
        view.addSubview(farmDetailsView)
        
        // Add a tap gesture recognizer to make the card clickable
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(updateFarmTapped))
        farmDetailsView.addGestureRecognizer(tapGestureRecognizer)
        
        // Enable user interaction on the farmDetailsView
        farmDetailsView.isUserInteractionEnabled = true

        farmDetailsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            farmDetailsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            farmDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            farmDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            farmDetailsView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }

    private func loadFarmDetails() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let farmRef = Database.database().reference().child("customers").child(uid).child("farmData")
        
        farmRef.observeSingleEvent(of: .value) { snapshot in
            guard let farmData = snapshot.value as? [String: Any] else { return }
            
            let farmName = farmData["farmName"] as? String ?? "N/A"
            let totalAcres = farmData["totalAcres"] as? String ?? "N/A"
            let totalHectares = farmData["totalHectares"] as? String ?? "N/A"
            let herdNumber = farmData["herdNumber"] as? String ?? "N/A"
            let igasNumber = farmData["igasNumber"] as? String ?? "N/A"
            let puNumber = farmData["puNumber"] as? String ?? "N/A"
            let eircode = farmData["eircode"] as? String ?? "N/A"
            
            var coordinatesText = "Coordinates: Not Set"
            if let latitude = farmData["latitude"] as? Double, let longitude = farmData["longitude"] as? Double {
                coordinatesText = "Coordinates: \(latitude), \(longitude)"
            }
            
            self.displayFarmDetails(farmName: farmName, totalAcres: totalAcres, totalHectares: totalHectares, herdNumber: herdNumber, igasNumber: igasNumber, puNumber: puNumber, eircode: eircode, coordinates: coordinatesText)
        }
    }

    private func displayFarmDetails(farmName: String, totalAcres: String, totalHectares: String, herdNumber: String, igasNumber: String, puNumber: String, eircode: String, coordinates: String) {
        let farmNameLabel = UILabel()
        farmNameLabel.text = "Farm Name: \(farmName)"
        farmNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold) // Emphasize Farm Name

        let totalAcresLabel = UILabel()
        totalAcresLabel.text = "Total Acres: \(totalAcres)"
        totalAcresLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        let totalHectaresLabel = UILabel()
        totalHectaresLabel.text = "Total Hectares: \(totalHectares)"
        totalHectaresLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        let herdNumberLabel = UILabel()
        herdNumberLabel.text = "Herd Number: \(herdNumber)"
        herdNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let igasNumberLabel = UILabel()
        igasNumberLabel.text = "IGAS Number: \(igasNumber)"
        igasNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let puNumberLabel = UILabel()
        puNumberLabel.text = "PU Number: \(puNumber)"
        puNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let eircodeLabel = UILabel()
        eircodeLabel.text = "Eircode: \(eircode)"
        eircodeLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let coordinatesLabel = UILabel()
        coordinatesLabel.text = coordinates
        coordinatesLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let stackView = UIStackView(arrangedSubviews: [
            farmNameLabel,
            totalAcresLabel,
            totalHectaresLabel,
            herdNumberLabel,
            igasNumberLabel,
            puNumberLabel,
            eircodeLabel,
            coordinatesLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 12 // Increased spacing for better readability
        
        farmDetailsView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: farmDetailsView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: farmDetailsView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: farmDetailsView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: farmDetailsView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func updateFarmTapped() {
        print("Update farm tapped")
//        let farmOverviewVC = FarmOverviewViewController()
//        navigationController?.pushViewController(farmOverviewVC, animated: true)
    }
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is OperatorVC {
            if let navController = navigationController {
                navController.popToRootViewController(animated: true)
            }
        }
        return true
    }
}





//import UIKit
//import FirebaseAuth
//import FirebaseStorage
//import CoreLocation
//
//class OperatorVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
//    
//    var forms: [Form] = []
//    var collectionView: UICollectionView!
//    private let updateFarmButton = UIBarButtonItem()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = .white
//        print("I'm in the OperatorVC")
//        navigationController?.title = "Hello There"
//
//        // Set up navigation bar appearance
//        setupNavigationBar()
//
//        // Setup collection view
//        setupCollectionView()
//
//        // Layout constraints for the collection view
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),  // Corrected from bottomAnchor to topAnchor
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//    }
//
//    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        print("viewWillLayoutSubviews")
//        logNavigationBarDetails()
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        print("viewDidLayoutSubviews")
//        
//        // Manually adjust the navigation bar frame if necessary
//        if let navigationBar = self.navigationController?.navigationBar {
//            var frame = navigationBar.frame
//            frame.origin.y = 0
//            navigationBar.frame = frame
//            
//            // Ensure no unexpected insets are applied
//            navigationBar.layoutMargins = UIEdgeInsets.zero
//            navigationBar.insetsLayoutMarginsFromSafeArea = false
//        }
//        
//        logNavigationBarDetails()
//        logViewHierarchyConstraints()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        if let navigationBar = self.navigationController?.navigationBar {
//            navigationBar.layoutMargins = .zero
//            navigationBar.insetsLayoutMarginsFromSafeArea = false
//        }
//    }
//
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        print("viewDidAppear")
//        logNavigationBarDetails()
//    }
//    
//    func logNavigationBarDetails() {
//        if let navigationBar = self.navigationController?.navigationBar {
//            let frame = navigationBar.frame
//            print("Navigation Bar Frame: \(frame)")
//            print("Navigation Bar Height: \(frame.height)")
//            print("Navigation Bar Y Position: \(frame.origin.y)")
//        } else {
//            print("No Navigation Bar Found")
//        }
//    }
//    
//    func logViewHierarchyConstraints() {
//        if let navigationBar = self.navigationController?.navigationBar {
//            print("Logging constraints for navigation bar and its superviews")
//            var view: UIView? = navigationBar
//            while view != nil {
//                print("View: \(String(describing: view))")
//                for constraint in view!.constraints {
//                    print("Constraint: \(constraint)")
//                }
//                view = view?.superview
//            }
//        }
//    }
//    
//    override var prefersStatusBarHidden: Bool {
//        return false
//    }
//
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//    }
//    
////    private func setupNavigationBar() {
////        updateFarmButton.title = "Update Farm"
////        updateFarmButton.style = .plain
////        updateFarmButton.target = self
////        navigationItem.rightBarButtonItem = updateFarmButton
////
////        if #available(iOS 13.0, *) {
////            let appearance = UINavigationBarAppearance()
////            appearance.configureWithOpaqueBackground()
////            appearance.backgroundColor = ColorScheme.amBlue
////            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
////            navigationController?.navigationBar.standardAppearance = appearance
////            navigationController?.navigationBar.scrollEdgeAppearance = appearance
////        } else {
////            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
////            navigationController?.navigationBar.isTranslucent = false
////            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
////        }
////        
////        navigationController?.navigationBar.tintColor = .white
////        navigationController?.navigationBar.prefersLargeTitles = false
////    }
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
////        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(menuButtonTapped))
////        menuButton.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)], for: .normal)
////        navigationItem.rightBarButtonItem = menuButton
//    }
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
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return forms.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormCell", for: indexPath) as! FormCell
//        cell.form = forms[indexPath.item]
//        return cell
//    }
//
//}
//
