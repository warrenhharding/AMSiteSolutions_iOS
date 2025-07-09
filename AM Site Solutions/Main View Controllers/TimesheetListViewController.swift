//
//  TimesheetListViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFunctions
import PDFKit

// MARK: - TimesheetCell

class TimesheetCell: UITableViewCell {
    
    // UI Elements
    private let dateRangeLabel = UILabel()
    private let createdDateLabel = UILabel()
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
        dateRangeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        dateRangeLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        dateRangeLabel.numberOfLines = 1
        
        createdDateLabel.font = UIFont.systemFont(ofSize: 14)
        createdDateLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
        
        // Configure PDF icon
        pdfIconImageView.image = UIImage(systemName: "doc.fill")
        pdfIconImageView.tintColor = ColorScheme.amOrange // Using orange for timesheets as in Android
        pdfIconImageView.contentMode = .scaleAspectFit
        pdfIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure delete button
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = UIColor.systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Configure stack views
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
        contentStackView.addArrangedSubview(dateRangeLabel)
        contentStackView.addArrangedSubview(createdDateLabel)
        
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
    
    func configure(with timesheet: Timesheet) {
        // Set date range
        dateRangeLabel.text = "\(timesheet.startDateString) - \(timesheet.endDateString)"
        
        // Format created date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = Date(timeIntervalSince1970: timesheet.createdAt / 1000)
        createdDateLabel.text = "Created: \(dateFormatter.string(from: date))"
    }
}

// MARK: - TimesheetListViewController

class TimesheetListViewController: UIViewController {
    
    // UI Elements
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let noTimesheetsLabel = UILabel()
    
    // Data
    private var allTimesheets: [Timesheet] = []
    private var filteredTimesheets: [Timesheet] = []
    
    // Firebase
    private let databaseRef = Database.database().reference()
    private let functions = Functions.functions()
    private let auth = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TranslationManager.shared.getTranslation(for: "timesheetList.title")
        view.backgroundColor = .white
        
