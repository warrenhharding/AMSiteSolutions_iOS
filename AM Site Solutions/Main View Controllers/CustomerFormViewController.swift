
import UIKit
import FirebaseDatabase
import os.log

class CustomerFormViewController: UIViewController {

    // MARK: - Properties
    private var customer: Customer?
    private var isEditMode: Bool = false
    private var databaseRef: DatabaseReference!

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let companyNameTextField = CustomTextField()
    private let contactNameTextField = CustomTextField()
    private let emailTextField = CustomTextField()
    private let phoneTextField = CustomTextField()
    private let roadNumberTextField = CustomTextField()
    private let areaTextField = CustomTextField()
    private let countyTextField = CustomTextField()
    private let eircodeTextField = CustomTextField()
    private let archivedSwitch = UISwitch()
    
    private let saveButton = CustomButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CustomerFormViewController")

    // MARK: - Initializers
    
    init(customer: Customer? = nil) {
        self.customer = customer
        self.isEditMode = (customer != nil)
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
        
        if isEditMode, let customer = customer {
            populateFields(with: customer)
            title = "Edit Customer"
        } else {
            title = "Create Customer"
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
        databaseRef = Database.database().reference().child("subscriberCustomers/\(userParent)")
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
        stackView.addArrangedSubview(createLabel(text: "Company Name *"))
        companyNameTextField.placeholder = "Enter company name"
        companyNameTextField.autocapitalizationType = .words
        companyNameTextField.accessibilityLabel = "Company Name Input"
        stackView.addArrangedSubview(companyNameTextField)

        stackView.addArrangedSubview(createLabel(text: "Contact Name"))
        contactNameTextField.placeholder = "Enter contact name"
        contactNameTextField.autocapitalizationType = .words
        contactNameTextField.accessibilityLabel = "Contact Name Input"
        stackView.addArrangedSubview(contactNameTextField)

        stackView.addArrangedSubview(createLabel(text: "Email"))
        emailTextField.placeholder = "Enter email address"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.accessibilityLabel = "Email Input"
        stackView.addArrangedSubview(emailTextField)

        stackView.addArrangedSubview(createLabel(text: "Phone"))
        phoneTextField.placeholder = "Enter phone number"
        phoneTextField.keyboardType = .phonePad
        phoneTextField.accessibilityLabel = "Phone Input"
        stackView.addArrangedSubview(phoneTextField)

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
        saveButton.setTitle(isEditMode ? "Update Customer" : "Save Customer", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.accessibilityLabel = isEditMode ? "Update Customer Button" : "Save Customer Button"
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
    
    private func populateFields(with customer: Customer) {
        companyNameTextField.text = customer.companyName
        contactNameTextField.text = customer.contactName
        emailTextField.text = customer.email
        phoneTextField.text = customer.phone
        roadNumberTextField.text = customer.address.roadNumber
        areaTextField.text = customer.address.area
        countyTextField.text = customer.address.county
        eircodeTextField.text = customer.address.eircode
        archivedSwitch.isOn = customer.archived
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        logger.info("Cancel button tapped.")
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        logger.info("Save button tapped.")
        guard validateForm() else { return }
        
        showLoading(true)
        
        let customerId = isEditMode ? customer!.id : databaseRef.childByAutoId().key!
        
        let address = Address(
            roadNumber: roadNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            area: areaTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            county: countyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            eircode: eircodeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
        
        var customerData = Customer(
            id: customerId,
            companyName: companyNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            contactName: contactNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            email: emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            phone: phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            address: address,
            appUser: customer?.appUser ?? false, // Preserve original value
            archived: archivedSwitch.isOn,
            linkedCustomerId: customer?.linkedCustomerId, // Preserve original value
            linkedCustomerName: customer?.linkedCustomerName // Preserve original value
        )
        
        do {
            let data = try JSONEncoder().encode(customerData)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            
            databaseRef.child(customerId).setValue(dictionary) { [weak self] error, _ in
                guard let self = self else { return }
                self.showLoading(false)
                
                if let error = error {
                    self.logger.error("Firebase save error: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to save customer. Please try again.")
                } else {
                    self.logger.info("Successfully saved customer with ID: \(customerId)")
                    let successMessage = self.isEditMode ? "Customer updated successfully!" : "Customer created successfully!"
                    self.showAlert(title: "Success", message: successMessage) {
                        self.dismiss(animated: true)
                    }
                }
            }
        } catch {
            showLoading(false)
            logger.error("Failed to encode customer data: \(error.localizedDescription)")
            showAlert(title: "Error", message: "An unexpected error occurred while preparing data.")
        }
    }

    // MARK: - Validation
    
    private func validateForm() -> Bool {
        guard let companyName = companyNameTextField.text, !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Validation failed: Company name is required.")
            showAlert(title: "Validation Error", message: "Company Name is a required field.")
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
}
