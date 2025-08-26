import UIKit
import PencilKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import PhotosUI
import SafariServices

// A simple in-memory image cache to prevent re-downloading images
private class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// Helper extension to encode Codable structs into Dictionaries for Firebase.
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

// Enum to represent the report types, mirroring Android.
enum ReportType: String, CaseIterable {
    case progressReport = "Progress Report"
    case incidentReport = "Incident Report"
    case snagList = "Snag List"
    case siteSafetyAudit = "Site Safety Audit Report"

    var firebaseValue: String {
        return self.rawValue
    }
}

// Data model for the Site Audit Report, aligned with the Android source of truth.
struct SiteAuditReport: Codable {
    var reportId: String
    var reportType: String
    var reportTitle: String
    var clientId: String      // Renamed to match Android
    var clientName: String    // Renamed to match Android
    var siteId: String
    var siteName: String
    var notes: [String: SiteAuditNote]
    var signatureUrl: String?
    var status: String // "Draft" or "Finalized"
    var createdBy: String
    var createdAt: TimeInterval // Handles ms/s in custom decoder
    var finalizedAt: TimeInterval?
    var isFinalized: Bool // Handles Int/Bool in custom decoder
    var pdfGenerationRequested: Bool
    var pdfDownloadUrl: String?
    var pdfGenerationError: String?

    // CodingKeys now directly match the property names and the Firebase structure.
    enum CodingKeys: String, CodingKey {
        case reportId, reportType, reportTitle, clientId, clientName, siteId, siteName, notes, signatureUrl, status, createdBy, createdAt, finalizedAt, isFinalized, pdfGenerationRequested, pdfDownloadUrl, pdfGenerationError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reportId = try container.decode(String.self, forKey: .reportId)
        reportType = try container.decode(String.self, forKey: .reportType)
        reportTitle = try container.decode(String.self, forKey: .reportTitle)
        clientId = try container.decode(String.self, forKey: .clientId)
        clientName = try container.decode(String.self, forKey: .clientName)
        siteId = try container.decode(String.self, forKey: .siteId)
        siteName = try container.decode(String.self, forKey: .siteName)
        notes = try container.decodeIfPresent([String: SiteAuditNote].self, forKey: .notes) ?? [:]
        signatureUrl = try container.decodeIfPresent(String.self, forKey: .signatureUrl)
        status = try container.decode(String.self, forKey: .status)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        finalizedAt = try container.decodeIfPresent(TimeInterval.self, forKey: .finalizedAt)
        pdfGenerationRequested = try container.decodeIfPresent(Bool.self, forKey: .pdfGenerationRequested) ?? false
        pdfDownloadUrl = try container.decodeIfPresent(String.self, forKey: .pdfDownloadUrl)
        pdfGenerationError = try container.decodeIfPresent(String.self, forKey: .pdfGenerationError)

        // Handle timestamp conversion (Android: ms, iOS: s)
        let rawCreatedAt = try container.decode(TimeInterval.self, forKey: .createdAt)
        if rawCreatedAt > 1_000_000_000_000 { // Likely milliseconds
            createdAt = rawCreatedAt / 1000.0
        } else { // Likely seconds
            createdAt = rawCreatedAt
        }
        
        // Handle boolean for isFinalized (Android can send 0/1)
        do {
            isFinalized = try container.decode(Bool.self, forKey: .isFinalized)
        } catch {
            let intValue = try container.decode(Int.self, forKey: .isFinalized)
            isFinalized = (intValue != 0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reportId, forKey: .reportId)
        try container.encode(reportType, forKey: .reportType)
        try container.encode(reportTitle, forKey: .reportTitle)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(clientName, forKey: .clientName)
        try container.encode(siteId, forKey: .siteId)
        try container.encode(siteName, forKey: .siteName)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(signatureUrl, forKey: .signatureUrl)
        try container.encode(status, forKey: .status)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(finalizedAt, forKey: .finalizedAt)
        try container.encode(pdfGenerationRequested, forKey: .pdfGenerationRequested)
        try container.encodeIfPresent(pdfDownloadUrl, forKey: .pdfDownloadUrl)
        try container.encodeIfPresent(pdfGenerationError, forKey: .pdfGenerationError)
        try container.encode(isFinalized, forKey: .isFinalized)

        // Always encode timestamp in milliseconds for consistency
        let createdAtInMilliseconds = Int64(createdAt * 1000)
        try container.encode(createdAtInMilliseconds, forKey: .createdAt)
    }
    
    // Custom initializer for creating a new report, ensuring all required fields are set.
    init(reportId: String, reportType: String, reportTitle: String, clientId: String, clientName: String, siteId: String, siteName: String, createdBy: String, isFinalised: Bool) {
        self.reportId = reportId
        self.reportType = reportType
        self.reportTitle = reportTitle
        self.clientId = clientId
        self.clientName = clientName
        self.siteId = siteId
        self.siteName = siteName
        self.createdBy = createdBy
        self.isFinalized = isFinalised
        
        self.notes = [:]
        self.signatureUrl = nil
        self.status = isFinalised ? "Finalized" : "Draft"
        self.createdAt = Date().timeIntervalSince1970
        self.finalizedAt = isFinalised ? Date().timeIntervalSince1970 : nil
        self.pdfGenerationRequested = false
        self.pdfDownloadUrl = nil
        self.pdfGenerationError = nil
    }
}

// Data model for a single note, identical to the Android source of truth.
struct SiteAuditNote: Codable, Equatable {
    var noteId: String
    var description: String?
    var imageUrl: String?
    var annotatedImageUrl: String?
    var order: Int
    var timestamp: TimeInterval
    
    // Helper properties not encoded into JSON
    var localImage: UIImage?
    var localAnnotatedImage: UIImage?

    enum CodingKeys: String, CodingKey {
        case noteId, description, imageUrl, annotatedImageUrl, order, timestamp
    }
    
    // Custom decoder to handle data inconsistencies from Firebase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        noteId = try container.decodeIfPresent(String.self, forKey: .noteId) ?? UUID().uuidString
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        annotatedImageUrl = try container.decodeIfPresent(String.self, forKey: .annotatedImageUrl)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0

        // Handle timestamp conversion (Android: ms, iOS: s)
        let rawTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timestamp) ?? Date().timeIntervalSince1970 * 1000
        if rawTimestamp > 1_000_000_000_000 { // Likely milliseconds
            timestamp = rawTimestamp / 1000.0
        } else { // Likely seconds
            timestamp = rawTimestamp
        }
    }

    // Custom encoder to ensure data is written in the Android-compatible format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(noteId, forKey: .noteId)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(annotatedImageUrl, forKey: .annotatedImageUrl)
        try container.encode(order, forKey: .order)
        
        // Always encode timestamp in milliseconds for consistency
        let timestampInMilliseconds = Int64(timestamp * 1000)
        try container.encode(timestampInMilliseconds, forKey: .timestamp)
    }

    // Custom initializer for creating a new note within the iOS app
    init(order: Int, description: String? = nil, localImage: UIImage? = nil) {
        self.noteId = UUID().uuidString
        self.order = order
        self.description = description
        self.localImage = localImage
        self.timestamp = Date().timeIntervalSince1970
        self.imageUrl = nil
        self.annotatedImageUrl = nil
    }
    
    static func == (lhs: SiteAuditNote, rhs: SiteAuditNote) -> Bool {
        return lhs.noteId == rhs.noteId
    }
}

// MARK: - CreateSiteAuditReportViewController

class CreateSiteAuditReportViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Firebase Constants
    private let customersPath = "subscriberCustomers"
    private let customerSitesPath = "subscriberCustomerSites"
    private let siteAuditReportsPath = "siteAudits"
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private lazy var reportTypeTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.setPlaceholder("Select Report Type")
        textField.accessibilityIdentifier = "reportTypeTextField"
        return textField
    }()
    
    private lazy var customerTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.setPlaceholder("Select Customer")
        textField.accessibilityIdentifier = "customerTextField"
        return textField
    }()
    
    private lazy var siteTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.setPlaceholder("Select Site")
        textField.accessibilityIdentifier = "siteTextField"
        textField.isEnabled = false
        return textField
    }()
    
    private lazy var reportTitleTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.setPlaceholder("Enter Report Title")
        textField.accessibilityIdentifier = "reportTitleTextField"
        textField.shouldCapitalizeWords = true
        return textField
    }()
    
    private lazy var signatureView: SignatureCaptureView = {
        let view = SignatureCaptureView()
        view.accessibilityIdentifier = "signatureCaptureView"
        return view
    }()
    
    private lazy var saveDraftButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Save Draft", for: .normal)
        button.customBackgroundColor = .systemGray
        button.accessibilityIdentifier = "saveDraftButton"
        button.addTarget(self, action: #selector(saveDraftTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var pdfStatusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isHidden = true // Initially hidden
        return stackView
    }()

    private lazy var pdfStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.text = "PDF not generated"
        return label
    }()

    private lazy var pdfActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var pdfButton: UIButton = {
        let button = UIButton(type: .system)
        let pdfIcon = UIImage(systemName: "doc.fill")
        button.setImage(pdfIcon, for: .normal)
        button.tintColor = ColorScheme.amBlue
        button.addTarget(self, action: #selector(pdfButtonTapped), for: .touchUpInside)
        button.isHidden = true // Initially hidden
        return button
    }()

    private lazy var finaliseButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Finalise", for: .normal)
        button.customBackgroundColor = ColorScheme.amBlue
        button.accessibilityIdentifier = "finaliseButton"
        button.addTarget(self, action: #selector(finaliseTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Pickers
    private let reportTypePicker = CustomPickerView()
    private let customerPicker = CustomPickerView()
    private let sitePicker = CustomPickerView()
    
    // MARK: - Notes UI Elements
    private lazy var notesTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NoteTableViewCell.self, forCellReuseIdentifier: "NoteTableViewCell")
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = 10
        tableView.isScrollEnabled = false // Will resize dynamically
        return tableView
    }()
    
    private lazy var addNoteButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Add Note", for: .normal)
        button.customBackgroundColor = ColorScheme.amBlue
        button.addTarget(self, action: #selector(addNoteTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var addMultipleImagesButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Add Multiple Images", for: .normal)
        button.customBackgroundColor = ColorScheme.amOrange
        button.addTarget(self, action: #selector(addMultipleImagesTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var dragAndDropInstructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Long Press to Drag and Drop the Notes"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = ColorScheme.amPink
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true // Initially hidden
        return label
    }()
    
    // MARK: - Data
    private var customers: [Customer] = []
    private var sites: [CustomerSite] = []
    private var selectedReportType: ReportType?
    private var selectedCustomer: Customer?
    private var selectedSite: CustomerSite?
        private var notes: [SiteAuditNote] = []
        var siteAuditReport: SiteAuditReport? {
        didSet {
            if let report = siteAuditReport {
                print("DEBUG: siteAuditReport property was set. Report ID: \(report.reportId), Client: \(report.clientName)")
            } else {
                print("DEBUG: siteAuditReport property was set to nil.")
            }
        }
    }
    
    private var isEditMode: Bool {
        return siteAuditReport != nil
    }
    
    
    private var spinnerOverlay: UIView?
    private var pdfStatusListenerHandle: DatabaseHandle?
    private var notesTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Firebase References
    private let databaseRef = Database.database().reference()
    private let storageRef = Storage.storage().reference()
    private let auth = Auth.auth()
    
    deinit {
        if let handle = pdfStatusListenerHandle, let report = siteAuditReport, let parentId = UserSession.shared.userParent {
            let reportRef = databaseRef.child(siteAuditReportsPath).child(parentId).child(report.clientId).child(report.siteId).child(report.reportId)
            reportRef.removeObserver(withHandle: handle)
            print("DEBUG: Removed PDF status listener.")
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
                setupUI()
        setupPickers()
        setupNotesTableView()
        setupTapToDismissKeyboard()

        print("DEBUG: viewDidLoad - Checking mode. isEditMode = \(isEditMode)")
        if isEditMode {
            configureForEditMode()
            fetchReportDetails()
        } else {
            self.title = "Create Site Audit Report"
            loadCustomers()
        }
        
        // Replace system back with our own so we can intercept taps
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // Intercept swipe-to-go-back as well (otherwise users can bypass the alert)
        if let popGesture = navigationController?.interactivePopGestureRecognizer {
            popGesture.delegate = self
            popGesture.isEnabled = true
        }
    }
    
    // MARK: - Back handling
    @objc private func backButtonTapped() {
        presentSaveChangesAlert()
    }

    // Intercept the edge-swipe back gesture to show the same alert.
    // We return false to stop the default pop and instead show our alert.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }
       presentSaveChangesAlert()
        return false
    }

    // MARK: - Alert
    private func presentSaveChangesAlert() {
        let alert = UIAlertController(
            title: "Save changes?",
            message: "Would you like to save any changes before exiting?",
            preferredStyle: .alert
        )

        // Save (calls your saveReport with isFinalised = false)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            print("About to save with false")
            saveReport(isFinalised: false)
//            self.popOrDismiss()
        }))

        // Don't Save (discard and go back)
        alert.addAction(UIAlertAction(title: "Don’t Save", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.popOrDismiss()
        }))

        // Cancel (stay on page)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
        }))

        present(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation helper
    private func popOrDismiss() {
        if let nav = navigationController {
//            log.debug("Popping view controller.")
            nav.popViewController(animated: true)
        } else {
//            log.debug("Dismissing presented view controller.")
            dismiss(animated: true, completion: nil)
        }
    }


    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let reportTypeLabel = createLabel(with: "Report Type")
        let customerLabel = createLabel(with: "Customer")
        let siteLabel = createLabel(with: "Site")
        let reportTitleLabel = createLabel(with: "Report Title")
        let pdfStatusLabel = createLabel(with: "PDF Status")
        let notesLabel = createLabel(with: "Notes")
        let signatureLabel = createLabel(with: "Signature")
        
        // --- The order of elements in this array has been changed ---
        pdfStatusStackView.addArrangedSubview(self.pdfStatusLabel)
        pdfStatusStackView.addArrangedSubview(pdfActivityIndicator)
        pdfStatusStackView.addArrangedSubview(pdfButton)

        let stackView = UIStackView(arrangedSubviews: [
            reportTypeLabel, reportTypeTextField,
            customerLabel, customerTextField,
            siteLabel, siteTextField,
            reportTitleLabel, reportTitleTextField,
            pdfStatusLabel, pdfStatusStackView,
            
            // Notes section now comes before the signature
            notesLabel,
            addNoteButton,
            addMultipleImagesButton,
            dragAndDropInstructionLabel,
            notesTableView,
            
            // Signature section is now after the notes
            signatureLabel,
            signatureView,
            
            // Final action buttons
            saveDraftButton, finaliseButton
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // --- The custom spacing has been updated for the new layout ---
        stackView.setCustomSpacing(16, after: reportTypeTextField)
        stackView.setCustomSpacing(16, after: customerTextField)
        stackView.setCustomSpacing(16, after: siteTextField)
        stackView.setCustomSpacing(16, after: reportTitleTextField)
        stackView.setCustomSpacing(24, after: pdfStatusStackView) // Larger gap before Notes section
        
        stackView.setCustomSpacing(16, after: notesLabel)
        stackView.setCustomSpacing(16, after: addMultipleImagesButton)
        stackView.setCustomSpacing(24, after: notesTableView) // Larger gap before Signature section
        
        stackView.setCustomSpacing(24, after: signatureView) // Larger gap before action buttons
        stackView.setCustomSpacing(16, after: saveDraftButton)
        
        contentView.addSubview(stackView)
        
        signatureView.translatesAutoresizingMaskIntoConstraints = false
        
        // Initialize the height constraint for the notes table view with a starting constant of 0.
        notesTableViewHeightConstraint = notesTableView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            signatureView.heightAnchor.constraint(equalToConstant: 250),
            
            // Activate our height constraint for the table view.
            notesTableViewHeightConstraint
        ])
    }
    
    private func createLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupPickers() {
        var reportTypes = ReportType.allCases.map { $0.rawValue }
        reportTypes.insert("Select Report Type", at: 0)
        reportTypePicker.data = reportTypes
        reportTypeTextField.inputView = reportTypePicker.pickerView
        reportTypeTextField.inputAccessoryView = reportTypePicker.getInputAccessoryView()
        reportTypePicker.onSelect = { [weak self] selectedValue in
            guard let self = self, selectedValue != "Select Report Type" else {
                self?.reportTypeTextField.resignFirstResponder()
                return
            }
            self.reportTypeTextField.text = selectedValue
            self.selectedReportType = ReportType(rawValue: selectedValue)
            self.reportTypeTextField.resignFirstResponder()
        }
        
        customerTextField.inputView = customerPicker.pickerView
        customerTextField.inputAccessoryView = customerPicker.getInputAccessoryView()
        customerPicker.onSelect = { [weak self] selectedValue in
            guard let self = self else { return }
            self.customerTextField.resignFirstResponder()
            
            if selectedValue == "Select Customer" {
                self.selectedCustomer = nil
                self.siteTextField.text = ""
                self.selectedSite = nil
                self.siteTextField.isEnabled = false
                self.sitePicker.data = ["Select Site"]
                return
            }
            
            if let selected = self.customers.first(where: { $0.companyName == selectedValue }) {
                self.customerTextField.text = selectedValue
                self.selectedCustomer = selected
                self.siteTextField.text = ""
                self.selectedSite = nil
                self.siteTextField.isEnabled = true
                self.loadSites(for: selected.id)
            }
        }
        
        siteTextField.inputView = sitePicker.pickerView
        siteTextField.inputAccessoryView = sitePicker.getInputAccessoryView()
        sitePicker.onSelect = { [weak self] selectedValue in
            guard let self = self else { return }
            self.siteTextField.resignFirstResponder()
            
            if selectedValue == "Select Site" {
                self.selectedSite = nil
                return
            }
            
            if let selected = self.sites.first(where: { $0.siteName == selectedValue }) {
                self.siteTextField.text = selectedValue
                self.selectedSite = selected
            }
        }
    }
    
    // MARK: - Firebase Data Loading
    private func loadCustomers() {
        guard let parentId = UserSession.shared.userParent, !parentId.isEmpty else {
            print("User parent ID not found.")
            showAlert(title: "Error", message: "Could not find user account details.")
            return
        }
        
        print("Loading customers for parent: \(parentId)...")
        showSpinner()
        databaseRef.child(customersPath).child(parentId).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.hideSpinner()
            
            guard let value = snapshot.value as? [String: Any] else {
                print("Could not decode customers or no customers found.")
                self.showAlert(title: "Error", message: "Could not load customers.")
                return
            }
            
            self.customers = value.compactMap { (key, val) -> Customer? in
                guard let dict = val as? [String: Any] else { return nil }
                var customer = Customer()
                customer.id = key
                customer.companyName = dict["companyName"] as? String ?? "Unknown"
                return customer
            }.sorted { $0.companyName < $1.companyName }
            
            var customerNames = self.customers.map { $0.companyName }
            customerNames.insert("Select Customer", at: 0)
            self.customerPicker.data = customerNames
            print("Successfully loaded \(self.customers.count) customers.")
        } withCancel: { [weak self] error in
            self?.hideSpinner()
            print("Error loading customers: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load customers: \(error.localizedDescription)")
        }
    }
    
        private func configureForEditMode() {
        self.title = "Edit Site Report"
        
        // Disable fields that shouldn't be changed in edit mode
        reportTypeTextField.isEnabled = false
        customerTextField.isEnabled = false
        siteTextField.isEnabled = false
        
        print("Configured for edit mode.")
    }

    private func fetchReportDetails() {
        print("DEBUG: fetchReportDetails called.")
                guard let report = siteAuditReport,
              let parentId = UserSession.shared.userParent, !parentId.isEmpty else {
            print("DEBUG: fetchReportDetails guard failed. Report is \(siteAuditReport == nil ? "nil" : "not nil"), parentId is \(UserSession.shared.userParent ?? "nil").")
            showAlert(title: "Error", message: "Missing report data or user session.")
            return
    }
        
        print("Fetching details for report: \(report.reportId)")
        showSpinner()
        
                let reportRef = databaseRef.child(siteAuditReportsPath).child(parentId).child(report.clientId).child(report.siteId).child(report.reportId)
        print("DEBUG: Firebase path: \(reportRef.url)")
        
        reportRef.observeSingleEvent(of: .value) { [weak self] snapshot in
                        self?.hideSpinner()
            print("DEBUG: Firebase query completed. Snapshot exists: \(snapshot.exists()).")
            guard let self = self, let value = snapshot.value else {
                print("Report data not found or error reading from database.")
                self?.showAlert(title: "Error", message: "Could not load the report details.")
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let decodedReport = try JSONDecoder().decode(SiteAuditReport.self, from: data)
                self.siteAuditReport = decodedReport
                
                DispatchQueue.main.async {
                    self.populateForm(with: decodedReport)
                }
            } catch {
                print("Error decoding report: \(error)")
                self.showAlert(title: "Error", message: "Failed to parse report data.")
            }
        } withCancel: { [weak self] error in
            self?.hideSpinner()
            print("Error fetching report details: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load report details: \(error.localizedDescription)")
        }
    }

        private func populateForm(with report: SiteAuditReport) {
        print("Populating form with data for report: \(report.reportId)")
        
        reportTypeTextField.text = report.reportType
        customerTextField.text = report.clientName
        siteTextField.text = report.siteName
        reportTitleTextField.text = report.reportTitle
        
        // Populate notes
                self.notes = Array(report.notes.values).sorted { $0.order < $1.order }
        reloadNotesTableView()
        
        // Load signature image
        if let signatureUrlString = report.signatureUrl, let signatureUrl = URL(string: signatureUrlString) {
            // Here you would use an image loading library like SDWebImage or Kingfisher
            // For simplicity, we'll use a basic URLSession data task.
            URLSession.shared.dataTask(with: signatureUrl) { [weak self] data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.signatureView.signatureImage = image
                    }
                } else if let error = error {
                    print("Error loading signature image: \(error.localizedDescription)")
                }
            }.resume()
        }
        
        // Set selected objects to ensure they are available for saving
        self.selectedReportType = ReportType(rawValue: report.reportType)
        // We need to create dummy Customer and CustomerSite objects since we don't fetch the full lists in edit mode.
        self.selectedCustomer = Customer(id: report.clientId, companyName: report.clientName)
            self.selectedSite = CustomerSite(id: report.siteId, customerName: report.clientName, siteName: report.siteName)
        
        print("Form populated.")
        setupPDFStatusListener()
    }

    private func loadSites(for customerId: String) {
        guard let parentId = UserSession.shared.userParent, !parentId.isEmpty else {
            print("User parent ID not found.")
            showAlert(title: "Error", message: "Could not find user account details.")
            return
        }
        
        guard let selectedCustomerName = selectedCustomer?.companyName else {
            print("Could not find selected customer name.")
            return
        }
        
        print("Loading sites for parent: \(parentId)...")
        showSpinner()
        databaseRef.child(customerSitesPath).child(parentId).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.hideSpinner()
            
            guard let value = snapshot.value as? [String: Any] else {
                print("Could not decode sites or no sites found.")
                self.sites = []
                self.sitePicker.data = ["Select Site"]
                return
            }
            
            self.sites = value.compactMap { (key, val) -> CustomerSite? in
                guard let dict = val as? [String: Any],
                      let siteCustomerName = dict["customerName"] as? String,
                      siteCustomerName == selectedCustomerName else {
                    return nil
                }
                var site = CustomerSite()
                site.id = key
                site.siteName = dict["siteName"] as? String ?? "Unknown"
                site.customerName = siteCustomerName
                return site
            }.sorted { $0.siteName < $1.siteName }
            
            var siteNames = self.sites.map { $0.siteName }
            siteNames.insert("Select Site", at: 0)
            self.sitePicker.data = siteNames
            print("Successfully loaded \(self.sites.count) sites for customer \(selectedCustomerName).")
        } withCancel: { [weak self] error in
            self?.hideSpinner()
            print("Error loading sites: \(error.localizedDescription)")
            self?.showAlert(title: "Error", message: "Failed to load sites: \(error.localizedDescription)")
        }
    }
    
    // MARK: - PDF Status Handling
    private func setupPDFStatusListener() {
        guard isEditMode, let report = siteAuditReport, let parentId = UserSession.shared.userParent, !parentId.isEmpty else {
            return
        }

        pdfStatusStackView.isHidden = false
        print("DEBUG: Setting up PDF status listener for report: \(report.reportId)")

        let reportRef = databaseRef.child(siteAuditReportsPath).child(parentId).child(report.clientId).child(report.siteId).child(report.reportId)

        pdfStatusListenerHandle = reportRef.observe(.value, with: { [weak self] snapshot in
            guard let self = self, let value = snapshot.value else {
                print("DEBUG: PDF listener callback but no value or self is nil.")
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let decodedReport = try JSONDecoder().decode(SiteAuditReport.self, from: data)
                // Update only the relevant PDF fields in the local model
                self.siteAuditReport?.pdfDownloadUrl = decodedReport.pdfDownloadUrl
                self.siteAuditReport?.pdfGenerationError = decodedReport.pdfGenerationError
                self.siteAuditReport?.pdfGenerationRequested = decodedReport.pdfGenerationRequested
                
                DispatchQueue.main.async {
                    self.updatePDFStatusUI()
                }
            } catch {
                print("Error decoding report for PDF status update: \(error)")
            }
        })
    }

    private func updatePDFStatusUI() {
        guard let report = siteAuditReport else {
            pdfStatusStackView.isHidden = true
            return
        }

        // Hide all components initially
        pdfActivityIndicator.stopAnimating()
        pdfStatusLabel.isHidden = true
        pdfButton.isHidden = true

        if let downloadUrl = report.pdfDownloadUrl, !downloadUrl.isEmpty {
            // PDF is ready
            pdfButton.isHidden = false
            print("DEBUG: PDF is available at \(downloadUrl)")
        } else if let error = report.pdfGenerationError, !error.isEmpty {
            // An error occurred
            pdfStatusLabel.text = "Error: \(error)"
            pdfStatusLabel.textColor = .systemRed
            pdfStatusLabel.isHidden = false
            print("DEBUG: PDF generation failed with error: \(error)")
        } else if report.pdfGenerationRequested {
            // PDF generation is in progress
            pdfActivityIndicator.startAnimating()
            pdfStatusLabel.text = "Generating PDF..."
            pdfStatusLabel.textColor = .darkGray
            pdfStatusLabel.isHidden = false
            print("DEBUG: PDF generation is in progress.")
        } else {
            // Default state: PDF not generated
            pdfStatusLabel.text = "PDF not generated"
            pdfStatusLabel.textColor = .darkGray
            pdfStatusLabel.isHidden = false
            print("DEBUG: PDF has not been generated.")
        }
    }

    @objc private func pdfButtonTapped() {
        guard let pdfUrlString = siteAuditReport?.pdfDownloadUrl, let url = URL(string: pdfUrlString) else {
            showAlert(title: "Error", message: "The PDF URL is invalid.")
            return
        }

        print("Opening PDF in browser from: \(url.absoluteString)")

        // Present the URL in an in-app browser
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }

    // MARK: - Actions & Data Persistence
    @objc private func saveDraftTapped() {
        saveReport(isFinalised: false)
    }

    @objc private func finaliseTapped() {
        saveReport(isFinalised: true)
    }

    private func saveReport(isFinalised: Bool) {
        print("Just about to start saving and the mode is \(isFinalised)")
        if isEditMode {
            print("We're in edit mode and I'm saving")
            updateReport(isFinalised: isFinalised)
        } else {
            print("We're NOT in edit mode and I'm saving")
            createReport(isFinalised: isFinalised)
        }
    }
    
    private func updateReport(isFinalised: Bool) {
        print("About to start updating the report now...")
        if let validationError = validateFields(isFinalising: isFinalised) {
            showAlert(title: "Missing Information", message: validationError)
            return
        }

        guard let existingReport = self.siteAuditReport,
              let parentId = UserSession.shared.userParent, !parentId.isEmpty,
              let title = reportTitleTextField.text else {
            showAlert(title: "Error", message: "Could not proceed with saving. Internal data is missing.")
            return
        }

        showSpinner()

        let reportRef = databaseRef.child(siteAuditReportsPath).child(parentId).child(existingReport.clientId).child(existingReport.siteId).child(existingReport.reportId)

        // Create an updated report object from the form data
        var updatedReport = existingReport
        updatedReport.reportTitle = title
        updatedReport.status = isFinalised ? "Finalized" : "Draft"
        updatedReport.isFinalized = isFinalised
        if isFinalised {
            updatedReport.pdfGenerationRequested = true
            if updatedReport.finalizedAt == nil {
                // Set finalized timestamp only if it's being finalized for the first time
                updatedReport.finalizedAt = Date().timeIntervalSince1970
            }
        }

        // For a complete implementation, you would ideally check if the signature has actually changed
        // before re-uploading. This requires a modification to SignatureCaptureView to track changes.
        // For now, we re-upload if a signature image is present.
        if let signatureImage = signatureView.signatureImage {
            let signatureData = signatureImage.pngData() ?? Data()
            let signatureRef = storageRef.child("\(siteAuditReportsPath)/\(parentId)/\(existingReport.clientId)/\(existingReport.siteId)/\(existingReport.reportId)/signature.png")

            signatureRef.putData(signatureData, metadata: nil) { [weak self] (metadata, error) in
                guard let self = self else { return }
                if let error = error {
                    self.hideSpinner()
                    self.showAlert(title: "Upload Error", message: "Failed to upload signature: \(error.localizedDescription)")
                    return
                }

                signatureRef.downloadURL { (url, error) in
                    if let error = error {
                        self.hideSpinner()
                        self.showAlert(title: "Upload Error", message: "Failed to get signature URL: \(error.localizedDescription)")
                        return
                    }
                    updatedReport.signatureUrl = url?.absoluteString
                    self.uploadNotesImagesAndSave(report: updatedReport, at: reportRef)
                }
            }
        } else {
            // If the signature was cleared, update the URL to nil.
            updatedReport.signatureUrl = nil
            self.uploadNotesImagesAndSave(report: updatedReport, at: reportRef)
        }
    }

    
    private func createReport(isFinalised: Bool) {
        if let validationError = validateFields(isFinalising: isFinalised) {
            showAlert(title: "Missing Information", message: validationError)
            return
        }
        
        guard let parentId = UserSession.shared.userParent, !parentId.isEmpty,
              let customer = selectedCustomer,
              let site = selectedSite,
              let reportType = selectedReportType,
              let title = reportTitleTextField.text,
              let userId = auth.currentUser?.uid
        else {
            showAlert(title: "Error", message: "Could not proceed with saving. Internal data is missing.")
            return
        }
        
        showSpinner()
        
        let reportRef = databaseRef.child(siteAuditReportsPath).child(parentId).child(customer.id).child(site.id).childByAutoId()
        let reportId = reportRef.key ?? UUID().uuidString
        
        if let signatureImage = signatureView.signatureImage {
            let signatureData = signatureImage.pngData() ?? Data()
            let signatureRef = storageRef.child("\(siteAuditReportsPath)/\(parentId)/\(customer.id)/\(site.id)/\(reportId)/signature.png")
            
            signatureRef.putData(signatureData, metadata: nil) { [weak self] (metadata, error) in
                guard let self = self else { return }
                if let error = error {
                    self.hideSpinner()
                    self.showAlert(title: "Upload Error", message: "Failed to upload signature: \(error.localizedDescription)")
                    return
                }
                
                signatureRef.downloadURL { (url, error) in
                    if let error = error {
                        self.hideSpinner()
                        self.showAlert(title: "Upload Error", message: "Failed to get signature URL: \(error.localizedDescription)")
                        return
                    }
                    
                    var report = SiteAuditReport(
                        reportId: reportId,
                        reportType: reportType.firebaseValue,
                        reportTitle: title,
                        clientId: customer.id,
                        clientName: customer.companyName,
                        siteId: site.id,
                        siteName: site.siteName,
                        createdBy: userId,
                        isFinalised: isFinalised
                    )
                    report.signatureUrl = url?.absoluteString
                    if isFinalised {
                        report.pdfGenerationRequested = true
                    }
                    
                    self.uploadNotesImagesAndSave(report: report, at: reportRef)
                }
            }
        } else {
            // No signature to upload, proceed directly to saving data
            var report = SiteAuditReport(
                reportId: reportId,
                reportType: reportType.firebaseValue,
                reportTitle: title,
                clientId: customer.id,
                clientName: customer.companyName,
                siteId: site.id,
                siteName: site.siteName,
                createdBy: userId,
                isFinalised: isFinalised
            )
            if isFinalised {
                report.pdfGenerationRequested = true
            }
            self.uploadNotesImagesAndSave(report: report, at: reportRef)
        }
    }
    
    
