//
//  TimesheetViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//

import UIKit
import Firebase
import CoreLocation
import Network
import CoreLocation
import FirebaseFunctions
import FirebaseDatabase
import FirebaseAuth

class TimesheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    
    // UI Elements
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    var startButton: CustomButton!
    var stopButton: CustomButton!
    var submitButton: CustomButton!
    var addNoteButton: CustomButton!
    var addForemanSignatureButton: CustomButton!
    var addOperatorSignatureButton: CustomButton!
    
    var startTimeLabel: UILabel!
    var timesheetTableView: UITableView!
    var locationManager: CLLocationManager!
    var activityIndicator: UIActivityIndicatorView!
    var noteTextView = UITextView()
    var foremanSignatureImageView = UIImageView()
    var foremanNoteTextView = UITextView()
    var operatorSignatureImageView = UIImageView()
    var operatorNoteTextView = UITextView()
    
    var timesheetEntries = [TimesheetEntry]()  // Data for table view
    var currentSessionID: String?
    var isWorking = false
    var isHireEquipmentUsed: Bool = false
    var userParent: String = UserSession.shared.userParent ?? ""
    
    var lastLocation: CLLocation?
    var lastLocationFetchTime: Date?

    
    // Firebase Database reference
    let databaseRef = Database.database().reference()
    var locationCompletion: ((String?) -> Void)?
    
    // Height Constraints (for dynamic resizing)
    var noteTextViewHeightConstraint: NSLayoutConstraint!
    var foremanSignatureImageViewHeightConstraint: NSLayoutConstraint!
    var foremanNoteTextViewHeightConstraint: NSLayoutConstraint!
    var operatorSignatureImageViewHeightConstraint: NSLayoutConstraint!
    var operatorNoteTextViewHeightConstraint: NSLayoutConstraint!


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TranslationManager.shared.getTranslation(for: "timesheetTab.timeTabTitle")
    
        setupUI()
        setupLocationManager()
        
        // Register the custom cell
        timesheetTableView.register(TimesheetEntryCell.self, forCellReuseIdentifier: "TimesheetEntryCell")
        
        // Check permissions and setup the location manager properly
        checkPermissionsAndInitializeLocation()

        // setupUI()
        loadTimesheetData()
        checkOngoingSession()
        updateButtonStates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSignatureData() // 🔥 Reload signatures when returning
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timesheetTableView.flashScrollIndicators()
    }

    func loadSignatureData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let timesheetRef = databaseRef.child("customers").child(userParent).child("timesheets").child(userID)

        timesheetRef.observeSingleEvent(of: .value) { snapshot in
            let data = snapshot.value as? [String: Any] ?? [:]
            
//            // 🔹 Foreman Signature
//            if let foremanSignatureURL = data["foremanSignature"] as? String {
//                self.loadImage(from: foremanSignatureURL, into: self.foremanSignatureImageView)
//            }
//            if let foremanNote = data["foremanNote"] as? String {
//                self.foremanNoteTextView.text = foremanNote
//                self.foremanNoteTextView.isHidden = false
//            } else {
//                self.foremanNoteTextView.isHidden = true
//            }
//
//            // 🔹 Operator Signature
//            if let operatorSignatureURL = data["operatorSignature"] as? String {
//                self.loadImage(from: operatorSignatureURL, into: self.operatorSignatureImageView)
//            }
//            if let operatorNote = data["operatorNote"] as? String {
//                self.operatorNoteTextView.text = operatorNote
//                self.operatorNoteTextView.isHidden = false
//            } else {
//                self.operatorNoteTextView.isHidden = true
//            }
            
            // 🔹 Foreman Signature
            if let foremanSignatureURL = data["foremanSignature"] as? String {
                self.loadImage(from: foremanSignatureURL, into: self.foremanSignatureImageView)
                self.foremanSignatureImageViewHeightConstraint.constant = 100 // Show
                self.foremanSignatureImageView.isHidden = false
            } else {
                self.foremanSignatureImageViewHeightConstraint.constant = 0 // Hide
                self.foremanSignatureImageView.isHidden = true
            }

            if let foremanNote = data["foremanNote"] as? String {
                self.foremanNoteTextView.text = foremanNote
                self.foremanNoteTextViewHeightConstraint.constant = 80 // Show
                self.foremanNoteTextView.isHidden = false
            } else {
                self.foremanNoteTextViewHeightConstraint.constant = 0 // Hide
                self.foremanNoteTextView.isHidden = true
            }

            // 🔹 Operator Signature
            if let operatorSignatureURL = data["operatorSignature"] as? String {
                self.loadImage(from: operatorSignatureURL, into: self.operatorSignatureImageView)
                self.operatorSignatureImageViewHeightConstraint.constant = 100 // Show
                self.operatorSignatureImageView.isHidden = false
            } else {
                self.operatorSignatureImageViewHeightConstraint.constant = 0 // Hide
                self.operatorSignatureImageView.isHidden = true
            }
            
            if let operatorNote = data["operatorNote"] as? String {
                self.operatorNoteTextView.text = operatorNote
                self.operatorNoteTextViewHeightConstraint.constant = 80 // Show
                self.operatorNoteTextView.isHidden = false
            } else {
                self.operatorNoteTextViewHeightConstraint.constant = 0 // Hide
                self.operatorNoteTextView.isHidden = true
            }

            // Important: Update layout after changing constraints
            UIView.animate(withDuration: 0.25) {
              self.view.layoutIfNeeded()
            }
        }
    }
    
    func loadImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                    imageView.isHidden = false
                }
            }
        }
    }


    
    
    
    @objc func reloadTranslations() {
        navigationItem.title = TranslationManager.shared.getTranslation(for: "timesheetTab.timeTabTitle")
        startButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOnButton"), for: .normal)
        stopButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOffButton"), for: .normal)
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.submitTimesheetButton"), for: .normal)
    }

    

    
    func setupUI() {
        view.backgroundColor = .white
        
        // Setup navigation bar
        navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Create ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Create ContentView inside ScrollView
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Start Button
        startButton = CustomButton(type: .system)
        startButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOnButton"), for: .normal)
        startButton.addTarget(self, action: #selector(startWorkSession), for: .touchUpInside)
        contentView.addSubview(startButton)
        
        // Stop Button
        stopButton = CustomButton(type: .system)
        stopButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOffButton"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopWorkSession), for: .touchUpInside)
        stopButton.isEnabled = false
        contentView.addSubview(stopButton)
        
        // Start Time Label
        startTimeLabel = UILabel()
        startTimeLabel.textAlignment = .center
        startTimeLabel.isHidden = true
        contentView.addSubview(startTimeLabel)
        
        // Timesheet TableView
        timesheetTableView = UITableView()
        timesheetTableView.delegate = self
        timesheetTableView.dataSource = self
        contentView.addSubview(timesheetTableView)
        
        addNoteButton = CustomButton(type: .system)
        addNoteButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.addNoteButton"), for: .normal)
        addNoteButton.addTarget(self, action: #selector(addNoteTapped), for: .touchUpInside)
        contentView.addSubview(addNoteButton)
        
        // Note TextView
        noteTextView = UITextView()
        noteTextView.isEditable = false
        noteTextView.isHidden = true  // Initially hidden when there's no note
        noteTextView.font = UIFont.systemFont(ofSize: 16)
        noteTextView.backgroundColor = UIColor.systemGray6
        noteTextView.layer.cornerRadius = 8
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.addSubview(noteTextView)
        
        // Add Foreman Signature Button
        addForemanSignatureButton = CustomButton(type: .system)
        addForemanSignatureButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.addForemanSignatureButton"), for: .normal)
        addForemanSignatureButton.addTarget(self, action: #selector(addForemanSignatureTapped), for: .touchUpInside)
        contentView.addSubview(addForemanSignatureButton)

        // Add Operator Signature Button
        addOperatorSignatureButton = CustomButton(type: .system)
        addOperatorSignatureButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.addOperatorSignatureButton"), for: .normal)
        addOperatorSignatureButton.addTarget(self, action: #selector(addOperatorSignatureTapped), for: .touchUpInside)
        contentView.addSubview(addOperatorSignatureButton)

        // Foreman Signature Image
        foremanSignatureImageView = UIImageView()
        foremanSignatureImageView.contentMode = .scaleAspectFit
        foremanSignatureImageView.isHidden = true
        contentView.addSubview(foremanSignatureImageView)
        
        // Foreman Note
        foremanNoteTextView = UITextView()
        foremanNoteTextView.isEditable = false
        foremanNoteTextView.isHidden = true
        foremanNoteTextView.font = UIFont.systemFont(ofSize: 16)
        foremanNoteTextView.backgroundColor = UIColor.systemGray6
        foremanNoteTextView.layer.cornerRadius = 8
        foremanNoteTextView.layer.borderWidth = 1
        foremanNoteTextView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.addSubview(foremanNoteTextView)

        // Operator Signature Image
        operatorSignatureImageView = UIImageView()
        operatorSignatureImageView.contentMode = .scaleAspectFit
        operatorSignatureImageView.isHidden = true
        contentView.addSubview(operatorSignatureImageView)
        
        // Operator Note
        operatorNoteTextView = UITextView()
        operatorNoteTextView.isEditable = false
        operatorNoteTextView.isHidden = true
        operatorNoteTextView.font = UIFont.systemFont(ofSize: 16)
        operatorNoteTextView.backgroundColor = UIColor.systemGray6
        operatorNoteTextView.layer.cornerRadius = 8
        operatorNoteTextView.layer.borderWidth = 1
        operatorNoteTextView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.addSubview(operatorNoteTextView)

        
        // Submit Button
        submitButton = CustomButton(type: .system)
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.submitTimesheetButton"), for: .normal)
        submitButton.addTarget(self, action: #selector(submitTimesheet), for: .touchUpInside)
        contentView.addSubview(submitButton)
        
        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        
        // ✅ ScrollView Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // ✅ ContentView Constraints (IMPORTANT: Must match ScrollView width)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)  // Very important!
        ])
        
        // Constraints
        setupConstraints()
    }
    
    
//    func setupConstraints() {
//        // Use AutoLayout for positioning the UI elements
//        startButton.translatesAutoresizingMaskIntoConstraints = false
//        stopButton.translatesAutoresizingMaskIntoConstraints = false
//        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
//        timesheetTableView.translatesAutoresizingMaskIntoConstraints = false
//        submitButton.translatesAutoresizingMaskIntoConstraints = false
//        addNoteButton.translatesAutoresizingMaskIntoConstraints = false
//        noteTextView.translatesAutoresizingMaskIntoConstraints = false
//        
//        addForemanSignatureButton.translatesAutoresizingMaskIntoConstraints = false
//        addOperatorSignatureButton.translatesAutoresizingMaskIntoConstraints = false
//        foremanSignatureImageView.translatesAutoresizingMaskIntoConstraints = false
//        operatorSignatureImageView.translatesAutoresizingMaskIntoConstraints = false
//        foremanNoteTextView.translatesAutoresizingMaskIntoConstraints = false
//        operatorNoteTextView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            // Start Button
//            startButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
//            startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//
//            // Stop Button
//            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
//            stopButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//
//            // Start Time Label
//            startTimeLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 8),
//            startTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            startTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//
//            // Timesheet TableView
//            timesheetTableView.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 16),
//            timesheetTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            timesheetTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            timesheetTableView.heightAnchor.constraint(equalToConstant: 300), // Set a height so it appears
//
//            // Add Note Button
//            addNoteButton.topAnchor.constraint(equalTo: timesheetTableView.bottomAnchor, constant: 16),
//            addNoteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//
//            // Note TextView
//            noteTextView.topAnchor.constraint(equalTo: addNoteButton.bottomAnchor, constant: 8),
//            noteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            noteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            noteTextView.heightAnchor.constraint(equalToConstant: 80),
//
//            // Foreman Signature Button
//            addForemanSignatureButton.topAnchor.constraint(equalTo: noteTextView.bottomAnchor, constant: 16),
//            addForemanSignatureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//
//            // Foreman Signature Image
//            foremanSignatureImageView.topAnchor.constraint(equalTo: addForemanSignatureButton.bottomAnchor, constant: 8),
//            foremanSignatureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            foremanSignatureImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            foremanSignatureImageView.heightAnchor.constraint(equalToConstant: 100),
//
//            // Foreman Note
//            foremanNoteTextView.topAnchor.constraint(equalTo: foremanSignatureImageView.bottomAnchor, constant: 8),
//            foremanNoteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            foremanNoteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            foremanNoteTextView.heightAnchor.constraint(equalToConstant: 80),
//
//            // Operator Signature Button
//            addOperatorSignatureButton.topAnchor.constraint(equalTo: foremanNoteTextView.bottomAnchor, constant: 16),
//            addOperatorSignatureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//
//            // Operator Signature Image
//            operatorSignatureImageView.topAnchor.constraint(equalTo: addOperatorSignatureButton.bottomAnchor, constant: 8),
//            operatorSignatureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            operatorSignatureImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            operatorSignatureImageView.heightAnchor.constraint(equalToConstant: 100),
//
//            // Operator Note
//            operatorNoteTextView.topAnchor.constraint(equalTo: operatorSignatureImageView.bottomAnchor, constant: 8),
//            operatorNoteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            operatorNoteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            operatorNoteTextView.heightAnchor.constraint(equalToConstant: 80),
//
//            // Submit Button (At Bottom)
//            submitButton.topAnchor.constraint(equalTo: operatorNoteTextView.bottomAnchor, constant: 16),
//            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
//            
//            // Activity Indicator (Centered)
//            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//
//        ])
//    }
    
    
    func setupConstraints() {
        // Use AutoLayout for positioning the UI elements
        startButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        timesheetTableView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        addNoteButton.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        
        addForemanSignatureButton.translatesAutoresizingMaskIntoConstraints = false
        addOperatorSignatureButton.translatesAutoresizingMaskIntoConstraints = false
        foremanSignatureImageView.translatesAutoresizingMaskIntoConstraints = false
        operatorSignatureImageView.translatesAutoresizingMaskIntoConstraints = false
        foremanNoteTextView.translatesAutoresizingMaskIntoConstraints = false
        operatorNoteTextView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        // Create and store height constraints *before* the activate block
        noteTextViewHeightConstraint = noteTextView.heightAnchor.constraint(equalToConstant: 80)
        foremanSignatureImageViewHeightConstraint = foremanSignatureImageView.heightAnchor.constraint(equalToConstant: 100)
        foremanNoteTextViewHeightConstraint = foremanNoteTextView.heightAnchor.constraint(equalToConstant: 80)
        operatorSignatureImageViewHeightConstraint = operatorSignatureImageView.heightAnchor.constraint(equalToConstant: 100)
        operatorNoteTextViewHeightConstraint = operatorNoteTextView.heightAnchor.constraint(equalToConstant: 80)

        NSLayoutConstraint.activate([
            // Start Button
            startButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Stop Button
            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            stopButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Start Time Label
            startTimeLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 8),
            startTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Timesheet TableView
            timesheetTableView.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 16),
            timesheetTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timesheetTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timesheetTableView.heightAnchor.constraint(equalToConstant: 300), // Set a height so it appears

            // Add Note Button
            addNoteButton.topAnchor.constraint(equalTo: timesheetTableView.bottomAnchor, constant: 16),
            addNoteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Note TextView
            noteTextView.topAnchor.constraint(equalTo: addNoteButton.bottomAnchor, constant: 8),
            noteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // noteTextViewHeightConstraint = noteTextView.heightAnchor.constraint(equalToConstant: 80), // Moved up

            // Foreman Signature Button
            addForemanSignatureButton.topAnchor.constraint(equalTo: noteTextView.bottomAnchor, constant: 16),
            addForemanSignatureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Foreman Signature Image
            foremanSignatureImageView.topAnchor.constraint(equalTo: addForemanSignatureButton.bottomAnchor, constant: 8),
            foremanSignatureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foremanSignatureImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // foremanSignatureImageViewHeightConstraint = foremanSignatureImageView.heightAnchor.constraint(equalToConstant: 100), // Moved up

            // Foreman Note
            foremanNoteTextView.topAnchor.constraint(equalTo: foremanSignatureImageView.bottomAnchor, constant: 8),
            foremanNoteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foremanNoteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // foremanNoteTextViewHeightConstraint = foremanNoteTextView.heightAnchor.constraint(equalToConstant: 80), // Moved up

            // Operator Signature Button
            addOperatorSignatureButton.topAnchor.constraint(equalTo: foremanNoteTextView.bottomAnchor, constant: 16),
            addOperatorSignatureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Operator Signature Image
            operatorSignatureImageView.topAnchor.constraint(equalTo: addOperatorSignatureButton.bottomAnchor, constant: 8),
            operatorSignatureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            operatorSignatureImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // operatorSignatureImageViewHeightConstraint = operatorSignatureImageView.heightAnchor.constraint(equalToConstant: 100), // Moved up

            // Operator Note
            operatorNoteTextView.topAnchor.constraint(equalTo: operatorSignatureImageView.bottomAnchor, constant: 8),
            operatorNoteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            operatorNoteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // operatorNoteTextViewHeightConstraint = operatorNoteTextView.heightAnchor.constraint(equalToConstant: 80), // Moved up

            // Submit Button (At Bottom)
            submitButton.topAnchor.constraint(equalTo: operatorNoteTextView.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            // Activity Indicator (Centered)
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Activate the stored height constraints after NSLayoutConstraint.activate()
        noteTextViewHeightConstraint.isActive = true
        foremanSignatureImageViewHeightConstraint.isActive = true
        foremanNoteTextViewHeightConstraint.isActive = true
        operatorSignatureImageViewHeightConstraint.isActive = true
        operatorNoteTextViewHeightConstraint.isActive = true
    }

    
    
    @objc func addForemanSignatureTapped() {
        openSignatureScreen(isForeman: true)
    }

    @objc func addOperatorSignatureTapped() {
        openSignatureScreen(isForeman: false)
    }

    func openSignatureScreen(isForeman: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let signatureKey = isForeman ? "foremanSignature" : "operatorSignature"
        let noteKey = isForeman ? "foremanNote" : "operatorNote"

        let timesheetRef = databaseRef.child("customers").child(userParent).child("timesheets").child(userID)

        timesheetRef.observeSingleEvent(of: .value) { snapshot in
            let data = snapshot.value as? [String: Any] ?? [:]
            
            let signatureURL = data[signatureKey] as? String
            let note = data[noteKey] as? String ?? ""  // Default to empty if no note

            // Open SignatureViewController & pass existing data
            let signatureVC = SignatureViewController()
            signatureVC.isForemanMode = isForeman
            signatureVC.existingSignatureURL = signatureURL
            signatureVC.existingNote = note
            signatureVC.modalPresentationStyle = .fullScreen
            self.present(signatureVC, animated: true)
        }
    }
    
    
    // Helper methods to show and hide the spinner
    func showSpinner() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false  // Freeze the screen by disabling user interaction
        
        // Disable the tab bar to prevent switching
        self.tabBarController?.tabBar.isUserInteractionEnabled = false
    }


    func hideSpinner() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true  // Re-enable user interaction
        
        // Re-enable the tab bar after completion
        self.tabBarController?.tabBar.isUserInteractionEnabled = true
    }
    
    
    // MARK: - Permissions and Location Manager Setup

    func checkPermissionsAndInitializeLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self

        // Don't check locationServicesEnabled() directly on the main thread
        let status = locationManager.authorizationStatus  // Use the instance property for iOS 14+

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            handleLocationPermissionDenied()  // Call when permission is denied
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            showAlert(title: TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetErrorHeading"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.unknownErrorText"))
        }
    }
    

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus()
    }

    func handleAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start updating location when permission is granted
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            handleLocationPermissionDenied()  // Handle permission denied
            locationCompletion?("None")  // Provide a fallback
        case .notDetermined:
            // No action needed; permission request is in progress
            break
        @unknown default:
            showAlert(title: TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetErrorHeding"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.unknownErrorText"))
            locationCompletion?("None")  // Provide a fallback
        }
    }



    // Called when authorization changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            handleLocationPermissionDenied()  // Call when permission is denied
        case .notDetermined:
            break
        @unknown default:
            showAlert(title: TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetErrorHeding"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.unknownErrorText"))
        }
    }


    // MARK: - Location Manager
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()  // Request location permission
    }
    
