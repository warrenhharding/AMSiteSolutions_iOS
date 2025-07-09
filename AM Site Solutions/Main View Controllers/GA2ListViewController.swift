//
//  GA2ListViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFunctions
import PDFKit

// MARK: - GA2ReportCell

class GA2ReportCell: UITableViewCell {
    
    // UI Elements
    private let formNameLabel = UILabel()
    private let plantNoLabel = UILabel()
    private let dateLabel = UILabel()
    private let pdfIconImageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    
    // Stack views for layout
    private let mainStackView = UIStackView()
    private let contentStackView = UIStackView()
    
    // Callback for delete action
    var onDeleteTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Configure labels
        formNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        formNameLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        formNameLabel.numberOfLines = 1
        
        plantNoLabel.font = UIFont.systemFont(ofSize: 14)
        plantNoLabel.textColor = ColorScheme.amBlue
        plantNoLabel.numberOfLines = 1
        
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
        
        // Configure PDF icon
        pdfIconImageView.image = UIImage(systemName: "doc.fill")
        pdfIconImageView.tintColor = ColorScheme.amPink
        pdfIconImageView.contentMode = .scaleAspectFit
        pdfIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure delete button
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = UIColor.systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Configure stack views
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
        contentStackView.addArrangedSubview(formNameLabel)
        contentStackView.addArrangedSubview(plantNoLabel)
        contentStackView.addArrangedSubview(dateLabel)
        
        mainStackView.axis = .horizontal
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(pdfIconImageView)
        mainStackView.addArrangedSubview(contentStackView)
        mainStackView.addArrangedSubview(deleteButton)
        
        // Set content hugging and resistance priorities
        pdfIconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        deleteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        contentView.addSubview(mainStackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            pdfIconImageView.widthAnchor.constraint(equalToConstant: 48),
            pdfIconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 48),
            deleteButton.heightAnchor.constraint(equalToConstant: 48),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add card-like appearance
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 2
        contentView.layer.masksToBounds = false
        
        // Remove default selection style
        selectionStyle = .none
    }
    
    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
    
    func configure(with report: GA2Report) {
        formNameLabel.text = report.formName
        plantNoLabel.text = "Plant No: \(report.plantNo)"
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = Date(timeIntervalSince1970: report.createdAt / 1000)
        dateLabel.text = dateFormatter.string(from: date)
    }
}

// MARK: - GA2ListViewController

class GA2ListViewController: UIViewController {
    
    // UI Elements
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let noReportsLabel = UILabel()
    
    // Data
    private var allReports: [GA2Report] = []
    private var filteredReports: [GA2Report] = []
    
    // Firebase
    private let databaseRef = Database.database().reference()
    private let functions = Functions.functions()
    private let auth = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TranslationManager.shared.getTranslation(for: "ga2List.title")
        view.backgroundColor = .white
        