        setupUI()
        setupTableView()
        setupSearchBar()
        loadTimesheets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when returning to this screen
        loadTimesheets()
    }
    
    deinit {
        // Remove all observers when the view controller is deallocated
        if let currentUser = auth.currentUser {
            let uid = currentUser.uid
            databaseRef.child("userTimesheets").child(uid).removeAllObservers()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = TranslationManager.shared.getTranslation(for: "timesheetList.searchHint")
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
        
        // Configure noTimesheetsLabel
        noTimesheetsLabel.translatesAutoresizingMaskIntoConstraints = false
        noTimesheetsLabel.textAlignment = .center
        noTimesheetsLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0) // #757575
        noTimesheetsLabel.font = UIFont.systemFont(ofSize: 16)
        noTimesheetsLabel.text = TranslationManager.shared.getTranslation(for: "timesheetList.noTimesheets")
        noTimesheetsLabel.isHidden = true
        view.addSubview(noTimesheetsLabel)
        
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
            
            noTimesheetsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noTimesheetsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noTimesheetsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noTimesheetsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TimesheetCell.self, forCellReuseIdentifier: "TimesheetCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    // MARK: - Data Loading
    
    private func loadTimesheets() {
        showLoading(true)
        
        guard let currentUser = auth.currentUser else {
            showLoading(false)
            showNoTimesheets(message: TranslationManager.shared.getTranslation(for: "common.errorUserNotAuthenticated"))
            return
        }
        
        let uid = currentUser.uid
        let timesheetsRef = databaseRef.child("userTimesheets").child(uid)
        
        // Use observe instead of observeSingleEvent to keep listening for changes
        timesheetsRef.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            self.allTimesheets.removeAll()
            self.filteredTimesheets.removeAll()
            
            for child in snapshot.children {
                guard let timesheetSnapshot = child as? DataSnapshot,
                      let timesheetData = timesheetSnapshot.value as? [String: Any] else {
                    continue
                }
                
                let timesheet = Timesheet(id: timesheetSnapshot.key, dictionary: timesheetData)
                self.allTimesheets.append(timesheet)
            }
            
            // Sort timesheets by date (newest first)
            self.allTimesheets.sort { $0.createdAt > $1.createdAt }
            self.filteredTimesheets = self.allTimesheets
            
            self.showLoading(false)
            
            if self.allTimesheets.isEmpty {
                self.showNoTimesheets(message: TranslationManager.shared.getTranslation(for: "timesheetList.noTimesheets"))
            } else {
                self.tableView.reloadData()
                self.tableView.isHidden = false
                self.noTimesheetsLabel.isHidden = true
            }
        } withCancel: { [weak self] error in
            self?.showLoading(false)
            self?.showNoTimesheets(message: TranslationManager.shared.getTranslation(for: "timesheetList.failedToLoadTimesheets"))
            print("Error fetching timesheets: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            tableView.isHidden = true
            noTimesheetsLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func showNoTimesheets(message: String) {
        noTimesheetsLabel.text = message
        noTimesheetsLabel.isHidden = false
        tableView.isHidden = true
    }
    
    private func filterTimesheets(with searchText: String) {
        if searchText.isEmpty {
            filteredTimesheets = allTimesheets
        } else {
            filteredTimesheets = allTimesheets.filter {
                let dateRange = "\($0.startDateString) - \($0.endDateString)"
                return dateRange.lowercased().contains(searchText.lowercased()) ||
                       $0.startDateString.lowercased().contains(searchText.lowercased()) ||
                       $0.endDateString.lowercased().contains(searchText.lowercased())
            }
        }
        
        tableView.reloadData()
        
        if filteredTimesheets.isEmpty {
            showNoTimesheets(message: TranslationManager.shared.getTranslation(for: "timesheetList.noMatchingTimesheets"))
        } else {
            noTimesheetsLabel.isHidden = true
            tableView.isHidden = false
        }
    }
    
    private func openTimesheet(_ timesheet: Timesheet) {
        showLoading(true)
        
        let originalPath = timesheet.originalPath
        print("Opening timesheet with path: \(originalPath)")
        
        let data = ["originalPath": originalPath]
        
        // Reusing the same cloud function as GA2 reports
        functions.httpsCallable("getGA2ReportUrl").call(data) { [weak self] result, error in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                print("Error getting timesheet URL: \(error.localizedDescription)")
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.error"),
                    message: TranslationManager.shared.getTranslation(for: "timesheetList.errorOpeningTimesheet") + ": \(error.localizedDescription)"
                )
                return
            }
            
            guard let resultData = result?.data as? [String: Any],
                  let url = resultData["url"] as? String,
                  let pdfURL = URL(string: url) else {
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.error"),
                    message: TranslationManager.shared.getTranslation(for: "timesheetList.errorOpeningTimesheet")
                )
                return
            }
            
            print("Received URL from function: \(url)")
            
            // Create a title for the PDF using the date range
            let title = "Timesheet \(timesheet.startDateString) - \(timesheet.endDateString)"
            
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
                        message: TranslationManager.shared.getTranslation(for: "timesheetList.errorLoadingPdf") + ": \(error.localizedDescription)"
                    )
                    return
                }
                
                guard let data = data, let pdfDocument = PDFDocument(data: data) else {
                    self.showAlert(
                        title: TranslationManager.shared.getTranslation(for: "common.error"),
                        message: TranslationManager.shared.getTranslation(for: "timesheetList.invalidPdfData")
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
    
    private func confirmDeleteTimesheet(_ timesheet: Timesheet) {
        let dateRange = "\(timesheet.startDateString) - \(timesheet.endDateString)"
        
        // Get the translation string
        let translationFormat = TranslationManager.shared.getTranslation(for: "timesheetList.deleteConfirmMessage")
        
        // Replace %s with %@ for Swift string formatting
        let swiftFormatString = translationFormat.replacingOccurrences(of: "%s", with: "%@")
        
        let alertController = UIAlertController(
            title: TranslationManager.shared.getTranslation(for: "timesheetList.deleteConfirmTitle"),
            message: String(format: swiftFormatString, dateRange),
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.delete"),
            style: .destructive
        ) { [weak self] _ in
            self?.deleteTimesheet(timesheet)
        }
        
        let cancelAction = UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.cancel"),
            style: .cancel
        )
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }

    
    private func deleteTimesheet(_ timesheet: Timesheet) {
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
        let timesheetRef = databaseRef.child("userTimesheets").child(uid).child(timesheet.id)
        
        timesheetRef.removeValue { [weak self] error, _ in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                print("Error deleting timesheet: \(error.localizedDescription)")
                self.showAlert(
                    title: TranslationManager.shared.getTranslation(for: "common.error"),
                    message: TranslationManager.shared.getTranslation(for: "timesheetList.deleteError") + ": \(error.localizedDescription)"
                )
            } else {
                // Show success message
                self.showToast(message: TranslationManager.shared.getTranslation(for: "timesheetList.deleteSuccess"))
                
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

extension TimesheetListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTimesheets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimesheetCell", for: indexPath) as? TimesheetCell else {
            return UITableViewCell()
        }
        
        let timesheet = filteredTimesheets[indexPath.row]
        cell.configure(with: timesheet)
        
        cell.onDeleteTapped = { [weak self] in
            self?.confirmDeleteTimesheet(timesheet)
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
        let timesheet = filteredTimesheets[indexPath.row]
        openTimesheet(timesheet)
    }
}

// MARK: - UISearchBarDelegate

extension TimesheetListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterTimesheets(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

