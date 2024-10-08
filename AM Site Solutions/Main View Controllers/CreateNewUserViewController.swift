//
//  CreateNewUserViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//

import UIKit
import FirebaseFunctions
import FirebaseDatabase

class CreateNewUserViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // UI Elements
    var firstNameLabel: UILabel!
    var surnameLabel: UILabel!
    var phoneNumberLabel: UILabel!
    var userTypeLabel: UILabel!
    
    var firstNameTextField: CustomTextField!
    var surnameTextField: CustomTextField!
    var phoneNumberTextField: CustomTextField!
    var userTypeTextField: CustomTextField!
    var userTypePicker: CustomPickerView!
    var submitButton: CustomButton!
    var activityIndicator: UIActivityIndicatorView!
    
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    // Variables to manage user creation/editing
    var isEditingUser: Bool = false // default to false
    var editingUserID: String? // store the user ID to edit
    
    // Firebase
    lazy var functions = Functions.functions()
    var userTypes: [String] = ["Please Select"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        title = "Create New User"
        title = isEditingUser ? "Edit User" : "Create New User"
        view.backgroundColor = .white

        setupNavigationBar()
        setupScrollView()
        setupUI()
        setupDismissKeyboardGesture()
        fetchUserTypes()
        
        // Fetch user details if in edit mode
        if isEditingUser, let userID = editingUserID {
            fetchUserDetails(userID: userID)
            addCloseButton()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Setup UI
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.rightBarButtonItem = closeButton
        navigationController?.navigationBar.tintColor = .white
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = ColorScheme.amBlue
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        }

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isUserInteractionEnabled = true
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = true

        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Force layout pass
        view.layoutIfNeeded()
        
        // Add print statements to debug
        print("ScrollView Frame: \(scrollView.frame)")
        print("ContentView Frame: \(contentView.frame)")
    }
    

    func setupUI() {
        // Initialize the userTypePicker and other UI components
        userTypePicker = CustomPickerView()
        userTypePicker.delegate = self
        userTypePicker.dataSource = self
        
        // First Name Label and Field
        firstNameLabel = UILabel()
        firstNameLabel.text = "First Name"
        contentView.addSubview(firstNameLabel)
        
        firstNameTextField = CustomTextField()
        firstNameTextField.placeholder = "Enter First Name"
        firstNameTextField.delegate = self
        contentView.addSubview(firstNameTextField)
        print("First Name TextField Frame: \(firstNameTextField.frame), Interactive: \(firstNameTextField.isUserInteractionEnabled)")
        
        // Surname Label and Field
        surnameLabel = UILabel()
        surnameLabel.text = "Surname"
        contentView.addSubview(surnameLabel)
        
        surnameTextField = CustomTextField()
        surnameTextField.placeholder = "Enter Surname"
        surnameTextField.delegate = self
        contentView.addSubview(surnameTextField)
        print("Surname TextField Frame: \(surnameTextField.frame), Interactive: \(surnameTextField.isUserInteractionEnabled)")
        
        // Phone Number Label and Field
        phoneNumberLabel = UILabel()
        phoneNumberLabel.text = "Phone Number"
        contentView.addSubview(phoneNumberLabel)
        
        phoneNumberTextField = CustomTextField()
        phoneNumberTextField.placeholder = "Enter Phone Number"
        phoneNumberTextField.keyboardType = .phonePad
        phoneNumberTextField.delegate = self
        contentView.addSubview(phoneNumberTextField)
        print("Phone Number TextField Frame: \(phoneNumberTextField.frame), Interactive: \(phoneNumberTextField.isUserInteractionEnabled)")
        
        // User Type Label and Field
        userTypeLabel = UILabel()
        userTypeLabel.text = "User Type"
        contentView.addSubview(userTypeLabel)
        
        userTypeTextField = CustomTextField()
        userTypeTextField.placeholder = "Select User Type"
        userTypeTextField.delegate = self
        userTypeTextField.addTarget(self, action: #selector(userTypeTextFieldTapped), for: .editingDidBegin)
        contentView.addSubview(userTypeTextField)
        
        // Submit Button and Activity Indicator
        submitButton = CustomButton(type: .system)
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        contentView.addSubview(submitButton)
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        contentView.addSubview(activityIndicator)
        
        setupConstraints()
    }

 
    func setupConstraints() {
        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
        surnameLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        userTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        surnameTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        userTypeTextField.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 16
        let textFieldHeight: CGFloat = 40
        
        print("ContentView is nil: \(contentView == nil)")  // Check if contentView is nil
        print("FirstNameLabel is nil: \(firstNameLabel == nil)")  // Check if firstNameLabel is nil
        print("UserTypeTextField Frame before layout: \(userTypeTextField.frame)")
        
        
        NSLayoutConstraint.activate([
            // First Name Label and Field
            firstNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            firstNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            firstNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            firstNameTextField.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 4),
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            firstNameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
            
            // Surname Label and Field
            surnameLabel.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: margin),
            surnameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            surnameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            surnameTextField.topAnchor.constraint(equalTo: surnameLabel.bottomAnchor, constant: 4),
            surnameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            surnameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            surnameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
            
            // Phone Number Label and Field
            phoneNumberLabel.topAnchor.constraint(equalTo: surnameTextField.bottomAnchor, constant: margin),
            phoneNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            phoneNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            phoneNumberTextField.topAnchor.constraint(equalTo: phoneNumberLabel.bottomAnchor, constant: 4),
            phoneNumberTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            phoneNumberTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
            
            // User Type Label and Field
            userTypeLabel.topAnchor.constraint(equalTo: phoneNumberTextField.bottomAnchor, constant: margin),
            userTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            userTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            userTypeTextField.topAnchor.constraint(equalTo: userTypeLabel.bottomAnchor, constant: 4),
            userTypeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            userTypeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            userTypeTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
            
            submitButton.topAnchor.constraint(equalTo: userTypeTextField.bottomAnchor, constant: margin),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            activityIndicator.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: margin),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Add this bottom constraint to ensure the contentView expands
            activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Check frames after layout
        view.layoutIfNeeded()
        print("First Name TextField Frame after layout: \(firstNameTextField.frame)")
        print("UserTypeTextField Frame after layout: \(userTypeTextField.frame)")
    }

    
    // MARK: - Firebase Functions

    func fetchUserTypes() {
        let ref = Database.database().reference(withPath: "staticData/userTypes")
        ref.observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: String] {
                self.userTypes = Array(value.values)
                print("Fetched user types: \(self.userTypes)")
            } else {
                print("Error fetching user types")
            }
        }
    }
    
    func fetchUserDetails(userID: String) {
        let ref = Database.database().reference().child("users").child(userID)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                print("Error: No user data found")
                return
            }
            
            // Populate the text fields with existing user data
            self.firstNameTextField.text = userData["firstName"] as? String
            self.surnameTextField.text = userData["surname"] as? String
            self.phoneNumberTextField.text = userData["userPhone"] as? String
            if let userType = userData["userType"] as? String,
               let userTypeIndex = self.userTypes.firstIndex(of: userType) {
                self.userTypePicker.selectRow(userTypeIndex, inComponent: 0, animated: false)
                self.userTypeTextField.text = userType
            }
        }
    }



    
    @objc func submitButtonTapped() {
        print("Submit Button Tapped")
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "Please enter a first name.")
            return
        }
        
        guard let surname = surnameTextField.text, !surname.isEmpty else {
            showAlert(message: "Please enter a surname.")
            return
        }
        
        guard let phoneNumber = phoneNumberTextField.text, isValidPhoneNumber(phoneNumber) else {
            showAlert(message: "Please enter a valid phone number.")
            return
        }
        
        let userType = userTypes[userTypePicker.selectedRow(inComponent: 0)]
        if userType == "Please Select" {
            showAlert(message: "Please select a user type.")
            return
        }
        
        // If in edit mode, update the user; otherwise, create a new user
        if isEditingUser, let userID = editingUserID {
            updateUser(userID: userID, firstName: firstName, surname: surname, phoneNumber: formatPhoneNumber(phoneNumber), userType: userType)
        } else {
            createUser(firstName: firstName, surname: surname, phoneNumber: formatPhoneNumber(phoneNumber), userType: userType)
        }
    }

    
    func createUser(firstName: String, surname: String, phoneNumber: String, userType: String) {
        let userCompany = "Company 1"  // Hardcoded for now
        let userParent = UserSession.shared.userParent

        let data = [
            "firstName": firstName,
            "surname": surname,
            "phoneNumber": phoneNumber,
            "userType": userType,
            "userCompany": userCompany,
            "userParent": userParent ?? ""
        ]

        showSpinner()

        functions.httpsCallable("createSubUser").call(data) { result, error in
            self.hideSpinner()

            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.showAlert(message: "An error occurred. Please try again.")
                return
            }

            if let response = result?.data as? [String: Any], response["success"] as? Bool == true {
                self.showAlertWithDismiss(message: "User created successfully!")
            } else {
                self.showAlert(message: "An unknown error occurred.")
            }
        }
    }
    
    func updateUser(userID: String, firstName: String, surname: String, phoneNumber: String, userType: String) {
        let userCompany = "Company 1"  // Hardcoded for now
        let userParent = UserSession.shared.userParent
        let formattedPhoneNumber = formatPhoneNumber(phoneNumber)

        let data: [String: Any] = [
            "userUID": userID,
            "firstName": firstName,
            "surname": surname,
            "userPhone": formattedPhoneNumber,  // The field name must be "userPhone" to match the cloud function
            "userType": userType,
            "userParent": userParent ?? ""  // Make sure userParent is not nil
        ]

        showSpinner()

        functions.httpsCallable("updateUser").call([
            "userUID": userID,
            "firstName": firstName,
            "surname": surname,
            "userPhone": phoneNumber,
            "userType": userType,
            "userParent": userParent
        ]) { result, error in

            self.hideSpinner()

            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.showAlert(message: "An error occurred. Please try again.")
                return
            }

            if let response = result?.data as? [String: Any], response["success"] as? Bool == true {
                self.showAlertWithDismiss(message: "User updated successfully!")
            } else {
                self.showAlert(message: "An unknown error occurred.")
            }
        }
    }

    
    // Spinner functions
    func showSpinner() {
        activityIndicator.startAnimating()
        submitButton.isEnabled = false
        view.isUserInteractionEnabled = false
    }
    
    func hideSpinner() {
        activityIndicator.stopAnimating()
        submitButton.isEnabled = true
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - UIPickerViewDelegate, UIPickerViewDataSource
        
    @objc func userTypeTextFieldTapped() {
        // Make sure we use the existing userTypePicker instance
        userTypeTextField.inputView = userTypePicker
        
        // Create a toolbar with a Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        toolbar.setItems([doneButton], animated: true)
        
        userTypeTextField.inputAccessoryView = toolbar
        
        // Ensure the picker is shown
        userTypeTextField.becomeFirstResponder()
    }

    // Done button action to close the picker
    @objc func doneTapped() {
        // Safely unwrap userTypePicker
        guard let picker = userTypePicker else {
            print("userTypePicker is nil")
            return
        }
        
        // Get the selected row and set the text in the text field
        let row = picker.selectedRow(inComponent: 0)
        userTypeTextField.text = userTypes[row]
        
        // Dismiss picker
        userTypeTextField.resignFirstResponder()
    }




    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1  // We only have one component (the list of user types)
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return userTypes.count  // The number of rows is based on the userTypes array
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return userTypes[row]  // Display each user type in the picker
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Optional: Handle what happens when the user selects a new user type
        // For now, this method can remain empty unless you want to update something dynamically based on the selected user type.
    }

    // MARK: - Validation & Formatting

    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        return phoneNumber.hasPrefix("+353") || phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089")
    }

    func formatPhoneNumber(_ phoneNumber: String) -> String {
        if phoneNumber.hasPrefix("+353") {
            return phoneNumber
        } else if phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089") {
            return "+353" + phoneNumber.dropFirst()
        }
        return phoneNumber
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Capitalize the first letter of each word
        if textField == firstNameTextField || textField == surnameTextField {
            let currentText = textField.text ?? ""
            let newString = (currentText as NSString).replacingCharacters(in: range, with: string)
            let capitalizedString = newString.capitalized
            textField.text = capitalizedString
            return false  // Return false because we've manually updated the text
        }
        return true
    }

    
    // MARK: - Helpers

    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showAlertWithDismiss(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)  // Pop the view controller to go back to the previous screen
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("Should Begin Editing: \(textField.placeholder ?? "No Placeholder")")
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Did Begin Editing: \(textField.placeholder ?? "No Placeholder")")
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("Did End Editing: \(textField.placeholder ?? "No Placeholder")")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("Should Return Editing: \(textField.placeholder ?? "No Placeholder")")
        textField.resignFirstResponder()
        return true
    }
}