//    private func uploadNotesImagesAndSave(report: SiteAuditReport, at ref: DatabaseReference) {
//        let group = DispatchGroup()
//        var reportToSave = report
//        // Create a mutable copy of the notes to update with new URLs
//        var finalNotes = self.notes
//
//        // This dictionary will safely store the mapping from a note's ID to its new download URL.
//        var uploadedURLMapping = [String: String]()
//        // A serial queue to synchronize access to the dictionary from multiple concurrent uploads.
//        let mappingQueue = DispatchQueue(label: "com.amsitesolutions.urlMappingQueue")
//        
//        // Iterate over the notes again to find annotated images that need uploading.
//        // This block should be present in your upload function
//        // Iterate over the notes again to find annotated images that need uploading.
//        for note in self.notes {
//            // Only upload notes that have a local annotated image.
//            guard let annotatedImage = note.localAnnotatedImage else {
//                continue
//            }
//            
//            guard let imageData = annotatedImage.jpegData(compressionQuality: 0.8) else {
//                print("Could not get JPEG data for annotated image in note \(note.noteId)")
//                continue
//            }
//            
//            group.enter()
//            // Use a distinct filename for the annotated image in storage.
//            let imageRef = storageRef.child("\(siteAuditReportsPath)/\(report.reportId)/\(note.noteId)_annotated.jpg")
//            
//            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
//                if let error = error {
//                    print("Error uploading annotated note image for note \(note.noteId): \(error.localizedDescription)")
//                    group.leave()
//                    return
//                }
//                
//                imageRef.downloadURL { (url, error) in
//                    if let url = url {
//                        print("Annotated note image uploaded: \(url.absoluteString)")
//                        // Safely update our mapping dictionary for the annotated image.
//                        mappingQueue.async {
//                            if let index = finalNotes.firstIndex(where: { $0.noteId == note.noteId }) {
//                                finalNotes[index].annotatedImageUrl = url.absoluteString
//                            }
//                            group.leave()
//                        }
//                    } else {
//                        print("Error getting download URL for annotated image: \(error?.localizedDescription ?? "Unknown error")")
//                        group.leave()
//                    }
//                }
//            }
//        }
//        
//        // This will be executed only after all image upload tasks have completed.
//        group.notify(queue: .main) {
//            print("All image uploads complete. Merging URLs.")
//            
//            // Merge the newly uploaded URLs back into our notes array.
//            // We iterate by index to modify the array in place.
//            for i in 0..<finalNotes.count {
//                let noteId = finalNotes[i].noteId
//                if let urlString = uploadedURLMapping[noteId] {
//                    finalNotes[i].imageUrl = urlString
//                }
//            }
//            
//            // Now, convert the updated array of notes into the dictionary format required by Firebase.
//            let notesDict = Dictionary(uniqueKeysWithValues: finalNotes.map { ($0.noteId, $0) })
//            reportToSave.notes = notesDict
//            
//            // Finally, persist the entire updated report object to the database.
//            self.persistReportData(reportToSave, at: ref)
//        }
//    }
    
    
    private func uploadNotesImagesAndSave(report: SiteAuditReport, at ref: DatabaseReference) {
    let group = DispatchGroup()
    var reportToSave = report
    var finalNotes = self.notes // A mutable copy of the notes to update with URLs

    // Base path for storing images for this specific report
    let reportStorageRef = storageRef.child("\(siteAuditReportsPath)/\(report.reportId)")

    for (index, note) in finalNotes.enumerated() {
        // --- Upload Original Image ---
        // If a local image exists, it's considered new or updated and needs to be uploaded.
        if let localImage = note.localImage {
            guard let imageData = localImage.jpegData(compressionQuality: 0.8) else {
                print("Could not get JPEG data for note \(note.noteId)")
                continue
            }
            
            group.enter()
            let imageRef = reportStorageRef.child("\(note.noteId)_image.jpg")
            
            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading original image for note \(note.noteId): \(error.localizedDescription)")
                    group.leave() // IMPORTANT: Always leave the group
                    return
                }
                
                imageRef.downloadURL { (url, error) in
                    if let url = url {
                        // Safely update the note in our mutable array
                        finalNotes[index].imageUrl = url.absoluteString
                    } else if let error = error {
                        print("Error getting download URL for original image for note \(note.noteId): \(error.localizedDescription)")
                    }
                    group.leave() // IMPORTANT: Always leave the group
                }
            }
        }

        // --- Upload Annotated Image ---
        // If a local annotated image exists, it's considered new or updated and needs to be uploaded.
        if let localAnnotatedImage = note.localAnnotatedImage {
            guard let annotatedImageData = localAnnotatedImage.jpegData(compressionQuality: 0.8) else {
                print("Could not get JPEG data for annotated image in note \(note.noteId)")
                continue
            }
            
            group.enter()
            let annotatedImageRef = reportStorageRef.child("\(note.noteId)_annotated_image.jpg")
            
            annotatedImageRef.putData(annotatedImageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading annotated image for note \(note.noteId): \(error.localizedDescription)")
                    group.leave()
                    return
                }
                
                annotatedImageRef.downloadURL { (url, error) in
                    if let url = url {
                        finalNotes[index].annotatedImageUrl = url.absoluteString
                    } else if let error = error {
                        print("Error getting download URL for annotated image for note \(note.noteId): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
    }

    // This block will execute only after all image uploads are complete
    group.notify(queue: .main) {
        // Convert the final notes array (now with URLs) into the dictionary format for Firebase
        reportToSave.notes = finalNotes.reduce(into: [String: SiteAuditNote]()) { dict, note in
            // Create a clean copy of the note for saving, without local images
            var noteToSave = note
            noteToSave.localImage = nil
            noteToSave.localAnnotatedImage = nil
            dict[note.noteId] = noteToSave
        }

        do {
            // Encode the final report object to a dictionary
            let reportData = try reportToSave.asDictionary()
            
            // Save the entire report to the database
            ref.setValue(reportData) { [weak self] (error, ref) in
                self?.hideSpinner()
                if let error = error {
                    self?.showAlert(title: "Save Error", message: "Failed to save report: \(error.localizedDescription)")
                } else {
                    let successMessage = self?.isEditMode ?? false ? "Report updated successfully." : "Report created successfully."
                    self?.showAlert(title: "Success", message: successMessage) {
                        // Go back to the previous screen on success
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } catch {
            self.hideSpinner()
            self.showAlert(title: "Save Error", message: "Could not encode report data for saving: \(error.localizedDescription)")
        }
    }
}

    private func persistReportData(_ report: SiteAuditReport, at ref: DatabaseReference) {
            do {
                // Use JSONEncoder to convert the Codable struct into Data, respecting CodingKeys and custom logic.
                let data = try JSONEncoder().encode(report)
                // Convert the Data into a dictionary [String: Any] that Firebase requires.
                let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]

                ref.setValue(dictionary) { [weak self] (error, ref) in
                    guard let self = self else { return }
                    self.hideSpinner()
                    
                    if let error = error {
                        print("Error saving report data: \(error.localizedDescription)")
                        self.showAlert(title: "Save Error", message: "Failed to save report data: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Report saved successfully at path: \(ref.url)")
                    let successMessage = report.isFinalized ? "Report finalised successfully." : "Draft saved successfully."
                    self.showAlert(title: "Success", message: successMessage) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                hideSpinner()
                print("Error encoding report or converting to dictionary: \(error.localizedDescription)")
                showAlert(title: "Save Error", message: "Failed to prepare report for saving: \(error.localizedDescription)")
            }
        }

    private func presentNoteEditor(with note: SiteAuditNote) {
        let editorVC = NoteEditorViewController(note: note)
        editorVC.delegate = self
        let navController = UINavigationController(rootViewController: editorVC)
        present(navController, animated: true)
    }


    // MARK: - Validation
    private func validateFields(isFinalising: Bool) -> String? {
        if selectedReportType == nil {
            return "Please select a report type."
        }
        if selectedCustomer == nil {
            return "Please select a customer."
        }
        if selectedSite == nil {
            return "Please select a site."
        }
        if reportTitleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            return "Please enter a report title."
        }
        // Signature is only mandatory when finalising
        if isFinalising && signatureView.signatureImage == nil {
            return "A signature is required to finalise the report."
        }
        return nil
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }

    private func showSpinner() {
        spinnerOverlay = UIView(frame: view.bounds)
        spinnerOverlay!.backgroundColor = UIColor(white: 0, alpha: 0.5)
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = spinnerOverlay!.center
        activityIndicator.startAnimating()
        spinnerOverlay!.addSubview(activityIndicator)
        view.addSubview(spinnerOverlay!)
    }

    private func hideSpinner() {
        DispatchQueue.main.async {
            self.spinnerOverlay?.removeFromSuperview()
            self.spinnerOverlay = nil
        }
    }

    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    
    private func presentAnnotator(for note: SiteAuditNote, at index: Int) {
        // Determine the source image for annotation, prioritising the already annotated one.
        let imageToAnnotate: UIImage?
        if let annotated = note.localAnnotatedImage {
            imageToAnnotate = annotated
        } else if let original = note.localImage {
            imageToAnnotate = original
        } else {
            // If no local image, try to get it from the cache if it was downloaded for the cell.
            let key = note.annotatedImageUrl ?? note.imageUrl
            if let urlString = key, let cachedImage = ImageCache.shared.image(forKey: urlString) {
                imageToAnnotate = cachedImage
            } else {
                showAlert(title: "Image Not Ready", message: "The image is still downloading. Please try again in a moment.")
                return
            }
        }

        guard let sourceImage = imageToAnnotate else {
            showAlert(title: "Error", message: "No image available to annotate.")
            return
        }

        let annotatorVC = AnnotateImageViewController(image: sourceImage)
        annotatorVC.onSave = { [weak self] annotatedImage in
            guard let self = self else { return }
            
            // Update the note with the new annotated image
            self.notes[index].localAnnotatedImage = annotatedImage
            
            // Refresh the UI to show the new thumbnail
            self.reloadNotesTableView()
        }
        
        let navController = UINavigationController(rootViewController: annotatorVC)
        present(navController, animated: true)
    }

    @objc private func imageTappedForAnnotation(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view else { return }
        let noteIndex = imageView.tag
        
        guard noteIndex >= 0 && noteIndex < self.notes.count else { return }
        
        let note = self.notes[noteIndex]
        
        // Dismiss the current alert before presenting the annotator
        presentedViewController?.dismiss(animated: true, completion: {
            self.presentAnnotator(for: note, at: noteIndex)
        })
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    private func setupAnnotationForImageView(_ imageView: UIImageView, at index: Int) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTappedForAnnotation(_:)))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        imageView.tag = index
    }

    // MARK: - Notes Management
    private func setupNotesTableView() {
        notesTableView.dataSource = self
        notesTableView.delegate = self
        notesTableView.dragInteractionEnabled = true
        notesTableView.dragDelegate = self
        notesTableView.dropDelegate = self
    }

    @objc private func addNoteTapped() {
        print("Add Note tapped")
        let newNote = SiteAuditNote(order: notes.count, description: nil)
        let editorVC = NoteEditorViewController(note: newNote)
        editorVC.delegate = self
        let navController = UINavigationController(rootViewController: editorVC)
        present(navController, animated: true)
    }

    @objc private func addMultipleImagesTapped() {
        print("Add Multiple Images tapped")
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0 means no limit
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func updateNotesOrder() {
        for (index, note) in notes.enumerated() {
            notes[index].order = index
        }
        print("Notes order updated.")
    }

    
    private func reloadNotesTableView() {
        notesTableView.reloadData()
        
        // --- RELIABLE HEIGHT CALCULATION ---
        // Instead of relying on the table view's contentSize, which can be unreliable
        // during layout updates, we will manually calculate the required height.
        // The height of each row is fixed at 104 points (12 top padding + 80 image height + 12 bottom padding).
        let rowHeight: CGFloat = 104.0
        let newHeight = CGFloat(self.notes.count) * rowHeight
        
        // Since this calculation is synchronous, we no longer need DispatchQueue.main.async.
        if self.notesTableViewHeightConstraint.constant != newHeight {
            self.notesTableViewHeightConstraint.constant = newHeight
            
            // Animate the layout change for a smooth UI update.
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        
        // Update visibility of drag and drop instruction label
        dragAndDropInstructionLabel.isHidden = !(notes.count > 2)
    }

}




// MARK: - UITableViewDataSource, UITableViewDelegate
extension CreateSiteAuditReportViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell", for: indexPath) as! NoteTableViewCell
        let note = notes[indexPath.row]
        cell.configure(with: note)
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = notes[indexPath.row]
        print("Selected note at index \(indexPath.row) with ID: \(note.noteId)")

        // Task: Ensure both annotated (if exists) and original images are loaded locally before presenting the editor.
        
        let needsAnnotatedDownload = note.localAnnotatedImage == nil && note.annotatedImageUrl != nil
        let needsOriginalDownload = note.localImage == nil && note.imageUrl != nil

        let presentEditor = { [weak self] in
            guard let self = self else { return }
            // Always use the latest version of the note from the array
            let finalNote = self.notes[indexPath.row]
            self.presentNoteEditor(with: finalNote)
        }

        if needsAnnotatedDownload {
            // Must download annotated, then check if original is also needed.
            downloadImage(from: note.annotatedImageUrl!, for: indexPath, isAnnotated: true) { [weak self] success in
                guard let self = self, success else {
                    // If annotated fails, try to show editor with original
                    if needsOriginalDownload {
                        self?.downloadImage(from: note.imageUrl!, for: indexPath, isAnnotated: false) { _ in presentEditor() }
                    } else {
                        presentEditor()
                    }
                    return
                }
                
                // Annotated succeeded. Now ensure original is also loaded.
                let updatedNote = self.notes[indexPath.row]
                if updatedNote.localImage == nil && updatedNote.imageUrl != nil {
                    self.downloadImage(from: updatedNote.imageUrl!, for: indexPath, isAnnotated: false) { _ in presentEditor() }
                } else {
                    presentEditor()
                }
            }
        } else if needsOriginalDownload {
            // Only original needs downloading.
            downloadImage(from: note.imageUrl!, for: indexPath, isAnnotated: false) { _ in presentEditor() }
        } else {
            // No downloads needed.
            print("DEBUG: All required images are local. Presenting editor.")
            presentEditor()
        }
    }
    

    private func downloadImage(from urlString: String, for indexPath: IndexPath, isAnnotated: Bool, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            print("DEBUG: Image found in cache for \(isAnnotated ? "annotated" : "original").")
            if isAnnotated {
                self.notes[indexPath.row].localAnnotatedImage = cachedImage
            } else {
                self.notes[indexPath.row].localImage = cachedImage
            }
            completion(true)
            return
        }

        print("DEBUG: Starting download for \(isAnnotated ? "annotated" : "original") image...")
        showSpinner()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.hideSpinner()
                guard let self = self else {
                    completion(false)
                    return
                }

                guard let data = data, let image = UIImage(data: data), error == nil else {
                    print("DEBUG: Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                    return
                }

                print("DEBUG: Image downloaded successfully.")
                ImageCache.shared.setImage(image, forKey: urlString)
                
                if isAnnotated {
                    self.notes[indexPath.row].localAnnotatedImage = image
                } else {
                    self.notes[indexPath.row].localImage = image
                }
                completion(true)
            }
        }.resume()
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleting note at index \(indexPath.row)")
            notes.remove(at: indexPath.row)
            updateNotesOrder()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            reloadNotesTableView()
        }
    }
}

