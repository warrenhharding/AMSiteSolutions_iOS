//
//  LoginViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFunctions


class UserSession {
    static let shared = UserSession()
    
    var userType: String?
    var userParent: String?
    
    private init() { }
}


class LoginViewController: UIViewController {

    // UI elements
    let languageStackView = UIStackView()
    let globeImageView = UIImageView()
    let languageLabel = UILabel()
    
    let languageSelectorButton = CustomButton(type: .system)
    let logoImageView = UIImageView()
    let phoneNumberLabel = UILabel()
    let phoneNumberTextField = UITextField()
    let submitButton = CustomButton(type: .system)
    let termsButton = UIButton(type: .system)
    
    let spinner = UIActivityIndicatorView(style: .large)
    
    let pickerView = UIPickerView()
    let toolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        print("Inside the LoginViewController")

        // Temporarily disable checkLoggedInStatus()
        checkLoggedInStatus()
        
        // Add tap gesture recognizer to termsButton to open Safari
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openTermsAndConditions))
        termsButton.addGestureRecognizer(tapGestureRecognizer)
        
        setupLanguagePicker()
        
        setupDismissKeyboardGesture()
        
        // Configure spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .gray
        view.addSubview(spinner)

        // Center spinner
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Check if translations are already loaded
        if TranslationManager.shared.isTranslationsLoaded {
            print("Translations already loaded, setting up UI immediately.")
            setupUI()
        } else {
            print("Waiting for translations to load.")
            NotificationCenter.default.addObserver(self, selector: #selector(translationsLoaded), name: .translationsLoaded, object: nil)
        }
        
        // Add observers for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(translationsLoaded), name: .translationsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(languagesDidLoad), name: .languagesLoaded, object: nil)
        
        // Check if a user is already logged in
        if let user = Auth.auth().currentUser {
            // User is signed in, fetch user details
            fetchUserDetails(user: user)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded() // Force layout update
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func languagesDidLoad() {
        // Update your UI here
        updateLanguageSelector()
        pickerView.reloadAllComponents()
    }
    
    private func setupLanguagePicker() {
        // Picker View
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.backgroundColor = .white
        pickerView.isHidden = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)

        // Toolbar
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = ColorScheme.amBlue
        toolbar.sizeToFit()
        toolbar.isHidden = true

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Layout
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: pickerView.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 216)
        ])
    }
    
    @objc private func languageSelectorTapped() {
        toolbar.isHidden = false
        pickerView.isHidden = false
    }

    @objc private func doneButtonTapped() {
        toolbar.isHidden = true
        pickerView.isHidden = true
    }
    
    
    
    func setupLanguageSelector() {
        // Configure the globe icon
        globeImageView.image = UIImage(systemName: "globe") // SF Symbol for globe
        globeImageView.tintColor = ColorScheme.amBlue
        globeImageView.contentMode = .scaleAspectFit
        globeImageView.translatesAutoresizingMaskIntoConstraints = false

        // Configure the language label
        languageLabel.text = TranslationManager.shared.getTranslation(for: "common.selectLanguage")
        languageLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        languageLabel.textColor = ColorScheme.amBlue
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stack View for Globe and Label
        let selectorStackView = UIStackView(arrangedSubviews: [globeImageView, languageLabel])
        selectorStackView.axis = .horizontal
        selectorStackView.spacing = 6 // Reduced spacing for closer alignment
        selectorStackView.alignment = .center
        selectorStackView.translatesAutoresizingMaskIntoConstraints = false

        // Add a background container with rounded edges
        let backgroundContainer = UIView()
        backgroundContainer.backgroundColor = UIColor.systemGray6
        backgroundContainer.layer.cornerRadius = 16
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add a transparent button for the tap area
        let tapAreaButton = UIButton(type: .system)
        tapAreaButton.addTarget(self, action: #selector(languageSelectorTapped), for: .touchUpInside)
        tapAreaButton.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        view.addSubview(backgroundContainer)
        backgroundContainer.addSubview(selectorStackView)
        backgroundContainer.addSubview(tapAreaButton)

        // Constraints for the background container
        NSLayoutConstraint.activate([
            backgroundContainer.bottomAnchor.constraint(equalTo: logoImageView.topAnchor, constant: -20), // Move closer to the logo
            backgroundContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundContainer.widthAnchor.constraint(equalTo: selectorStackView.widthAnchor, constant: 32), // Add 16 points padding on each side (left & right)
            backgroundContainer.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Constraints for the selector stack view
        NSLayoutConstraint.activate([
            selectorStackView.centerYAnchor.constraint(equalTo: backgroundContainer.centerYAnchor),
            selectorStackView.centerXAnchor.constraint(equalTo: backgroundContainer.centerXAnchor)
        ])

        // Tap area matches the container
        NSLayoutConstraint.activate([
            tapAreaButton.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            tapAreaButton.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            tapAreaButton.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            tapAreaButton.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor)
        ])
    }
    
    
    func updateLanguageSelector() {
        let currentLanguage = TranslationManager.shared.getSelectedLanguage()
        if let language = LanguageManager.shared.availableLanguages.first(where: { $0.code == currentLanguage }) {
            languageLabel.text = language.name
        } else {
            languageLabel.text = "English"
        }
    }
    
    
    @objc func translationsLoaded() {
        print("Translations loaded, setting up UI.")
        setupUI()
    }
    
    @objc func reloadTranslations() {
        phoneNumberLabel.text = TranslationManager.shared.getTranslation(for: "loginScreen.phoneNoLabel")
        phoneNumberTextField.placeholder = TranslationManager.shared.getTranslation(for: "loginScreen.phoneNoPrompt")
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "common.submitButton"), for: .normal)
        let termsText = TranslationManager.shared.getTranslation(for: "loginScreen.termsText")
        let attributedString = NSMutableAttributedString(string: termsText)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: termsText.count))
        termsButton.setAttributedTitle(attributedString, for: .normal)
        updateLanguageSelector()
    }
    
    func showLanguagePicker() {
        let alert = UIAlertController(title: "Select Language", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "English", style: .default, handler: { _ in
            TranslationManager.shared.changeLanguage(to: "en") { success in
                if success {
                    NotificationCenter.default.post(name: .languageChanged, object: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Español", style: .default, handler: { _ in
            TranslationManager.shared.changeLanguage(to: "es") { success in
                if success {
                    NotificationCenter.default.post(name: .languageChanged, object: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    
    
    func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    private func checkLoggedInStatus() {
        if let user = Auth.auth().currentUser {
//            print("User is logged in as: \(user.uid)")
//            self.logoutUser()
        } else {
//            print("User is not logged in")
        }
    }
    
    
    func logoutUser() {
        do {
            try Auth.auth().signOut()
            // Optionally, navigate the user back to the login screen
            // or update your app's UI to reflect the logged-out state.
            print("User signed out successfully.")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
            // Handle sign-out errors gracefully (e.g., show an error message).
        }
    }
    
    

    
    func setupUI() {
        print("Starting setupUI")
        
        // Logo
        logoImageView.image = UIImage(named: "AppLogo") // Set your logo image here
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Phone Number Label
//        phoneNumberLabel.text = "Phone Number"
        phoneNumberLabel.text = TranslationManager.shared.getTranslation(for: "loginScreen.phoneNoLabel")
        phoneNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Phone Number Text Field
//        phoneNumberTextField.placeholder = "Enter your phone number"
        phoneNumberTextField.placeholder = TranslationManager.shared.getTranslation(for: "loginScreen.phoneNoPrompt")
        phoneNumberTextField.borderStyle = .roundedRect
        phoneNumberTextField.keyboardType = .phonePad
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Submit Button
//        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "common.submitButton"), for: .normal)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        submitButton.backgroundColor = ColorScheme.amPink
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Terms Button
//        let termsText = "Terms and Conditions"
        let termsText = TranslationManager.shared.getTranslation(for: "loginScreen.termsText")
        let attributedString = NSMutableAttributedString(string: termsText)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: termsText.count))
        termsButton.setAttributedTitle(attributedString, for: .normal)
        termsButton.setTitleColor(ColorScheme.amBlue, for: .normal)
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack View for the TextField and Button
        let stackView = UIStackView(arrangedSubviews: [phoneNumberLabel, phoneNumberTextField, submitButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(logoImageView)
        view.addSubview(stackView)
        
        // Call setupLanguageSelector() here to add the selector
        setupLanguageSelector()
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            // Logo ImageView Constraints
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120), // Lowered further
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 0.5),

            // Stack View Constraints
            stackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 60), // More space below the logo
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Adjust the height of the text field and button
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 40),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        print("Finishing setupUI")
    }



 
    @objc func submitButtonTapped() {
        // Safely unwrap the phone number text field's text
        guard let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty else {
            displayErrorAlert(message: "Please enter a phone number.")
            return
        }
        
        // Validate phone number
        if !isValidPhoneNumber(phoneNumber) {
            displayErrorAlert(message: "Please enter a valid Irish phone number (starting with 083, 085, 086, 087, 089) or an international number.")
            return
        }
        
        // Show spinner
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
        
        // Format phone number with country code
        let phoneNumberWithCountryCode = formatPhoneNumber(phoneNumber)
        print("Formatted phone number: \(phoneNumberWithCountryCode)")
        
        // Firebase phone number verification
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberWithCountryCode, uiDelegate: nil) { [weak self] (verificationID, error) in
            print("About to send the request for a verifationId")
            guard let self = self else { return }
            
            if let error = error {
                // Handle Firebase error
                let errorMessage = self.parseFirebaseAuthError(error)
                self.displayErrorAlert(message: errorMessage)
                return
            }
            
            // Ensure verificationID is not nil before storing it
            guard let verificationID = verificationID else {
                self.displayErrorAlert(message: "Failed to send verification code. Please try again.")
                return
            }
            
            // Log the verificationID for debugging
            print("Received verificationID: \(verificationID)")
            
            // Successfully sent verification code
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.showVerificationCodeInputAlert()
        }
    }
    
    // Validate phone number format
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        var isValid = false

        // Check if the number starts with the Irish international code or an Irish mobile number prefix
        if phoneNumber.hasPrefix("+3538") || phoneNumber.range(of: "^08[35679]\\d{7}$", options: .regularExpression) != nil {
            // If it starts with '08', transform it to the international format
            if phoneNumber.hasPrefix("08") {
                let formattedNumber = phoneNumber.replacingOccurrences(of: "^08", with: "+3538", options: .regularExpression)
                print("Formatted Irish phone number: \(formattedNumber)")
                isValid = true
            } else {
                isValid = true
            }
        } else if phoneNumber.hasPrefix("+") {
            // Allow any number that starts with a "+" (indicating an international number)
            isValid = true
        }

        // Log the validation attempt (you can add logging logic here)
//        logValidationAttempt(phoneNumber: phoneNumber, isValid: isValid)

        // Return the validation result
        return isValid
    }


    // Format phone number with country code if needed
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        if phoneNumber.hasPrefix("+353") {
            // Already formatted with country code
            return phoneNumber
        } else if phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089") || phoneNumber.hasPrefix("083") {
            // Irish number without country code, add +353
            return "+353" + String(phoneNumber.dropFirst())
        } else if phoneNumber.hasPrefix("08") {
            // Handle other Irish numbers that need formatting
            return phoneNumber.replacingOccurrences(of: "^08", with: "+3538", options: .regularExpression)
        } else {
            // Handle other international numbers as needed
            return phoneNumber
        }
    }

    // Display alert for entering verification code
    private func showVerificationCodeInputAlert() {
        let alert = UIAlertController(title: "Enter Verification Code", message: "Please enter the verification code sent to your phone.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Verification Code"
            textField.keyboardType = .numberPad
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] action in
            guard let self = self else { return }
            
            // Safely unwrap the text field's text
            guard let verificationCode = alert.textFields?.first?.text, !verificationCode.isEmpty else {
                self.displayErrorAlert(message: "Verification code cannot be empty.")
                return
            }
            
            self.verifyPhoneNumberWithCode(verificationCode)
        }
        
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }


    // Verify phone number with entered verification code
    private func verifyPhoneNumberWithCode(_ verificationCode: String) {
        // Safely retrieve the verification ID from UserDefaults
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            displayErrorAlert(message: "Verification ID not found. Please try again.")
            return
        }
        
        // Show spinner
        spinner.startAnimating()
        view.isUserInteractionEnabled = false // Disable user interaction
        
        // Log the verificationID to ensure it's correct
        print("Retrieved verificationID: \(verificationID)")
        print("Verification code: \(verificationCode)")
        
        // Create the credential using the verification ID and code
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        // Sign in with Firebase using the credential
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            if let error = error {
                // Handle Firebase authentication error
                let errorMessage = self.parseFirebaseAuthError(error)
                self.displayErrorAlert(message: errorMessage)
                return
            }
            
            // Safely handle the authenticated user
            if let user = authResult?.user {
                self.fetchUserDetails(user: user)
            }
            
            // Authentication successful, handle next steps
            print("User authenticated successfully.")
        }
    }

    
    
    
    // Fetch user details from Realtime Database
    private func fetchUserDetails(user: User) {
        // Show spinner
        spinner.startAnimating()
        view.isUserInteractionEnabled = false // Disable user interaction
        
        let ref = Database.database().reference().child("users/\(user.uid)")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot, prevChildKey: String?) in

           // Hide spinner
           self.spinner.stopAnimating()
           self.view.isUserInteractionEnabled = true // Re-enable user interaction
            
            guard let userData = snapshot.value as? [String: Any] else {
                self.displayErrorAlert(message: "User data not found.")
                print("Error: User data snapshot is not a dictionary.")
                return
            }
            
            guard let userType = userData["userType"] as? String else {
                self.displayErrorAlert(message: "User type not found.")
                print("Error: userType not found in userData.")
                return
            }
            
            guard let userParent = userData["userParent"] as? String else {
                self.displayErrorAlert(message: "User parent not found.")
                print("Error: userParent not found in userData.")
                return
            }
            
            // Store userType and userParent in a global variable or singleton
            UserSession.shared.userType = userType
            UserSession.shared.userParent = userParent
            
            print("User details fetched successfully: userType=\(userType), userParent=\(userParent)")
            
            // Check subscription status
            self.checkSubscriptionStatus(userParent: userParent, userType: userType)
        }
    }
    
    
    
    // Check subscription status
    private func checkSubscriptionStatus(userParent: String, userType: String) {
        let ref = Database.database().reference().child("customers/\(userParent)/subscriptionStatus")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot, prevChildKey: String?) in
            guard let subscriptionStatus = snapshot.value as? String else {
                self.displayErrorAlert(message: "Subscription status not found.")
                print("Error: Subscription status not found for userParent \(userParent).")
                return
            }

            if subscriptionStatus != "inactive" {
                print("Subscription is active.")
                self.navigateToMainScreen(userType: userType)
            } else {
                self.displayErrorAlert(message: "Subscription is not active. Please renew your subscription.")
                print("Subscription is not active for userParent \(userParent).")
            }
        }
    }

    
    private func navigateToMainScreen(userType: String) {
        print("About to move to the main screen")

        if userType == "operator" || userType == "admin" || userType == "amAdmin"{
            let mainTabBarController = MainTabBarController(userType: userType) // Pass the userType to the TabBarController
            print("Presenting MainTabBarController modally")
            mainTabBarController.modalPresentationStyle = .fullScreen
            present(mainTabBarController, animated: true, completion: nil)
        } else {
            print("Unknown user type, defaulting to operator")
            let mainTabBarController = MainTabBarController(userType: "operator") // Default to operator if user type is unknown
            mainTabBarController.modalPresentationStyle = .fullScreen
            present(mainTabBarController, animated: true, completion: nil)
        }
    }

    

    private func parseFirebaseAuthError(_ error: Error) -> String {
        // Check if the error is an NSError
        if let nsError = error as NSError? {
            // Log the error domain and code for debugging
            print("Error Domain: \(nsError.domain)")
            print("Error Code: \(nsError.code)")
            print("Error Description: \(nsError.localizedDescription)")

            // Check if the error domain is FirebaseAuth
            if nsError.domain == AuthErrorDomain {
                // Get the error code
                let errorCode = AuthErrorCode(rawValue: nsError.code)
                // Handle the error code
                switch errorCode {
                case .invalidPhoneNumber:
                    return "Invalid phone number. Please enter a valid number."
                case .missingPhoneNumber:
                    return "Phone number is missing. Please enter a phone number."
                case .quotaExceeded:
                    return "SMS quota exceeded. Please try again later."
                case .sessionExpired:
                    return "Session expired. Please try again."
                default:
                    return "Authentication error: \(nsError.localizedDescription)"
                }
            }
        }
        
        // Return a generic error message if the error is not a FirebaseAuth error
        return "Authentication error: \(error.localizedDescription)"
    }



    // Display generic error alert
    private func displayErrorAlert(message: String) {
        // Hide spinner
        spinner.stopAnimating()
        view.isUserInteractionEnabled = true // Re-enable user interaction
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    @objc func openTermsAndConditions() {
        // Opens the terms and conditions page in safari
        if let url = URL(string: "https://www.your-website.com/terms-and-conditions") { // replace with the actual url to the terms and conditions page.
            UIApplication.shared.open(url)
        }
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            view.frame.origin.y = -keyboardHeight / 2
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
}




extension LoginViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return LanguageManager.shared.availableLanguages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return LanguageManager.shared.availableLanguages[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedLanguage = LanguageManager.shared.availableLanguages[row].code
        let selectedLanguageName = LanguageManager.shared.availableLanguages[row].name

        // Update the label immediately
        languageLabel.text = selectedLanguageName
        
        print("selectedLanguage: \(selectedLanguage)")
        print("selectedLanguageName: \(selectedLanguageName)")
        print("languageLabel.text: \(languageLabel.text)")
        
        // Change the app's language asynchronously
        TranslationManager.shared.changeLanguage(to: selectedLanguage) { success in
            if success {
                // Fetch the updated translation for "Done" after the language change is complete
                let doneLabel = TranslationManager.shared.getTranslation(for: "common.done")
                self.updateDoneButtonTitle(doneLabel)
                
                print("Updated Done label: \(doneLabel)")
                
                // Notify observers that the language has changed
                NotificationCenter.default.post(name: .languageChanged, object: nil)
            }
        }
    }
    
    

    // Helper method to update the "Done" button's title
    private func updateDoneButtonTitle(_ title: String) {
        if let doneButton = toolbar.items?.last {
            doneButton.title = title
        }
    }
}




// UIColor Extension (add to a separate file, or at the bottom of LoginViewController.swift)
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            self.init(hex: "ff0000") // Return red as default color for invalid hex code
            return
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}


