//
//  MechanicReportViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/03/2025.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import AVFoundation
import Photos


// MARK: - Data Models

struct Remediation: Codable {
    var id: String = UUID().uuidString
    var dateTimestamp: TimeInterval = Date().timeIntervalSince1970
    var dateFormatted: String = ""
    var itemName: String = ""
    var replaceRepaired: Bool = true
    var jobCompleted: Bool = true
    var jobDescription: String = ""
    var orderIndex: Int = 0
}

struct MechanicReport: Codable {
    var reportId: String = ""
    var make: String = ""
    var model: String = ""
    var serialNo: String = ""
    var dateTimestamp: TimeInterval = Date().timeIntervalSince1970
    var dateFormatted: String = ""
    var ga2Details: String = ""
    var location: String = ""
    var remarks: String = ""
    var reportNumber: Int = 0
    var remediations: [String: Remediation] = [:]
    var signatureUrl: String? = nil
    var mechanicJobReason: String? = nil
}

// MARK: - MechanicReportViewController

class MechanicReportViewController: UIViewController {
    
    let SIGNATURE_INFO_VERSION = 2
    var hasUnsavedChanges = false
    
    // UI Elements
    var scrollView = UIScrollView()
    let backButton = CustomButton(type: .system)
    let headerTitleLabel = UILabel()
    
    let makeTextField = UITextField()
    let modelTextField = UITextField()
    let serialNoTextField = UITextField()
    let dateTextField = UITextField()
    let ga2TextView = UITextView()
    let locationTextField = UITextField()
    let remarksTextView = UITextView()
    
    let reasonForWorkLabel = UILabel()
    let ga2FaultButton = UIButton(type: .system)
    let routineMaintenanceButton = UIButton(type: .system)
    var mechanicJobReason: String?
    
    let addRemediationButton = CustomButton(type: .system)
    let remediationTableView = UITableView()
    
    let addSignatureButton = CustomButton(type: .system)
    let signatureImageView = UIImageView()
    
    let saveButton = CustomButton(type: .system)
    
    // Data
    var remediationItems: [Remediation] = []
    var signatureImage: UIImage? = nil
    
    // DatePicker for dateTextField
    let datePicker = UIDatePicker()
    
    // Firebase references
    let databaseRef = Database.database().reference()
    let storageRef = Storage.storage().reference()
    let auth = Auth.auth()
    
    // Edit mode properties
    var isEditMode: Bool = false
    var reportId: String?
    var currentReport: MechanicReport?
    
    var remediationTableHeightConstraint: NSLayoutConstraint?
    var signatureImageHeightConstraint: NSLayoutConstraint?
    
    // Photo upload properties
    let addPhotoButton = CustomButton(type: .system)
    var photoScrollView: UIScrollView!
    var photoContainer: UIStackView!
    var photoUris: [URL] = []          // Local URLs for newly added photos
    var existingPhotoUrls: [String] = [] // URLs loaded from an existing report (if any)
    
    var spinnerOverlay: UIView?
    var activityIndicator: UIActivityIndicatorView?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MechanicReportViewController loaded.")
        view.backgroundColor = .white
        
        showSignatureInfoDialog()
        
        // Set up change listeners on text fields.
        makeTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        modelTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        serialNoTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        dateTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        locationTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        
        // For text views, assign the delegate (make sure to conform to UITextViewDelegate)
        ga2TextView.delegate = self
        remarksTextView.delegate = self
        
        self.title = isEditMode ? TranslationManager.shared.getTranslation(for: "mechanicReports.editMode") : TranslationManager.shared.getTranslation(for: "mechanicReports.addReport")
        setupUI()
        setupDatePicker()
        setupTapToDismissKeyboard()
        setupHelpButton()
        setupCustomBackButton()
        
        if isEditMode, let reportId = reportId {
            loadReportData(reportId: reportId)
        }
        
        print("isEditMode: \(self.isEditMode), reportId: \(String(describing: self.reportId)) ")
        print("Initial remediation items count: \(remediationItems.count)")
        print("TableView hidden: \(remediationTableView.isHidden)")
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
    
