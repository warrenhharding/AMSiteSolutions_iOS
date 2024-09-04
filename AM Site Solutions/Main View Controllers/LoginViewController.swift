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
//import SnapKit


class UserSession {
    static let shared = UserSession()
    
    var userType: String?
    var userParent: String?
    
    private init() { }
}



class LoginViewController: UIViewController {

    // UI elements
    let logoImageView = UIImageView()
    let phoneNumberLabel = UILabel()
    let phoneNumberTextField = UITextField()
    let submitButton = UIButton(type: .system)
    let termsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        print("Inside the LoginViewController")
        setupUI()
        // Temporarily disable checkLoggedInStatus()
        checkLoggedInStatus()
        // Add tap gesture recognizer to termsButton to open Safari
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openTermsAndConditions))
        termsButton.addGestureRecognizer(tapGestureRecognizer)
        
        // Add observers for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
    
    
    private func checkLoggedInStatus() {
        if let user = Auth.auth().currentUser {
            print("User is logged in as: \(user.uid)")
//            self.logoutUser()
        } else {
            print("User is not logged in")
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
        phoneNumberLabel.text = "Phone Number"
        phoneNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Phone Number Text Field
        phoneNumberTextField.placeholder = "Enter your phone number"
        phoneNumberTextField.borderStyle = .roundedRect
        phoneNumberTextField.keyboardType = .phonePad
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Submit Button
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        submitButton.backgroundColor = ColorScheme.amPink
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Terms Button
        let termsText = "Terms and Conditions"
        let attributedString = NSMutableAttributedString(string: termsText)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: termsText.count))
        termsButton.setAttributedTitle(attributedString, for: .normal)
        termsButton.setTitleColor(ColorScheme.amBlue, for: .normal)
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(logoImageView)
        view.addSubview(phoneNumberLabel)
        view.addSubview(phoneNumberTextField)
        view.addSubview(submitButton)
        view.addSubview(termsButton)
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            // Logo ImageView Constraints
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 400),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Phone Number Label Constraints
            phoneNumberLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 100),
            phoneNumberLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            phoneNumberLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Phone Number TextField Constraints
            phoneNumberTextField.topAnchor.constraint(equalTo: phoneNumberLabel.bottomAnchor, constant: 12),
            phoneNumberTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            phoneNumberTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Submit Button Constraints
            submitButton.topAnchor.constraint(equalTo: phoneNumberTextField.bottomAnchor, constant: 30),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Terms Button Constraints
            termsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            termsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
            displayErrorAlert(message: "Please enter a valid Irish phone number (starting with 085, 086, 087) or an international number.")
            return
        }
        
        // Format phone number with country code
        let phoneNumberWithCountryCode = formatPhoneNumber(phoneNumber)
        print("Formatted phone number: \(phoneNumberWithCountryCode)")
        
        // Firebase phone number verification
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberWithCountryCode, uiDelegate: nil) { [weak self] (verificationID, error) in
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
            
            // Successfully sent verification code
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.showVerificationCodeInputAlert()
        }
    }

    // Validate phone number format
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        // Check if it's a valid Irish number or international number
        return phoneNumber.hasPrefix("+353") || phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089")
    }

    // Format phone number with country code if needed
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        if phoneNumber.hasPrefix("+353") {
            // Already formatted with country code
            return phoneNumber
        } else if phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089") {
            // Irish number without country code, add +353
            return "+353" + String(phoneNumber.dropFirst())
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
        let ref = Database.database().reference().child("users/\(user.uid)")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot, prevChildKey: String?) in
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

        if userType == "operator" {
            let operatorVC = OperatorViewController()
            if let navigationController = navigationController {
                print("Pushing to OperatorVC")
                navigationController.pushViewController(operatorVC, animated: true)
            } else {
                print("navigationController is nil. Presenting OperatorVC modally.")
                let newNavigationController = UINavigationController(rootViewController: operatorVC)
                newNavigationController.modalPresentationStyle = .fullScreen
                present(newNavigationController, animated: true, completion: nil)
            }
        } else if userType == "admin" {
            let mainTabBarController = MainTabBarController()
            print("Presenting MainTabBarController modally")
            mainTabBarController.modalPresentationStyle = .fullScreen
            present(mainTabBarController, animated: true, completion: nil)
        } else {
            print("Unknown user type")
            return
        }
    }



    
//    private func navigateToMainScreen(userType: String) {
//        print("About to move to the tab controller")
//
//        let viewController: UIViewController
//
//        if userType == "operator" {
//            viewController = OperatorVC()
//        } else if userType == "admin" {
//            viewController = MainTabBarController()
//        } else {
//            print("Unknown user type")
//            return
//        }
//
//        if let navigationController = navigationController {
//            print("Pushing to the \(userType) view controller")
//            navigationController.pushViewController(viewController, animated: true)
//        } else {
//            print("Presenting the \(userType) view controller modally")
//            let newNavigationController = UINavigationController(rootViewController: viewController)
//            newNavigationController.modalPresentationStyle = .fullScreen
//            present(newNavigationController, animated: true, completion: nil)
//        }
//    }

    

    // Parse Firebase Auth errors to display meaningful messages
    private func parseFirebaseAuthError(_ error: Error) -> String {
        // Check if the error is an NSError
        if let nsError = error as NSError? {
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
                    return "Authentication error: \(error.localizedDescription)"
                }
            }
        }
        // Return a generic error message if the error is not a FirebaseAuth error
        return "Authentication error: \(error.localizedDescription)"
//        return "X"
    }



    // Display generic error alert
    private func displayErrorAlert(message: String) {
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