// MARK: - UITableViewDragDelegate, UITableViewDropDelegate
extension CreateSiteAuditReportViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = notes[indexPath.row]
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Ensure we are only handling drags that started within our app.
        guard session.localDragSession != nil else {
            return UITableViewDropProposal(operation: .cancel)
        }
        
        // Propose a 'move' operation, which tells the table view to animate the row into the new spot.
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // We only handle one item at a time in this implementation.
        guard let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else {
            return
        }

        // Determine the destination. If the user drops past the last row, this might be nil.
        // We'll use the source index path as a fallback, though a real drop will have a destination.
        let destinationIndexPath = coordinator.destinationIndexPath ?? sourceIndexPath

        // Use performBatchUpdates to safely animate the data source change.
        tableView.performBatchUpdates({
            // 1. Update the data source: remove the note from its old location.
            let movedNote = self.notes.remove(at: sourceIndexPath.row)
            
            // 2. Insert the note into its new location in the data source.
            self.notes.insert(movedNote, at: destinationIndexPath.row)
            
            // 3. Tell the table view to animate the move from the old path to the new path.
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            
        }, completion: { _ in
            // 4. After the animation is complete, update the 'order' property on all notes.
            self.updateNotesOrder()
        })
    }
    
    
}



// MARK: - PHPickerViewControllerDelegate
extension CreateSiteAuditReportViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        let group = DispatchGroup()
        var newNotes: [SiteAuditNote] = []

        for result in results {
            group.enter()
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            // This is the corrected line:
                            let newNote = SiteAuditNote(order: self?.notes.count ?? 0, description: nil, localImage: image)
                            newNotes.append(newNote)
                            print("Image loaded for a new note.")
                        }
                        group.leave()
                    }
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.notes.append(contentsOf: newNotes)
            self.updateNotesOrder()
            self.reloadNotesTableView()
            print("\(newNotes.count) new notes added from multiple images.")
        }
    }
}


