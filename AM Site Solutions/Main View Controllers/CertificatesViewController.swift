//
//  CertificatesViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 17/03/2025.
//

import UIKit
import FirebaseDatabase
import SafariServices

// MARK: - Certificate Model
struct Certificate {
    let plantEquipmentNumber: String
    let equipParticulars: String
    let dateOfExamination: TimeInterval
    let nextExaminationDate: TimeInterval
    let status: String
    let downloadUrl: String
    let paymentStatus: String

    init?(dictionary: [String: Any]) {
        guard let plantEquipmentNumber = dictionary["plantEquipmentNumber"] as? String,
              let equipParticulars = dictionary["equipParticulars"] as? String,
              let dateOfExamination = dictionary["dateOfExamination"] as? TimeInterval,
              let nextExaminationDate = dictionary["nextExaminationDate"] as? TimeInterval,
              let status = dictionary["status"] as? String,
              let downloadUrl = dictionary["downloadUrl"] as? String,
              let paymentStatus = dictionary["paymentStatus"] as? String else {
            print("Error parsing certificate dictionary: \(dictionary)")
            return nil
        }
        
        self.plantEquipmentNumber = plantEquipmentNumber
        self.equipParticulars = equipParticulars
        self.dateOfExamination = dateOfExamination
        self.nextExaminationDate = nextExaminationDate
        self.status = status
        self.downloadUrl = downloadUrl
        self.paymentStatus = paymentStatus
    }
}

// MARK: - CertificateTableViewCell
class CertificateTableViewCell: UITableViewCell {

    static let reuseIdentifier = "CertificateCell"

