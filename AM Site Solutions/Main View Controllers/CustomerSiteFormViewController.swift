//
//  CustomerSiteFormViewController.swift
//  AM Site Solutions
//
//  Created by [Your Name] on [Date]
//

import UIKit
import FirebaseDatabase
import os.log

class CustomerSiteFormViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Properties
    private var customerSite: CustomerSite?
    private var isEditMode: Bool = false
    private var databaseRef: DatabaseReference!
    private var customersRef: DatabaseReference!
    
    private var customers: [Customer] = []
    private var customerNames: [String] = []

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let customerNameTextField = CustomTextField()
    private let siteNameTextField = CustomTextField()
    private let contactNameTextField = CustomTextField()
    private let contactPhoneTextField = CustomTextField()
    private let contactEmailTextField = CustomTextField()
    private let roadNumberTextField = CustomTextField()
    private let areaTextField = CustomTextField()
    private let countyTextField = CustomTextField()
    private let eircodeTextField = CustomTextField()
    private let archivedSwitch = UISwitch()
    
    private let customerPicker = UIPickerView()

    private let saveButton = CustomButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CustomerSiteFormViewController")

    // MARK: - Initializers
    
    init(customerSite: CustomerSite? = nil) {
        self.customerSite = customerSite
        self.isEditMode = (customerSite != nil)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("viewDidLoad - isEditMode: \(self.isEditMode)")
        setupFirebase()
        setupUI()
        fetchCustomers()
        
        if isEditMode, let site = customerSite {
            populateFields(with: site)
            title = "Edit Customer Site"
        } else {
            title = "Create Customer Site"
        }
    }

    // MARK: - Setup Methods

    private func setupFirebase() {
        guard let userParent = UserSession.shared.userParent else {
            logger.error("User parent not found in UserSession.")
            showAlert(title: "Error", message: "Could not determine user account. Please sign in again.") {
                self.dismiss(animated: true)
            }
            return
        }
        databaseRef = Database.database().reference().child("subscriberCustomerSites/\(userParent)")
        customersRef = Database.database().reference().child("subscriberCustomers/\(userParent)")
        logger.info("Firebase reference set to: \(self.databaseRef.url)")
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // ScrollView and ContentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        // StackView configuration
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        setupFormFields()
        setupButtons()
        setupActivityIndicator()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    private func setupFormFields() {
        customerPicker.delegate = self
        customerPicker.dataSource = self
        
        stackView.addArrangedSubview(createLabel(text: "Customer Name *"))
        customerNameTextField.placeholder = "Select a customer"
        customerNameTextField.inputView = customerPicker
        customerNameTextField.accessibilityLabel = "Customer Name Picker"
        stackView.addArrangedSubview(customerNameTextField)

        stackView.addArrangedSubview(createLabel(text: "Site Name *"))
        siteNameTextField.placeholder = "Enter site name"
        siteNameTextField.autocapitalizationType = .words
        siteNameTextField.accessibilityLabel = "Site Name Input"
        stackView.addArrangedSubview(siteNameTextField)

        stackView.addArrangedSubview(createLabel(text: "Contact Name"))
        contactNameTextField.placeholder = "Enter contact name"
        contactNameTextField.autocapitalizationType = .words
        contactNameTextField.accessibilityLabel = "Contact Name Input"
        stackView.addArrangedSubview(contactNameTextField)
        
        stackView.addArrangedSubview(createLabel(text: "Contact Phone"))
        contactPhoneTextField.placeholder = "Enter contact phone"
        contactPhoneTextField.keyboardType = .phonePad
        contactPhoneTextField.accessibilityLabel = "Contact Phone Input"
        stackView.addArrangedSubview(contactPhoneTextField)

        stackView.addArrangedSubview(createLabel(text: "Contact Email"))
        contactEmailTextField.placeholder = "Enter contact email"
        contactEmailTextField.keyboardType = .emailAddress
        contactEmailTextField.autocapitalizationType = .none
        contactEmailTextField.accessibilityLabel = "Contact Email Input"
        stackView.addArrangedSubview(contactEmailTextField)

        stackView.addArrangedSubview(createLabel(text: "Address Line 1"))
        roadNumberTextField.placeholder = "e.g., 123 Main St"
        roadNumberTextField.autocapitalizationType = .words
        roadNumberTextField.accessibilityLabel = "Address Line 1 Input"
        stackView.addArrangedSubview(roadNumberTextField)

        stackView.addArrangedSubview(createLabel(text: "Area / Town"))
        areaTextField.placeholder = "e.g., Springfield"
        areaTextField.autocapitalizationType = .words
        areaTextField.accessibilityLabel = "Area or Town Input"
        stackView.addArrangedSubview(areaTextField)

        stackView.addArrangedSubview(createLabel(text: "County"))
        countyTextField.placeholder = "e.g., Co. Dublin"
        countyTextField.autocapitalizationType = .words
        countyTextField.accessibilityLabel = "County Input"
        stackView.addArrangedSubview(countyTextField)

        stackView.addArrangedSubview(createLabel(text: "Eircode"))
        eircodeTextField.placeholder = "e.g., A65 F4E2"
        eircodeTextField.autocapitalizationType = .allCharacters
        eircodeTextField.accessibilityLabel = "Eircode Input"
        stackView.addArrangedSubview(eircodeTextField)
        
        let archivedContainer = UIView()
        let archivedLabel = createLabel(text: "Archived")
        archivedSwitch.translatesAutoresizingMaskIntoConstraints = false
        archivedLabel.translatesAutoresizingMaskIntoConstraints = false
        archivedContainer.addSubview(archivedLabel)
        archivedContainer.addSubview(archivedSwitch)
        
        NSLayoutConstraint.activate([
            archivedLabel.leadingAnchor.constraint(equalTo: archivedContainer.leadingAnchor),
            archivedLabel.centerYAnchor.constraint(equalTo: archivedContainer.centerYAnchor),
            archivedSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: archivedLabel.trailingAnchor, constant: 8),
            archivedSwitch.trailingAnchor.constraint(equalTo: archivedContainer.trailingAnchor),
            archivedSwitch.centerYAnchor.constraint(equalTo: archivedContainer.centerYAnchor)
        ])
        
        stackView.addArrangedSubview(archivedContainer)
    }

    private func setupButtons() {
        saveButton.setTitle(isEditMode ? "Update Site" : "Save Site", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.accessibilityLabel = isEditMode ? "Update Customer Site Button" : "Save Customer Site Button"
        stackView.addArrangedSubview(saveButton)
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }
    
    private func populateFields(with site: CustomerSite) {
        customerNameTextField.text = site.customerName
        siteNameTextField.text = site.siteName
        contactNameTextField.text = site.contactName
        contactPhoneTextField.text = site.contactPhone
        contactEmailTextField.text = site.contactEmail
        roadNumberTextField.text = site.siteAddress.roadNumber
        areaTextField.text = site.siteAddress.area
        countyTextField.text = site.siteAddress.county
        eircodeTextField.text = site.siteAddress.eircode
        archivedSwitch.isOn = site.archived
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        logger.info("Cancel button tapped.")
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveTapped() {
        logger.info("Save button tapped.")
        guard validateForm() else { return }
        
        showLoading(true)
        
        let siteId = isEditMode ? customerSite!.id : databaseRef.childByAutoId().key!
        
        let address = Address(
            roadNumber: roadNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            area: areaTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            county: countyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            eircode: eircodeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
        
        let siteData = CustomerSite(
            id: siteId,
            customerName: customerNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            siteName: siteNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            contactName: contactNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            contactPhone: contactPhoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            contactEmail: contactEmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            siteAddress: address,
            archived: archivedSwitch.isOn
        )
        
        do {
            let data = try JSONEncoder().encode(siteData)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            
            databaseRef.child(siteId).setValue(dictionary) { [weak self] error, _ in
                guard let self = self else { return }
                self.showLoading(false)
                
                if let error = error {
                    self.logger.error("Firebase save error: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to save customer site. Please try again.")
                } else {
                    self.logger.info("Successfully saved customer site with ID: \(siteId)")
                    let successMessage = self.isEditMode ? "Site updated successfully!" : "Site created successfully!"
                    self.showAlert(title: "Success", message: successMessage) {
                        self.dismiss(animated: true)
                    }
                }
            }
        } catch {
            showLoading(false)
            logger.error("Failed to encode customer site data: \(error.localizedDescription)")
            showAlert(title: "Error", message: "An unexpected error occurred while preparing data.")
        }
    }

    // MARK: - Data Fetching
    
    private func fetchCustomers() {
        showLoading(true)
        customersRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.showLoading(false)
            
            guard snapshot.exists() else {
                self.logger.warning("No customers found in Firebase.")
                return
            }
            
            var fetchedCustomers: [Customer] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                        let customer = try JSONDecoder().decode(Customer.self, from: jsonData)
                        fetchedCustomers.append(customer)
                    } catch {
                        self.logger.error("Failed to decode customer: \(error.localizedDescription)")
                    }
                }
            }
            
            self.customers = fetchedCustomers.sorted { $0.companyName < $1.companyName }
            self.customerNames = self.customers.map { $0.companyName }
            self.customerPicker.reloadAllComponents()
            
            // If not in edit mode, select the first customer by default
            if !self.isEditMode && !self.customerNames.isEmpty {
                self.customerNameTextField.text = self.customerNames[0]
            }
        }
    }

    // MARK: - Validation
    
    private func validateForm() -> Bool {
        guard let customerName = customerNameTextField.text, !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Validation failed: Customer name is required.")
            showAlert(title: "Validation Error", message: "Customer Name is a required field.")
            return false
        }
        
        guard let siteName = siteNameTextField.text, !siteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Validation failed: Site name is required.")
            showAlert(title: "Validation Error", message: "Site Name is a required field.")
            return false
        }
        
        return true
    }

    // MARK: - Helper Methods
    
    private func showLoading(_ show: Bool) {
        DispatchQueue.main.async {
            if show {
                self.activityIndicator.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }


    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return customerNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return customerNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if !customerNames.isEmpty {
            customerNameTextField.text = customerNames[row]
        }
    }
}
