//
//  MechanicReportsListViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/03/2025.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth


class MechanicReportCell: UITableViewCell {
    
    // Labels for first row
    let dateLabel = UILabel()
    let serialNoLabel = UILabel()
    
    // Labels for second row
    let makeLabel = UILabel()
    let modelLabel = UILabel()
    
    // StackViews to organise labels
    private let firstRowStack = UIStackView()
    private let secondRowStack = UIStackView()
    private let mainStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCellUI()
    }
    
    private func setupCellUI() {
        // Configure individual labels with their prefixes.
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = ColorScheme.amBlue
        serialNoLabel.font = UIFont.systemFont(ofSize: 14)
        serialNoLabel.textColor = ColorScheme.amBlue
        
        makeLabel.font = UIFont.systemFont(ofSize: 14)
        makeLabel.textColor = ColorScheme.amBlue
        modelLabel.font = UIFont.systemFont(ofSize: 14)
        modelLabel.textColor = ColorScheme.amBlue
        
        // Setup first row stack: left-aligned date, right-aligned serial no.
        firstRowStack.axis = .horizontal
        firstRowStack.distribution = .fillEqually
        firstRowStack.addArrangedSubview(dateLabel)
        firstRowStack.addArrangedSubview(serialNoLabel)
        
        // Setup second row stack: left-aligned make, right-aligned model.
        secondRowStack.axis = .horizontal
        secondRowStack.distribution = .fillEqually
        secondRowStack.addArrangedSubview(makeLabel)
        secondRowStack.addArrangedSubview(modelLabel)
        
        // Main stack view to hold the two rows.
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(firstRowStack)
        mainStack.addArrangedSubview(secondRowStack)
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    /// Configure the cell with a given report.
    func configure(with report: MechanicReport) {
        dateLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.date")): \(report.dateFormatted)"
        serialNoLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.serialNumber")): \(report.serialNo)"
        makeLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.make")): \(report.make)"
        modelLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.model")): \(report.model)"
    }
}





class MechanicReportsListViewController: UIViewController {
    
    let tableView = UITableView()
    let createReportButton = CustomButton(type: .system)
    
    var reports: [MechanicReport] = []
    
    let databaseRef = Database.database().reference()
    let auth = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = TranslationManager.shared.getTranslation(for: "mechanicReports.mechanicsReports")
        print("MechanicReportsListViewController loaded.")
        view.backgroundColor = .white

        setupUI()
        loadReports()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data from Firebase (or use a refresh method)
        loadReports()
    }
    
    
    func setupUI() {
        // Setup Create Report Button
        createReportButton.setTitle(TranslationManager.shared.getTranslation(for: "mechanicReports.createMechRep"), for: .normal)
        createReportButton.translatesAutoresizingMaskIntoConstraints = false
        createReportButton.addTarget(self, action: #selector(createReportTapped), for: .touchUpInside)
        view.addSubview(createReportButton)
        
        // Setup TableView
        tableView.register(MechanicReportCell.self, forCellReuseIdentifier: "MechanicReportCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()  // Removes extra empty rows
        view.addSubview(tableView)
        
        // Activate layout constraints
        NSLayoutConstraint.activate([
            // Button constraints (anchored at the bottom and centered horizontally)
            createReportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createReportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            createReportButton.heightAnchor.constraint(equalToConstant: 44),
            
            // TableView constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createReportButton.topAnchor, constant: -20)
        ])
    }

    
    
    
    func loadReports() {
        print("Loading mechanic reports.")
        guard let userId = auth.currentUser?.uid else { return }
        guard let userParent = UserSession.shared.userParent else { return }
        let reportsPath = "mechanicReports/\(userParent)/\(userId)"
        databaseRef.child(reportsPath).observeSingleEvent(of: .value) { snapshot in
            self.reports.removeAll()
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                if let dict = child.value as? [String: Any] {
                    // Convert dictionary to MechanicReport (manual mapping)
                    var report = MechanicReport()
                    report.reportId = child.key
                    report.make = dict["make"] as? String ?? ""
                    report.model = dict["model"] as? String ?? ""
                    report.serialNo = dict["serialNo"] as? String ?? ""
                    report.dateFormatted = dict["dateFormatted"] as? String ?? ""
                    report.dateTimestamp = dict["dateTimestamp"] as? TimeInterval ?? 0
                    self.reports.append(report)
                }
            }
            // Sort reports by most recent date first
            self.reports.sort { $0.reportId > $1.reportId }
            self.tableView.reloadData()
            print("Loaded \(self.reports.count) reports.")
        }
    }
    
    @objc func createReportTapped() {
        print("Create Mechanic Report tapped.")
        let reportVC = MechanicReportViewController()
        reportVC.isEditMode = false
        navigationController?.pushViewController(reportVC, animated: true)
    }
}

extension MechanicReportsListViewController: UITableViewDataSource, UITableViewDelegate {
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }
    

    
    // Configure custom cell layout
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MechanicReportCell", for: indexPath) as? MechanicReportCell else {
            return UITableViewCell()
        }
        let report = reports[indexPath.row]
        cell.configure(with: report)
        
        // Alternate background colours
        cell.contentView.backgroundColor = (indexPath.row % 2 == 0) ? UIColor.white : UIColor(white: 0.95, alpha: 1)
        
        return cell
    }
    
    // UITableViewDelegate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let report = reports[indexPath.row]
        print("Selected report with id: \(report.reportId)")
        let reportVC = MechanicReportViewController()
        reportVC.isEditMode = true
        reportVC.reportId = report.reportId
        navigationController?.pushViewController(reportVC, animated: true)
    }
}