// MARK: - NoteEditorViewControllerDelegate
extension CreateSiteAuditReportViewController: NoteEditorViewControllerDelegate {
    // The method must be 'fileprivate' to match the access level of the private NoteEditorViewController
    // and the fileprivate protocol.
    internal func noteEditor(_ editor: NoteEditorViewController, didSave note: SiteAuditNote) {
        // Find the index of the note if it already exists.
        if let index = notes.firstIndex(where: { $0.noteId == note.noteId }) {
            // It exists, so update it.
            notes[index] = note
            print("Note updated: \(note.noteId)")
        } else {
            // It's a new note, so add it to the end of the list.
            notes.append(note)
            print("New note added: \(note.noteId)")
        }
        // After any change, update the order of all notes and reload the table.
        updateNotesOrder()
        reloadNotesTableView()
    }
}



// MARK: - UIImagePickerControllerDelegate
extension CreateSiteAuditReportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // This will be used by the NoteEditorViewController, but the delegate needs to be here
    // to be assigned. We will handle the image picking result within the NoteEditor itself.
}

// MARK: - SignatureCaptureView (Nested Helper Class)
// MARK: - NoteTableViewCell (Nested Helper Class)
private class NoteTableViewCell: UITableViewCell {
    private let noteImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 3
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
        contentView.addSubview(noteImageView)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            noteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            noteImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            noteImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            noteImageView.widthAnchor.constraint(equalToConstant: 80),
            noteImageView.heightAnchor.constraint(equalToConstant: 80),

