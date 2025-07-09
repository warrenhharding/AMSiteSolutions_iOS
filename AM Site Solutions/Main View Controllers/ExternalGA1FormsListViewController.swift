//
//  ExternalGA1FormsListViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - ExternalGA1FormCell

class ExternalGA1FormCell: UITableViewCell {
    
    // UI Elements
    private let descriptionLabel = UILabel()
    private let equipmentParticularsLabel = UILabel()
    private let expiryDateLabel = UILabel()
    private let statusLabel = UILabel()
    
    // Stack views for layout
    private let mainStackView = UIStackView()
    private let bottomStackView = UIStackView()
    
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
        descriptionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // #333333
        descriptionLabel.numberOfLines = 1
        
        equipmentParticularsLabel.font = UIFont.systemFont(ofSize: 14)
        equipmentParticularsLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0) // #757575
        equipmentParticularsLabel.numberOfLines = 1
        
        expiryDateLabel.font = UIFont.systemFont(ofSize: 14)
        expiryDateLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0) // #757575
        
        statusLabel.font = UIFont.boldSystemFont(ofSize: 14)
        
        // Configure stack views
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .equalSpacing
        bottomStackView.alignment = .center
        bottomStackView.addArrangedSubview(expiryDateLabel)
        bottomStackView.addArrangedSubview(statusLabel)
        
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(descriptionLabel)
        mainStackView.addArrangedSubview(equipmentParticularsLabel)
        mainStackView.addArrangedSubview(bottomStackView)
        
        contentView.addSubview(mainStackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with form: ExternalGA1Form) {
        descriptionLabel.text = form.description
        equipmentParticularsLabel.text = form.equipmentParticulars
        
        // Format expiry date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let expiryDate = Date(timeIntervalSince1970: form.expiryDate / 1000)
        expiryDateLabel.text = "\(TranslationManager.shared.getTranslation(for: "externalGA1FormsList.expires")) \(dateFormatter.string(from: expiryDate))"
        
        // Calculate days until expiry
        let currentTimeMillis = Date().timeIntervalSince1970 * 1000
        let daysUntilExpiry = Int((form.expiryDate - currentTimeMillis) / (1000 * 60 * 60 * 24))
        
        // Set status text and color
        switch daysUntilExpiry {
        case ..<0:
            statusLabel.text = TranslationManager.shared.getTranslation(for: "externalGA1FormsList.expired")
            statusLabel.textColor = .red
        case 0..<30:
            statusLabel.text = TranslationManager.shared.getTranslation(for: "externalGA1FormsList.expiringSoon")
            statusLabel.textColor = UIColor.orange
        default:
            statusLabel.text = TranslationManager.shared.getTranslation(for: "externalGA1FormsList.valid")
            statusLabel.textColor = UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1.0) // #4CAF50 (green)
        }
    }
}

// MARK: - ExternalGA1FormsListViewController

class ExternalGA1FormsListViewController: UIViewController {
    
    // UI Elements
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let noFormsLabel = UILabel()
    
    // Data
    private var formsList: [ExternalGA1Form] = []
    
    // Firebase
    private let databaseRef = Database.database().reference()
    private let auth = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TranslationManager.shared.getTranslation(for: "externalGA1FormsList.title")
        view.backgroundColor = .white
        
        setupUI()
        setupTableView()
        loadForms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when returning to this screen
        loadForms()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
        view.addSubview(tableView)
        
        // Configure activityIndicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Configure noFormsLabel
        noFormsLabel.translatesAutoresizingMaskIntoConstraints = false
        noFormsLabel.textAlignment = .center
        noFormsLabel.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0) // #757575
        noFormsLabel.font = UIFont.systemFont(ofSize: 16)
        noFormsLabel.isHidden = true
        view.addSubview(noFormsLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            noFormsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noFormsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noFormsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noFormsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ExternalGA1FormCell.self, forCellReuseIdentifier: "ExternalGA1FormCell")
    }
    
    // MARK: - Data Loading
    
    private func loadForms() {
        showLoading(true)
        
        guard let currentUser = auth.currentUser else {
            showLoading(false)
            showNoForms(message: TranslationManager.shared.getTranslation(for: "externalGA1FormsList.userNotAuthenticated"))
            return
        }
        
        // Get user parent
        databaseRef.child("users").child(currentUser.uid).child("userParent").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            guard let parentUid = snapshot.value as? String else {
                self.showLoading(false)
                self.showNoForms(message: TranslationManager.shared.getTranslation(for: "externalGA1FormsList.parentUidNotFound"))
                return
            }
            
            self.fetchForms(parentUid: parentUid)
        } withCancel: { [weak self] error in
            self?.showLoading(false)
            self?.showNoForms(message: TranslationManager.shared.getTranslation(for: "externalGA1FormsList.failedToGetParentUid"))
            print("Error getting parent UID: \(error.localizedDescription)")
        }
    }
    
    private func fetchForms(parentUid: String) {
        let formsRef = databaseRef.child("externalGa1Forms").child(parentUid)
        
        formsRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            self.formsList.removeAll()
            
            for child in snapshot.children {
                guard let formSnapshot = child as? DataSnapshot,
                      let dataSnapshot = formSnapshot.childSnapshot(forPath: "data").value as? [String: Any] else {
                    continue
                }
                
                let form = ExternalGA1Form(
                    id: formSnapshot.key,
                    description: dataSnapshot["description"] as? String ?? "",
                    equipmentParticulars: dataSnapshot["equipmentParticulars"] as? String ?? "",
                    expiryDate: dataSnapshot["expiryDate"] as? TimeInterval ?? 0,
                    imageUrls: dataSnapshot["imageUrls"] as? [String] ?? [],
                    createdAt: dataSnapshot["createdAt"] as? TimeInterval ?? 0,
                    updatedAt: dataSnapshot["updatedAt"] as? TimeInterval ?? 0
                )
                
                self.formsList.append(form)
            }
            
            self.showLoading(false)
            
            if self.formsList.isEmpty {
                self.showNoForms(message: TranslationManager.shared.getTranslation(for: "externalGA1FormsList.noFormsFound"))
            } else {
                self.tableView.reloadData()
                self.tableView.isHidden = false
                self.noFormsLabel.isHidden = true
            }
        } withCancel: { [weak self] error in
            self?.showLoading(false)
            self?.showNoForms(message: TranslationManager.shared.getTranslation(for: "externalGA1FormsList.failedToLoadForms"))
            print("Error fetching forms: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            tableView.isHidden = true
            noFormsLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func showNoForms(message: String) {
        noFormsLabel.text = message
        noFormsLabel.isHidden = false
        tableView.isHidden = true
    }
    
    private func openFormInEditMode(form: ExternalGA1Form) {
        let editVC = AddExternalGa1FormViewController()
        editVC.configureForEdit(formId: form.id)
        navigationController?.pushViewController(editVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ExternalGA1FormsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExternalGA1FormCell", for: indexPath) as? ExternalGA1FormCell else {
            return UITableViewCell()
        }
        
        let form = formsList[indexPath.row]
        cell.configure(with: form)
        
        // Add card-like appearance
        cell.contentView.backgroundColor = .white
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 0.1
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.contentView.layer.shadowRadius = 2
        
        // Add some padding around the cell
        cell.contentView.layer.masksToBounds = false
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let form = formsList[indexPath.row]
        openFormInEditMode(form: form)
    }
}

