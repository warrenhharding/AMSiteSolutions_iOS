
import UIKit
import FirebaseDatabase
import os.log

// MARK: - Customer Table View Cell

private class CustomerTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CustomerCell"

    private let companyNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let contactNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let archivedIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "archivebox.fill")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(companyNameLabel)
        contentView.addSubview(contactNameLabel)
        contentView.addSubview(archivedIcon)
        
        accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            archivedIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            archivedIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            archivedIcon.widthAnchor.constraint(equalToConstant: 24),
            archivedIcon.heightAnchor.constraint(equalToConstant: 24),

            companyNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            companyNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            companyNameLabel.trailingAnchor.constraint(equalTo: archivedIcon.leadingAnchor, constant: -8),

            contactNameLabel.topAnchor.constraint(equalTo: companyNameLabel.bottomAnchor, constant: 4),
            contactNameLabel.leadingAnchor.constraint(equalTo: companyNameLabel.leadingAnchor),
            contactNameLabel.trailingAnchor.constraint(equalTo: companyNameLabel.trailingAnchor),
            contactNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with customer: Customer) {
        companyNameLabel.text = customer.companyName
        contactNameLabel.text = customer.contactName.isEmpty ? "No contact name" : customer.contactName
        archivedIcon.isHidden = !customer.archived
    }
}

// MARK: - Main View Controller

class SubscriberCustomerCustViewController: UIViewController {

    // MARK: - Properties
    private var allCustomers: [Customer] = []
    private var filteredCustomers: [Customer] = []
    private var databaseRef: DatabaseReference!
    private var includeArchived = false

    // Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubscriberCustomerCustViewController")

    // MARK: - UI Elements
    
    private let searchBar = UISearchBar()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CustomerTableViewCell.self, forCellReuseIdentifier: CustomerTableViewCell.reuseIdentifier)
        return tableView
    }()

    private let filterContainer = UIView()
    private let includeArchivedLabel: UILabel = {
        let label = UILabel()
        label.text = "Include Archived"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    private let archivedSwitch = UISwitch()
//    private let clearFiltersButton = CustomButton(type: .system)
    private let createCustomerButton = CustomButton(type: .system)
    
    private let emptyView: UILabel = {
        let label = UILabel()
        label.text = "No customers found."
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("viewDidLoad started")
        setupUI()
        setupFirebase()
        fetchCustomers()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)

        title = "Customer List"
        
        // Search Bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Customers"
        searchBar.delegate = self
        searchBar.backgroundColor = view.backgroundColor
        searchBar.backgroundImage = UIImage()

        // Filter Container
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        includeArchivedLabel.translatesAutoresizingMaskIntoConstraints = false
        archivedSwitch.translatesAutoresizingMaskIntoConstraints = false
//        clearFiltersButton.translatesAutoresizingMaskIntoConstraints = false
        
        archivedSwitch.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        
//        clearFiltersButton.setTitle("Clear", for: .normal)
//        clearFiltersButton.addTarget(self, action: #selector(clearFiltersTapped), for: .touchUpInside)

        filterContainer.addSubview(includeArchivedLabel)
        filterContainer.addSubview(archivedSwitch)
//        filterContainer.addSubview(clearFiltersButton)

        // Create Button
        createCustomerButton.translatesAutoresizingMaskIntoConstraints = false
        createCustomerButton.setTitle("Create New Customer", for: .normal)
        createCustomerButton.addTarget(self, action: #selector(createCustomerTapped), for: .touchUpInside)

        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        
        // Add subviews
        
        view.addSubview(searchBar)
        view.addSubview(filterContainer)
        view.addSubview(tableView)
        view.addSubview(createCustomerButton)
        view.addSubview(emptyView)

        // Layout Constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            filterContainer.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            filterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterContainer.heightAnchor.constraint(equalToConstant: 50),

            includeArchivedLabel.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor),
            includeArchivedLabel.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            
            archivedSwitch.leadingAnchor.constraint(equalTo: includeArchivedLabel.trailingAnchor, constant: 8),
            archivedSwitch.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            
//            clearFiltersButton.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor),
//            clearFiltersButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),

            createCustomerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createCustomerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createCustomerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createCustomerButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: filterContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createCustomerButton.topAnchor, constant: -8),
            
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // Accessibility
        
        searchBar.accessibilityLabel = "Search Customers"
        archivedSwitch.accessibilityLabel = "Include Archived Customers Switch"