        setupUI()
        setupTableView()
        setupSearchBar()
        loadReports()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when returning to this screen
        loadReports()
    }


    deinit {
        // Remove all observers when the view controller is deallocated
        if let currentUser = auth.currentUser {
            let uid = currentUser.uid
            databaseRef.child("userGA2s").child(uid).removeAllObservers()
        }
    }

    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = TranslationManager.shared.getTranslation(for: "ga2List.searchHint")
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        // Configure tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
        view.addSubview(tableView)
        
        // Configure activityIndicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Configure noReportsLabel
        noReportsLabel.translatesAutoresizingMaskIntoConstraints = false
        noReportsLabel.textAlignment = .center
        noReportsLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0) // #757575
        noReportsLabel.font = UIFont.systemFont(ofSize: 16)
        noReportsLabel.text = TranslationManager.shared.getTranslation(for: "ga2List.noReports")
        noReportsLabel.isHidden = true
        view.addSubview(noReportsLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            noReportsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noReportsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noReportsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noReportsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GA2ReportCell.self, forCellReuseIdentifier: "GA2ReportCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    // MARK: - Data Loading
    
//private func loadReports() {
//    showLoading(true)
//    
//    guard let currentUser = auth.currentUser else {
//        showLoading(false)
//        showNoReports(message: TranslationManager.shared.getTranslation(for: "common.errorUserNotAuthenticated"))
//        return
//    }
//    
//    let uid = currentUser.uid
//    let reportsRef = databaseRef.child("userGA2s").child(uid)
//    
//    // Change from observeSingleEvent to observe to keep listening for changes
//    reportsRef.observe(.value) { [weak self] snapshot in
//        guard let self = self else { return }
//        
//        self.allReports.removeAll()
//        self.filteredReports.removeAll()
//        
//        for child in snapshot.children {
//            guard let reportSnapshot = child as? DataSnapshot,
//                  let reportData = reportSnapshot.value as? [String: Any] else {
//                continue
//            }
//            
//            let report = GA2Report(id: reportSnapshot.key, dictionary: reportData)
//            self.allReports.append(report)
//        }
//        
//        // Sort reports by date (newest first)
//        self.allReports.sort { $0.createdAt > $1.createdAt }
//        self.filteredReports = self.allReports
//        
//        self.showLoading(false)
//        
//        if self.allReports.isEmpty {
//            self.showNoReports(message: TranslationManager.shared.getTranslation(for: "ga2List.noReports"))
//        } else {
//            self.tableView.reloadData()
//            self.tableView.isHidden = false
//            self.noReportsLabel.isHidden = true
//        }
//    } withCancel: { [weak self] error in
//        self?.showLoading(false)
//        self?.showNoReports(message: TranslationManager.shared.getTranslation(for: "ga2List.failedToLoadReports"))
//        print("Error fetching GA2 reports: \(error.localizedDescription)")
//    }
//}


     private func loadReports() {
         showLoading(true)
        
         guard let currentUser = auth.currentUser else {
             showLoading(false)
             showNoReports(message: TranslationManager.shared.getTranslation(for: "common.errorUserNotAuthenticated"))
             return
         }
        
         let uid = currentUser.uid
         let reportsRef = databaseRef.child("userGA2s").child(uid)
        
         // Change from observeSingleEvent to observe to keep listening for changes
         reportsRef.observe(.value) { [weak self] snapshot in
             guard let self = self else { return }
            
             self.allReports.removeAll()
             self.filteredReports.removeAll()
            
             var validReportsCount = 0
             var skippedReportsCount = 0
            
             for child in snapshot.children {
                 guard let reportSnapshot = child as? DataSnapshot,
                     let reportData = reportSnapshot.value as? [String: Any] else {
                     continue
                 }
                
                 // Check if the record has an originalFBPath field
                 if reportData["originalFBPath"] != nil {
                     let report = GA2Report(id: reportSnapshot.key, dictionary: reportData)
                     self.allReports.append(report)
                     validReportsCount += 1
                     print("Added report with ID: \(reportSnapshot.key), has originalFBPath")
                 } else {
                     skippedReportsCount += 1
                     print("Skipped report with ID: \(reportSnapshot.key) - missing originalFBPath")
                 }
             }
            
             print("Reports processing complete - Valid: \(validReportsCount), Skipped: \(skippedReportsCount)")
            
             // Sort reports by date (newest first)
             self.allReports.sort { $0.createdAt > $1.createdAt }
             self.filteredReports = self.allReports
            
             self.showLoading(false)
            
             if self.allReports.isEmpty {
                 self.showNoReports(message: TranslationManager.shared.getTranslation(for: "ga2List.noReports"))
             } else {
                 self.tableView.reloadData()
                 self.tableView.isHidden = false
                 self.noReportsLabel.isHidden = true
             }
         } withCancel: { [weak self] error in
             self?.showLoading(false)
             self?.showNoReports(message: TranslationManager.shared.getTranslation(for: "ga2List.failedToLoadReports"))
             print("Error fetching GA2 reports: \(error.localizedDescription)")
         }
     }




    
    // MARK: - Helper Methods
    
    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            tableView.isHidden = true
            noReportsLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func showNoReports(message: String) {
        noReportsLabel.text = message
        noReportsLabel.isHidden = false
        tableView.isHidden = true
    }
    
    private func filterReports(with searchText: String) {
        if searchText.isEmpty {
            filteredReports = allReports
        } else {
            filteredReports = allReports.filter {
                $0.formName.lowercased().contains(searchText.lowercased()) ||
                $0.plantNo.lowercased().contains(searchText.lowercased())
            }
        }
        
        tableView.reloadData()
        
        if filteredReports.isEmpty {
            showNoReports(message: TranslationManager.shared.getTranslation(for: "ga2List.noMatchingReports"))
        } else {
            noReportsLabel.isHidden = true
            tableView.isHidden = false
        }
    }
    
    private func openReport(_ report: GA2Report) {
        showLoading(true)
        
        var originalPath = report.originalPath
        print("Opening report with path: \(originalPath)")

        // Check if the path is in the completedForms format
        if originalPath.starts(with: "completedForms/") {
            // Extract components from the path
            let pathComponents = originalPath.components(separatedBy: "/")
            
            // Check if we have enough components to extract the necessary information
            if pathComponents.count >= 5 {
                let userId = pathComponents[1]
                let formName = pathComponents[2]
                let timestamp = pathComponents[3]
                
                // Construct the new path in the pdfs format
                let newPath = "pdfs/\(userId)_\(formName)_\(timestamp)_\(userId).pdf"
                print("Converting path format from: \(originalPath) to: \(newPath)")
                originalPath = newPath
            } else {
                print("Warning: completedForms path doesn't have expected format: \(originalPath)")
            }
        } else if !originalPath.hasSuffix(".pdf") {
            // If the path doesn't end with .pdf, add it
            originalPath = originalPath + ".pdf"
            print("Adding .pdf extension to path: \(originalPath)")
        }
        
        print("Using final path: \(originalPath)")
        
        let data = ["originalPath": originalPath]
        
        functions.httpsCallable("getGA2ReportUrl").call(data) { [weak self] result, error in
            guard let self = self else { return }
            self.showLoading(false)
                        if let error = error {
                print("Error getting report URL: \(error.localizedDescription)")
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                    message: TranslationManager.shared.getTranslation(for: "ga2List.errorOpeningReport") + ": \(error.localizedDescription)"
                )
                return
            }
            
            guard let resultData = result?.data as? [String: Any],
                  let url = resultData["url"] as? String,
                  let pdfURL = URL(string: url) else {
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.error"),
                    message: TranslationManager.shared.getTranslation(for: "ga2List.errorOpeningReport")
                )
                return
            }
            
            print("Received URL from function: \(url)")
            
            // Create a title for the PDF using the form name and plant number
            let title = "GA2 \(report.formName) - \(report.plantNo)"
            
            // Present PDF viewer
            self.presentPDFViewer(with: pdfURL, title: title)
        }
    }


    



    
    private func presentPDFViewer(with url: URL, title: String) {
        // Create a PDF view controller
        let pdfViewController = UIViewController()
        pdfViewController.title = title
        
        // Create a PDF view
        let pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfViewController.view.addSubview(pdfView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: pdfViewController.view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: pdfViewController.view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: pdfViewController.view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: pdfViewController.view.bottomAnchor)
        ])
        
        // Add share button
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(sharePDF(_:))
        )
        pdfViewController.navigationItem.rightBarButtonItem = shareButton
        
        // Load PDF data
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(
                        title: TranslationManager.shared.getTranslation(for: "common.error"),
                        message: TranslationManager.shared.getTranslation(for: "ga2List.errorLoadingPdf") + ": \(error.localizedDescription)"
                    )
                    return
                }
                
                guard let data = data, let pdfDocument = PDFDocument(data: data) else {
                    self.showAlert(
                        title: TranslationManager.shared.getTranslation(for: "common.error"),
                        message: TranslationManager.shared.getTranslation(for: "ga2List.invalidPdfData")
                    )
                    return
                }
                
                // Store the PDF data for sharing
                pdfViewController.navigationItem.rightBarButtonItem?.tag = data.hashValue
                UserDefaults.standard.set(data, forKey: "pdfData_\(data.hashValue)")
                
                // Display the PDF
                pdfView.document = pdfDocument
            }
        }.resume()
        
        // Present the PDF viewer
        navigationController?.pushViewController(pdfViewController, animated: true)
    }
    
    @objc private func sharePDF(_ sender: UIBarButtonItem) {
        guard let pdfData = UserDefaults.standard.data(forKey: "pdfData_\(sender.tag)") else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        present(activityViewController, animated: true)
    }
    
    private func confirmDeleteReport(_ report: GA2Report) {
        let reportName = "\(report.formName) - \(report.plantNo)"
        
        // Get the translation string
        let translationFormat = TranslationManager.shared.getTranslation(for: "ga2List.deleteConfirmMessage")
        
        // Replace %s with %@ for Swift string formatting
        let swiftFormatString = translationFormat.replacingOccurrences(of: "%s", with: "%@")
        
        let alertController = UIAlertController(
            title: TranslationManager.shared.getTranslation(for: "ga2List.deleteConfirmTitle"),
            message: String(format: swiftFormatString, reportName),
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.delete"),
            style: .destructive
        ) { [weak self] _ in
            self?.deleteReport(report)
        }
        
        let cancelAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.cancel"),
            style: .cancel
        )
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }

    
    private func deleteReport(_ report: GA2Report) {
        showLoading(true)
        
        guard let currentUser = auth.currentUser else {
            showLoading(false)
            showAlert(
                title: TranslationManager.shared.getTranslation(for: "common.error"),
                message: TranslationManager.shared.getTranslation(for: "common.errorUserNotAuthenticated")
            )
            return
        }
        
        let uid = currentUser.uid
        let reportRef = databaseRef.child("userGA2s").child(uid).child(report.id)
        
        reportRef.removeValue { [weak self] error, _ in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                print("Error deleting GA2 report: \(error.localizedDescription)")
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.error"),
                    message: TranslationManager.shared.getTranslation(for: "ga2List.deleteError") + ": \(error.localizedDescription)"
                )
            } else {
                // Show success message
                self.showToast(message: TranslationManager.shared.getTranslation(for: "ga2List.deleteSuccess"))
                
                // No need to manually update the list as the ValueEventListener will trigger
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.ok"),
            style: .default
        )
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension GA2ListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GA2ReportCell", for: indexPath) as? GA2ReportCell else {
            return UITableViewCell()
        }
        
        let report = filteredReports[indexPath.row]
        cell.configure(with: report)
        
        cell.onDeleteTapped = { [weak self] in
            self?.confirmDeleteReport(report)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let report = filteredReports[indexPath.row]
        openReport(report)
    }
}

// MARK: - UISearchBarDelegate

extension GA2ListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterReports(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