//    func checkOngoingSession() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("Error: No current user ID found")
//            return
//        }
//
//        print("Checking ongoing session for userParent = \(userParent) and userID = \(userID)")
//
//        // Query the database for the latest session
//        databaseRef.child("customers")
//            .child(userParent)
//            .child("timesheets")
//            .child(userID)
//            .queryOrderedByKey()
//            .queryLimited(toLast: 1)
//            .observeSingleEvent(of: .value) { snapshot in
//                print("Snapshot children count: \(snapshot.childrenCount)")
//                
//                if let lastSession = snapshot.children.allObjects.first as? DataSnapshot {
//                    print("Last session data: \(lastSession)")
//                    
//                    let stopTime = lastSession.childSnapshot(forPath: "stopTime").value as? TimeInterval
//                    let startTime = lastSession.childSnapshot(forPath: "startTime").value as? TimeInterval ?? 0
//                    
//                    print("Session startTime: \(startTime)")
//                    if let stopTime = stopTime {
//                        print("Session stopTime: \(stopTime)")
//                    } else {
//                        print("No stopTime, session is ongoing")
//                    }
//                    
//                    // Fetch 'hireEquipmentIncluded' and store it
//                    self.isHireEquipmentUsed = lastSession.childSnapshot(forPath: "hireEquipmentIncluded").value as? Bool ?? false
//                    print("Hire Equipment Used: \(self.isHireEquipmentUsed)")
//
//
//                    if stopTime == nil {
//                        // Ongoing session, check if it's from a previous day
//                        let startDate = Date(timeIntervalSince1970: startTime / 1000)  // Assuming timestamp is in milliseconds
//                        let today = Date()
//
//                        if !Calendar.current.isDate(startDate, inSameDayAs: today) {
//                            // Set stop time to 23:59 of the start day
//                            var calendar = Calendar.current
//                            calendar.timeZone = TimeZone.current
//                            
//                            var endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) ?? startDate
//                            let midnightTimestamp = endOfDay.timeIntervalSince1970 * 1000  // Convert to milliseconds
//                            
//                            let updates: [String: Any] = [
//                                "stopTime": midnightTimestamp,
//                                "stopLocation": "None"
//                            ]
//                            
//                            // Update the session with the stop time at 23:59
//                            self.databaseRef.child("customers")
//                                .child(self.userParent)
//                                .child("timesheets")
//                                .child(userID)
//                                .child(lastSession.key)
//                                .updateChildValues(updates) { error, _ in
//                                    if let error = error {
//                                        self.showError("\(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedOutdatedWorkSession")) \(error.localizedDescription)")
//                                    } else {
//                                        print("Session ended at 23:59 of the previous day")
//                                        self.isWorking = false
//                                        self.currentSessionID = nil
//                                        self.updateButtonStates()
//                                    }
//                                }
//                        } else {
//                            // Session is from today, continue as usual
//                            self.isWorking = true
//                            self.currentSessionID = lastSession.key
//                            self.updateUIForStartWork(startTime: startTime)
//                            self.updateButtonStates()
//                        }
//                    } else {
//                        // Session has already been stopped
//                        self.isWorking = false
//                        self.currentSessionID = nil
//                        self.updateButtonStates()
//                    }
//                } else {
//                    print("No session exists, no ongoing session.")
//                    // No session exists, ensure no ongoing session
//                    self.isWorking = false
//                    self.updateButtonStates()
//                }
//            }
//    }
    
    
    func checkOngoingSession() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found")
            return
        }

        print("Checking ongoing session for userParent = \(userParent) and userID = \(userID)")

        // Query the database for all sessions under the user's timesheet
        databaseRef.child("customers")
            .child(userParent)
            .child("timesheets")
            .child(userID)
            .observeSingleEvent(of: .value) { snapshot in
                print("Snapshot children count: \(snapshot.childrenCount)")

                // Filter for timesheet entries only, based on startTime and startLocation presence
                var timesheetEntries: [DataSnapshot] = []
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot else { continue }
                    if childSnapshot.hasChild("startTime") && childSnapshot.hasChild("startLocation") {
                        timesheetEntries.append(childSnapshot)
                    }
                }
                
                // Sort the timesheet entries by their keys (which are inherently time-ordered by Firebase)
                timesheetEntries.sort { $0.key > $1.key } // Sort in descending order (newest first)

                if let lastSession = timesheetEntries.first {
                    print("Last session data: \(lastSession)")

                    let stopTime = lastSession.childSnapshot(forPath: "stopTime").value as? TimeInterval
                    let startTime = lastSession.childSnapshot(forPath: "startTime").value as? TimeInterval ?? 0

                    print("Session startTime: \(startTime)")
                    if let stopTime = stopTime {
                        print("Session stopTime: \(stopTime)")
                    } else {
                        print("No stopTime, session is ongoing")
                    }

                    // Fetch 'hireEquipmentIncluded' and store it
                    self.isHireEquipmentUsed = lastSession.childSnapshot(forPath: "hireEquipmentIncluded").value as? Bool ?? false
                    print("Hire Equipment Used: \(self.isHireEquipmentUsed)")


                    if stopTime == nil {
                        // Ongoing session, check if it's from a previous day
                        let startDate = Date(timeIntervalSince1970: startTime / 1000)  // Assuming timestamp is in milliseconds
                        let today = Date()

                        if !Calendar.current.isDate(startDate, inSameDayAs: today) {
                            // Set stop time to 23:59 of the start day
                            var calendar = Calendar.current
                            calendar.timeZone = TimeZone.current

                            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) ?? startDate
                            let midnightTimestamp = endOfDay.timeIntervalSince1970 * 1000  // Convert to milliseconds

                            let updates: [String: Any] = [
                                "stopTime": midnightTimestamp,
                                "stopLocation": "None"
                            ]

                            // Update the session with the stop time at 23:59
                            self.databaseRef.child("customers")
                                .child(self.userParent)
                                .child("timesheets")
                                .child(userID)
                                .child(lastSession.key)
                                .updateChildValues(updates) { error, _ in
                                    if let error = error {
                                        self.showError("\(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedOutdatedWorkSession")) \(error.localizedDescription)")
                                    } else {
                                        print("Session ended at 23:59 of the previous day")
                                        self.isWorking = false
                                        self.currentSessionID = nil
                                        self.updateButtonStates()
                                    }
                                }
                        } else {
                            // Session is from today, continue as usual
                            self.isWorking = true
                            self.currentSessionID = lastSession.key
                            self.updateUIForStartWork(startTime: startTime)
                            self.updateButtonStates()
                        }
                    } else {
                        // Session has already been stopped
                        self.isWorking = false
                        self.currentSessionID = nil
                        self.updateButtonStates()
                    }
                } else {
                    print("No session exists, no ongoing session.")
                    // No session exists, ensure no ongoing session
                    self.isWorking = false
                    self.updateButtonStates()
                }
            }
    }

    
    func updateButtonStates() {
        if isWorking {
            startButton.isEnabled = false
            startButton.alpha = 0.5  // Dimmed to show disabled
            stopButton.isEnabled = true
            stopButton.alpha = 1.0   // Fully enabled
        } else {
            startButton.isEnabled = true
            startButton.alpha = 1.0  // Fully enabled
            stopButton.isEnabled = false
            stopButton.alpha = 0.5   // Dimmed to show disabled
        }
    }

    
    @objc func startWorkSession() {
        guard !isWorking else {
            print("Attempted to start session but already working.")
            return
        }

        print("\(Date()): Start work session initiated.")

        // Generate session ID
        currentSessionID = databaseRef.child("customers")
            .child(userParent)
            .child("timesheets")
            .child(Auth.auth().currentUser?.uid ?? "")
            .childByAutoId().key

        print("\(Date()): Generated session ID: \(currentSessionID ?? "None")")

        // Get the start time in milliseconds
        let startTime = Int64(Date().timeIntervalSince1970 * 1000)
        print("\(Date()): Start time (timestamp in milliseconds): \(startTime)")

        self.showSpinner()

        // Fetch location and reverse-geocoded address in background
        getLocation { locationString in
            print("\(Date()): Location received: \(locationString ?? "None")")

            self.showHireEquipmentDialog { hireEquipmentIncluded, equipmentType in
                guard let hireEquipmentIncluded = hireEquipmentIncluded else {
                    print("User canceled the hire equipment dialog. Session initiation canceled.")
                    self.hideSpinner()
                    return
                }

                var timesheetData: [String: Any] = [
                    "date": startTime,
                    "startTime": startTime,
                    "startLocation": locationString ?? "Unknown Location",
                    "hireEquipmentIncluded": hireEquipmentIncluded
                ]

                if hireEquipmentIncluded, let equipmentType = equipmentType {
                    timesheetData["equipmentType"] = equipmentType
                }

                guard let sessionID = self.currentSessionID else {
                    print("\(Date()): Error: currentSessionID is nil")
                    self.hideSpinner()
                    self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetNoSessionId"))
                    return
                }

                print("\(Date()): Timesheet data to save: \(timesheetData)")
                print("\(Date()): Attempting to save start work session to Firebase.")

                // Save to Firebase
                self.databaseRef.child("customers")
                    .child(self.userParent)
                    .child("timesheets")
                    .child(Auth.auth().currentUser?.uid ?? "")
                    .child(sessionID)
                    .setValue(timesheetData) { error, _ in
                        self.hideSpinner()
                        if let error = error {
                            print("Error saving start work session: \(error.localizedDescription)")
                            self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedToStart"))
                        } else {
                            print("Successfully started work session with ID: \(sessionID)")
                            self.isWorking = true
                            self.updateUIForStartWork(startTime: Double(startTime))
                            self.updateButtonStates()
                        }
                    }
            }
        }
    }

    

    private func showHireEquipmentDialog(completion: @escaping (Bool?, String?) -> Void) {
        let hireEquipmentAlert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.hireEquipmentTitle"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.hireEqupmentMessage"), preferredStyle: .alert)

        hireEquipmentAlert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.yesButton"), style: .default, handler: { _ in
                    self.showEquipmentTypeDialog { equipmentType in
                        if equipmentType == nil {
                            self.isHireEquipmentUsed = true
                            completion(nil, nil) // User canceled equipment type dialog
                        } else {
                            self.isHireEquipmentUsed = true
                            completion(true, equipmentType)
                        }
                    }
                }))

        hireEquipmentAlert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.noButton"), style: .default, handler: { _ in
            self.isHireEquipmentUsed = false
            completion(false, nil)
        }))

        present(hireEquipmentAlert, animated: true)
    }

    private func showEquipmentTypeDialog(completion: @escaping (String?) -> Void) {
        let equipmentTypeAlert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.equipmentTypeTitle"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.typeOfEquipmentHired"), preferredStyle: .alert)

        equipmentTypeAlert.addTextField { textField in
            textField.placeholder = "e.g., Excavator"
            textField.autocapitalizationType = .sentences
        }

        equipmentTypeAlert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: { _ in
            print("User canceled equipment type dialog.")
            completion(nil)
        }))

        equipmentTypeAlert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: { _ in
            let equipmentType = equipmentTypeAlert.textFields?.first?.text ?? ""
            completion(equipmentType)
        }))

        present(equipmentTypeAlert, animated: true)
    }