    @objc func textFieldChanged(_ textField: UITextField) {
        hasUnsavedChanges = true
    }
    
    
    func showUnsavedChangesDialog() {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "mechanicReports.unsavedChanges"),
                                      message: TranslationManager.shared.getTranslation(for: "mechanicReports.unsavedChangesMessage"),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.saveButton"), style: .default, handler: { _ in
            self.saveReportTapped() // or call saveReportTapped() if that’s your saving method
        }))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.discardButton"), style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }

    
    
    func showSignatureInfoDialog(force: Bool = false) {
        let defaults = UserDefaults.standard
        let storedVersion = defaults.integer(forKey: "signature_info_version")
        if storedVersion < SIGNATURE_INFO_VERSION {
            print("Resetting signature info flag due to version change.")
            defaults.set(false, forKey: "hide_signature_info") // Reset hidden flag
            defaults.set(SIGNATURE_INFO_VERSION, forKey: "signature_info_version")
        }
        
        if !force && defaults.bool(forKey: "hide_signature_info") {
            print("Signature info dialog is set to hidden.")
            return
        }
        
        // Retrieve and format the message.
        let rawMessage = TranslationManager.shared.getTranslation(for: "mechanicReports.signatureInfoMessage")
        let extendedMessage = rawMessage.replacingOccurrences(of: "\\n", with: "\n") + "\n\n\n"
        
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "mechanicReports.signatureInfoTitle"),
                                      message: extendedMessage,
                                      preferredStyle: .alert)
        
        // Create container for the switch and label.
        let switchContainer = UIView()
        switchContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let dontShowSwitch = UISwitch()
        dontShowSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = TranslationManager.shared.getTranslation(for: "mechanicReports.doNotShowAgain")
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        switchContainer.addSubview(dontShowSwitch)
        switchContainer.addSubview(label)
        
        NSLayoutConstraint.activate([
            dontShowSwitch.leadingAnchor.constraint(equalTo: switchContainer.leadingAnchor, constant: 8),
            dontShowSwitch.centerYAnchor.constraint(equalTo: switchContainer.centerYAnchor),
            
            label.leadingAnchor.constraint(equalTo: dontShowSwitch.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: switchContainer.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: switchContainer.centerYAnchor)
        ])
        
        alert.view.addSubview(switchContainer)
        
        NSLayoutConstraint.activate([
            switchContainer.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 16),
            switchContainer.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -16),
            switchContainer.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -45),
            switchContainer.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let okAction = UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default) { _ in
            if dontShowSwitch.isOn {
                defaults.set(true, forKey: "hide_signature_info")
                print("User chose to hide the signature info dialog in future.")
            }
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }


    func setupHelpButton() {
        // Create a custom UIButton for the help icon.
        let helpButton = UIButton(type: .system)
        if let helpImage = UIImage(named: "help_icon") {
            helpButton.setImage(helpImage, for: .normal)
        } else {
            // Fallback title if no image is found.
            helpButton.setTitle("?", for: .normal)
        }
        // Set the desired frame size (adjust as needed).
        helpButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        // Optional: adjust content mode and tint color if needed.
        helpButton.contentMode = .scaleAspectFit
        helpButton.tintColor = .white
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
        
        // Wrap the custom button in a UIBarButtonItem.
        let barButtonItem = UIBarButtonItem(customView: helpButton)
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    @objc func helpButtonTapped() {
        showSignatureInfoDialog(force: true)
    }

    
    // MARK: - UI Setup Methods
    func setupUI() {
        // Create a scroll view and add it to the main view.
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Create a content view to hold all UI elements.
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Constrain the scroll view to fill the safe area.
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Constrain the content view to the scroll view (fixed width).
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // MARK: - Create Labels and Fields for Static Content
        
        // Make
        let makeLabel = UILabel()
        makeLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.make")):"
        makeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(makeLabel)
        
        makeTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterMake")
        makeTextField.borderStyle = .roundedRect
        makeTextField.autocapitalizationType = .words
        makeTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(makeTextField)
        
        // Model
        let modelLabel = UILabel()
        modelLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.model")):"
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(modelLabel)
        
        modelTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterModel")
        modelTextField.borderStyle = .roundedRect
        modelTextField.autocapitalizationType = .words
        modelTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(modelTextField)
        
        // Serial No
        let serialNoLabel = UILabel()
        serialNoLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.serialNumber")):"
        serialNoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(serialNoLabel)
        
        serialNoTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterSerialNo")
        serialNoTextField.borderStyle = .roundedRect
        serialNoTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(serialNoTextField)
        
        // Date
        let dateLabel = UILabel()
        dateLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.date")):"
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        dateTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterDate")
        dateTextField.borderStyle = .roundedRect
        dateTextField.translatesAutoresizingMaskIntoConstraints = false
        dateTextField.inputView = datePicker
        contentView.addSubview(dateTextField)
        
        // Location
        let locationLabel = UILabel()
        locationLabel.text = "\(TranslationManager.shared.getTranslation(for: "common.location")):"
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationLabel)
        
        locationTextField.placeholder = TranslationManager.shared.getTranslation(for: "mechanicReports.enterLocation")
        locationTextField.borderStyle = .roundedRect
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationTextField)
        
        // GA2 Reported Failure Details
        let ga2Label = UILabel()
        ga2Label.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.ga2Faults")):"
        ga2Label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ga2Label)
        
        ga2TextView.layer.borderWidth = 1
        ga2TextView.layer.borderColor = UIColor.lightGray.cgColor
        ga2TextView.layer.cornerRadius = 5
        ga2TextView.font = UIFont.systemFont(ofSize: 16)
        ga2TextView.autocapitalizationType = .sentences
        ga2TextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ga2TextView)
        
        // Remarks
        let remarksLabel = UILabel()
        remarksLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.remarks")):"
        remarksLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(remarksLabel)
        
        remarksTextView.layer.borderWidth = 1
        remarksTextView.layer.borderColor = UIColor.lightGray.cgColor
        remarksTextView.layer.cornerRadius = 5
        remarksTextView.font = UIFont.systemFont(ofSize: 16)
        remarksTextView.autocapitalizationType = .sentences
        remarksTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(remarksTextView)
        
        // Reason for Work
        reasonForWorkLabel.text = "\(TranslationManager.shared.getTranslation(for: "mechanicReports.reasonForWork")):"
        reasonForWorkLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reasonForWorkLabel)
        
        configureReasonButton(ga2FaultButton, title: TranslationManager.shared.getTranslation(for: "mechanicReports.ga2Fault"))
        ga2FaultButton.addTarget(self, action: #selector(reasonButtonTapped(_:)), for: .touchUpInside)
        contentView.addSubview(ga2FaultButton)
        
        configureReasonButton(routineMaintenanceButton, title: TranslationManager.shared.getTranslation(for: "mechanicReports.routineMaintenance"))
        routineMaintenanceButton.addTarget(self, action: #selector(reasonButtonTapped(_:)), for: .touchUpInside)
        contentView.addSubview(routineMaintenanceButton)
        
        // MARK: - Optional Views (Wrapped in Stack Views)
        
        // Remediation Section: "Add Remediation" Button and Remediation TableView
        addRemediationButton.setTitle(TranslationManager.shared.getTranslation(for: "mechanicReports.remediationButton"), for: .normal)
        addRemediationButton.customBackgroundColor = ColorScheme.amOrange
//        addRemediationButton.setTitleColor(.white, for: .normal)
//        addRemediationButton.layer.cornerRadius = 5
        addRemediationButton.translatesAutoresizingMaskIntoConstraints = false
        addRemediationButton.addTarget(self, action: #selector(addRemediationTapped), for: .touchUpInside)

        remediationTableView.dataSource = self
        remediationTableView.delegate = self
        remediationTableView.register(UITableViewCell.self, forCellReuseIdentifier: "RemediationCell")
        remediationTableView.tableFooterView = UIView()
        remediationTableView.translatesAutoresizingMaskIntoConstraints = false
        // Initially, hide the table view if there are no items.
        remediationTableView.isHidden = remediationItems.isEmpty

        // Create a vertical stack view for remediation section.
        let remediationStack = UIStackView(arrangedSubviews: [addRemediationButton, remediationTableView])
        remediationStack.axis = .vertical
        remediationStack.spacing = 8
        remediationStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(remediationStack)

        // Add a height constraint to the table view.
        remediationTableHeightConstraint = remediationTableView.heightAnchor.constraint(equalToConstant: remediationItems.isEmpty ? 0 : 150)
        remediationTableHeightConstraint?.isActive = true
        
        // Add Photo Button
//        addPhotoButton = CustomButton(type: .system)
        addPhotoButton.setTitle(TranslationManager.shared.getTranslation(for: "mechanicReports.addPhotos"), for: .normal)
        addPhotoButton.customBackgroundColor = ColorScheme.amOrange
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        contentView.addSubview(addPhotoButton)

        // Photo Scroll View and Container
        photoScrollView = UIScrollView()
        photoScrollView.translatesAutoresizingMaskIntoConstraints = false
        photoScrollView.showsHorizontalScrollIndicator = true
        contentView.addSubview(photoScrollView)

        photoContainer = UIStackView()
        photoContainer.axis = .horizontal
        photoContainer.spacing = 8
        photoContainer.alignment = .center
        photoContainer.translatesAutoresizingMaskIntoConstraints = false
        photoScrollView.addSubview(photoContainer)

        
        // Signature Section: "Add Signature" Button and Signature ImageView
        addSignatureButton.setTitle(TranslationManager.shared.getTranslation(for: "mechanicReports.addSignature"), for: .normal)
        addSignatureButton.customBackgroundColor = ColorScheme.amOrange
        addSignatureButton.translatesAutoresizingMaskIntoConstraints = false
        addSignatureButton.addTarget(self, action: #selector(addSignatureTapped), for: .touchUpInside)
        
        signatureImageView.contentMode = .scaleAspectFit
        signatureImageView.clipsToBounds = true
        signatureImageView.isHidden = (signatureImage == nil)  // Hide if no signature yet.
        signatureImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let signatureStack = UIStackView(arrangedSubviews: [addSignatureButton, signatureImageView])
        signatureStack.axis = .vertical
        signatureStack.spacing = 8
        signatureStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(signatureStack)
        
        signatureImageHeightConstraint = signatureImageView.heightAnchor.constraint(equalToConstant: 200)
        signatureImageHeightConstraint?.isActive = true
        
        // Save Report Button
        saveButton.setTitle(TranslationManager.shared.getTranslation(for: "common.saveButton"), for: .normal)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveReportTapped), for: .touchUpInside)
        contentView.addSubview(saveButton)
        
        // MARK: - Layout Constraints
        NSLayoutConstraint.activate([
            // Static fields
            makeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            makeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            makeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            makeTextField.topAnchor.constraint(equalTo: makeLabel.bottomAnchor, constant: 4),
            makeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            makeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            makeTextField.heightAnchor.constraint(equalToConstant: 40),
            
            modelLabel.topAnchor.constraint(equalTo: makeTextField.bottomAnchor, constant: 12),
            modelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            modelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            modelTextField.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 4),
            modelTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            modelTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            modelTextField.heightAnchor.constraint(equalToConstant: 40),
            
            serialNoLabel.topAnchor.constraint(equalTo: modelTextField.bottomAnchor, constant: 12),
            serialNoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            serialNoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            serialNoTextField.topAnchor.constraint(equalTo: serialNoLabel.bottomAnchor, constant: 4),
            serialNoTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            serialNoTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            serialNoTextField.heightAnchor.constraint(equalToConstant: 40),
            
            dateLabel.topAnchor.constraint(equalTo: serialNoTextField.bottomAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateTextField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            dateTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateTextField.heightAnchor.constraint(equalToConstant: 40),
            
            locationLabel.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Reason for Work Section
            reasonForWorkLabel.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 16),
            reasonForWorkLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reasonForWorkLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            ga2FaultButton.topAnchor.constraint(equalTo: reasonForWorkLabel.bottomAnchor, constant: 8),
            ga2FaultButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ga2FaultButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            routineMaintenanceButton.topAnchor.constraint(equalTo: ga2FaultButton.bottomAnchor, constant: 8),
            routineMaintenanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            routineMaintenanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                        
            ga2Label.topAnchor.constraint(equalTo: routineMaintenanceButton.bottomAnchor, constant: 12),
            ga2Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ga2Label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ga2TextView.topAnchor.constraint(equalTo: ga2Label.bottomAnchor, constant: 4),
            ga2TextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ga2TextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ga2TextView.heightAnchor.constraint(equalToConstant: 100),
            
            remarksLabel.topAnchor.constraint(equalTo: ga2TextView.bottomAnchor, constant: 12),
            remarksLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            remarksLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            remarksTextView.topAnchor.constraint(equalTo: remarksLabel.bottomAnchor, constant: 4),
            remarksTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            remarksTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            remarksTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // Remediation Stack (Add Remediation + Table)
            remediationStack.topAnchor.constraint(equalTo: remarksTextView.bottomAnchor, constant: 16),
            remediationStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            remediationStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            addPhotoButton.topAnchor.constraint(equalTo: remediationStack.bottomAnchor, constant: 16),
            addPhotoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addPhotoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            
            photoScrollView.topAnchor.constraint(equalTo: addPhotoButton.bottomAnchor, constant: 8),
            photoScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            photoScrollView.heightAnchor.constraint(equalToConstant: 110),
            
            photoContainer.topAnchor.constraint(equalTo: photoScrollView.topAnchor),
            photoContainer.bottomAnchor.constraint(equalTo: photoScrollView.bottomAnchor),
            photoContainer.leadingAnchor.constraint(equalTo: photoScrollView.leadingAnchor),
            photoContainer.trailingAnchor.constraint(equalTo: photoScrollView.trailingAnchor),
            
            // Signature Stack (Add Signature + Signature Image)
            signatureStack.topAnchor.constraint(equalTo: photoScrollView.bottomAnchor, constant: 16),
            signatureStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            signatureStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Save Report Button
            saveButton.topAnchor.constraint(equalTo: signatureStack.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Initially hide the photo scroll view if there are no photos.
        photoScrollView.isHidden = true
    }

    // func configureReasonButton(_ button: UIButton, title: String) {
    //     button.setTitle(title, for: .normal)
    //     button.setImage(UIImage(systemName: "circle"), for: .normal)
    //     button.setImage(UIImage(systemName: "circle.inset.filled"), for: .selected)
    //     button.tintColor = ColorScheme.amBlue
    //     button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    //     button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
    //     button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
    //     button.translatesAutoresizingMaskIntoConstraints = false
    //     button.contentHorizontalAlignment = .left
    // }

    func configureReasonButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "circle.inset.filled"), for: .selected)
        button.tintColor = ColorScheme.amBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // Allow text to wrap to multiple lines
        button.titleLabel?.numberOfLines = 0
        
        // Prevent the default highlight effect on the text and image
        button.adjustsImageWhenHighlighted = false
        button.setTitleColor(button.titleColor(for: .normal), for: .highlighted)

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
    }

    @objc func reasonButtonTapped(_ sender: UIButton) {
        hasUnsavedChanges = true
        if sender == ga2FaultButton {
            ga2FaultButton.isSelected = true
            routineMaintenanceButton.isSelected = false
            mechanicJobReason = "ga2"
        } else {
            ga2FaultButton.isSelected = false
            routineMaintenanceButton.isSelected = true
            mechanicJobReason = "routine"
        }
    }


    
    func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        // Set default date
        updateDateField(with: Date())
    }
    
    // MARK: - Button Actions
    
    func setupCustomBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func handleBack() {
        if hasUnsavedChanges {
            showUnsavedChangesDialog()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func addRemediationTapped() {
        print("Add Remediation tapped")
        let remediationVC = RemediationViewController()
        remediationVC.modalPresentationStyle = .formSheet
        remediationVC.remediationDelegate = self
        present(remediationVC, animated: true, completion: nil)
    }
    
    @objc func addSignatureTapped() {
        print("Add Signature tapped")
        let signatureVC = MechanicSignatureViewController()
        signatureVC.modalPresentationStyle = .fullScreen
        signatureVC.signatureDelegate = self
        present(signatureVC, animated: true, completion: nil)
    }
    
    
    
    @objc func saveReportTapped() {
        print("Save Report tapped")
        showSpinner()
        // Validate mandatory fields
        guard let make = makeTextField.text, !make.isEmpty,
              let model = modelTextField.text, !model.isEmpty,
              let serialNo = serialNoTextField.text, !serialNo.isEmpty else {
            hideSpinner()
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.validationError"), message: TranslationManager.shared.getTranslation(for:"mechanicReports.fillMandatoryFields"))
            return
        }

        guard mechanicJobReason != nil else {
            hideSpinner()
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.validationError"), message: TranslationManager.shared.getTranslation(for: "mechanicReports.selectJobReason"))
            return
        }
        
        // Check if a signature is present.
        if signatureImage == nil {
            // Display an alert asking user whether to continue without a signature.
            let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "mechanicReports.sigAlertTitle"), message: TranslationManager.shared.getTranslation(for: "mechanicReports.sigAlertMessage"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.continue"), style: .default, handler: { _ in
                self.continueSaveReport(make: make, model: model, serialNo: serialNo)
            }))
            alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: { _ in
                self.hideSpinner()  // Cancel: hide spinner and allow interactions again.
            }))
            present(alert, animated: true, completion: nil)
        } else {
            self.continueSaveReport(make: make, model: model, serialNo: serialNo)
        }
    }
    
    

    
    // Continues saving the report after validating mandatory fields.
    // If in edit mode, reuses the loaded reportNumber; otherwise, it increments the counter.
    func continueSaveReport(make: String, model: String, serialNo: String) {
        print("Continue saving report with make: \(make), model: \(model), serialNo: \(serialNo)")
        
        // Prepare the report data.
        var report = MechanicReport()
        report.make = make
        report.model = model
        report.serialNo = serialNo
        report.dateFormatted = dateTextField.text ?? ""
        report.dateTimestamp = datePicker.date.timeIntervalSince1970
        report.location = locationTextField.text ?? ""
        report.ga2Details = ga2TextView.text
        report.remarks = remarksTextView.text
        report.mechanicJobReason = mechanicJobReason
        
        // Map remediation items.
        for remediation in remediationItems {
            report.remediations[remediation.id] = remediation
        }
        
        print("currentReport: \(self.currentReport)")
        
        // If in edit mode, re-use the loaded report number without running a transaction.
        if isEditMode {
            guard let loadedReport = self.currentReport, loadedReport.reportNumber > 0 else {
                print("Edit mode: report number not available – aborting save.")
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: "Report number not found in edit mode.")
                return
            }
            print("Edit mode detected. Reusing report number: \(loadedReport.reportNumber)")
            report.reportNumber = loadedReport.reportNumber
            self.saveReportToFirebase(report: report)
            return
        }
        
        // In add mode: run transaction on the customer's counter.
        guard let userParent = UserSession.shared.userParent else {
            print("User parent not available. Aborting save.")
            return
        }
        let counterRef = databaseRef.child("customers").child(userParent).child("mechanicReportCounter")
        counterRef.runTransactionBlock { currentData -> TransactionResult in
            var currentCount = currentData.value as? Int ?? 0
            print("Current mechanicReportCounter value: \(currentCount)")
            if currentCount <= 0 {
                // Initialise counter to 101 if not set.
                print("Counter is zero or not set. Initialising counter to 101.")
                currentCount = 101
            } else {
                // Increment counter.
                currentCount += 1
            }
            currentData.value = currentCount
            print("Updated counter value: \(currentCount)")
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, snapshot in
            if let error = error {
                print("Transaction error: \(error.localizedDescription)")
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "mechanicReports.failedReportCounter"))
                return
            }
            guard let counterValue = snapshot?.value as? Int, counterValue > 0 else {
                print("Invalid counter value received after transaction.")
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "mechanicReports.failedReportId"))
                return
            }
            // Subtract 1 from the counter value to obtain the report number.
            let newReportNumber = counterValue - 1
            print("Transaction successful. New report number obtained: \(newReportNumber)")
            report.reportNumber = newReportNumber
            self.saveReportToFirebase(report: report)
        }
    }


    
    // Saves the given report to Firebase.
    // If not in edit mode, generates a new reportId.
    func saveReportToFirebase(report: MechanicReport) {
        // In add mode, generate a new reportId if necessary.
        if !isEditMode, reportId == nil {
            self.reportId = databaseRef.child("mechanicReports")
                .child(auth.currentUser?.uid ?? "unknown")
                .childByAutoId().key
            print("Generated new report ID: \(self.reportId ?? "nil")")
        }
        
        // Assign the reportId.
        var reportToSave = report
        reportToSave.reportId = self.reportId ?? ""
        
        let userId = auth.currentUser?.uid ?? "unknown"
        guard let userParent = UserSession.shared.userParent else {
            hideSpinner()
            print("User parent not available.")
            return
        }
        let reportPath = "mechanicReports/\(userParent)/\(userId)/\(reportToSave.reportId)"
        print("Saving report at path: \(reportPath) with data: \(dictionaryFrom(report: reportToSave))")
        
        databaseRef.child(reportPath).setValue(dictionaryFrom(report: reportToSave)) { error, _ in
            if let error = error {
                print("Error saving report: \(error.localizedDescription)")
                self.hideSpinner()
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "mechanicReports.reportSaveFailed"))
            } else {
                print("Report saved successfully with report number: \(reportToSave.reportNumber)")
                
                self.hasUnsavedChanges = false
                
                // Now upload photos first (if any)
                // Check if there are any photos (new or existing)
                if !self.photoUris.isEmpty || !self.existingPhotoUrls.isEmpty {
                    let signaturePath = "mechanicReports/\(userParent)/\(userId)/\(reportToSave.reportId)/signatureUrl"
                    // Remove signatureUrl by setting its value to NSNull.
                    self.databaseRef.child(signaturePath).setValue(NSNull()) { error, _ in
                        if let error = error {
                            print("Error removing signatureUrl: \(error.localizedDescription)")
                        } else {
                            print("Signature URL removed successfully.")
                        }
                        // Now, upload photos.
                        self.uploadPhotosAndGetUrls { combinedPhotoUrls in
                            // After photos are saved, check if there's a signature image to upload.
                            if let signatureImg = self.signatureImage {
                                self.uploadSignature(image: signatureImg, reportId: reportToSave.reportId, parentId: userParent, userId: userId) {
                                    self.hideSpinner()
                                    self.hideSpinner()
                                    self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.successHeader"),
                                                   message: TranslationManager.shared.getTranslation(for: "mechanicReports.reportSaved"),
                                                   completion: {
                                        self.navigationController?.popViewController(animated: true)
                                    })
                                }
                            } else {
                                self.hideSpinner()
                                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.successHeader"),
                                               message: TranslationManager.shared.getTranslation(for: "mechanicReports.reportSaved"),
                                               completion: {
                                    self.navigationController?.popViewController(animated: true)
                                })
                            }
                        }
                    }
                } else {
                    // No photos to upload; proceed with signature upload if available.
                    if let signatureImg = self.signatureImage {
                        self.uploadSignature(image: signatureImg, reportId: reportToSave.reportId, parentId: userParent, userId: userId) {
                            self.hideSpinner()
                            self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.successHeader"),
                                           message: TranslationManager.shared.getTranslation(for: "mechanicReports.reportSaved"),
                                           completion: {
                                self.navigationController?.popViewController(animated: true)
                            })
                        }
                    } else {
                        self.hideSpinner()
                        self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.successHeader"),
                                       message: TranslationManager.shared.getTranslation(for: "mechanicReports.reportSaved"),
                                       completion: {
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                }
            }
        }
    }


    
    
    
    
    @objc func dateChanged() {
        updateDateField(with: datePicker.date)
    }
    
    func updateDateField(with date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let formattedDate = formatter.string(from: date)
        dateTextField.text = formattedDate
        print("Date selected: \(formattedDate)")
    }
    
    // MARK: - Helper Methods
    
    func loadReportData(reportId: String) {
        print("Loading report data for reportId: \(reportId)")
        
        showSpinner()
        // Ensure the user is logged in.
        guard let currentUser = auth.currentUser else {
            print("User not logged in")
            hideSpinner()
            self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "common.userNotLoggedIn"))
            return
        }
        // Replace "userParentPlaceholder" with the actual parent ID from your session, if available.