//import UIKit
//import FirebaseFunctions
//import FirebaseDatabase
//
//class CreateNewUserViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
//    
//    // UI Elements
//    var firstNameLabel: UILabel!
//    var surnameLabel: UILabel!
//    var phoneNumberLabel: UILabel!
//    var userTypeLabel: UILabel!
//    
//    var firstNameTextField: CustomTextField!
//    var surnameTextField: CustomTextField!
//    var phoneNumberTextField: CustomTextField!
//    var userTypeTextField: CustomTextField!
//    var userTypePicker: CustomPickerView!
//    var submitButton: CustomButton!
//    var activityIndicator: UIActivityIndicatorView!
//    
//    var scrollView: UIScrollView!
//    var contentView: UIView!
//    
//    // Firebase
//    lazy var functions = Functions.functions()
//    var userTypes: [String] = ["Please Select"]
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        title = "Create New User"
//        view.backgroundColor = .white
//
//        setupNavigationBar()
//        setupScrollView()
//        setupUI()
//        setupDismissKeyboardGesture()
//        fetchUserTypes()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//
//    @objc func keyboardWillShow(notification: NSNotification) {
//        if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
//            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
//            scrollView.contentInset = contentInsets
//            scrollView.scrollIndicatorInsets = contentInsets
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification) {
//        scrollView.contentInset = .zero
//        scrollView.scrollIndicatorInsets = .zero
//    }
//    
//    // MARK: - Setup UI
//    
//    private func setupNavigationBar() {
//        if #available(iOS 13.0, *) {
//            let appearance = UINavigationBarAppearance()
//            appearance.configureWithOpaqueBackground()
//            appearance.backgroundColor = ColorScheme.amBlue
//            appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
//            
//            navigationController?.navigationBar.standardAppearance = appearance
//            navigationController?.navigationBar.scrollEdgeAppearance = appearance
//            navigationController?.navigationBar.compactAppearance = appearance
//        } else {
//            navigationController?.navigationBar.barTintColor = ColorScheme.amBlue
//            navigationController?.navigationBar.isTranslucent = false
//            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
//        }
//
//        navigationController?.navigationBar.tintColor = .white
//        navigationController?.navigationBar.prefersLargeTitles = false
//    }
//    
//    func setupScrollView() {
//        scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.isUserInteractionEnabled = true
//        view.addSubview(scrollView)
//        
//        contentView = UIView()
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.isUserInteractionEnabled = true
//
//        scrollView.addSubview(contentView)
//        
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
//        ])
//        
//        // Force layout pass
//        view.layoutIfNeeded()
//        
//        // Add print statements to debug
//        print("ScrollView Frame: \(scrollView.frame)")
//        print("ContentView Frame: \(contentView.frame)")
//    }
//    
//
//    func setupUI() {
//        // Initialize the userTypePicker and other UI components
//        userTypePicker = CustomPickerView()
//        userTypePicker.delegate = self
//        userTypePicker.dataSource = self
//        
//        // First Name Label and Field
//        firstNameLabel = UILabel()
//        firstNameLabel.text = "First Name"
//        contentView.addSubview(firstNameLabel)
//        
//        firstNameTextField = CustomTextField()
//        firstNameTextField.placeholder = "Enter First Name"
//        firstNameTextField.delegate = self
//        contentView.addSubview(firstNameTextField)
//        print("First Name TextField Frame: \(firstNameTextField.frame), Interactive: \(firstNameTextField.isUserInteractionEnabled)")
//        
//        // Surname Label and Field
//        surnameLabel = UILabel()
//        surnameLabel.text = "Surname"
//        contentView.addSubview(surnameLabel)
//        
//        surnameTextField = CustomTextField()
//        surnameTextField.placeholder = "Enter Surname"
//        surnameTextField.delegate = self
//        contentView.addSubview(surnameTextField)
//        print("Surname TextField Frame: \(surnameTextField.frame), Interactive: \(surnameTextField.isUserInteractionEnabled)")
//        
//        // Phone Number Label and Field
//        phoneNumberLabel = UILabel()
//        phoneNumberLabel.text = "Phone Number"
//        contentView.addSubview(phoneNumberLabel)
//        
//        phoneNumberTextField = CustomTextField()
//        phoneNumberTextField.placeholder = "Enter Phone Number"
//        phoneNumberTextField.keyboardType = .phonePad
//        phoneNumberTextField.delegate = self
//        contentView.addSubview(phoneNumberTextField)
//        print("Phone Number TextField Frame: \(phoneNumberTextField.frame), Interactive: \(phoneNumberTextField.isUserInteractionEnabled)")
//        
//        // User Type Label and Field
//        userTypeLabel = UILabel()
//        userTypeLabel.text = "User Type"
//        contentView.addSubview(userTypeLabel)
//        
//        userTypeTextField = CustomTextField()
//        userTypeTextField.placeholder = "Select User Type"
//        userTypeTextField.delegate = self
//        userTypeTextField.addTarget(self, action: #selector(userTypeTextFieldTapped), for: .editingDidBegin)
//        contentView.addSubview(userTypeTextField)
//        
//        // Submit Button and Activity Indicator
//        submitButton = CustomButton(type: .system)
//        submitButton.setTitle("Submit", for: .normal)
//        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
//        contentView.addSubview(submitButton)
//        
//        activityIndicator = UIActivityIndicatorView(style: .large)
//        activityIndicator.hidesWhenStopped = true
//        contentView.addSubview(activityIndicator)
//        
//        setupConstraints()
//    }
//
// 
//    func setupConstraints() {
//        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
//        surnameLabel.translatesAutoresizingMaskIntoConstraints = false
//        phoneNumberLabel.translatesAutoresizingMaskIntoConstraints = false
//        userTypeLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
//        surnameTextField.translatesAutoresizingMaskIntoConstraints = false
//        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
//        userTypeTextField.translatesAutoresizingMaskIntoConstraints = false
//        submitButton.translatesAutoresizingMaskIntoConstraints = false
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//
//        let margin: CGFloat = 16
//        let textFieldHeight: CGFloat = 40
//        
//        print("ContentView is nil: \(contentView == nil)")  // Check if contentView is nil
//        print("FirstNameLabel is nil: \(firstNameLabel == nil)")  // Check if firstNameLabel is nil
//        print("UserTypeTextField Frame before layout: \(userTypeTextField.frame)")
//        
//        
//        NSLayoutConstraint.activate([
//            // First Name Label and Field
//            firstNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
//            firstNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            firstNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            
//            firstNameTextField.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 4),
//            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            firstNameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
//            
//            // Surname Label and Field
//            surnameLabel.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: margin),
//            surnameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            surnameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            
//            surnameTextField.topAnchor.constraint(equalTo: surnameLabel.bottomAnchor, constant: 4),
//            surnameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            surnameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            surnameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
//            
//            // Phone Number Label and Field
//            phoneNumberLabel.topAnchor.constraint(equalTo: surnameTextField.bottomAnchor, constant: margin),
//            phoneNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            phoneNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            
//            phoneNumberTextField.topAnchor.constraint(equalTo: phoneNumberLabel.bottomAnchor, constant: 4),
//            phoneNumberTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            phoneNumberTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            phoneNumberTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
//            
//            // User Type Label and Field
//            userTypeLabel.topAnchor.constraint(equalTo: phoneNumberTextField.bottomAnchor, constant: margin),
//            userTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            userTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            
//            userTypeTextField.topAnchor.constraint(equalTo: userTypeLabel.bottomAnchor, constant: 4),
//            userTypeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            userTypeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            userTypeTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // Set height constraint
//            
//            submitButton.topAnchor.constraint(equalTo: userTypeTextField.bottomAnchor, constant: margin),
//            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
//            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
//            
//            activityIndicator.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: margin),
//            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            
//            // Add this bottom constraint to ensure the contentView expands
//            activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
//        ])
//        
//        // Check frames after layout
//        view.layoutIfNeeded()
//        print("First Name TextField Frame after layout: \(firstNameTextField.frame)")
//        print("UserTypeTextField Frame after layout: \(userTypeTextField.frame)")
//    }
//
//    
//    // MARK: - Firebase Functions
//
//    func fetchUserTypes() {
//        let ref = Database.database().reference(withPath: "staticData/userTypes")
//        ref.observeSingleEvent(of: .value) { snapshot in
//            if let value = snapshot.value as? [String: String] {
//                self.userTypes = Array(value.values)
//                print("Fetched user types: \(self.userTypes)")
//            } else {
//                print("Error fetching user types")
//            }
//        }
//    }
//
//
//    
//    @objc func submitButtonTapped() {
//        print("Submit Button Tapped")
//        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
//            showAlert(message: "Please enter a first name.")
//            return
//        }
//        
//        guard let surname = surnameTextField.text, !surname.isEmpty else {
//            showAlert(message: "Please enter a surname.")
//            return
//        }
//        
//        guard let phoneNumber = phoneNumberTextField.text, isValidPhoneNumber(phoneNumber) else {
//            showAlert(message: "Please enter a valid phone number.")
//            return
//        }
//        
//        let userType = userTypes[userTypePicker.selectedRow(inComponent: 0)]
//        if userType == "Please Select" {
//            showAlert(message: "Please select a user type.")
//            return
//        }
//        
//        createUser(firstName: firstName, surname: surname, phoneNumber: formatPhoneNumber(phoneNumber), userType: userType)
//    }
//
//    func createUser(firstName: String, surname: String, phoneNumber: String, userType: String) {
//        let userCompany = "Company 1"  // Hardcoded for now
//        let userParent = UserSession.shared.userParent
//
//        let data = [
//            "firstName": firstName,
//            "surname": surname,
//            "phoneNumber": phoneNumber,
//            "userType": userType,
//            "userCompany": userCompany,
//            "userParent": userParent ?? ""
//        ]
//
//        showSpinner()
//
//        functions.httpsCallable("createSubUser").call(data) { result, error in
//            self.hideSpinner()
//
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//                self.showAlert(message: "An error occurred. Please try again.")
//                return
//            }
//
//            if let response = result?.data as? [String: Any], response["success"] as? Bool == true {
//                self.showAlertWithDismiss(message: "User created successfully!")
//            } else {
//                self.showAlert(message: "An unknown error occurred.")
//            }
//        }
//    }
//    
//    // Spinner functions
//    func showSpinner() {
//        activityIndicator.startAnimating()
//        submitButton.isEnabled = false
//        view.isUserInteractionEnabled = false
//    }
//    
//    func hideSpinner() {
//        activityIndicator.stopAnimating()
//        submitButton.isEnabled = true
//        view.isUserInteractionEnabled = true
//    }
//    
//    // MARK: - UIPickerViewDelegate, UIPickerViewDataSource
//        
//    @objc func userTypeTextFieldTapped() {
//        // Make sure we use the existing userTypePicker instance
//        userTypeTextField.inputView = userTypePicker
//        
//        // Create a toolbar with a Done button
//        let toolbar = UIToolbar()
//        toolbar.sizeToFit()
//        
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
//        toolbar.setItems([doneButton], animated: true)
//        
//        userTypeTextField.inputAccessoryView = toolbar
//        
//        // Ensure the picker is shown
//        userTypeTextField.becomeFirstResponder()
//    }
//
//    // Done button action to close the picker
//    @objc func doneTapped() {
//        // Safely unwrap userTypePicker
//        guard let picker = userTypePicker else {
//            print("userTypePicker is nil")
//            return
//        }
//        
//        // Get the selected row and set the text in the text field
//        let row = picker.selectedRow(inComponent: 0)
//        userTypeTextField.text = userTypes[row]
//        
//        // Dismiss picker
//        userTypeTextField.resignFirstResponder()
//    }
//
//
//
//
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1  // We only have one component (the list of user types)
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return userTypes.count  // The number of rows is based on the userTypes array
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return userTypes[row]  // Display each user type in the picker
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        // Optional: Handle what happens when the user selects a new user type
//        // For now, this method can remain empty unless you want to update something dynamically based on the selected user type.
//    }
//
//    // MARK: - Validation & Formatting
//
//    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
//        return phoneNumber.hasPrefix("+353") || phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089")
//    }
//
//    func formatPhoneNumber(_ phoneNumber: String) -> String {
//        if phoneNumber.hasPrefix("+353") {
//            return phoneNumber
//        } else if phoneNumber.hasPrefix("085") || phoneNumber.hasPrefix("086") || phoneNumber.hasPrefix("087") || phoneNumber.hasPrefix("089") {
//            return "+353" + phoneNumber.dropFirst()
//        }
//        return phoneNumber
//    }
//    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        // Capitalize the first letter of each word
//        if textField == firstNameTextField || textField == surnameTextField {
//            let currentText = textField.text ?? ""
//            let newString = (currentText as NSString).replacingCharacters(in: range, with: string)
//            let capitalizedString = newString.capitalized
//            textField.text = capitalizedString
//            return false  // Return false because we've manually updated the text
//        }
//        return true
//    }
//
//    
//    // MARK: - Helpers
//
//    func showAlert(message: String) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    func showAlertWithDismiss(message: String) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
//            self.navigationController?.popViewController(animated: true)  // Pop the view controller to go back to the previous screen
//        }
//        alert.addAction(okAction)
//        present(alert, animated: true, completion: nil)
//    }
//
//    func setupDismissKeyboardGesture() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        view.addGestureRecognizer(tapGesture)
//    }
//
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//    
//    
//    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        print("Should Begin Editing: \(textField.placeholder ?? "No Placeholder")")
//        return true
//    }
//
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        print("Did Begin Editing: \(textField.placeholder ?? "No Placeholder")")
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        print("Did End Editing: \(textField.placeholder ?? "No Placeholder")")
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        print("Should Return Editing: \(textField.placeholder ?? "No Placeholder")")
//        textField.resignFirstResponder()
//        return true
//    }
//}

