import UIKit
import FirebaseDatabase
import os.log

// MARK: - Report Table View Cell
private class ReportTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ReportCell"

    private let reportTitleLabel: UILabel = {
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

    private let siteNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let reportTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(reportTitleLabel)
        contentView.addSubview(customerNameLabel)
        contentView.addSubview(siteNameLabel)
        contentView.addSubview(reportTypeLabel)
        contentView.addSubview(dateLabel)
        
        accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            reportTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            reportTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reportTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            customerNameLabel.topAnchor.constraint(equalTo: reportTitleLabel.bottomAnchor, constant: 4),
            customerNameLabel.leadingAnchor.constraint(equalTo: reportTitleLabel.leadingAnchor),
            customerNameLabel.trailingAnchor.constraint(equalTo: reportTitleLabel.trailingAnchor),

            siteNameLabel.topAnchor.constraint(equalTo: customerNameLabel.bottomAnchor, constant: 4),
            siteNameLabel.leadingAnchor.constraint(equalTo: reportTitleLabel.leadingAnchor),
            siteNameLabel.trailingAnchor.constraint(equalTo: reportTitleLabel.trailingAnchor),

            reportTypeLabel.topAnchor.constraint(equalTo: siteNameLabel.bottomAnchor, constant: 4),
            reportTypeLabel.leadingAnchor.constraint(equalTo: reportTitleLabel.leadingAnchor),
            reportTypeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            dateLabel.topAnchor.constraint(equalTo: reportTypeLabel.topAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: reportTitleLabel.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: reportTypeLabel.bottomAnchor)
        ])
    }

    func configure(with report: SiteAuditReport) {
        reportTitleLabel.text = report.reportTitle
        customerNameLabel.text = report.clientName
        siteNameLabel.text = report.siteName
        reportTypeLabel.text = report.reportType
        
        let date = Date(timeIntervalSince1970: report.createdAt)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: date)
    }
}

// MARK: - Main View Controller
class SiteAuditReportListViewController: UIViewController {

    // MARK: - Properties
    private var allReports: [SiteAuditReport] = []
    private var filteredReports: [SiteAuditReport] = []
    private var databaseRef: DatabaseReference!
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SiteAuditReportListViewController")

    // MARK: - UI Elements
    
