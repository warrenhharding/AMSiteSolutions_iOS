//
//  SubscriberCustomerManagementViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 2024-07-25.
//

import UIKit
import os.log

// MARK: - Menu Item Models

private struct MenuItem {
    let title: String
    let systemIconName: String
    let identifier: String
}

private struct MenuSection {
    let title: String
    let items: [MenuItem]
}

// MARK: - SubscriberCustomerManagementViewController

class SubscriberCustomerManagementViewController: UIViewController {

    // MARK: - Properties

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var menuSections = [MenuSection]()
    private let logger = Logger(subsystem: "com.amsitesolutions.app", category: "SubscriberCustomerManagement")

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("SubscriberCustomerManagementViewController loaded")
        
        setupUI()
        setupMenuItems()
        setupTableView()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "Manage My Customers"
        
        setupCustomBackButton()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        logger.info("Back button tapped")
        dismiss(animated: true, completion: nil)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuItemCell")
        tableView.backgroundColor = .clear
    }

    // MARK: - Data Setup

    private func setupMenuItems() {
        menuSections = [
            MenuSection(title: "Customer Management", items: [
//                MenuItem(title: "Add New Customer", systemIconName: "person.badge.plus", identifier: "add_customer"),
                MenuItem(title: "Manage Customers", systemIconName: "person.3.fill", identifier: "view_customers")
            ]),
            MenuSection(title: "Site Management", items: [
//                MenuItem(title: "Add New Site", systemIconName: "mappin.and.ellipse", identifier: "add_site"),
                MenuItem(title: "Manage Customer Sites", systemIconName: "map.fill", identifier: "view_sites")
            ])
        ]
        tableView.reloadData()
    }

    // MARK: - Navigation

    private func handleMenuSelection(with identifier: String) {
        logger.info("Handling menu selection for identifier: \(identifier)")
        switch identifier {
        case "add_customer", "view_customers":
            let customerVC = SubscriberCustomerCustViewController()
            // You might want to pass a parameter to distinguish between add and view/edit modes
            navigationController?.pushViewController(customerVC, animated: true)
            
        case "add_site", "view_sites":
            let siteVC = SubscriberCustomerSiteViewController()
            // You might want to pass a parameter here as well
            navigationController?.pushViewController(siteVC, animated: true)
            
        default:
            logger.warning("Unknown menu item identifier: \(identifier)")
        }
    }
}

// MARK: - UITableViewDataSource

extension SubscriberCustomerManagementViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menuSections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCell", for: indexPath)
        let item = menuSections[indexPath.section].items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.title
        
        if let image = UIImage(systemName: item.systemIconName) {
            content.image = image
            content.imageProperties.tintColor = UIColor(named: "amBlue")
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SubscriberCustomerManagementViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = menuSections[indexPath.section].items[indexPath.row]
        logger.info("User selected menu item: \(item.title)")
        handleMenuSelection(with: item.identifier)
    }
}
