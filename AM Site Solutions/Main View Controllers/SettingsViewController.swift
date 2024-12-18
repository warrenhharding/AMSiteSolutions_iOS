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
    
    @objc func reloadTranslations() {
        // Update the navigation bar title
        title = TranslationManager.shared.getTranslation(for: "adminTab.adminTabTitle")
        
        // Update button titles
        createNewUserButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.newUserButton"), for: .normal)
        manageUsersButton.setTitle(TranslationManager.shared.getTranslation(for: "adminTab.manageUsersButton"), for: .normal)
    }

}
