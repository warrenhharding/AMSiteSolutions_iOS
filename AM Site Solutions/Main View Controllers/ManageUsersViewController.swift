//
//  ManageUsersViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//

import UIKit
import Firebase

class ManageUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    var usersTableView: UITableView!
    var searchBar: UISearchBar!
    var previousPageButton: UIButton!
    var nextPageButton: UIButton!
    
    var usersList = [String]()
    var userUIDs = [String]()
    var currentPage = 0
    
    let userParent = UserSession.shared.userParent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupUI()
        fetchUsers()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
    }
    
    private func setupNavigationBar() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.rightBarButtonItem = closeButton
        navigationController?.navigationBar.tintColor = .white
        title = TranslationManager.shared.getTranslation(for: "manageUsersScreen.manageUsersScreenTitle")
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func reloadTranslations() {
        // Update the navigation bar title
        title = TranslationManager.shared.getTranslation(for: "manageUsersScreen.manageUsersScreenTitle")
        
        // Update the search bar placeholder
        searchBar.placeholder = TranslationManager.shared.getTranslation(for: "manageUsersScreen.usersSearchBarPlaceholder")
        
        // Update pagination button titles
        previousPageButton.setTitle(TranslationManager.shared.getTranslation(for: "manageUsersScreen.previousButton"), for: .normal)
        nextPageButton.setTitle(TranslationManager.shared.getTranslation(for: "manageUsersScreen.nextButton"), for: .normal)
        
        // Reload table view to reflect any dynamic content changes
        usersTableView.reloadData()
    }


    func setupUI() {
        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)  // Semi-transparent modal background
        
        // Search bar setup
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = TranslationManager.shared.getTranslation(for: "manageUsersScreen.usersSearchBarPlaceholder")
        view.addSubview(searchBar)
        
        // Table view setup
        usersTableView = UITableView()
        usersTableView.delegate = self
        usersTableView.dataSource = self
        view.addSubview(usersTableView)
        
        // Pagination buttons
        previousPageButton = CustomButton(type: .system)
        previousPageButton.setTitle(TranslationManager.shared.getTranslation(for: "manageUsersScreen.previousButton"), for: .normal)
        previousPageButton.addTarget(self, action: #selector(previousPageTapped), for: .touchUpInside)
        
        nextPageButton = CustomButton(type: .system)
        nextPageButton.setTitle(TranslationManager.shared.getTranslation(for: "manageUsersScreen.nextButton"), for: .normal)
        nextPageButton.addTarget(self, action: #selector(nextPageTapped), for: .touchUpInside)
        
        // Add pagination buttons to the view
        let buttonStackView = UIStackView(arrangedSubviews: [previousPageButton, nextPageButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.alignment = .center
        view.addSubview(buttonStackView)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        usersTableView.translatesAutoresizingMaskIntoConstraints = false
        previousPageButton.translatesAutoresizingMaskIntoConstraints = false
        nextPageButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the stack view layout instead of individual buttons
        let buttonStackView = UIStackView(arrangedSubviews: [previousPageButton, nextPageButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.alignment = .center
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            usersTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            usersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            usersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            usersTableView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -16),
            
            // Stack view for buttons
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor), // Center horizontally
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }



    
    // Fetch users and refresh table view
    func fetchUsers(query: String = "") {
        guard let userParent = userParent else {
            print("Error: userParent is nil")
            return
        }
        
        guard let thisUser = Auth.auth().currentUser?.uid else {
            print("Error: don't seem to be signed in - mad...")
            return
        }
        
        print("thisUser = \(thisUser)")
        
        let ref = Database.database().reference().child("customers/\(userParent)/users")
        ref.observeSingleEvent(of: .value) { snapshot in
            self.usersList.removeAll()
            self.userUIDs.removeAll()

            for userSnapshot in snapshot.children {
                if let userSnapshot = userSnapshot as? DataSnapshot,
                   let userName = userSnapshot.childSnapshot(forPath: "userName").value as? String {
                    
                    // Filter based on the query
                    if query.isEmpty || userName.lowercased().contains(query.lowercased()) {
                        self.usersList.append(userName)
                        self.userUIDs.append(userSnapshot.key)
                    }
                }
            }
            
            // Reload the table view with the filtered results
            self.usersTableView.reloadData()
        }
    }


    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") ?? UITableViewCell(style: .default, reuseIdentifier: "UserCell")
        cell.textLabel?.text = usersList[indexPath.row]
        return cell
    }

    // UITableViewDelegate method - Handle user selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUserUID = userUIDs[indexPath.row]
        // Present the alert first, and then dismiss the view controller once the action is completed
        showUserManagementOptions(userUID: selectedUserUID)
    }

    // UISearchBarDelegate method
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchUsers(query: searchText)
    }

    // Pagination actions
    @objc func previousPageTapped() {
        if currentPage > 0 {
            currentPage -= 1
            fetchUsers()
        }
    }

    @objc func nextPageTapped() {
        currentPage += 1
        fetchUsers()
    }
}



extension ManageUsersViewController {
    func showUserManagementOptions(userUID: String) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "manageUsersScreen.manageUser"), message: nil, preferredStyle: .actionSheet)
        
        // Option 1: Edit User
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "manageUsersScreen.editUserButton"), style: .default, handler: { _ in
            let editUserVC = CreateNewUserViewController()  // Reused for editing
            editUserVC.editingUserID = userUID
            editUserVC.isEditingUser = true
            let navController = UINavigationController(rootViewController: editUserVC)
            self.present(navController, animated: true, completion: nil)
        }))
        
        // Option 2: View User Cards
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "adminTab.viewUserCards"), style: .default, handler: { _ in
            let adminCardsVC = AdminUserCardsViewController()
            adminCardsVC.userId = userUID  // Pass the selected user's UID
            self.navigationController?.pushViewController(adminCardsVC, animated: true)
        }))
        
        // Option 3: Delete User
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "manageUsersScreen.deleteUserButton"), style: .destructive, handler: { _ in
            self.showDeleteConfirmation(userUID: userUID)
        }))
        
        // Option 4: Cancel
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel))
        
        present(alert, animated: true)
    }

    func showDeleteConfirmation(userUID: String) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "manageUsersScreen.deleteUserButton"), message: TranslationManager.shared.getTranslation(for: "manageUsersScreen.dialogDeleteUserMessage"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.yesButton"), style: .destructive, handler: { _ in
            self.deleteUser(userUID: userUID)
        }))
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.noButton"), style: .cancel))
        present(alert, animated: true)
    }

    func deleteUser(userUID: String) {
        let functions = Functions.functions()
        functions.httpsCallable("deleteUser").call(["userUID": userUID]) { result, error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
                return
            }
            print("User deleted successfully")
            self.fetchUsers()  // Refresh list
        }
    }
}