//    @objc func stopWorkSession() {
//        guard isWorking, let sessionID = currentSessionID else {
//            print("\(Date()): Attempted to stop session but no active session is running.")
//            return
//        }
//        
//        // Log the beginning of the stop session process
//        print("\(Date()): Stop work session initiated.")
//        
//        // Get the stop time in milliseconds
//        let stopTime = Int64(Date().timeIntervalSince1970 * 1000)
//        print("\(Date()): Stop time (timestamp in milliseconds): \(stopTime)")
//        
//        self.showSpinner()
//        
//        getLocation { location in
//            print("\(Date()): Location received: \(location ?? "None")")
//            
//            let updates: [String: Any] = [
//                "stopTime": stopTime,
//                "stopLocation": location ?? "None"
//            ]
//            
//            print("\(Date()): Updates to save: \(updates)")
//            
//            // Attempt to save the stop time to the database
//            print("\(Date()): Attempting to save stop work session to Firebase.")
//            
//            self.databaseRef.child("customers")
//                .child(self.userParent)
//                .child("timesheets")
//                .child(Auth.auth().currentUser?.uid ?? "")
//                .child(sessionID)
//                .updateChildValues(updates) { error, _ in
//                    self.hideSpinner()
//                    if let error = error {
//                        print("\(Date()): Error saving stop work session: \(error.localizedDescription)")
//                        self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedToStop"))
//                    } else {
//                        print("\(Date()): Successfully stopped work session with ID: \(sessionID)")
//                        self.isWorking = false
//                        self.updateUIForStopWork()
//                        self.updateButtonStates()
//                    }
//                }
//        }
//    }
//    
    
    @objc func stopWorkSession() {
        guard isWorking, let sessionID = currentSessionID else {
            print("\(Date()): Attempted to stop session but no active session is running.")
            return
        }

        print("\(Date()): Stop work session initiated.")
        print("Just calling the dialog - isHireEquipmentUsed = \(self.isHireEquipmentUsed)")

        getLocation { location in
            print("\(Date()): Location received: \(location ?? "None")")

            let dialogVC = ClockOffDialogViewController()
            dialogVC.isHireEquipmentUsed = self.isHireEquipmentUsed
            dialogVC.stopLocation = location ?? "None"
            dialogVC.delegate = self
            dialogVC.modalPresentationStyle = .overFullScreen
            dialogVC.modalTransitionStyle = .crossDissolve
            self.present(dialogVC, animated: true, completion: nil)
        }
    }



    



    // MARK: - Submit Timesheet
    @objc func submitTimesheet() {
        guard !isWorking else {
            showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetErrorText"))
            return
        }
        
        // Show spinner before calling the Cloud Function
        showSpinner()
        
        let functions = Functions.functions()
        let data = [
            "parentUser": userParent,
            "uid": Auth.auth().currentUser?.uid ?? ""
        ]
        
        functions.httpsCallable("generateAndSendTimesheet").call(data) { result, error in
            self.hideSpinner()
            
            if let error = error {
                self.showError("\(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedToSubmit")) \(error.localizedDescription)")
            } else {
                self.showConfirmation(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetSubmitSuccess"))
//                self.foremanSignatureImageView.image = nil
//                self.foremanSignatureImageView.isHidden = true
//
//                self.foremanNoteTextView.text = ""
//                self.foremanNoteTextView.isHidden = true
//
//                self.operatorSignatureImageView.image = nil
//                self.operatorSignatureImageView.isHidden = true
//
//                self.operatorNoteTextView.text = ""
//                self.operatorNoteTextView.isHidden = true
                
                // Reset the fields
                self.foremanSignatureImageView.image = nil
                self.foremanNoteTextView.text = ""
                self.operatorSignatureImageView.image = nil
                self.operatorNoteTextView.text = ""

                // Update UI (hide and adjust height constraints)
                self.foremanSignatureImageView.isHidden = true
                self.foremanSignatureImageViewHeightConstraint.constant = 0
                self.foremanNoteTextView.isHidden = true
                self.foremanNoteTextViewHeightConstraint.constant = 0
                self.operatorSignatureImageView.isHidden = true
                self.operatorSignatureImageViewHeightConstraint.constant = 0
                self.operatorNoteTextView.isHidden = true
                self.operatorNoteTextViewHeightConstraint.constant = 0

                // Animate the layout changes
                UIView.animate(withDuration: 0.25) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Helper Methods for UI Updates
    func updateUIForStartWork(startTime: Double) {
        startButton.isEnabled = false
        stopButton.isEnabled = true
        startTimeLabel.text = "\(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetProgressLabel")) \(formatTime(startTime))"
        startTimeLabel.isHidden = false
//        startTimeLabel.backgroundColor = .red
    }
    
    func updateUIForStopWork() {
        startButton.isEnabled = true
        stopButton.isEnabled = false
        startTimeLabel.isHidden = true
    }
        
    func formatTime(_ timestamp: Double) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        
        // Convert timestamp from seconds to milliseconds by multiplying by 1000
        let timestampInMilliseconds = timestamp / 1000
        
        return formatter.string(from: Date(timeIntervalSince1970: timestampInMilliseconds))
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default))
        present(alert, animated: true)
    }
    
    func showConfirmation(_ message: String) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.successHeader"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default))
        present(alert, animated: true)
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timesheetEntries.count
    }