            descriptionLabel.leadingAnchor.constraint(equalTo: noteImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            descriptionLabel.centerYAnchor.constraint(equalTo: noteImageView.centerYAnchor)
        ])
    }

    
    func configure(with note: SiteAuditNote) {
        descriptionLabel.text = note.description ?? ""
        
        // Reset image before loading new one
        noteImageView.image = UIImage(systemName: "photo")

        // Prioritise showing annotated images, local first, then remote.
        if let localAnnotatedImage = note.localAnnotatedImage {
            noteImageView.image = localAnnotatedImage
        } else if let annotatedImageUrlString = note.annotatedImageUrl, let url = URL(string: annotatedImageUrlString) {
            loadImage(from: url)
        // Fallback to original images, local first, then remote.
        } else if let localImage = note.localImage {
            noteImageView.image = localImage
        } else if let imageUrlString = note.imageUrl, let url = URL(string: imageUrlString) {
            loadImage(from: url)
        } else {
            noteImageView.image = UIImage(systemName: "photo") // Placeholder
        }
    }
    
    private func loadImage(from url: URL) {
        // Use shared cache to avoid re-downloading
        if let cachedImage = ImageCache.shared.image(forKey: url.absoluteString) {
            self.noteImageView.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                ImageCache.shared.setImage(image, forKey: url.absoluteString)
                DispatchQueue.main.async {
                    self.noteImageView.image = image
                }
            }
        }.resume()
    }
}

