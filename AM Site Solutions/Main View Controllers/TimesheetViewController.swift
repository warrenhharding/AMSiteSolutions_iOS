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
    var startButton: CustomButton!
    var stopButton: CustomButton!
    var submitButton: CustomButton!
    var startTimeLabel: UILabel!
    var timesheetTableView: UITableView!
    var locationManager: CLLocationManager!
    var activityIndicator: UIActivityIndicatorView!
    
    var timesheetEntries = [TimesheetEntry]()  // Data for table view
    var currentSessionID: String?
    var isWorking = false
    var userParent: String = UserSession.shared.userParent ?? ""
    
    var lastLocation: CLLocation?
    var lastLocationFetchTime: Date?

    
    // Firebase Database reference
    let databaseRef = Database.database().reference()
//    var locationCompletionHandler: ((String?) -> Void)?
    var locationCompletion: ((String?) -> Void)?


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TranslationManager.shared.getTranslation(for: "timesheetTab.timeTabTitle")
    
        setupUI()
        setupLocationManager()
        
        // Register the custom cell
        timesheetTableView.register(TimesheetEntryCell.self, forCellReuseIdentifier: "TimesheetEntryCell")
        
        // Check permissions and setup the location manager properly
        checkPermissionsAndInitializeLocation()

//        setupUI()
        loadTimesheetData()
        checkOngoingSession()
        updateButtonStates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
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
        
        // Start Button
        startButton = CustomButton(type: .system)