//        let parentId = "userParentPlaceholder"
        guard let userParent = UserSession.shared.userParent else {
            hideSpinner()
            return
        }
        
        let reportRef = databaseRef.child("mechanicReports")
            .child(userParent)
            .child(currentUser.uid)
            .child(reportId)
        
        reportRef.observeSingleEvent(of: .value) { snapshot in
            // Ensure we hide the spinner when processing is done.
            defer { self.hideSpinner() }
            
            guard let dict = snapshot.value as? [String: Any] else {
                print("Failed to load report data.")
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "mechanicReports.errorLoadingData"))
                return
            }
            print("Report data loaded: \(dict)")
            
            // Populate text fields
            self.makeTextField.text = dict["make"] as? String ?? ""
            self.modelTextField.text = dict["model"] as? String ?? ""
            self.serialNoTextField.text = dict["serialNo"] as? String ?? ""
            self.dateTextField.text = dict["dateFormatted"] as? String ?? ""
            if let timestamp = dict["dateTimestamp"] as? TimeInterval {
                self.datePicker.date = Date(timeIntervalSince1970: timestamp)
            }
            self.locationTextField.text = dict["location"] as? String ?? ""
            self.ga2TextView.text = dict["ga2Details"] as? String ?? ""
            self.remarksTextView.text = dict["remarks"] as? String ?? ""

            if let reason = dict["mechanicJobReason"] as? String {
                if reason == "ga2" {
                    self.reasonButtonTapped(self.ga2FaultButton)
                } else if reason == "routine" {
                    self.reasonButtonTapped(self.routineMaintenanceButton)
                }
            }
            
            if let imageUrls = dict["images"] as? [String] {
                self.existingPhotoUrls = imageUrls
                DispatchQueue.main.async {
                    self.displayExistingPhotos()
                    self.updatePhotoContainerVisibility()
                }
            }
            
            // Load remediation items
            self.remediationItems.removeAll()
            if let remediationsDict = dict["remediations"] as? [String: Any] {
                for (_, value) in remediationsDict {
                    if let remDict = value as? [String: Any] {
                        var remediation = Remediation()
                        remediation.id = remDict["id"] as? String ?? UUID().uuidString
                        remediation.itemName = remDict["itemName"] as? String ?? ""
                        remediation.dateFormatted = remDict["dateFormatted"] as? String ?? ""
                        remediation.dateTimestamp = remDict["dateTimestamp"] as? TimeInterval ?? 0
                        remediation.replaceRepaired = remDict["replaceRepaired"] as? Bool ?? true
                        remediation.jobCompleted = remDict["jobCompleted"] as? Bool ?? true
                        remediation.jobDescription = remDict["jobDescription"] as? String ?? ""
                        remediation.orderIndex = remDict["orderIndex"] as? Int ?? 0
                        self.remediationItems.append(remediation)
                    }
                }
                // Sort remediation items by orderIndex and reload the table view.
                self.remediationItems.sort { $0.orderIndex < $1.orderIndex }
                DispatchQueue.main.async {
                    self.remediationTableView.reloadData()
                    self.remediationTableView.isHidden = self.remediationItems.isEmpty
                    self.remediationTableHeightConstraint?.constant = self.remediationItems.isEmpty ? 0 : 150
                    self.view.layoutIfNeeded()
                }
            }
            
            // Create a MechanicReport instance from the loaded data.
            var loadedReport = MechanicReport()
            loadedReport.reportId = dict["reportId"] as? String ?? ""
            loadedReport.make = dict["make"] as? String ?? ""
            loadedReport.model = dict["model"] as? String ?? ""
            loadedReport.serialNo = dict["serialNo"] as? String ?? ""
            loadedReport.dateTimestamp = dict["dateTimestamp"] as? TimeInterval ?? 0
            loadedReport.dateFormatted = dict["dateFormatted"] as? String ?? ""
            loadedReport.location = dict["location"] as? String ?? ""
            loadedReport.ga2Details = dict["ga2Details"] as? String ?? ""
            loadedReport.remarks = dict["remarks"] as? String ?? ""
            loadedReport.reportNumber = dict["reportNumber"] as? Int ?? 0
            loadedReport.signatureUrl = dict["signatureUrl"] as? String ?? ""
            loadedReport.mechanicJobReason = dict["mechanicJobReason"] as? String
            
            // Assign the loaded report to currentReport for later use in edit mode.
            self.currentReport = loadedReport
            
            // Load signature image if available.
        } withCancel: { error in
            print("Error loading report data: \(error.localizedDescription)")
            self.hideSpinner()
            self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: "\(TranslationManager.shared.getTranslation(for: "mechanicReports.errorLoadingData")): \(error.localizedDescription)")
        }
    }

    
    func dictionaryFrom(report: MechanicReport) -> [String: Any] {
        // Convert MechanicReport to a dictionary to save to Firebase.
        // Here we'll use a simple approach assuming Remediation is encodable.
        var remediationDict: [String: Any] = [:]
        for (key, remediation) in report.remediations {
            remediationDict[key] = [
                "id": remediation.id,
                "dateTimestamp": remediation.dateTimestamp,
                "dateFormatted": remediation.dateFormatted,
                "itemName": remediation.itemName,
                "replaceRepaired": remediation.replaceRepaired,
                "jobCompleted": remediation.jobCompleted,
                "jobDescription": remediation.jobDescription,
                "orderIndex": remediation.orderIndex
            ]
        }
        
        var dict: [String: Any] = [
            "reportId": report.reportId,
            "make": report.make,
            "model": report.model,
            "serialNo": report.serialNo,
            "dateTimestamp": report.dateTimestamp,
            "dateFormatted": report.dateFormatted,
            "ga2Details": report.ga2Details,
            "location": report.location,
            "remarks": report.remarks,
            "reportNumber": report.reportNumber,
            "remediations": remediationDict
        ]
        
        if let signatureUrl = report.signatureUrl {
            dict["signatureUrl"] = signatureUrl
        }
        
        // --- THIS IS THE NEW BLOCK TO ADD ---
        if let mechanicJobReason = report.mechanicJobReason {
            dict["mechanicJobReason"] = mechanicJobReason
        }
        // ------------------------------------
        
        return dict
    }
    
    func displayExistingPhotos() {
        // Clear any existing thumbnails in photoContainer (if needed)
        for view in photoContainer.arrangedSubviews {
            photoContainer.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for urlString in existingPhotoUrls {
            if let url = URL(string: urlString) {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                
                // Assuming you have an extension method "load(url:)" to load images asynchronously:
                imageView.load(url: url)
                
                // Optionally add a tap gesture recogniser to allow removal of an existing photo.
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(removeExistingPhoto(_:)))
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                
                photoContainer.addArrangedSubview(imageView)
            }
        }
    }

    func updatePhotoContainerVisibility() {
        let hasPhotos = !photoUris.isEmpty || !existingPhotoUrls.isEmpty
        photoScrollView.isHidden = !hasPhotos
    }
    
    @objc func removeExistingPhoto(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView,
              let index = photoContainer.arrangedSubviews.firstIndex(of: imageView) else { return }
        
        // Remove the photo URL from the existing photos array.
        existingPhotoUrls.remove(at: index)
        // Remove the thumbnail from the container.
        photoContainer.removeArrangedSubview(imageView)
        imageView.removeFromSuperview()
        hasUnsavedChanges = true
        print("Should now show save dialog...")
        
        updatePhotoContainerVisibility()
    }


    
    

    
    func uploadSignature(image: UIImage, reportId: String, parentId: String, userId: String, completion: @escaping () -> Void) {
        print("Uploading signature for report: \(reportId)")
        guard let imageData = image.pngData() else {
            print("Error: Could not convert signature image to data.")
            completion()
            return
        }
        let signatureRef = storageRef.child("customers").child(parentId).child("mechanicReports").child(reportId).child("signature.png")
        signatureRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Signature upload error: \(error.localizedDescription)")
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "mechanicReports.failedSigUpload"))
                completion()
                return
            }
            signatureRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                   message: TranslationManager.shared.getTranslation(for: "mechanicReports.failedSigfUrl"))
                    completion()
                    return
                }
                if let url = url {
                    print("Signature uploaded. URL: \(url.absoluteString)")
                    let reportPath = "mechanicReports/\(parentId)/\(userId)/\(reportId)/signatureUrl"
                    self.databaseRef.child(reportPath).setValue(url.absoluteString) { error, _ in
                        if let error = error {
                            print("Failed to save signature URL: \(error.localizedDescription)")
                        } else {
                            print("Signature URL saved successfully.")
                        }
                        completion()
                    }
                } else {
                    completion()
                }
            }
        }
    }

    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        print("Showing alert: \(title) - \(message)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default) { _ in completion?() }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    @objc func addPhotoTapped() {
        showImagePickerOptions()
    }

    func showImagePickerOptions() {
        let alertController = UIAlertController(title: TranslationManager.shared.getTranslation(for: "mechanicReports.addPhotos"),
                                                    message: TranslationManager.shared.getTranslation(for: "mechanicReports.chooseOption"),
                                                    preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "formScreen.takePhotoButton"), style: .default, handler: { _ in
            self.openCamera()
        }))
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "formScreen.chooseFromGalleryButton"), style: .default, handler: { _ in
            self.openGallery()
        }))
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func openCamera() {
        // Check for camera permission
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                presentImagePicker(sourceType: .camera)
            } else if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.presentImagePicker(sourceType: .camera)
                        } else {
                            self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                           message: TranslationManager.shared.getTranslation(for: "formScreen.cameraAccessDenied"))
                        }
                    }
                }
            } else {
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "formScreen.cameraAccessDenied"))
            }
        } else {
            self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                           message: TranslationManager.shared.getTranslation(for: "formScreen.cameraNotAvailable"))
        }
    }

    func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    
    func addPhoto(uri: URL) {
        photoUris.append(uri)
        updatePhotoContainerVisibility()
        
        // Create thumbnail image view
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        // Assuming you have an extension to load image from URL:
        imageView.load(url: uri)
        
        // Add tap gesture for removal
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(removePhoto(_:)))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        
        photoContainer.addArrangedSubview(imageView)
    }

    @objc func removePhoto(_ sender: UITapGestureRecognizer) {
        print("Deleting photo")
        guard let imageView = sender.view as? UIImageView else { return }
        if let index = photoContainer.arrangedSubviews.firstIndex(of: imageView) {
            photoUris.remove(at: index)
            photoContainer.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
            updatePhotoContainerVisibility()
            hasUnsavedChanges = true
            print("Should now show save dialog...")
        }
    }


    
    func uploadPhotosAndGetUrls(completion: @escaping ([String]) -> Void) {
        guard let userParent = UserSession.shared.userParent,
              let reportId = self.reportId,
              let userId = auth.currentUser?.uid else {
            completion([])
            return
        }
        
        let storagePhotosRef = storageRef.child("customers").child(userParent).child("mechanicReports").child(reportId).child("images")
        var newPhotoUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, uri) in photoUris.enumerated() {
            dispatchGroup.enter()
            let uniqueFilename = "image_\(Int(Date().timeIntervalSince1970))_\(index).png"
            let photoRef = storagePhotosRef.child(uniqueFilename)
            photoRef.putFile(from: uri, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading photo: \(error.localizedDescription)")
                    dispatchGroup.leave()
                } else {
                    photoRef.downloadURL { url, error in
                        if let url = url {
                            newPhotoUrls.append(url.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Combine existing photo URLs (if any) with the new ones.
            let combinedPhotoUrls = self.existingPhotoUrls + newPhotoUrls
            let reportImagesPath = "mechanicReports/\(userParent)/\(userId)/\(reportId)/images"
            self.databaseRef.child(reportImagesPath).setValue(combinedPhotoUrls) { error, _ in
                if let error = error {
                    print("Failed to save photo URLs: \(error.localizedDescription)")
                } else {
                    print("Photo URLs saved successfully.")
                }
                completion(combinedPhotoUrls)
            }
        }
    }
    
    
    func showSpinner() {
        // Create an overlay view that fills the entire screen.
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.5)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Create and configure the activity indicator.
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = overlay.center
        indicator.startAnimating()
        
        overlay.addSubview(indicator)
        view.addSubview(overlay)
        
        // Save references so we can remove them later.
        spinnerOverlay = overlay
        activityIndicator = indicator
        
        // Disable user interaction for the whole view.
        view.isUserInteractionEnabled = false
    }

    func hideSpinner() {
        spinnerOverlay?.removeFromSuperview()
        activityIndicator?.stopAnimating()
        spinnerOverlay = nil
        activityIndicator = nil
        
        // Re-enable user interaction.
        view.isUserInteractionEnabled = true
    }



}

// MARK: - UITableViewDataSource & Delegate for Remediation List

extension MechanicReportViewController: UITableViewDataSource, UITableViewDelegate {
    // Number of remediation items
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        remediationItems.count
    }
    
    // Display remediation item (only itemName)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RemediationCell", for: indexPath)
        cell.textLabel?.text = remediationItems[indexPath.row].itemName
        return cell
    }
    
    // iOS swipe actions for editing and deleting remediation items
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: TranslationManager.shared.getTranslation(for: "common.delete")) { action, view, completion in
            print("Deleting remediation at index \(indexPath.row)")
            self.remediationItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.hasUnsavedChanges = true
            completion(true)
        }
        
        // Edit Action
        let editAction = UIContextualAction(style: .normal, title: TranslationManager.shared.getTranslation(for: "mechanicReports.editButton")) { action, view, completion in
            print("Editing remediation at index \(indexPath.row)")
            let remediationVC = RemediationViewController()
            remediationVC.modalPresentationStyle = .formSheet
            remediationVC.remediationToEdit = self.remediationItems[indexPath.row]
            remediationVC.remediationDelegate = self
            self.present(remediationVC, animated: true, completion: nil)
            completion(true)
        }
        editAction.backgroundColor = ColorScheme.amPink
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    
    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            // Adjust scrollView's content inset
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
        // Optional: set cancelsTouchesInView to false if you need to pass touches to subviews
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
}