    private let searchBar = UISearchBar()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ReportTableViewCell.self, forCellReuseIdentifier: ReportTableViewCell.reuseIdentifier)
        return tableView
    }()

    private let createReportButton = CustomButton(type: .system)
    
    private let emptyView: UILabel = {
        let label = UILabel()
        label.text = "No reports found."
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
        fetchReports()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)

        title = "Site Reports"
        
        // Search Bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Reports"
        searchBar.delegate = self
        searchBar.backgroundColor = view.backgroundColor
        searchBar.backgroundImage = UIImage()

        // Create Button
        createReportButton.translatesAutoresizingMaskIntoConstraints = false
        createReportButton.setTitle("Create New Report", for: .normal)
        createReportButton.addTarget(self, action: #selector(createReportTapped), for: .touchUpInside)

        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        
        // Add subviews
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(createReportButton)
        view.addSubview(emptyView)

        // Layout Constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            createReportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createReportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createReportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createReportButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createReportButton.topAnchor, constant: -8),
            
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // Accessibility
        searchBar.accessibilityLabel = "Search Reports"
        createReportButton.accessibilityLabel = "Create New Report Button"
    }

    private func setupFirebase() {
        guard let userParent = UserSession.shared.userParent else {
            logger.error("User parent not found in UserSession.")
            showAlert(title: "Error", message: "Could not determine user account. Please sign in again.")
            return
        }
        databaseRef = Database.database().reference().child("siteAudits/\(userParent)")
        logger.info("Firebase reference set to: \(self.databaseRef.url)")
    }

    // MARK: - Data Handling
    private func fetchReports() {
        guard let databaseRef = databaseRef else {
            logger.error("Database reference is not configured.")
            return
        }
        
        databaseRef.observe(.value) { [weak self] (snapshot: DataSnapshot) in
            guard let self = self else { return }
            
            self.allReports.removeAll()
            
            // The data is nested: customerId -> siteId -> reportId -> reportData
            // We need to iterate through all levels to get to the report data.
            
            // Level 1: Customer IDs
            for customerSnapshot in snapshot.children {
                guard let customerSnap = customerSnapshot as? DataSnapshot else { continue }
                
                // Level 2: Site IDs
                for siteSnapshot in customerSnap.children {
                    guard let siteSnap = siteSnapshot as? DataSnapshot else { continue }
                    
                    // Level 3: Report IDs
                    for reportSnapshot in siteSnap.children {
                        guard let reportSnap = reportSnapshot as? DataSnapshot,
                              let value = reportSnap.value as? [String: Any] else {
                            self.logger.warning("Could not parse report snapshot value.")
                            continue
                        }
                        
                        // Log the raw dictionary before attempting to decode
                        self.logger.info("Attempting to decode report data: \(value)")

                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                            let report = try JSONDecoder().decode(SiteAuditReport.self, from: jsonData)
                            self.allReports.append(report)
                        } catch {
                            // Provide more detailed logging on failure
                            self.logger.error("Failed to decode report: \(error.localizedDescription)")
                            if let decodingError = error as? DecodingError {
                                self.logger.error("Decoding error details: \(decodingError)")
                            }
                        }
                    }
                }
            }
            
            self.logger.info("Fetched \(self.allReports.count) total reports.")
            
            DispatchQueue.main.async {
                self.applyFilters()
            }
        } withCancel: { [weak self] error in
            self?.logger.error("Database error: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load reports: \(error.localizedDescription)")
        }
    }

    private func applyFilters() {
        let searchText = searchBar.text?.lowercased() ?? ""
        
        filteredReports = allReports.filter { report in
            if searchText.isEmpty {
                return true
            } else {
                return (report.reportTitle.lowercased().contains(searchText) ||
                         report.clientName.lowercased().contains(searchText) ||
                         report.siteName.lowercased().contains(searchText))
            }
        }
        
        // Sort by creation date (newest first)
        filteredReports.sort { $0.createdAt > $1.createdAt }
        
        updateUIForDataState()
    }
    
    private func updateUIForDataState() {
        if filteredReports.isEmpty {
            emptyView.isHidden = false
            tableView.isHidden = true
            emptyView.text = allReports.isEmpty ? "No reports found." : "No reports match your search."
        } else {
            emptyView.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func createReportTapped() {
        logger.info("Create report tapped.")
        let createVC = CreateSiteAuditReportViewController()
        navigationController?.pushViewController(createVC, animated: true)
    }
    
    private func editReport(_ report: SiteAuditReport) {
        logger.info("Editing report with ID: \(report.reportId)")
        let createVC = CreateSiteAuditReportViewController()
        createVC.siteAuditReport = report
        navigationController?.pushViewController(createVC, animated: true)
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SiteAuditReportListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReports.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReportTableViewCell.reuseIdentifier, for: indexPath) as? ReportTableViewCell else {
            fatalError("Unable to dequeue ReportTableViewCell")
        }
        let report = filteredReports[indexPath.row]
        cell.configure(with: report)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let report = filteredReports[indexPath.row]
        editReport(report)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let report = filteredReports[indexPath.row]
            deleteReport(report)
        }
    }
    
    private func deleteReport(_ report: SiteAuditReport) {
        let alert = UIAlertController(title: "Delete Report", message: "Are you sure you want to delete this report?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete(report)
        })
        present(alert, animated: true)
    }
    
    private func performDelete(_ report: SiteAuditReport) {
        guard let userParent = UserSession.shared.userParent else {
            showAlert(title: "Error", message: "User not authenticated")
            return
        }
        
        // The databaseRef is already pointing to 'siteAudits/{userParent}', 
        // so we just need to append the rest of the path.
        let reportRef = databaseRef.child(report.clientId).child(report.siteId).child(report.reportId)
        reportRef.removeValue { [weak self] error, _ in
            if let error = error {
                self?.logger.error("Failed to delete report: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Failed to delete report: \(error.localizedDescription)")
            } else {
                self?.logger.info("Report deleted successfully")
                // The Firebase observer will automatically update the list
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension SiteAuditReportListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilters()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
