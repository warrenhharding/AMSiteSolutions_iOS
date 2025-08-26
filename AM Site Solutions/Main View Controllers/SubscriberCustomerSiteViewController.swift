
import UIKit
import FirebaseDatabase
import os.log

// MARK: - Customer Site Table View Cell

private class CustomerSiteTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CustomerSiteCell"

//    private let customerNameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let siteNameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
    
    private let siteNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let customerNameLabel: UILabel = {
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
        contentView.addSubview(customerNameLabel)
        contentView.addSubview(siteNameLabel)
        contentView.addSubview(archivedIcon)
        
        accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            archivedIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            archivedIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            archivedIcon.widthAnchor.constraint(equalToConstant: 24),
            archivedIcon.heightAnchor.constraint(equalToConstant: 24),

            customerNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            customerNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            customerNameLabel.trailingAnchor.constraint(equalTo: archivedIcon.leadingAnchor, constant: -8),

            siteNameLabel.topAnchor.constraint(equalTo: customerNameLabel.bottomAnchor, constant: 4),
            siteNameLabel.leadingAnchor.constraint(equalTo: customerNameLabel.leadingAnchor),
            siteNameLabel.trailingAnchor.constraint(equalTo: customerNameLabel.trailingAnchor),
            siteNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with site: CustomerSite) {
        customerNameLabel.text = site.customerName
        siteNameLabel.text = site.siteName.isEmpty ? "No site name" : site.siteName
        archivedIcon.isHidden = !site.archived
    }
}

// MARK: - Main View Controller

class SubscriberCustomerSiteViewController: UIViewController {

    // MARK: - Properties
    private var allSites: [CustomerSite] = []
    private var filteredSites: [CustomerSite] = []
    private var databaseRef: DatabaseReference!
    private var includeArchived = false

    // Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubscriberCustomerSiteViewController")

    // MARK: - UI Elements
    private let searchBar = UISearchBar()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CustomerSiteTableViewCell.self, forCellReuseIdentifier: CustomerSiteTableViewCell.reuseIdentifier)
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
    private let createSiteButton = CustomButton(type: .system)
    
    private let emptyView: UILabel = {
        let label = UILabel()
        label.text = "No customer sites found."
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
        fetchCustomerSites()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        
        title = "Customer Site List"

        // Search Bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Sites"
        searchBar.delegate = self
        searchBar.backgroundColor = view.backgroundColor
        searchBar.backgroundImage = UIImage()

        // Filter Container
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        includeArchivedLabel.translatesAutoresizingMaskIntoConstraints = false
        archivedSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        archivedSwitch.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        
        filterContainer.addSubview(includeArchivedLabel)
        filterContainer.addSubview(archivedSwitch)

        // Create Button
        createSiteButton.translatesAutoresizingMaskIntoConstraints = false
        createSiteButton.setTitle("Create New Site", for: .normal)
        createSiteButton.addTarget(self, action: #selector(createSiteTapped), for: .touchUpInside)

        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        
        // Add subviews
        view.addSubview(searchBar)
        view.addSubview(filterContainer)
        view.addSubview(tableView)
        view.addSubview(createSiteButton)
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
            
            createSiteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createSiteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createSiteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createSiteButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: filterContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createSiteButton.topAnchor, constant: -8),
            
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // Accessibility
        searchBar.accessibilityLabel = "Search Customer Sites"
        archivedSwitch.accessibilityLabel = "Include Archived Sites Switch"
        createSiteButton.accessibilityLabel = "Create New Customer Site Button"
    }

    private func setupFirebase() {
        guard let userParent = UserSession.shared.userParent else {
            logger.error("User parent not found in UserSession.")
            showAlert(title: "Error", message: "Could not determine user account. Please sign in again.")
            return
        }
        databaseRef = Database.database().reference().child("subscriberCustomerSites/\(userParent)")
        logger.info("Firebase reference set to: \(self.databaseRef.url)")
    }

    // MARK: - Data Handling
    private func fetchCustomerSites() {
        guard let databaseRef = databaseRef else {
            logger.error("Database reference is not configured.")
            return
        }
        
        databaseRef.observe(.value) { [weak self] (snapshot: DataSnapshot) in
            guard let self = self else { return }
            
            self.allSites.removeAll()
            
            for child in snapshot.children {
                 guard let childSnapshot = child as? DataSnapshot,
                      let value = childSnapshot.value as? [String: Any] else {
                    self.logger.error("Failed to parse customer site snapshot value.")
                    continue
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                    var site = try JSONDecoder().decode(CustomerSite.self, from: jsonData)
                    site.id = childSnapshot.key
                    self.allSites.append(site)
                } catch {
                    self.logger.error("Failed to decode customer site: \(error.localizedDescription)")
                }
            }
            
            self.logger.info("Fetched \(self.allSites.count) customer sites.")
            
            DispatchQueue.main.async {
                self.applyFilters()
            }
        } withCancel: { [weak self] error in
            self?.logger.error("Database error: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load customer sites: \(error.localizedDescription)")
        }
    }

    private func applyFilters() {
        let searchText = searchBar.text?.lowercased() ?? ""
        
        filteredSites = allSites.filter { site in
            let matchesArchived = includeArchived || !site.archived
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = (site.customerName.lowercased().contains(searchText) ||
                                 site.siteName.lowercased().contains(searchText))
            }
            
            return matchesArchived && matchesSearch
        }
        
        // Sort by customer name, then site name
        filteredSites.sort {
            if $0.customerName.lowercased() != $1.customerName.lowercased() {
                return $0.customerName.lowercased() < $1.customerName.lowercased()
            }
            return $0.siteName.lowercased() < $1.siteName.lowercased()
        }
        
        updateUIForDataState()
    }
    
    private func updateUIForDataState() {
        if filteredSites.isEmpty {
            emptyView.isHidden = false
            tableView.isHidden = true
            emptyView.text = allSites.isEmpty ? "No customer sites found." : "No sites match your filters."
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

    @objc private func createSiteTapped() {
        logger.info("Create customer site tapped.")
        let formVC = CustomerSiteFormViewController(customerSite: nil)
        navigationController?.pushViewController(formVC, animated: true)
    }
    
    private func editSite(_ site: CustomerSite) {
        logger.info("Editing customer site with ID: \(site.id)")
        let formVC = CustomerSiteFormViewController(customerSite: site)
        navigationController?.pushViewController(formVC, animated: true)
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SubscriberCustomerSiteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomerSiteTableViewCell.reuseIdentifier, for: indexPath) as? CustomerSiteTableViewCell else {
            fatalError("Unable to dequeue CustomerSiteTableViewCell")
        }
        let site = filteredSites[indexPath.row]
        cell.configure(with: site)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let site = filteredSites[indexPath.row]
        editSite(site)
    }
}

// MARK: - UISearchBarDelegate
extension SubscriberCustomerSiteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilters()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