    // Row 1
    private let equipmentNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)  // Standard iOS bold font
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let examDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)  // Standard iOS font
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Row 2
    private let particularsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Row 3
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let expiryDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15) // Bold for expiry date
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Date formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_IE")
        return formatter
    }()

    // Initialiser
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Adding subviews
        contentView.addSubview(equipmentNumberLabel)
        contentView.addSubview(examDateLabel)
        contentView.addSubview(particularsLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(expiryDateLabel)

        // Layout constraints

        // Row 1: equipmentNumberLabel (left) and examDateLabel (right)
        NSLayoutConstraint.activate([
            equipmentNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            equipmentNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            equipmentNumberLabel.trailingAnchor.constraint(lessThanOrEqualTo: examDateLabel.leadingAnchor, constant: -8),

            examDateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            examDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            examDateLabel.widthAnchor.constraint(equalToConstant: 160)
        ])

        // Row 2: particularsLabel full width
        NSLayoutConstraint.activate([
            particularsLabel.topAnchor.constraint(equalTo: equipmentNumberLabel.bottomAnchor, constant: 4),
            particularsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            particularsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // Row 3: statusLabel (left) and expiryDateLabel (right)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: particularsLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: expiryDateLabel.leadingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            expiryDateLabel.topAnchor.constraint(equalTo: particularsLabel.bottomAnchor, constant: 4),
            expiryDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expiryDateLabel.widthAnchor.constraint(equalToConstant: 160),
            expiryDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with certificate: Certificate) {
        equipmentNumberLabel.text = certificate.plantEquipmentNumber

        let examDate = Date(timeIntervalSince1970: certificate.dateOfExamination / 1000)
        examDateLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.date")): \(CertificateTableViewCell.dateFormatter.string(from: examDate))"
        
        particularsLabel.text = certificate.equipParticulars
        
        statusLabel.text = "\(TranslationManager.shared.getTranslation(for: "ga1FormList.status")): \(certificate.status)"
        let expiryDate = Date(timeIntervalSince1970: certificate.nextExaminationDate / 1000)
        expiryDateLabel.text = "\(TranslationManager.shared.getTranslation(for: "ga1FormList.expiryDate")): \(CertificateTableViewCell.dateFormatter.string(from: expiryDate))"
    }
}

// MARK: - CertificatesViewController
class CertificatesViewController: UIViewController {

    // MARK: - UI Elements
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = TranslationManager.shared.getTranslation(for: "ga1FormList.searchHintText")
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(CertificateTableViewCell.self, forCellReuseIdentifier: CertificateTableViewCell.reuseIdentifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Data Properties
    private var certificates: [Certificate] = []
    private var filteredCertificates: [Certificate] = []
    
    // Replace with your actual user session value
    private var userParent: String?
    private var amssCustomerId: String?

    // Firebase Database reference
    private var databaseRef: DatabaseReference!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = TranslationManager.shared.getTranslation(for: "ga1FormList.title")
        view.backgroundColor = .white
        print("CertificatesViewController: viewDidLoad called.")

        setupViews()
        setupTableView()
        setupSearchField()
        
        guard let userParent = UserSession.shared.userParent else {
            // Handle the case where userParent is nil
            return
        }
        
        self.userParent = userParent

        // Start loading indicator and fetch data from Firebase
        activityIndicator.startAnimating()
        fetchAmssCustomerId()
    }

    // MARK: - Setup Views
    private func setupViews() {
        view.addSubview(searchTextField)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        // Auto Layout constraints
        NSLayoutConstraint.activate([
            // Search text field at the top (below the navigation bar)
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 40),

            // Table view below search field
            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            // Activity indicator centered
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupSearchField() {
        // Live search filtering as the user types.
        searchTextField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
    }

    // MARK: - Firebase Data Fetching
    private func fetchAmssCustomerId() {
        guard let userParent = UserSession.shared.userParent else { return }
        print("Fetching AMSS customer ID for userParent: \(userParent)")
        databaseRef = Database.database().reference().child("customerIdsSynced").child(userParent)
        
        databaseRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            if snapshot.exists(), let dict = snapshot.value as? [String: Any],
               let id = dict["amssCustomerId"] as? String {
                self.amssCustomerId = id
                print("Retrieved amssCustomerId: \(id)")
                self.fetchCertificates(for: id)
            } else {
                print("Error: No data exists for userParent: \(String(describing: self.userParent)) in customerIdsSynced or amssCustomerId is missing.")
                self.activityIndicator.stopAnimating()
            }
        } withCancel: { error in
            print("Error fetching amssCustomerId: \(error.localizedDescription)")
            self.activityIndicator.stopAnimating()
        }
    }

    private func fetchCertificates(for amssCustomerId: String) {
        print("Fetching certificates for amssCustomerId: \(amssCustomerId)")
        let certsRef = Database.database().reference().child("ga1Forms").child(amssCustomerId)
        
        certsRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.certificates.removeAll()
            
            if snapshot.exists() {
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let dict = childSnapshot.value as? [String: Any],
                       let certificate = Certificate(dictionary: dict) {
                        // Only include certificates where paymentStatus is "Paid"
                        if certificate.paymentStatus == "Paid" {
                            print("Certificate retrieved: \(certificate.plantEquipmentNumber), \(certificate.equipParticulars)")
                            self.certificates.append(certificate)
                        } else {
                            print("Skipping certificate \(certificate.plantEquipmentNumber) with paymentStatus: \(certificate.paymentStatus)")
                        }
                    } else {
                        print("Warning: Could not parse certificate data for child: \(child)")
                    }
                }
                
                // Sort certificates by expiry date (nextExaminationDate)
                self.certificates.sort { $0.nextExaminationDate < $1.nextExaminationDate }
                
                // Update filtered list and reload table view
                self.filteredCertificates = self.certificates
                self.tableView.reloadData()
                print("Certificate list updated. Total certificates: \(self.certificates.count)")
            } else {
                print("Error: No certificates found for amssCustomerId: \(amssCustomerId)")
            }
            
            self.activityIndicator.stopAnimating()
        } withCancel: { error in
            print("Error fetching certificates: \(error.localizedDescription)")
            self.activityIndicator.stopAnimating()
        }
    }

    // MARK: - Search Filtering
    @objc private func searchTextChanged(_ textField: UITextField) {
        guard let query = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            filteredCertificates = certificates
            tableView.reloadData()
            return
        }
        
        print("Search query changed: '\(query)'")
        if query.isEmpty {
            filteredCertificates = certificates
        } else {
            filteredCertificates = certificates.filter { certificate in
                // Partial match in either plantEquipmentNumber or equipParticulars
                return certificate.plantEquipmentNumber.lowercased().contains(query) ||
                       certificate.equipParticulars.lowercased().contains(query)
            }
        }
        print("Filtered list size: \(filteredCertificates.count) for query: '\(query)'")
        tableView.reloadData()
    }

    // MARK: - Certificate PDF Handling
    private func openCertificate(urlString: String) {
        let trimmedUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUrl.isEmpty {
            print("Download URL is blank. Cannot open certificate.")
            presentAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "ga1FormList.certNotAvailable"))
            return
        }
        
        guard let url = URL(string: trimmedUrl) else {
            print("Invalid URL: \(trimmedUrl)")
            presentAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "ga1FormList.certNotAvailable"))
            return
        }
        
        // Open the certificate using SFSafariViewController so that users can print/share easily.
        let safariVC = SFSafariViewController(url: url)
        print("Opening certificate URL: \(url.absoluteString)")
        present(safariVC, animated: true, completion: nil)
    }

    // MARK: - Alert Helper
    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.retry"), style: .default) { _ in
            // If retry is tapped, attempt to fetch certificates again.
            if let amssId = self.amssCustomerId {
                self.activityIndicator.startAnimating()
                self.fetchCertificates(for: amssId)
            }
        }
        let cancelAction = UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil)
        alertController.addAction(retryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CertificatesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCertificates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: CertificateTableViewCell.reuseIdentifier, for: indexPath) as? CertificateTableViewCell else {
            return UITableViewCell()
        }
        
        let certificate = filteredCertificates[indexPath.row]
        cell.configure(with: certificate)
        
        // Set alternating background colours
        cell.contentView.backgroundColor = (indexPath.row % 2 == 0) ? UIColor.white : UIColor(white: 0.95, alpha: 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let certificate = filteredCertificates[indexPath.row]
        print("Certificate tapped: \(certificate.plantEquipmentNumber)")
        openCertificate(urlString: certificate.downloadUrl)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