//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimesheetEntryCell", for: indexPath) as? TimesheetEntryCell else {
//            return UITableViewCell()
//        }
//        
//        let entry = timesheetEntries[indexPath.row]
//        cell.configure(with: entry)
//
//        // Add alternating row background colors
//        if indexPath.row % 2 == 0 {
//            cell.backgroundColor = UIColor.white
//        } else {
//            cell.backgroundColor = UIColor(white: 0.9, alpha: 1.0)  // Light gray
//        }
//
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimesheetEntryCell", for: indexPath) as? TimesheetEntryCell else {
            return UITableViewCell()
        }
        
        let entry = timesheetEntries[indexPath.row]
        cell.configure(with: entry)

        // Add alternating row background colors
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = UIColor(white: 0.9, alpha: 1.0)  // Light gray
        }

        return cell
    }



    
    // MARK: - Fetch Timesheet Data
//    func loadTimesheetData() {
//        databaseRef.child("customers")
//            .child(userParent)
//            .child("timesheets")
//            .child(Auth.auth().currentUser?.uid ?? "")
//            .observe(.value) { snapshot in
//                self.timesheetEntries.removeAll()
//                for child in snapshot.children {
//                    if let snapshot = child as? DataSnapshot {
//                        print("snapshot = \(snapshot)")
//                        let entry = TimesheetEntry(snapshot: snapshot) // No optional check needed
//                        self.timesheetEntries.append(entry)
//                    }
//                }
//                self.timesheetEntries = self.timesheetEntries.reversed()
//                self.timesheetTableView.reloadData()
//                
//                // Fetch note if it exists
//                if let noteSnapshot = snapshot.childSnapshot(forPath: "note").value as? String {
//                    self.noteTextView.text = noteSnapshot
//                    self.noteTextView.isHidden = noteSnapshot.isEmpty
//                } else {
//                    self.noteTextView.isHidden = true
//                }
//            }
//    }
    
    
    // MARK: - Fetch Timesheet Data
    func loadTimesheetData() {
        databaseRef.child("customers")
            .child(userParent)
            .child("timesheets")
            .child(Auth.auth().currentUser?.uid ?? "")
            .observe(.value) { snapshot in
                self.timesheetEntries.removeAll()

                // Separate timesheet entries from other data
                var timesheetData: [DataSnapshot] = []
                var otherData: [String: Any] = [:]

                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        if childSnapshot.hasChild("startTime") && childSnapshot.hasChild("startLocation") {
                            // It's a timesheet entry
                            timesheetData.append(childSnapshot)
                        } else {
                            // It's not a timesheet entry (e.g., note, foremanNote, etc.)
                            if let childValue = childSnapshot.value as? [String: Any] {
                                otherData[childSnapshot.key] = childValue
                            } else if let childValue = childSnapshot.value as? String {
                                // Handle cases where the value is a single string
                                otherData[childSnapshot.key] = childValue
                            }
                        }
                    }
                }

                // Create TimesheetEntry objects from timesheet data
                for entrySnapshot in timesheetData {
                    let entry = TimesheetEntry(snapshot: entrySnapshot)
                    self.timesheetEntries.append(entry)
                }

                // Sort the timesheet entries by key in descending order (newest first)
                self.timesheetEntries.sort { $0.date > $1.date }
                print("Timesheet Entries Count: \(self.timesheetEntries.count)")