// MARK: - RemediationDelegate

protocol RemediationDelegate: AnyObject {
    func didSaveRemediation(_ remediation: Remediation)
}

extension MechanicReportViewController: RemediationDelegate {
    func didSaveRemediation(_ remediation: Remediation) {
        print("Before update - remediationItems count: \(remediationItems.count)")

        // Check if remediation exists; if so, update it, otherwise append new
        if let index = remediationItems.firstIndex(where: { $0.id == remediation.id }) {
            remediationItems[index] = remediation
            print("Updated remediation with id: \(remediation.id)")
        } else {
            remediationItems.append(remediation)
            print("Added new remediation with id: \(remediation.id)")
        }
        
        // Update orderIndex for each remediation using a simple for-loop.
        for index in 0..<remediationItems.count {
            remediationItems[index].orderIndex = index
        }

        DispatchQueue.main.async {
            self.remediationTableView.reloadData()
            self.remediationTableView.isHidden = self.remediationItems.isEmpty
            self.remediationTableHeightConstraint?.constant = self.remediationItems.isEmpty ? 0 : 150
            self.hasUnsavedChanges = true
            self.view.layoutIfNeeded()
        }
    }
}


// MARK: - SignatureDelegate

protocol SignatureDelegate: AnyObject {
    func didCaptureSignature(_ image: UIImage)
}

extension MechanicReportViewController: SignatureDelegate {
    func didCaptureSignature(_ image: UIImage) {
        signatureImage = image
        signatureImageView.image = image
        signatureImageView.isHidden = false
        hasUnsavedChanges = true
        print("Signature captured and displayed.")
    }
}



// MARK: - UIImagePickerControllerDelegate
extension MechanicReportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let imageUrl = info[.imageURL] as? URL {
            addPhoto(uri: imageUrl)
        } else if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            if let fileUrl = saveImageLocally(imageData) {
                self.hasUnsavedChanges = true
                addPhoto(uri: fileUrl)
            }
        }
    }
    
    func saveImageLocally(_ data: Data) -> URL? {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent(UUID().uuidString + ".jpg")
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image locally: \(error)")
            return nil
        }
    }
}



extension MechanicReportViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }
}