//        startButton.setTitle("Clock On", for: .normal)
        startButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOnButton"), for: .normal)
        startButton.addTarget(self, action: #selector(startWorkSession), for: .touchUpInside)
        view.addSubview(startButton)
        
        // Stop Button
        stopButton = CustomButton(type: .system)
        stopButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clockOffButton"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopWorkSession), for: .touchUpInside)
        stopButton.isEnabled = false
        view.addSubview(stopButton)
        
        // Start Time Label
        startTimeLabel = UILabel()
        startTimeLabel.textAlignment = .center
        startTimeLabel.isHidden = true
        view.addSubview(startTimeLabel)
        
        // Timesheet TableView
        timesheetTableView = UITableView()
        timesheetTableView.delegate = self
        timesheetTableView.dataSource = self
        view.addSubview(timesheetTableView)
        
        // Submit Button
        submitButton = CustomButton(type: .system)
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.submitTimesheetButton"), for: .normal)
        submitButton.addTarget(self, action: #selector(submitTimesheet), for: .touchUpInside)
        view.addSubview(submitButton)
        
        // Actiity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Constraints
        setupConstraints()
    }
    
    func setupConstraints() {
        // Use AutoLayout for positioning the UI elements
        startButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        timesheetTableView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Start Button
            startButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Stop Button
            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Start Time Label
            startTimeLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 8),
            startTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            startTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Timesheet TableView
            timesheetTableView.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 16),
            timesheetTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timesheetTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timesheetTableView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -16),
            
            // Submit Button
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Actiity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
    
    func checkOngoingSession() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found")
            return
        }

        print("Checking ongoing session for userParent = \(userParent) and userID = \(userID)")

        // Query the database for the latest session
        databaseRef.child("customers")
            .child(userParent)
            .child("timesheets")
            .child(userID)
            .queryOrderedByKey()
            .queryLimited(toLast: 1)
            .observeSingleEvent(of: .value) { snapshot in
                print("Snapshot children count: \(snapshot.childrenCount)")
                
                if let lastSession = snapshot.children.allObjects.first as? DataSnapshot {
                    print("Last session data: \(lastSession)")
                    
                    let stopTime = lastSession.childSnapshot(forPath: "stopTime").value as? TimeInterval
                    let startTime = lastSession.childSnapshot(forPath: "startTime").value as? TimeInterval ?? 0
                    
                    print("Session startTime: \(startTime)")
                    if let stopTime = stopTime {
                        print("Session stopTime: \(stopTime)")
                    } else {
                        print("No stopTime, session is ongoing")
                    }

                    if stopTime == nil {
                        // Ongoing session, check if it's from a previous day
                        let startDate = Date(timeIntervalSince1970: startTime / 1000)  // Assuming timestamp is in milliseconds
                        let today = Date()

                        if !Calendar.current.isDate(startDate, inSameDayAs: today) {
                            // Set stop time to 23:59 of the start day
                            var calendar = Calendar.current
                            calendar.timeZone = TimeZone.current
                            
                            var endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) ?? startDate
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



    // MARK: - Start and Stop Work Sessions
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
//        let startTime = Date().timeIntervalSince1970 * 1000  // Convert to milliseconds
        let startTime = Int64(Date().timeIntervalSince1970 * 1000)
        print("\(Date()): Start time (timestamp in milliseconds): \(startTime)")
        
        self.showSpinner()
        
        getLocation { location in
            print("\(Date()): Location received: \(location ?? "None")")
            
            let timesheetData: [String: Any] = [
                "date": startTime,
                "startTime": startTime,
                "startLocation": location ?? "None"
            ]
            
            print("\(Date()): Timesheet data to save: \(timesheetData)")
                        
            guard let sessionID = self.currentSessionID else {
                print("\(Date()): Error: currentSessionID is nil")
                self.hideSpinner()
                self.showError(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetNoSessionId"))
                return
            }
            
            print("\(Date()): Attempting to save start work session to Firebase.")
            
            // Attempt to save data to the database
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


    @objc func stopWorkSession() {
        guard isWorking, let sessionID = currentSessionID else {
            print("\(Date()): Attempted to stop session but no active session is running.")
            return
        }
        
        // Log the beginning of the stop session process
        print("\(Date()): Stop work session initiated.")
        
        // Get the stop time in milliseconds
//        let stopTime = Date().timeIntervalSince1970 * 1000  // Convert to milliseconds
        let stopTime = Int64(Date().timeIntervalSince1970 * 1000)
        print("\(Date()): Stop time (timestamp in milliseconds): \(stopTime)")
        
        self.showSpinner()
        
        getLocation { location in
            print("\(Date()): Location received: \(location ?? "None")")
            
            let updates: [String: Any] = [
                "stopTime": stopTime,
                "stopLocation": location ?? "None"
            ]
            
            print("\(Date()): Updates to save: \(updates)")
            
            // Attempt to save the stop time to the database
            print("\(Date()): Attempting to save stop work session to Firebase.")
            
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
            }
        }
    }
    
    // MARK: - Helper Methods for UI Updates
    func updateUIForStartWork(startTime: Double) {
        startButton.isEnabled = false
        stopButton.isEnabled = true
        startTimeLabel.text = "\(TranslationManager.shared.getTranslation(for: "timesheetTab.timesheetProgressLabel")) \(formatTime(startTime))"
        startTimeLabel.isHidden = false
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
    func loadTimesheetData() {
        databaseRef.child("customers")
            .child(userParent)
            .child("timesheets")
            .child(Auth.auth().currentUser?.uid ?? "")
            .observe(.value) { snapshot in
                self.timesheetEntries.removeAll()
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot {
                        print("snapshot = \(snapshot)")
                        let entry = TimesheetEntry(snapshot: snapshot) // No optional check needed
                        self.timesheetEntries.append(entry)
                    }
                }
                self.timesheetEntries = self.timesheetEntries.reversed()
                self.timesheetTableView.reloadData()
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
            showAlert(title: "Unknown Error", message: "An unknown error occurred with location permissions.")
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
    private func handleLocation(_ location: CLLocation, completion: ((String?) -> Void)?) {
        // Use the coordinates first to provide a quick response
        let locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        completion?(locationString)  // Safely call the closure if it exists

        // Optionally, perform reverse geocoding in the background
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
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
                completion?(addressString)  // Safely call the closure if it exists
            }
        }
    }

    
    func handleLocationPermissionDenied() {
        let alert = UIAlertController(title: "Location Permission Required",
                                      message: "We need access to your location to track your timesheet. Please enable location services in Settings.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.settings"), style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel))
        present(alert, animated: true)
    }


    // MARK: - Error Handling
    func showLocationManualEntryAlert() {
        showAlert(title: "Location Permission Denied", message: "Please enter the location manually.")
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



struct TimesheetEntry {
    let date: TimeInterval
    let startTime: TimeInterval
    let startLocation: String?
    let stopTime: TimeInterval?
    let stopLocation: String?

    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as? [String: Any] ?? [:]
        self.date = snapshotValue["date"] as? TimeInterval ?? 0
        self.startTime = snapshotValue["startTime"] as? TimeInterval ?? 0
        self.startLocation = snapshotValue["startLocation"] as? String
        self.stopTime = snapshotValue["stopTime"] as? TimeInterval
        self.stopLocation = snapshotValue["stopLocation"] as? String
    }
}
