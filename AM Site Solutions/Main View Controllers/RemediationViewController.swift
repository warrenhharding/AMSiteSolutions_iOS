//
//  RemediationViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/03/2025.
//



import UIKit

class RemediationViewController: UIViewController {
    
    weak var remediationDelegate: RemediationDelegate?
    var remediationToEdit: Remediation?
    
    // UI Elements
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    let dateTextField = UITextField()
    let itemNameTextField = UITextField()
    // We'll use a segmented control instead of a switch for Replace/Repaired.
    var replaceRepairedSegmentedControl: UISegmentedControl!
    // Use the declared jobCompletedSwitch property.
    let jobCompletedSwitch = UISwitch()
    let jobDescriptionTextView = UITextView()
    let saveButton = CustomButton(type: .system)
    let cancelButton = CustomButton(type: .system)
    
    // Labels for each field
    let dateLabel = UILabel()
    let itemNameLabel = UILabel()
    let replaceRepairedLabel = UILabel()
    let jobCompletedLabel = UILabel()
    let descriptionLabel = UILabel()
    
    let datePicker = UIDatePicker()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RemediationViewController loaded.")
        view.backgroundColor = .white
        setupUI()
        setupDatePicker()
        setupTapToDismiss()
        populateFieldsIfEditing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - UI Setup
    func setupUI() {
        // Create a scroll view and a content view inside it.
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Constrain scrollView to fill the safe area.
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Constrain contentView to scrollView (with same width as scrollView).
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // MARK: - Create and Add Labels
        dateLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.labelRemediationDate")):"
        itemNameLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.labelItemName")):"
        replaceRepairedLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.replaceRepairedLabel")):"
        jobCompletedLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.labelJobCompleted")):"
        descriptionLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.labelJobDescription")):"
        
        [dateLabel, itemNameLabel, replaceRepairedLabel, jobCompletedLabel, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // MARK: - Configure and Add Input Fields
        
        // Date Text Field
        dateTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterDate")
        dateTextField.borderStyle = .roundedRect
        dateTextField.inputView = datePicker
        dateTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateTextField)
        
        // Item Name Text Field
        itemNameTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterItemName")
        itemNameTextField.borderStyle = .roundedRect
        itemNameTextField.autocapitalizationType = .words
        itemNameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemNameTextField)
        
        // Replace / Repaired Segmented Control
        replaceRepairedSegmentedControl = UISegmentedControl(items: [TranslationManager.shared.getTranslation(for: "mechanicReports.labelReplaced"),TranslationManager.shared.getTranslation(for: "mechanicReports.labelRepaired")])
        // Default selection: "Replaced" (which we store as true)
        replaceRepairedSegmentedControl.selectedSegmentIndex = 0
        replaceRepairedSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(replaceRepairedSegmentedControl)
        
        // Job Completed Switch (already declared)
        jobCompletedSwitch.isOn = true  // default is Yes (true)
        jobCompletedSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(jobCompletedSwitch)
        
        // Job Description Text View
        jobDescriptionTextView.layer.borderWidth = 1
        jobDescriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        jobDescriptionTextView.layer.cornerRadius = 5
        jobDescriptionTextView.font = UIFont.systemFont(ofSize: 16)
        jobDescriptionTextView.autocapitalizationType = .sentences
        jobDescriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(jobDescriptionTextView)
        
        // Save and Cancel Buttons
        saveButton.setTitle(TranslationManager.shared.getTranslation(for: "common.saveButton"), for: .normal)
//        saveButton.backgroundColor = ColorScheme.amBlue
//        saveButton.setTitleColor(.white, for: .normal)
//        saveButton.layer.cornerRadius = 5
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        cancelButton.setTitle(TranslationManager.shared.getTranslation(for: "common.cancelButton"), for: .normal)
        cancelButton.customBackgroundColor = ColorScheme.amOrange
//        cancelButton.setTitleColor(.white, for: .normal)
//        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)
        
        // MARK: - Layout Constraints
        
        NSLayoutConstraint.activate([
            // Date Label & Field
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateTextField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            dateTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Item Name Label & Field
            itemNameLabel.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 12),
            itemNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            itemNameTextField.topAnchor.constraint(equalTo: itemNameLabel.bottomAnchor, constant: 4),
            itemNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            itemNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Replace / Repaired Label & Segmented Control
            replaceRepairedLabel.topAnchor.constraint(equalTo: itemNameTextField.bottomAnchor, constant: 12),
            replaceRepairedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replaceRepairedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            replaceRepairedSegmentedControl.topAnchor.constraint(equalTo: replaceRepairedLabel.bottomAnchor, constant: 4),
            replaceRepairedSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replaceRepairedSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            replaceRepairedSegmentedControl.heightAnchor.constraint(equalToConstant: 30),
            
            // Job Completed Label & Switch
            jobCompletedLabel.topAnchor.constraint(equalTo: replaceRepairedSegmentedControl.bottomAnchor, constant: 12),
            jobCompletedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            jobCompletedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            jobCompletedSwitch.topAnchor.constraint(equalTo: jobCompletedLabel.bottomAnchor, constant: 4),
            jobCompletedSwitch.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Description Label & Text View
            descriptionLabel.topAnchor.constraint(equalTo: jobCompletedSwitch.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            jobDescriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            jobDescriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            jobDescriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            jobDescriptionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // Save and Cancel Buttons
            saveButton.topAnchor.constraint(equalTo: jobDescriptionTextView.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Cancel Button: Same horizontal constraints.
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Bottom constraint for the content view.
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = keyboardFrame.height
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Tap to Dismiss Keyboard
    func setupTapToDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - DatePicker Setup
    func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        updateDateField(with: Date())
    }
    
    @objc func dateChanged() {
        updateDateField(with: datePicker.date)
    }
    
    func updateDateField(with date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: date)
        print("Remediation date selected: \(dateTextField.text ?? "")")
    }
    
    // MARK: - Populate Fields if Editing
    func populateFieldsIfEditing() {
        if let remediation = remediationToEdit {
            updateDateField(with: Date(timeIntervalSince1970: remediation.dateTimestamp))
            itemNameTextField.text = remediation.itemName
            jobDescriptionTextView.text = remediation.jobDescription
            // Set the segmented control based on stored value:
            replaceRepairedSegmentedControl.selectedSegmentIndex = remediation.replaceRepaired ? 0 : 1
            // Set jobCompleted switch.
            jobCompletedSwitch.isOn = remediation.jobCompleted
        }
    }
    
    // MARK: - Button Actions
    @objc func saveTapped() {
        guard let itemName = itemNameTextField.text, !itemName.isEmpty,
              let dateFormatted = dateTextField.text, !dateFormatted.isEmpty else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "mechanicReports.enterTaskAndTime"))
            return
        }
        // Determine the value for Replace/Repaired from the segmented control.
        let isReplaced = (replaceRepairedSegmentedControl.selectedSegmentIndex == 0)
        let remediation = Remediation(
            id: remediationToEdit?.id ?? UUID().uuidString,
            dateTimestamp: datePicker.date.timeIntervalSince1970,
            dateFormatted: dateTextField.text ?? "",
            itemName: itemName,
            replaceRepaired: isReplaced,
            jobCompleted: jobCompletedSwitch.isOn,
            jobDescription: jobDescriptionTextView.text,
            orderIndex: 0
        )
        print("Remediation saved: \(remediation)")
        remediationDelegate?.didSaveRemediation(remediation)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelTapped() {
        print("Remediation cancelled.")
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Alert
    func showAlert(title: String, message: String) {
        print("Remediation Alert: \(title) - \(message)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