//        clearFiltersButton.accessibilityLabel = "Clear Filters Button"
        createCustomerButton.accessibilityLabel = "Create New Customer Button"
    }

    private func setupFirebase() {
        guard let userParent = UserSession.shared.userParent else {
            logger.error("User parent not found in UserSession.")
            showAlert(title: "Error", message: "Could not determine user account. Please sign in again.")
            return
        }
        databaseRef = Database.database().reference().child("subscriberCustomers/\(userParent)")
        logger.info("Firebase reference set to: \(self.databaseRef.url)")
    }

    // MARK: - Data Handling
    private func fetchCustomers() {
        guard let databaseRef = databaseRef else {
            logger.error("Database reference is not configured.")
            return
        }
        
        databaseRef.observe(.value) { [weak self] (snapshot: DataSnapshot) in
            guard let self = self else { return }
            
            self.allCustomers.removeAll()
            
            for child in snapshot.children {
                 guard let childSnapshot = child as? DataSnapshot,
                      let value = childSnapshot.value as? [String: Any] else {
                    self.logger.error("Failed to parse customer snapshot value.")
                    continue
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                    var customer = try JSONDecoder().decode(Customer.self, from: jsonData)
                    customer.id = childSnapshot.key // Manually assign the ID from the snapshot key
                    self.allCustomers.append(customer)
                } catch {
                    self.logger.error("Failed to decode customer: \(error.localizedDescription)")
                }
            }
            
            self.logger.info("Fetched \(self.allCustomers.count) customers.")
            
            DispatchQueue.main.async {
                self.applyFilters()
            }
        } withCancel: { [weak self] error in
            self?.logger.error("Database error: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load customers: \(error.localizedDescription)")
        }
    }

    private func applyFilters() {
        let searchText = searchBar.text?.lowercased() ?? ""
        
        filteredCustomers = allCustomers.filter { customer in
            let matchesArchived = includeArchived || !customer.archived
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = (customer.companyName.lowercased().contains(searchText) ||
                                 customer.contactName.lowercased().contains(searchText))
            }
            
            return matchesArchived && matchesSearch
        }
        
        // Sort by company name
        filteredCustomers.sort { $0.companyName.lowercased() < $1.companyName.lowercased() }
        
        updateUIForDataState()
    }
    
    private func updateUIForDataState() {
        if filteredCustomers.isEmpty {
            emptyView.isHidden = false
            tableView.isHidden = true
            emptyView.text = allCustomers.isEmpty ? "No customers found." : "No customers match your filters."
        } else {
            emptyView.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func filterChanged() {
        self.includeArchived = archivedSwitch.isOn
        logger.info("Filter changed: includeArchived is now \(self.includeArchived)")
        applyFilters()
    }

    @objc private func createCustomerTapped() {
        logger.info("Create customer tapped.")
        let customerFormVC = CustomerFormViewController(customer: nil)
        navigationController?.pushViewController(customerFormVC, animated: true)
    }
    
    private func editCustomer(_ customer: Customer) {
        logger.info("Editing customer with ID: \(customer.id)")
        let customerFormVC = CustomerFormViewController(customer: customer)
        navigationController?.pushViewController(customerFormVC, animated: true)
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SubscriberCustomerCustViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCustomers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomerTableViewCell.reuseIdentifier, for: indexPath) as? CustomerTableViewCell else {
            fatalError("Unable to dequeue CustomerTableViewCell")
        }
        let customer = filteredCustomers[indexPath.row]
        cell.configure(with: customer)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let customer = filteredCustomers[indexPath.row]
        editCustomer(customer)
    }
}

// MARK: - UISearchBarDelegate
extension SubscriberCustomerCustViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilters()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