//}

//// MARK: - NoteEditorViewController (Nested Controller)
//fileprivate protocol NoteEditorViewControllerDelegate: AnyObject {
//    func noteEditor(_ editor: NoteEditorViewController, didSave note: SiteAuditNote)
//}
//
//
//private class NoteEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
//    
//    weak var delegate: NoteEditorViewControllerDelegate?
//    private var note: SiteAuditNote
//    
//    private let descriptionTextField = CustomTextField()
//    private let imageView = UIImageView()
//    private let addPhotoButton = CustomButton(type: .system)
//    private let deletePhotoButton = CustomButton(type: .system)
//    private let revertToOriginalButton = CustomButton(type: .system)
//
//    init(note: SiteAuditNote) {
//        self.note = note
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        title = note.description == nil || note.description!.isEmpty ? "Add Note" : "Edit Note"
//        setupNavigation()
//        setupUI()
//        configureViews()
//    }
//
//    private func setupNavigation() {
//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
//    }
//
//    private func setupUI() {
//        descriptionTextField.setPlaceholder("Enter note description...")
//        
//        imageView.contentMode = .scaleAspectFit
//        imageView.clipsToBounds = true
//        imageView.backgroundColor = .secondarySystemBackground
//        imageView.layer.cornerRadius = 10
//        imageView.layer.borderColor = UIColor.lightGray.cgColor
//        imageView.layer.borderWidth = 1
//
//        // Make the image view interactive and add the gesture recognizer
//        imageView.isUserInteractionEnabled = true
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed))
//        imageView.addGestureRecognizer(longPressGesture)
//        
//        addPhotoButton.setTitle("Add/Change Photo", for: .normal)
//        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
//        
//        deletePhotoButton.setTitle("Delete Photo", for: .normal)
//        deletePhotoButton.customBackgroundColor = .systemRed
//        deletePhotoButton.addTarget(self, action: #selector(deletePhotoTapped), for: .touchUpInside)
//        
//        revertToOriginalButton.setTitle("Revert to Original", for: .normal)
//        revertToOriginalButton.customBackgroundColor = .systemOrange
//        revertToOriginalButton.addTarget(self, action: #selector(revertToOriginalTapped), for: .touchUpInside)
//
//        let stackView = UIStackView(arrangedSubviews: [descriptionTextField, imageView, addPhotoButton, deletePhotoButton, revertToOriginalButton])
//        stackView.axis = .vertical
//        stackView.spacing = 16
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            
//            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),
//            imageView.heightAnchor.constraint(equalToConstant: 200)
//        ])
//    }
//
//    private func configureViews() {
//        descriptionTextField.text = note.description
//        imageView.image = note.localAnnotatedImage ?? note.localImage
//        updateButtonVisibility()
//    }
//
//    private func updateButtonVisibility() {
//        deletePhotoButton.isHidden = note.localImage == nil && note.imageUrl == nil
//        revertToOriginalButton.isHidden = note.localAnnotatedImage == nil && note.annotatedImageUrl == nil
//    }
//    
//    @objc private func imageLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
//        // We only want to trigger on the beginning of the press
//        if gestureRecognizer.state == .began {
//            print("Image long-pressed. Attempting to open annotator.")
//            presentAnnotator()
//        }
//    }
//
//    private func presentAnnotator() {
//        // Determine the source image for annotation.
//        // Prioritise the already-annotated image, then the original.
//        guard let imageToAnnotate = self.note.localAnnotatedImage ?? self.note.localImage else {
//            print("Annotation requested, but no image is available on the note.")
//            let alert = UIAlertController(title: "No Image", message: "There is no image to annotate.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//            return
//        }
//
//        let annotatorVC = AnnotateImageViewController(image: imageToAnnotate)
//        annotatorVC.onSave = { [weak self] annotatedImage in
//            guard let self = self else { return }
//            
//            // Update the note's local annotated image and refresh the UI
//            self.note.localAnnotatedImage = annotatedImage
//            self.imageView.image = annotatedImage
//            self.updateButtonVisibility() // The revert button should now be visible
//            print("Annotation saved. Local annotated image updated.")
//        }
//        
//        let navController = UINavigationController(rootViewController: annotatorVC)
//        present(navController, animated: true)
//    }
//
//    @objc private func cancelTapped() {
//        dismiss(animated: true)
//    }
//
//    @objc private func saveTapped() {
//        note.description = descriptionTextField.text
//        delegate?.noteEditor(self, didSave: note)
//        dismiss(animated: true)
//    }
//
//    @objc private func addPhotoTapped() {
//        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in self.openCamera() }))
//        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in self.openGallery() }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        present(alert, animated: true)
//    }
//
//    @objc private func deletePhotoTapped() {
//        note.localImage = nil
//        note.imageUrl = nil
//        note.localAnnotatedImage = nil
//        note.annotatedImageUrl = nil
//        imageView.image = nil
//        updateButtonVisibility()
//        print("Photo deleted.")
//    }
//    
//    @objc private func revertToOriginalTapped() {
//        print("Reverting to original image.")
//        note.annotatedImageUrl = nil
//        note.localAnnotatedImage = nil
//        imageView.image = note.localImage // Display the original local image
//        updateButtonVisibility()
//    }
//
//    private func openCamera() {
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            let picker = UIImagePickerController()
//            picker.sourceType = .camera
//            picker.delegate = self
//            present(picker, animated: true)
//        } else {
//            let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//        }
//    }
//
//    private func openGallery() {
//        var config = PHPickerConfiguration()
//        config.selectionLimit = 1
//        config.filter = .images
//        let picker = PHPickerViewController(configuration: config)
//        picker.delegate = self
//        present(picker, animated: true)
//    }
//    
//    // MARK: - UIImagePickerControllerDelegate
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true)
//        guard let image = info[.originalImage] as? UIImage else {
//            print("No image found")
//            return
//        }
//        note.localImage = image
//        note.localAnnotatedImage = nil
//        imageView.image = image
//        updateButtonVisibility()
//        print("Image picked from camera.")
//    }
//    
//    // MARK: - PHPickerViewControllerDelegate
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true)
//        guard let result = results.first else { return }
//        
//        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
//            if let image = object as? UIImage {
//                DispatchQueue.main.async {
//                    self?.note.localImage = image
//                    self?.note.localAnnotatedImage = nil
//                    self?.imageView.image = image
//                    self?.updateButtonVisibility()
//                    print("Image picked from gallery.")
//                }
//            }
//        }
//    }
//}



// MARK: - NoteEditorViewControllerDelegate (file-scope, internal)
protocol NoteEditorViewControllerDelegate: AnyObject {
    func noteEditor(_ editor: NoteEditorViewController, didSave note: SiteAuditNote)
}