//                self.timesheetTableView.reloadData()
                DispatchQueue.main.async {
                    self.timesheetTableView.reloadData()
                    self.timesheetTableView.flashScrollIndicators()
                }

                // Handle the 'note' field
                if let noteValue = otherData["note"] as? String {
                    self.noteTextView.text = noteValue
//                    self.noteTextView.isHidden = noteValue.isEmpty
                    self.noteTextViewHeightConstraint.constant = 80 // Show with default height
                    self.noteTextView.isHidden = false
                } else {
                    self.noteTextViewHeightConstraint.constant = 0
                    self.noteTextView.isHidden = true
                }

                // Important: Update layout after changing constraints
                UIView.animate(withDuration: 0.25) {
                  self.view.layoutIfNeeded()
                }
            }
    }

    
    
    
    // MARK: - Handle the Note
//    @objc func addNoteTapped() {
//        let alertController = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.addNoteButton"),
//                                                message: nil,
//                                                preferredStyle: .alert)
//        
//        // Add a textView to enter the note
//        alertController.addTextField { textField in
//            textField.placeholder = TranslationManager.shared.getTranslation(for: "timesheetTab.addNoteButton")
//            textField.text = self.noteTextView.text  // Pre-fill if a note already exists
//        }
//        
//        // Cancel Button
//        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil))
//
//        // Save Button
//        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.saveButton"), style: .default, handler: { _ in
//            if let noteText = alertController.textFields?.first?.text {
//                self.saveNoteToFirebase(noteText)
//            }
//        }))
//
//        present(alertController, animated: true)
//    }
    
    @objc func addNoteTapped() {
        let alertController = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.addNoteButton"),
                                                message: "\n\n\n\n\n", // Adds space for textView
                                                preferredStyle: .alert)
        
        // Create a UITextView for multi-line input
        let textView = UITextView(frame: CGRect(x: 10, y: 50, width: 250, height: 90)) // About 3 lines tall
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = self.noteTextView.text // Pre-fill existing note
        
        // Set autocapitalization to sentences
        textView.autocapitalizationType = .sentences
        
        // Add the textView to the UIAlertController's view
        alertController.view.addSubview(textView)
        
        // Cancel Button
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil))

        // Save Button
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.saveButton"), style: .default, handler: { _ in
            let noteText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.saveNoteToFirebase(noteText)
        }))

        // Present the alert
        present(alertController, animated: true)
    }

    
    func saveNoteToFirebase(_ note: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let notePath = databaseRef.child("customers").child(userParent).child("timesheets").child(userID).child("note")
        
        notePath.setValue(note) { error, _ in
            if let error = error {
                print("Error saving note: \(error.localizedDescription)")
                self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.noteSaveFailed"))
            } else {
                print("Successfully saved note")
//                self.noteTextView.text = note
//                self.noteTextView.isHidden = note.isEmpty  // Hide if empty
                
                self.noteTextView.text = note
                if note.isEmpty {
                    self.noteTextViewHeightConstraint.constant = 0
                    self.noteTextView.isHidden = true
                } else {
                    self.noteTextViewHeightConstraint.constant = 80 // Adjust height if needed
                    self.noteTextView.isHidden = false
                }

                // Animate the layout change
                UIView.animate(withDuration: 0.25) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }


    
    // MARK: - Location Helper
    
    func getLocation(completion: @escaping (String?) -> Void) {
        self.locationCompletion = completion  // Save the completion handler to be called later
        
        // Set a manual timeout for the location fetch
        let timeoutDuration: TimeInterval = 4  // Wait up to 5 seconds for the location
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutDuration) { [weak self] in
            guard let self = self else { return }
            
            if self.lastLocation == nil {
                print("\(Date()): Location fetch timed out.")
                self.locationManager.stopUpdatingLocation()
                self.locationCompletion?("None")  // Fallback to "None" if no location is fetched
            }
        }

        // Check the authorization status and handle it accordingly
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permissions are granted, start updating location
            print("\(Date()): Requesting location...")
            locationManager.startUpdatingLocation()
        case .notDetermined:
            // Request permission; the completion handler will be triggered in `locationManagerDidChangeAuthorization`
            print("\(Date()): Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Permission denied or restricted, handle appropriately
            handleLocationPermissionDenied()
            completion("None")  // Provide a fallback
        @unknown default:
            // Handle any unknown states
            showAlert(title: TranslationManager.shared.getTranslation(for: "timesheetTab.locationPermissionMessage"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.unknownErrorText"))
            completion("None")  // Provide a fallback
        }
    }



    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            self.locationCompletion?("None")  // Safely call the closure if it exists
            return
        }

        // Store the new location and the current timestamp
        lastLocation = location
        lastLocationFetchTime = Date()

        // Handle the location and stop further updates
        handleLocation(location, completion: self.locationCompletion)
        locationManager.stopUpdatingLocation()  // Stop location updates once we get the first location
    }

    // Handle location failure
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
        self.locationCompletion?("None")  // Fallback in case of failure
    }

    // Function to handle location data
