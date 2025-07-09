//
//  MyFolderViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - FolderItem Model

struct FolderItem {
    let title: String
    let systemIconName: String? // Using SF Symbols
    let id: String
    let isHeader: Bool
    
    init(title: String, systemIconName: String? = nil, id: String = "", isHeader: Bool = false) {
        self.title = title
        self.systemIconName = systemIconName
        self.id = id
        self.isHeader = isHeader
    }
}

// MARK: - MyFolderViewController

class MyFolderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var folderItems = [FolderItem]()
    private let databaseRef = Database.database().reference()
    private let auth = Auth.auth()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MyFolderViewController loaded")
        
        setupUI()
        setupTableView()
        setupFolderItems()
        checkUserTypeAndUpdateOptions()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = TranslationManager.shared.getTranslation(for: "myFolder.title")
        
        // Set up custom back button to match other VCs
        setupCustomBackButton()
    }

    func setupCustomBackButton() {
        // Create a button with both image and text
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Back", for: .normal)
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        // Add some spacing between image and text
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        
        // Create a bar button item with the custom button
        let barButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = barButtonItem
    }

    @objc func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FolderItemCell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // Light gray background similar to Android
    }
    
    // MARK: - Data Setup
    
    private func setupFolderItems() {
        folderItems.removeAll()
        
        // Documents & Forms section
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.documentsAndForms"),
                isHeader: true
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.uploadNewGA1"),
                systemIconName: "arrow.up.doc.fill", // Upload document icon
                id: "upload_ga1"
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.viewAllGA1s"),
                systemIconName: "doc.text.fill", // Document icon
                id: "view_ga1s"
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.viewMyGA2Reports"),
                systemIconName: "doc.richtext.fill", // Document with content icon
                id: "view_ga2s"
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.viewMyTimesheets"),
                systemIconName: "calendar.badge.clock", // Calendar with clock icon
                id: "view_user_timesheets"
            )
        )
        
        // Expenses section
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.expenses"),
                isHeader: true
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.uploadNewExpense"),
                systemIconName: "plus.circle.fill", // Add icon
                id: "upload_expense"
            )
        )
        folderItems.append(
            FolderItem(
                title: TranslationManager.shared.getTranslation(for: "myFolder.viewMyExpenses"),
                systemIconName: "eurosign.circle.fill", // Euro icon
                id: "view_expenses"
            )
        )
        
        tableView.reloadData()
    }
    
    // MARK: - User Type Check
    
    private func checkUserTypeAndUpdateOptions() {
        guard let currentUser = auth.currentUser else {
            print("No user logged in")
            return
        }
        
        let uid = currentUser.uid
        let userRef = databaseRef.child("users/\(uid)/userType")
        
        userRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if let userType = snapshot.value as? String {
                if userType != "admin" && userType != "amAdmin" {
                    // Remove the "Upload new GA1" option for non-admin users
                    self.folderItems.removeAll { $0.id == "upload_ga1" }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        } withCancel: { error in
            print("Error getting user type: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderItemCell", for: indexPath)
        let item = folderItems[indexPath.row]
        
        // Configure cell based on whether it's a header or regular item
        if item.isHeader {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            cell.textLabel?.textColor = ColorScheme.amBlue
            cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // Light gray background
            cell.selectionStyle = .none
            cell.imageView?.image = nil
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.textLabel?.textColor = .black
            cell.backgroundColor = .white
            cell.selectionStyle = .default
            
            // Set the SF Symbol icon
            if let systemIconName = item.systemIconName {
                if #available(iOS 13.0, *) {
                    let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
                    cell.imageView?.image = UIImage(systemName: systemIconName, withConfiguration: configuration)
                    cell.imageView?.tintColor = ColorScheme.amOrange // Use your app's color scheme
                }
            }
            
            // Add disclosure indicator for non-header cells
            cell.accessoryType = .disclosureIndicator
            
            // Add some padding and styling
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            cell.selectedBackgroundView = backgroundView
        }
        
        cell.textLabel?.text = item.title
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = folderItems[indexPath.row]
        if !item.isHeader {
            handleItemSelection(item.id)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return folderItems[indexPath.row].isHeader ? 50 : 60
    }
    
    // MARK: - Navigation
    
    private func handleItemSelection(_ itemId: String) {
        switch itemId {
        case "upload_ga1":
//            print("upload_ga1 selected")
            let addExternalGa1FormVC = AddExternalGa1FormViewController()
            navigationController?.pushViewController(addExternalGa1FormVC, animated: true)
    
        case "view_ga1s":
//            print("view_ga1s selected")
            let externalGA1FormsListVC = ExternalGA1FormsListViewController()
            navigationController?.pushViewController(externalGA1FormsListVC, animated: true)
            
        case "view_ga2s":
            // print("view_ga2s selected")
           let ga2ListVC = GA2ListViewController()
           navigationController?.pushViewController(ga2ListVC, animated: true)
            
        case "view_user_timesheets":
//             print("view_user_timesheets selected")
           let timesheetListVC = TimesheetListViewController()
           navigationController?.pushViewController(timesheetListVC, animated: true)
    
        case "upload_expense":
//            print("upload_expense selected")
            let addExpenseVC = AddExpenseViewController()
            navigationController?.pushViewController(addExpenseVC, animated: true)
    
        case "view_expenses":
//            print("view_expenses selected")
            let expenseListVC = ExpenseListViewController()
            navigationController?.pushViewController(expenseListVC, animated: true)
    
        default:
            print("Unknown item ID: \(itemId)")
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