// MARK: - NoteEditorViewController
final class NoteEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate,
                                      UIAdaptivePresentationControllerDelegate {
    
    // MARK: Dependencies & State
    weak var delegate: NoteEditorViewControllerDelegate?
    private var note: SiteAuditNote
    private var noteIsDirty: Bool = false
    
    // MARK: UI
    private let descriptionTextField = CustomTextField()
    private let imageView = UIImageView()
    private let addPhotoButton = CustomButton(type: .system)
    private let deletePhotoButton = CustomButton(type: .system)
    private let revertToOriginalButton = CustomButton(type: .system)
    
    // MARK: Init
    init(note: SiteAuditNote) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = (note.description?.isEmpty ?? true) ? "Add Note" : "Edit Note"
        setupNavigation()
        setupUI()
        configureViews()
        
        descriptionTextField.addTarget(self, action: #selector(descriptionChanged), for: .editingChanged)
        
        log("View loaded. Dirty=\(noteIsDirty)")
        
        // Important: hook into the presentation controller(s)
        presentationController?.delegate = self
        navigationController?.presentationController?.delegate = self

        // If already dirty (rare on first load), prevent swipe-to-dismiss
        isModalInPresentation = noteIsDirty
        navigationController?.isModalInPresentation = noteIsDirty

        log("Presentation delegates set. isModalInPresentation=\(isModalInPresentation)")
    }
    
    // MARK: Logging
    private func log(_ message: String) {
        print("[NoteEditorVC] \(message)")
    }
    
    // MARK: Nav
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    // MARK: UI build
    func setupUI() {
        descriptionTextField.setPlaceholder("Enter note description…")
        
        let annotateInstructionLabel = UILabel()
        annotateInstructionLabel.text = "Long Press on the Image to Draw or Annotate"
        annotateInstructionLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        annotateInstructionLabel.textColor = ColorScheme.amPink // Assuming ColorScheme.amPink is defined elsewhere
        annotateInstructionLabel.textAlignment = .center
        annotateInstructionLabel.numberOfLines = 0
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 10
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 1
        imageView.isUserInteractionEnabled = true
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed))
        imageView.addGestureRecognizer(longPressGesture)
        
        addPhotoButton.setTitle("Add/Change Photo", for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        
        deletePhotoButton.setTitle("Delete Photo", for: .normal)
        deletePhotoButton.customBackgroundColor = .systemRed
        deletePhotoButton.addTarget(self, action: #selector(deletePhotoTapped), for: .touchUpInside)
        
        revertToOriginalButton.setTitle("Revert to Original", for: .normal)
        revertToOriginalButton.customBackgroundColor = .systemOrange
        revertToOriginalButton.addTarget(self, action: #selector(revertToOriginalTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [descriptionTextField, annotateInstructionLabel, imageView, addPhotoButton, deletePhotoButton, revertToOriginalButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        log("UI set up.")
    }
    
    func configureViews() {
        descriptionTextField.text = note.description
        imageView.image = note.localAnnotatedImage ?? note.localImage
        updateButtonVisibility()
        log("Views configured. Description set, image applied.")
    }
    
    func updateButtonVisibility() {
        deletePhotoButton.isHidden = (note.localImage == nil && note.imageUrl == nil)
        revertToOriginalButton.isHidden = (note.localAnnotatedImage == nil && note.annotatedImageUrl == nil)
        log("Button visibility updated. delete=\(!deletePhotoButton.isHidden), revert=\(!revertToOriginalButton.isHidden)")
    }
    
    // MARK: Dirty handling
    @objc private func descriptionChanged() {
        noteIsDirty = true
        log("Dirty set (description changed).")
    }
    
    private func markDirty(reason: String) {
        noteIsDirty = true
        // Prevent pull-to-dismiss while dirty
        isModalInPresentation = true
        navigationController?.isModalInPresentation = true
        log("Dirty set (\(reason)). Swipe-to-dismiss disabled.")
    }
    
    // MARK: Actions
    @objc private func cancelTapped() {
        guard noteIsDirty else {
            log("Cancel tapped with no changes — dismissing.")
            dismiss(animated: true)
            return
        }
        
        log("Cancel tapped with unsaved changes — prompting.")
        showDiscardChangesAlert()
    }
    
    // MARK: - Discard confirmation
    private func showDiscardChangesAlert() {
        let alert = UIAlertController(
            title: "Discard changes?",
            message: "You’ve unsaved changes. Are you sure you want to close without saving?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel, handler: { [weak self] _ in
            self?.log("User chose to keep editing after discard prompt.")
        }))

        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.log("User confirmed discard. Clearing dirty flag and dismissing.")
            // Clear dirty + re-enable swipe-to-dismiss for the actual dismissal
            self.noteIsDirty = false
            self.isModalInPresentation = false
            self.navigationController?.isModalInPresentation = false
            self.dismiss(animated: true)
        }))

        // If another alert/sheet might be on-screen, present gracefully
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.present(alert, animated: true)
            }
        } else {
            present(alert, animated: true)
        }
    }

    
    @objc private func saveTapped() {
        note.description = descriptionTextField.text
        delegate?.noteEditor(self, didSave: note)
        noteIsDirty = false
        isModalInPresentation = false
        navigationController?.isModalInPresentation = false
        log("Saved. Dirty cleared. Swipe-to-dismiss enabled.")
        dismiss(animated: true)
    }
    
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Returning false blocks the automatic dismissal when dirty.
        let shouldDismiss = !noteIsDirty
        log("presentationControllerShouldDismiss? -> \(shouldDismiss ? "YES" : "NO (dirty)")")
        return shouldDismiss
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        // Called when user swipes down but we returned false above.
        log("User attempted to swipe-to-dismiss while dirty — showing discard alert.")
        showDiscardChangesAlert()
    }

    // Optional: if you allow dismissal (e.g., not dirty), you can log it.
    // func presentationControllerWillDismiss(_ presentationController: UIPresentationController) { ... }


    
    @objc private func addPhotoTapped() {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in self.openCamera() }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in self.openGallery() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        log("Add/Change Photo tapped — presenting source options.")
    }
    
    @objc private func deletePhotoTapped() {
        note.localImage = nil
        note.imageUrl = nil
        note.localAnnotatedImage = nil
        note.annotatedImageUrl = nil
        imageView.image = nil
        updateButtonVisibility()
        markDirty(reason: "photo deleted")
    }
    
    @objc private func revertToOriginalTapped() {
        log("Reverting to original image.")
        note.annotatedImageUrl = nil
        note.localAnnotatedImage = nil
        imageView.image = note.localImage
        updateButtonVisibility()
        markDirty(reason: "reverted to original")
    }
    
    // MARK: Annotator
    @objc private func imageLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            log("Image long-pressed — opening annotator.")
            presentAnnotator()
        }
    }
    
    private func presentAnnotator() {
        guard let imageToAnnotate = self.note.localAnnotatedImage ?? self.note.localImage else {
            log("Annotator requested but no image available.")
            let alert = UIAlertController(title: "No Image", message: "There is no image to annotate.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let annotatorVC = AnnotateImageViewController(image: imageToAnnotate)
        annotatorVC.onSave = { [weak self] annotatedImage in
            guard let self = self else { return }
            self.note.localAnnotatedImage = annotatedImage
            self.imageView.image = annotatedImage
            self.updateButtonVisibility()
            self.markDirty(reason: "image annotated")
            self.log("Annotation saved and applied.")
        }
        
        let navController = UINavigationController(rootViewController: annotatorVC)
        present(navController, animated: true)
    }
    
    // MARK: Camera / Gallery
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            log("Camera not available.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
        log("Camera opened.")
    }
    
    private func openGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
        log("Gallery opened.")
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            log("Camera returned no image.")
            return
        }
        note.localImage = image
        note.localAnnotatedImage = nil
        imageView.image = image
        updateButtonVisibility()
        markDirty(reason: "camera image added")
    }
    
    // MARK: PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else {
            log("Gallery closed with no selection.")
            return
        }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let error = error {
                print("[NoteEditorVC] Error loading image: \(error.localizedDescription)")
            }
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.note.localImage = image
                    self?.note.localAnnotatedImage = nil
                    self?.imageView.image = image
                    self?.updateButtonVisibility()
                    self?.markDirty(reason: "gallery image added")
                }
            }
        }
    }
}






private class SignatureCaptureView: UIView {

    var signatureImage: UIImage?

    private let canvasView = PKCanvasView()
    private let previewImageView = UIImageView()

    private lazy var signButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Sign", for: .normal)
        button.customBackgroundColor = ColorScheme.amOrange
        button.addTarget(self, action: #selector(signTapped), for: .touchUpInside)
        return button
    }()

    private lazy var clearButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.customBackgroundColor = .systemGray
        button.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return button
    }()

    private lazy var doneButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.customBackgroundColor = ColorScheme.amBlue
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.backgroundColor = .white
        canvasView.isHidden = true
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView(arrangedSubviews: [clearButton, doneButton])
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        
        let mainStack = UIStackView(arrangedSubviews: [signButton, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(canvasView)
        addSubview(previewImageView)
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: mainStack.topAnchor, constant: -8),
            
            previewImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            previewImageView.bottomAnchor.constraint(equalTo: mainStack.topAnchor, constant: -8),
            
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        buttonStack.isHidden = true
    }

    @objc private func signTapped() {
        signButton.isHidden = true
        clearButton.superview?.isHidden = false
        canvasView.isHidden = false
        previewImageView.isHidden = true
    }

    @objc private func clearTapped() {
        canvasView.drawing = PKDrawing()
        signatureImage = nil
        previewImageView.image = nil
        previewImageView.isHidden = true
        
        if canvasView.isHidden {
            signTapped()
        }
    }

    @objc private func doneTapped() {
        guard !canvasView.drawing.bounds.isEmpty else {
            canvasView.isHidden = true
            signButton.isHidden = false
            clearButton.superview?.isHidden = true
            return
        }
        
        signatureImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        previewImageView.image = signatureImage
        
        canvasView.isHidden = true
        previewImageView.isHidden = false
        signButton.isHidden = false
        clearButton.superview?.isHidden = true
    }
}