//    private func handleLocation(_ location: CLLocation, completion: ((String?) -> Void)?) {
//        // Use the coordinates first to provide a quick response
//        let locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
//        completion?(locationString)  // Safely call the closure if it exists
//
//        // Optionally, perform reverse geocoding in the background
//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
//            if let placemark = placemarks?.first {
//                var addressString = ""
//                if let name = placemark.name {
//                    addressString += name
//                }
//                if let locality = placemark.locality {
//                    addressString += ", \(locality)"
//                }
//                if let country = placemark.country {
//                    addressString += ", \(country)"
//                }
//
//                print("Address retrieved: \(addressString)")
//                completion?(addressString)  // Safely call the closure if it exists
//            }
//        }
//    }
    
    private func handleLocation(_ location: CLLocation, completion: ((String?) -> Void)?) {
        let geocoder = CLGeocoder()

        // Perform reverse geocoding to get a human-readable address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                completion?("\(location.coordinate.latitude), \(location.coordinate.longitude)") // Fallback to coordinates
                return
            }

            if let placemark = placemarks?.first {
                var addressString = ""

                if let name = placemark.name {
                    addressString += name
                }
                if let locality = placemark.locality {
                    addressString += ", \(locality)"
                }
                if let country = placemark.country {
                    addressString += ", \(country)"
                }

                print("Address retrieved: \(addressString)")
                completion?(addressString.isEmpty ? "\(location.coordinate.latitude), \(location.coordinate.longitude)" : addressString) // Fallback if no address found
            } else {
                print("No placemarks found. Using coordinates as fallback.")
                completion?("\(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }


    
    func handleLocationPermissionDenied() {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.locationPermissionMessage"),
                                      message: TranslationManager.shared.getTranslation(for: "timesheetTab.locationPermissionReason"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.settings"), style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel))
        present(alert, animated: true)
    }


    // MARK: - Error Handling
    func showLocationManualEntryAlert() {
        showAlert(title: TranslationManager.shared.getTranslation(for: "timesheetTab.locationPermissionDenied"), message: TranslationManager.shared.getTranslation(for: "timesheetTab.enterLocationManually"))
    }
    
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default))
        present(alert, animated: true)
    }
    
    
    func showInformUser(_ message: String) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetNoticeHeader"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default))
        present(alert, animated: true)
    }


}



