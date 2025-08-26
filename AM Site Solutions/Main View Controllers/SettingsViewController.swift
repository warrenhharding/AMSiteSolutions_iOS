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
    let manageMachineryButton = CustomButton(type: .system)
    let manageMyCustomersButton = CustomButton(type: .system)
    let manageMyLogoButton = CustomButton(type: .system)
    let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        title = TranslationManager.shared.getTranslation(for: "adminTab.adminTabTitle")
        
        stackView.axis = .vertical
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        createNewUserButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.newUserButton"), for: .normal)
        createNewUserButton.addTarget(self, action: #selector(createNewUserButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(createNewUserButton)
        
        manageUsersButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageUsersButton"), for: .normal)
        manageUsersButton.addTarget(self, action: #selector(manageUsersButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(manageUsersButton)
        
        manageMachineryButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageMachineryButton"), for: .normal)
        manageMachineryButton.addTarget(self, action: #selector(manageMachineryButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(manageMachineryButton)
        
        manageMyCustomersButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageMyCustomersButton"), for: .normal)
        manageMyCustomersButton.addTarget(self, action: #selector(manageMyCustomersButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(manageMyCustomersButton)
        
        manageMyLogoButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageMyLogoButton"), for: .normal)
        manageMyLogoButton.addTarget(self, action: #selector(manageMyLogoButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(manageMyLogoButton)


        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
    }
    
    @objc private func createNewUserButtonTapped() {
        let createNewUserVC = CreateNewUserViewController()
        navigationController?.pushViewController(createNewUserVC, animated: true)
    }
    
    @objc private func manageUsersButtonTapped() {
        let manageUsersVC = ManageUsersViewController()
        let navController = UINavigationController(rootViewController: manageUsersVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func manageMachineryButtonTapped() {
        let manageUsersVC = ManageMachineryViewController()
        let navController = UINavigationController(rootViewController: manageUsersVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func manageMyCustomersButtonTapped() {
        let manageCustomersVC = SubscriberCustomerManagementViewController()
        let navController = UINavigationController(rootViewController: manageCustomersVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func manageMyLogoButtonTapped() {
        let manageLogoVC = LogoManagementViewController()
        let navController = UINavigationController(rootViewController: manageLogoVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func reloadTranslations() {
        // Update the navigation bar title
        title = TranslationManager.shared.getTranslation(for: "adminTab.adminTabTitle")
        
        // Update button titles
        createNewUserButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.newUserButton"), for: .normal)
        manageUsersButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageUsersButton"), for: .normal)
    }

}
