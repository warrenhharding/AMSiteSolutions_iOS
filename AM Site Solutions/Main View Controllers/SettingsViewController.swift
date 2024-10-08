//
//  SettingsViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import FirebaseDatabase


class SettingsViewController: UIViewController {
    
    let createNewUserButton = CustomButton(type: .system)
    let manageUsersButton = CustomButton(type: .system)
    let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        title = "Admin"
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        createNewUserButton.setTitle("Create New User", for: .normal)
        createNewUserButton.addTarget(self, action: #selector(createNewUserButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(createNewUserButton)
        
        manageUsersButton.setTitle("Manage Users", for: .normal)
        manageUsersButton.addTarget(self, action: #selector(manageUsersButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(manageUsersButton)

        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func createNewUserButtonTapped() {
        let createNewUserVC = CreateNewUserViewController()
        navigationController?.pushViewController(createNewUserVC, animated: true)
    }
    
    @objc private func manageUsersButtonTapped() {
//        let manageUsersVC = ManageUsersViewController()
//        manageUsersVC.modalPresentationStyle = .overCurrentContext
//        present(manageUsersVC, animated: true, completion: nil)
        let manageUsersVC = ManageUsersViewController()
        let navController = UINavigationController(rootViewController: manageUsersVC)
        present(navController, animated: true, completion: nil)
    }
}











//class SettingsViewController: UIViewController {
//    
//    let createNewUserButton = CustomButton(type: .system)
//    let stackView = UIStackView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .white
//        
//        stackView.axis = .vertical
//        stackView.alignment = .fill
//        stackView.spacing = 10
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        createNewUserButton.setTitle("Create New User", for: .normal)
//        createNewUserButton.addTarget(self, action: #selector(createNewUserButtonTapped), for: .touchUpInside)
//        stackView.addArrangedSubview(createNewUserButton)
//        
//        // Add more buttons as needed
//        
//        view.addSubview(stackView)
//        
//        NSLayoutConstraint.activate([
//            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//    
//    @objc private func createNewUserButtonTapped() {
//        let createNewUserVC = CreateNewUserViewController()
//        // Push onto the navigation stack
//        navigationController?.pushViewController(createNewUserVC, animated: true)
//    }
//
//}
//
//
