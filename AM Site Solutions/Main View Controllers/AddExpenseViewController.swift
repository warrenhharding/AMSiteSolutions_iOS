//
//  AddExpenseViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Photos

// MARK: - Expense Model

struct Expense: Codable {
    var id: String = ""
    var description: String = ""
    var amount: Double = 0.0
    var expenseDetails: String = ""
    var expenseDate: TimeInterval = 0
    var requestReimbursement: Bool = false
    var imageUrls: [String] = []
    var createdAt: TimeInterval = 0
    var updatedAt: TimeInterval = 0
    var createdBy: String = ""
    
    init(id: String = "", description: String = "", amount: Double = 0.0, expenseDetails: String = "", expenseDate: TimeInterval = 0, requestReimbursement: Bool = false, imageUrls: [String] = [], createdAt: TimeInterval = 0, updatedAt: TimeInterval = 0, createdBy: String = "") {
        self.id = id
        self.description = description
        self.amount = amount
        self.expenseDetails = expenseDetails
        self.expenseDate = expenseDate
        self.requestReimbursement = requestReimbursement
        self.imageUrls = imageUrls
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
    }
}

// MARK: - AddExpenseViewController

class AddExpenseViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - Properties
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let descriptionTextField = UITextField()
    private let amountTextField = UITextField()
    private let expenseDetailsTextView = UITextView()
    private let expenseDateTextField = UITextField()
    private let reimbursementLabel = UILabel()
    private let reimbursementSwitch = UISwitch()
    
    private let imagesLabel = UILabel()
    private let imageScrollView = UIScrollView()
    private let imageStackView = UIStackView()
    
    private let addImageButton = CustomButton(type: .system)
    private let uploadButton = CustomButton(type: .system)
    private let shareButton = CustomButton(type: .system)
    private let updateButton = CustomButton(type: .system)
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // Date Picker
    private let datePicker = UIDatePicker()
    
    // Data
    private var expenseDateInMillis: TimeInterval = 0
    private var imageList: [UIImage] = []
    private var imageUrls: [String] = []
    private var hasUnsavedChanges = false
    
    // Edit mode
    private var isEditMode = false
    private var expenseId: String?
    private var existingExpense: Expense?
    
    // Constants
    private let MAX_IMAGES = 5
    private let MAX_DESCRIPTION_LENGTH = 50
    
    // Currency formatter
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IE") // Euro locale
        return formatter
    }()
    
    // Firebase
    private let databaseRef = Database.database().reference()
    private let storageRef = Storage.storage().reference()
    private let auth = Auth.auth()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupActions()
        setupDatePicker()
        setupCurrencyFormatting()
        setupTapToDismissKeyboard()
        
        // Check if we're in edit mode
        if isEditMode, let expenseId = expenseId {
            loadExpenseData(expenseId: expenseId)
        }
        
        // Setup back button handler for unsaved changes
        setupCustomBackButton()
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

    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo,
        let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            
            // Get the active text field or text view
            var activeView: UIView?
            if let textField = findFirstResponder() as? UITextField {
                activeView = textField
            } else if let textView = findFirstResponder() as? UITextView {
                activeView = textView
            }
            
            // If we have an active view, adjust the scroll view's content inset
            if let activeView = activeView {
                // Convert the active view's frame to the scroll view's coordinate system
                let activeViewFrame = activeView.convert(activeView.bounds, to: scrollView)
                
                // Calculate the bottom of the active view in the scroll view's coordinate system
                let activeViewBottom = activeViewFrame.origin.y + activeViewFrame.size.height
                
                // Calculate the visible area of the scroll view (excluding the keyboard)
                let visibleAreaHeight = scrollView.frame.size.height - keyboardFrame.size.height
                
                // If the active view's bottom is below the visible area, adjust the scroll view's content offset
                if activeViewBottom > visibleAreaHeight {
                    let offset = activeViewBottom - visibleAreaHeight + 20 // Add some padding
                    scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y + offset), animated: true)
                }
            }
            
            // Adjust scrollView's content inset to account for the keyboard
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        // Reset the content inset when the keyboard hides
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // Helper method to find the first responder (active input field)
    private func findFirstResponder() -> UIView? {
        return findFirstResponder(in: view)
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        
        return nil
    }

    // MARK: - Tap to Dismiss Keyboard

    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = isEditMode ?
            TranslationManager.shared.getTranslation(for: "expense.editTitle") :
            TranslationManager.shared.getTranslation(for: "expense.addTitle")
        
        // Setup ScrollView and ContentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Description TextField
        descriptionTextField.placeholder = TranslationManager.shared.getTranslation(for: "expense.descriptionHint")
        descriptionTextField.borderStyle = .roundedRect
        descriptionTextField.autocapitalizationType = .words
        descriptionTextField.delegate = self
        descriptionTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentView.addSubview(descriptionTextField)
        
        // Amount TextField
        amountTextField.placeholder = TranslationManager.shared.getTranslation(for: "expense.amountHint")
        amountTextField.borderStyle = .roundedRect
        amountTextField.keyboardType = .decimalPad
        amountTextField.delegate = self
        amountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentView.addSubview(amountTextField)
        
        // Expense Details TextView
        expenseDetailsTextView.layer.borderWidth = 1
        expenseDetailsTextView.layer.borderColor = UIColor.lightGray.cgColor
        expenseDetailsTextView.layer.cornerRadius = 5
        expenseDetailsTextView.font = UIFont.systemFont(ofSize: 16)
        expenseDetailsTextView.autocapitalizationType = .sentences
        expenseDetailsTextView.delegate = self
        contentView.addSubview(expenseDetailsTextView)
        
        // Expense Date TextField
        expenseDateTextField.placeholder = TranslationManager.shared.getTranslation(for: "expense.selectDate")
        expenseDateTextField.borderStyle = .roundedRect
        expenseDateTextField.inputView = datePicker
        contentView.addSubview(expenseDateTextField)
        
        // Reimbursement Switch and Label
        reimbursementLabel.text = TranslationManager.shared.getTranslation(for: "expense.requestReimbursement")
        contentView.addSubview(reimbursementLabel)
        
        reimbursementSwitch.onTintColor = ColorScheme.amBlue
        reimbursementSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        contentView.addSubview(reimbursementSwitch)
        
        // Images Label
        imagesLabel.text = TranslationManager.shared.getTranslation(for: "expense.images")
        imagesLabel.font = UIFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(imagesLabel)
        
        // Image ScrollView and StackView
        imageScrollView.showsHorizontalScrollIndicator = true
        imageScrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(imageScrollView)
        
        imageStackView.axis = .horizontal
        imageStackView.spacing = 8
        imageStackView.alignment = .center
        imageScrollView.addSubview(imageStackView)
        
        // Add Image Button
        addImageButton.setTitle(TranslationManager.shared.getTranslation(for: "expense.addImage"), for: .normal)
        addImageButton.customBackgroundColor = ColorScheme.amOrange
        contentView.addSubview(addImageButton)
        
        // Upload Button
        uploadButton.setTitle(TranslationManager.shared.getTranslation(for: "expense.upload"), for: .normal)
        uploadButton.customBackgroundColor = ColorScheme.amOrange
        contentView.addSubview(uploadButton)
        
        // Share Button
        shareButton.setTitle(TranslationManager.shared.getTranslation(for: "expense.share"), for: .normal)
        shareButton.customBackgroundColor = ColorScheme.amOrange
        shareButton.isHidden = !isEditMode
        contentView.addSubview(shareButton)
        
        // Update Button
        updateButton.setTitle(TranslationManager.shared.getTranslation(for: "expense.update"), for: .normal)
        updateButton.customBackgroundColor = ColorScheme.amOrange
        updateButton.isHidden = !isEditMode
        contentView.addSubview(updateButton)
        
        // Progress View
        progressView.progress = 0
        progressView.isHidden = true
        contentView.addSubview(progressView)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Hide upload button in edit mode
        uploadButton.isHidden = isEditMode
    }
    
    private func setupConstraints() {
        // Set translatesAutoresizingMaskIntoConstraints to false for all views
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        expenseDetailsTextView.translatesAutoresizingMaskIntoConstraints = false
        expenseDateTextField.translatesAutoresizingMaskIntoConstraints = false
        reimbursementLabel.translatesAutoresizingMaskIntoConstraints = false
        reimbursementSwitch.translatesAutoresizingMaskIntoConstraints = false
        imagesLabel.translatesAutoresizingMaskIntoConstraints = false
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        imageStackView.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Description TextField
            descriptionTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            descriptionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Amount TextField
            amountTextField.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 16),
            amountTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Expense Details TextView
            expenseDetailsTextView.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 16),
            expenseDetailsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            expenseDetailsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expenseDetailsTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // Expense Date TextField
            expenseDateTextField.topAnchor.constraint(equalTo: expenseDetailsTextView.bottomAnchor, constant: 16),
            expenseDateTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            expenseDateTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expenseDateTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Reimbursement Label
            reimbursementLabel.topAnchor.constraint(equalTo: expenseDateTextField.bottomAnchor, constant: 16),
            reimbursementLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Reimbursement Switch
            reimbursementSwitch.centerYAnchor.constraint(equalTo: reimbursementLabel.centerYAnchor),
            reimbursementSwitch.leadingAnchor.constraint(equalTo: reimbursementLabel.trailingAnchor, constant: 8),
            
            // Images Label
            imagesLabel.topAnchor.constraint(equalTo: reimbursementLabel.bottomAnchor, constant: 16),
            imagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imagesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Image ScrollView
            imageScrollView.topAnchor.constraint(equalTo: imagesLabel.bottomAnchor, constant: 8),
            imageScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageScrollView.heightAnchor.constraint(equalToConstant: 110),
            
            // Image StackView
            imageStackView.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageStackView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageStackView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageStackView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageStackView.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor),
            
            // Add Image Button
            addImageButton.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 16),
            addImageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addImageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Upload Button
            uploadButton.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 16),
            uploadButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            uploadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Share Button
            shareButton.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 16),
            shareButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Update Button
            updateButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 16),
            updateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            updateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            updateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Adjust bottom constraint based on edit mode
        if !isEditMode {
            uploadButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        }
    }
    
    private func setupActions() {
        addImageButton.addTarget(self, action: #selector(showImagePickerDialog), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadExpense), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareExpense), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(updateExpense), for: .touchUpInside)
    }
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        
        // Add a toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: TranslationManager.shared.getTranslation(for: "common.doneButton"),
                                        style: .done,
                                        target: self,
                                        action: #selector(datePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        expenseDateTextField.inputAccessoryView = toolbar
        
        // Add target to update the text field when date changes
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }
    
    private func setupCurrencyFormatting() {
        // We'll implement this in the textField delegate methods
    }
    
    private func setupCustomBackButton() {
        // Create a button with both image and text
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Back", for: .normal)
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        // Add some spacing between image and text
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        
        // Create a bar button item with the custom button
        let barButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = barButtonItem
    }
    
    // MARK: - Actions
    
    @objc private func handleBack() {
        if hasUnsavedChanges {
            showUnsavedChangesDialog()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        hasUnsavedChanges = true
        
        // Limit description length
        if textField == descriptionTextField, let text = textField.text {
            if text.count > MAX_DESCRIPTION_LENGTH {
                textField.text = String(text.prefix(MAX_DESCRIPTION_LENGTH))
            }
        }
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        hasUnsavedChanges = true
    }
    
    @objc private func datePickerDone() {
        updateExpenseDateText()
        expenseDateTextField.resignFirstResponder()
        hasUnsavedChanges = true
    }
    
    @objc private func dateChanged() {
        updateExpenseDateText()
    }
    
    private func updateExpenseDateText() {
        let selectedDate = datePicker.date
        expenseDateInMillis = selectedDate.timeIntervalSince1970 * 1000
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        expenseDateTextField.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func showImagePickerDialog() {
        if imageList.count + imageUrls.count >= MAX_IMAGES {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.maxImagesReached"))
            return
        }
        
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "expense.addPhoto"),
                                     message: nil,
                                     preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "expense.takePhoto"),
                                     style: .default,
                                     handler: { _ in self.takePicture() }))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "expense.chooseFromGallery"),
                                     style: .default,
                                     handler: { _ in self.chooseFromGallery() }))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"),
                                     style: .cancel,
                                     handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func takePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.cameraNotAvailable"))
        }
    }
    
    private func chooseFromGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func uploadExpense() {
        if !validateForm() { return }
        
        showLoading(true)
        
        guard let uid = auth.currentUser?.uid else {
            showLoading(false)
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "common.userNotLoggedIn"))
            return
        }
        
        // Get user parent
        databaseRef.child("users").child(uid).child("userParent").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, let parentUid = snapshot.value as? String else {
                self?.showLoading(false)
                self?.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: "Failed to get parent UID")
                return
            }
            
            // Create a new expense reference
            let expenseRef = self.databaseRef.child("userExpenses").child(parentUid).childByAutoId()
            let expenseId = expenseRef.key ?? UUID().uuidString
            
            // Upload images
            self.uploadImages(expenseId: expenseId) { imageUrls in
                // Create expense data
                let expenseData: [String: Any] = [
                    "description": self.descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    "amount": self.getAmountValue(),
                    "expenseDetails": self.expenseDetailsTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    "expenseDate": self.expenseDateInMillis,
                    "requestReimbursement": self.reimbursementSwitch.isOn,
                    "imageUrls": imageUrls,
                    "createdAt": Date().timeIntervalSince1970 * 1000,
                    "updatedAt": Date().timeIntervalSince1970 * 1000,
                    "createdBy": uid
                ]
                
                // Save expense data
                expenseRef.child("data").setValue(expenseData) { error, _ in
                    self.showLoading(false)
                    
                    if let error = error {
                        self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                      message: "\(TranslationManager.shared.getTranslation(for: "expense.uploadError")): \(error.localizedDescription)")
                    } else {
                        self.hasUnsavedChanges = false
                        self.showSuccessAlert(message: TranslationManager.shared.getTranslation(for: "expense.uploadSuccess"))
                    }
                }
            }
        }
    }
    
    @objc private func updateExpense() {
        if !validateForm() { return }
        
        showLoading(true)
        
        guard let expenseId = self.expenseId, let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: "Missing expense ID or user parent")
            return
        }
        
        // Upload any new images
        uploadImages(expenseId: expenseId) { [weak self] imageUrls in
            guard let self = self else { return }
            
            // Create updated expense data
            let updatedExpense: [String: Any] = [
                "description": self.descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "amount": self.getAmountValue(),
                "expenseDetails": self.expenseDetailsTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "expenseDate": self.expenseDateInMillis,
                "requestReimbursement": self.reimbursementSwitch.isOn,
                "updatedAt": Date().timeIntervalSince1970 * 1000,
                "imageUrls": imageUrls
            ]
            
            // Update expense data
            self.databaseRef.child("userExpenses").child(userParent).child(expenseId).child("data").updateChildValues(updatedExpense) { error, _ in
                self.showLoading(false)
                
                if let error = error {
                    self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                  message: "\(TranslationManager.shared.getTranslation(for: "expense.updateError")): \(error.localizedDescription)")
                } else {
                    self.hasUnsavedChanges = false
                    self.showSuccessAlert(message: TranslationManager.shared.getTranslation(for: "expense.updateSuccess"))
                }
            }
        }
    }
    
    @objc private func shareExpense() {
        guard !imageUrls.isEmpty else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.noImagesToShare"))
            return
        }
        
        showLoading(true)
        
        // Create text to share
        let expenseData = """
        \(TranslationManager.shared.getTranslation(for: "expense.shareDescription")): \(descriptionTextField.text ?? "")
        \(TranslationManager.shared.getTranslation(for: "expense.shareAmount")): \(amountTextField.text ?? "")
        \(TranslationManager.shared.getTranslation(for: "expense.shareDetails")): \(expenseDetailsTextView.text ?? "")
        \(TranslationManager.shared.getTranslation(for: "expense.shareDate")): \(expenseDateTextField.text ?? "")
        \(TranslationManager.shared.getTranslation(for: "expense.shareReimbursement")): \(reimbursementSwitch.isOn ? TranslationManager.shared.getTranslation(for: "common.yesButton") : TranslationManager.shared.getTranslation(for: "common.noButton"))
        """
        
        // Download images to share
        var imagesToShare: [UIImage] = []
        let group = DispatchGroup()
        
        for urlString in imageUrls {
            group.enter()
            
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    defer { group.leave() }
                    
                    if let data = data, let image = UIImage(data: data) {
                        imagesToShare.append(image)
                    } else {
                        print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }.resume()
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.showLoading(false)
            
            let activityVC = UIActivityViewController(activityItems: [expenseData] + imagesToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateForm() -> Bool {
        if descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.errorEmptyDescription"))
            return false
        }
        
        if getAmountValue() <= 0 {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.errorInvalidAmount"))
            return false
        }
        
        if expenseDetailsTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.errorEmptyDetails"))
            return false
        }
        
        if expenseDateInMillis == 0 {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.errorNoDate"))
            return false
        }
        
        if imageList.isEmpty && imageUrls.isEmpty {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "expense.errorNoImages"))
            return false
        }
        
        return true
    }
    
    // private func getAmountValue() -> Double {
    //     guard let amountText = amountTextField.text else { return 0.0 }
        
    //     // Remove all non-digit characters and convert to a decimal value
    //     let cleanString = amountText.replacingOccurrences(of: "[^0-9,.]", with: "", options: .regularExpression)
        
    //     // Replace comma with dot for decimal point if needed
    //     let normalizedString = cleanString.replacingOccurrences(of: ",", with: ".")
        
    //     // Try to convert to Double
    //     if let amount = Double(normalizedString) {
    //         return amount
    //     }
        
    //     // If we can't parse it directly, try to extract the number from the currency string
    //     if let number = currencyFormatter.number(from: amountText) {
    //         return number.doubleValue
    //     }
        
    //     return 0.0
    // }

    private func getAmountValue() -> Double {
        guard let amountText = amountTextField.text else { return 0.0 }
        
        // Extract only digits from the text
        let digitsOnly = amountText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Convert to a decimal value (divide by 100 to handle cents)
        if let amount = Double(digitsOnly) {
            return amount / 100.0
        }
        
        // If we can't parse it directly, try to extract the number from the currency string
        if let number = currencyFormatter.number(from: amountText) {
            return number.doubleValue
        }
        
        return 0.0
    }

    
    private func uploadImages(expenseId: String, completion: @escaping ([String]) -> Void) {
        if imageList.isEmpty {
            completion(imageUrls)
            return
        }
        
        var uploadedUrls: [String] = imageUrls
        let group = DispatchGroup()
        
        for (index, image) in imageList.enumerated() {
            group.enter()
            
            // Compress image
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            // Create a unique filename
            let imagePath = "userExpenses/\(expenseId)/image_\(Date().timeIntervalSince1970)_\(index).jpg"
            let imageRef = storageRef.child(imagePath)
            
            // Upload image
            let uploadTask = imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                
                // Get download URL
                imageRef.downloadURL { url, error in
                    if let url = url {
                        uploadedUrls.append(url.absoluteString)
                    } else if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                    }
                    
                    group.leave()
                }
            }
            
            // Monitor upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self else { return }
                let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                DispatchQueue.main.async {
                    self.progressView.isHidden = false
                    self.progressView.progress = Float(percentComplete)
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedUrls)
        }
    }
    
    private func loadExpenseData(expenseId: String) {
        showLoading(true)
        
        guard let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: "User parent not found")
            return
        }
        
        let expenseRef = databaseRef.child("userExpenses").child(userParent).child(expenseId).child("data")
        
        expenseRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, let data = snapshot.value as? [String: Any] else {
                self?.showLoading(false)
                self?.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "expense.errorLoadingData"))
                return
            }
            
            // Populate form fields
            self.descriptionTextField.text = data["description"] as? String
            
            // Format and set the amount
            if let amount = data["amount"] as? Double {
                self.amountTextField.text = self.currencyFormatter.string(from: NSNumber(value: amount))
            }
            
            self.expenseDetailsTextView.text = data["expenseDetails"] as? String
            
            if let expenseDate = data["expenseDate"] as? TimeInterval {
                self.expenseDateInMillis = expenseDate
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                let date = Date(timeIntervalSince1970: expenseDate / 1000)
                self.expenseDateTextField.text = dateFormatter.string(from: date)
                self.datePicker.date = date
            }
            
            self.reimbursementSwitch.isOn = data["requestReimbursement"] as? Bool ?? false
            
            if let imageUrls = data["imageUrls"] as? [String] {
                self.imageUrls = imageUrls
                self.displayExistingImages()
            }
            
            self.showLoading(false)
            self.hasUnsavedChanges = false
        }
    }
    
    private func displayExistingImages() {
        for urlString in imageUrls {
            if let url = URL(string: urlString) {
                addImageThumbnail(url: url)
            }
        }
    }
    
    private func addImageThumbnail(url: URL) {
        // Create container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Create image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        containerView.addSubview(imageView)
        
        // Create delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.tag = imageStackView.arrangedSubviews.count
        deleteButton.addTarget(self, action: #selector(removeImage(_:)), for: .touchUpInside)
        containerView.addSubview(deleteButton)
        
        // Add tap gesture to image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.tag = imageStackView.arrangedSubviews.count
        imageView.addGestureRecognizer(tapGesture)
        
        // Set constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Load image
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            } else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
        
        // Add to stack view
        imageStackView.addArrangedSubview(containerView)
        
        // Show scroll view if it was hidden
        imageScrollView.isHidden = false
    }
    
    private func addImageToList(image: UIImage) {
        imageList.append(image)
        hasUnsavedChanges = true
        
        // Create container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Create image view
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        containerView.addSubview(imageView)
        
        // Create delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.tag = imageStackView.arrangedSubviews.count
        deleteButton.addTarget(self, action: #selector(removeImage(_:)), for: .touchUpInside)
        containerView.addSubview(deleteButton)
        
        // Add tap gesture to image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.tag = imageStackView.arrangedSubviews.count
        imageView.addGestureRecognizer(tapGesture)
        
        // Set constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add to stack view
        imageStackView.addArrangedSubview(containerView)
        
        // Show scroll view if it was hidden
        imageScrollView.isHidden = false
    }
    
    @objc private func removeImage(_ sender: UIButton) {
        let index = sender.tag
        
        if index < imageStackView.arrangedSubviews.count {
            // Remove from UI
            let view = imageStackView.arrangedSubviews[index]
            imageStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
            
            // Remove from data
            if index < imageList.count {
                imageList.remove(at: index)
            } else if index - imageList.count < imageUrls.count {
                imageUrls.remove(at: index - imageList.count)
            }
            
            // Update tags for remaining buttons
            for i in 0..<imageStackView.arrangedSubviews.count {
                if let containerView = imageStackView.arrangedSubviews[i] as? UIView {
                    for subview in containerView.subviews {
                        if let button = subview as? UIButton {
                            button.tag = i
                        }
                        if let imageView = subview as? UIImageView {
                            imageView.tag = i
                        }
                    }
                }
            }
            
            hasUnsavedChanges = true
            
            // Hide scroll view if no images
            imageScrollView.isHidden = imageStackView.arrangedSubviews.isEmpty
        }
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        let index = imageView.tag
        
        // Show full-screen image viewer
        if index < imageList.count {
            // Local image
            showFullScreenImage(imageList[index])
        } else if index - imageList.count < imageUrls.count {
            // Remote image
            let urlString = imageUrls[index - imageList.count]
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.showFullScreenImage(image)
                        }
                    } else {
                        print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }.resume()
            }
        }
    }
    
    private func showFullScreenImage(_ image: UIImage) {
        let imageVC = UIViewController()
        imageVC.view.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageVC.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageVC.view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageVC.view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageVC.view.bottomAnchor)
        ])
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
        imageVC.view.addGestureRecognizer(tapGesture)
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissFullScreenImage), for: .touchUpInside)
        imageVC.view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: imageVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: imageVC.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        imageVC.modalPresentationStyle = .fullScreen
        present(imageVC, animated: true, completion: nil)
    }
    
    @objc private func dismissFullScreenImage() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showUnsavedChangesDialog() {
        let alert = UIAlertController(
            title: TranslationManager.shared.getTranslation(for: "expense.unsavedChangesTitle"),
            message: TranslationManager.shared.getTranslation(for: "expense.unsavedChangesMessage"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.leave"),
            style: .destructive,
            handler: { _ in self.navigationController?.popViewController(animated: true) }
        ))
        
        alert.addAction(UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.stay"),
            style: .cancel,
            handler: nil
        ))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(
            title: TranslationManager.shared.getTranslation(for: "common.successHeader"),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: TranslationManager.shared.getTranslation(for: "common.okButton"),
            style: .default,
            handler: { _ in self.navigationController?.popViewController(animated: true) }
        ))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            activityIndicator.stopAnimating()
            progressView.isHidden = true
            view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    // func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    //     if textField == amountTextField {
    //         // Handle currency formatting
    //         let currentText = textField.text ?? ""
    //         let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
    //         // Allow backspace
    //         if string.isEmpty {
    //             return true
    //         }
            
    //         // Only allow digits and decimal separator
    //         let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
    //         let characterSet = CharacterSet(charactersIn: string)
    //         if !allowedCharacters.isSuperset(of: characterSet) {
    //             return false
    //         }
            
    //         // Format as currency
    //         if let number = Double(newText.replacingOccurrences(of: ",", with: ".")) {
    //             textField.text = currencyFormatter.string(from: NSNumber(value: number))
    //             return false
    //         }
            
    //         return true
    //     }
        
    //     return true
    // }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if textField == amountTextField {
                // Allow backspace
                if string.isEmpty {
                return true
            }
            
            // Only allow digits
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            let characterSet = CharacterSet(charactersIn: string)
            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }
            
            // Get the current text without currency symbols and separators
            let currentText = textField.text ?? ""
            let digitsOnly = currentText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            
            // Append the new digit
            let newDigitsOnly = digitsOnly + string
            
            // Convert to a decimal value (divide by 100 to handle cents)
            if let amount = Double(newDigitsOnly) {
                let amountInEuros = amount / 100.0
                
                // Format as currency
                textField.text = currencyFormatter.string(from: NSNumber(value: amountInEuros))
                
                // Mark as having unsaved changes
                hasUnsavedChanges = true
                
                return false
            }
            
            return false
        }
        
        return true
    }

    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            // Resize image if needed
            let maxSize: CGFloat = 1200
            var newImage = image
            
            if image.size.width > maxSize || image.size.height > maxSize {
                let scale = maxSize / max(image.size.width, image.size.height)
                let newWidth = image.size.width * scale
                let newHeight = image.size.height * scale
                
                UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
                image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    newImage = resizedImage
                }
                UIGraphicsEndImageContext()
            }
            
            addImageToList(image: newImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extensions for AddExpenseViewController

extension AddExpenseViewController {
    // Configure for edit mode
    func configureForEdit(expenseId: String) {
        self.isEditMode = true
        self.expenseId = expenseId
        
        // Update UI for edit mode
        if isViewLoaded {
            title = TranslationManager.shared.getTranslation(for: "expense.editTitle")
            uploadButton.isHidden = true
            shareButton.isHidden = false
            updateButton.isHidden = false
        }
    }
}

// MARK: - Factory Method

extension AddExpenseViewController {
    static func createForNewExpense() -> AddExpenseViewController {
        let viewController = AddExpenseViewController()
        viewController.isEditMode = false
        return viewController
    }
    
    static func createForEditExpense(expenseId: String) -> AddExpenseViewController {
        let viewController = AddExpenseViewController()
        viewController.configureForEdit(expenseId: expenseId)
        return viewController
    }
}