extension TimesheetViewController: ClockOffDialogDelegate {
    func didCompleteClockOff(hadLunchBreak: Bool, lengthOfLunch: String, lengthOfHire: String, stopLocation: String) {
        guard let sessionID = currentSessionID else { return }

        let stopTime = Int64(Date().timeIntervalSince1970 * 1000)

        var updates: [String: Any] = [
            "stopTime": stopTime,
            "hadLunchBreak": hadLunchBreak,
            "lengthOfLunch": lengthOfLunch,
            "lengthOfHire": lengthOfHire,
            "stopLocation": stopLocation, // Add location here
        ]


        print("\(Date()): Updates to save: \(updates)")

        self.databaseRef.child("customers")
            .child(self.userParent)
            .child("timesheets")
            .child(Auth.auth().currentUser?.uid ?? "")
            .child(sessionID)
            .updateChildValues(updates) { error, _ in
                self.hideSpinner()
                if let error = error {
                    print("\(Date()): Error saving stop work session: \(error.localizedDescription)")
                    self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetFailedToStop"))
                } else {
                    print("\(Date()): Successfully stopped work session with ID: \(sessionID)")
                    self.isWorking = false
                    self.updateUIForStopWork()
                    self.updateButtonStates()
                }
            }
    }
}




//struct TimesheetEntry {
//    let date: TimeInterval
//    let startTime: TimeInterval
//    let startLocation: String?
//    let stopTime: TimeInterval?
//    let stopLocation: String?
//
//    init(snapshot: DataSnapshot) {
//        let snapshotValue = snapshot.value as? [String: Any] ?? [:]
//        self.date = snapshotValue["date"] as? TimeInterval ?? 0
//        self.startTime = snapshotValue["startTime"] as? TimeInterval ?? 0
//        self.startLocation = snapshotValue["startLocation"] as? String
//        self.stopTime = snapshotValue["stopTime"] as? TimeInterval
//        self.stopLocation = snapshotValue["stopLocation"] as? String
//    }
//}

struct TimesheetEntry {
    let date: TimeInterval
    let startTime: TimeInterval
    let startLocation: String?
    let stopTime: TimeInterval?
    let stopLocation: String?
    
    let hireEquipmentIncluded: Bool
    let equipmentType: String?
    let lengthOfHire: String?
    let hadLunchBreak: Bool?

    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as? [String: Any] ?? [:]
        self.date = snapshotValue["date"] as? TimeInterval ?? 0
        self.startTime = snapshotValue["startTime"] as? TimeInterval ?? 0
        self.startLocation = snapshotValue["startLocation"] as? String
        self.stopTime = snapshotValue["stopTime"] as? TimeInterval
        self.stopLocation = snapshotValue["stopLocation"] as? String
        
        // New Fields
        self.hireEquipmentIncluded = snapshotValue["hireEquipmentIncluded"] as? Bool ?? false
        self.equipmentType = snapshotValue["equipmentType"] as? String
        self.lengthOfHire = snapshotValue["lengthOfHire"] as? String
        self.hadLunchBreak = snapshotValue["hadLunchBreak"] as? Bool
    }
}

