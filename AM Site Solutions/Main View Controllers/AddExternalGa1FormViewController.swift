//
//  AddExternalGa1FormViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Photos
import MobileCoreServices

// MARK: - ExternalGA1Form Model

struct ExternalGA1Form: Codable {
    var id: String = ""
    var description: String = ""
    var equipmentParticulars: String = ""
    var expiryDate: TimeInterval = 0
    var imageUrls: [String] = []
    var createdAt: TimeInterval = 0
    var updatedAt: TimeInterval = 0
    
    init(id: String = "", description: String = "", equipmentParticulars: String = "", expiryDate: TimeInterval = 0, imageUrls: [String] = [], createdAt: TimeInterval = 0, updatedAt: TimeInterval = 0) {
        self.id = id
        self.description = description
        self.equipmentParticulars = equipmentParticulars
        self.expiryDate = expiryDate
        self.imageUrls = imageUrls
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AddExternalGa1FormViewController

class AddExternalGa1FormViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    // MARK: - Properties
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let descriptionTextField = UITextField()
    private let equipmentParticularsTextField = UITextField()
    private let expiryDateButton = CustomButton(type: .system)
    
    private let imagesLabel = UILabel()
    private let imageScrollView = UIScrollView()
    private let imageStackView = UIStackView()
    
    private let addImageButton = CustomButton(type: .system)
    private let uploadButton = CustomButton(type: .system)
    private let shareButton = CustomButton(type: .system)
    private let updateButton = CustomButton(type: .system)
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let expiryDateTextField = UITextField()
    private let datePicker = UIDatePicker()
    
    // Data
    private var expiryDateInMillis: TimeInterval = 0
    private var imageList: [UIImage] = []
    private var imageUrls: [String] = []
    private var currentPhotoPath: String = ""
    private var hasUnsavedChanges = false
    
    // Edit mode
    private var isEditMode = false
    private var formId: String?
    private var existingForm: ExternalGA1Form?
    
    // Constants
    private let MAX_IMAGES = 5
    private let MAX_DESCRIPTION_LENGTH = 50
    
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
        
        // Check if we're in edit mode
        if isEditMode, let formId = formId {
            loadFormData(formId: formId)
        }
        
        // Setup back button handler for unsaved changes
        setupCustomBackButton()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = isEditMode ?
            TranslationManager.shared.getTranslation(for: "externalGa1Form.editTitle") :
            TranslationManager.shared.getTranslation(for: "externalGa1Form.addTitle")
        
        // Setup ScrollView and ContentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.delegate = self
        
        // Description TextField
        descriptionTextField.placeholder = TranslationManager.shared.getTranslation(for: "externalGa1Form.descriptionHint")
        descriptionTextField.borderStyle = .roundedRect
        descriptionTextField.autocapitalizationType = .words
        descriptionTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentView.addSubview(descriptionTextField)
        
        // Equipment Particulars TextField
        equipmentParticularsTextField.placeholder = TranslationManager.shared.getTranslation(for: "externalGa1Form.equipmentParticularsHint")
        equipmentParticularsTextField.borderStyle = .roundedRect
        equipmentParticularsTextField.autocapitalizationType = .words
        equipmentParticularsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentView.addSubview(equipmentParticularsTextField)
        
        // // Expiry Date Button
        // expiryDateButton.setTitle(TranslationManager.shared.getTranslation(for: "externalGa1Form.selectExpiryDate"), for: .normal)
        // expiryDateButton.customBackgroundColor = ColorScheme.amOrange
        // contentView.addSubview(expiryDateButton)

        // Expiry Date TextField
        expiryDateTextField.placeholder = TranslationManager.shared.getTranslation(for: "externalGa1Form.selectExpiryDate")
        expiryDateTextField.borderStyle = .roundedRect
        expiryDateTextField.inputView = datePicker // Set the input view to the date picker
        contentView.addSubview(expiryDateTextField)
        
        // Setup date picker
        setupDatePicker()
        
        // Images Label
        imagesLabel.text = TranslationManager.shared.getTranslation(for: "externalGa1Form.images")
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
        addImageButton.setTitle(TranslationManager.shared.getTranslation(for: "externalGa1Form.addImage"), for: .normal)
        addImageButton.customBackgroundColor = ColorScheme.amOrange
        contentView.addSubview(addImageButton)
        
        // Upload Button
        uploadButton.setTitle(TranslationManager.shared.getTranslation(for: "externalGa1Form.upload"), for: .normal)
        uploadButton.customBackgroundColor = ColorScheme.amOrange
        contentView.addSubview(uploadButton)
        
        // Share Button
        shareButton.setTitle(TranslationManager.shared.getTranslation(for: "externalGa1Form.share"), for: .normal)
        shareButton.customBackgroundColor = ColorScheme.amOrange
        shareButton.isHidden = !isEditMode
        contentView.addSubview(shareButton)
        
        // Update Button
        updateButton.setTitle(TranslationManager.shared.getTranslation(for: "externalGa1Form.update"), for: .normal)
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
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        equipmentParticularsTextField.translatesAutoresizingMaskIntoConstraints = false
        expiryDateTextField.translatesAutoresizingMaskIntoConstraints = false  // Changed from expiryDateButton
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
            
            // Equipment Particulars TextField
            equipmentParticularsTextField.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 16),
            equipmentParticularsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            equipmentParticularsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            equipmentParticularsTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Expiry Date TextField - Changed from expiryDateButton
            expiryDateTextField.topAnchor.constraint(equalTo: equipmentParticularsTextField.bottomAnchor, constant: 16),
            expiryDateTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            expiryDateTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expiryDateTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Images Label
            imagesLabel.topAnchor.constraint(equalTo: expiryDateTextField.bottomAnchor, constant: 16),  // Changed from expiryDateButton
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
        // expiryDateButton.addTarget(self, action: #selector(showDatePickerDialog), for: .touchUpInside)
        addImageButton.addTarget(self, action: #selector(showImagePickerDialog), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadForm), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareForm), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(updateForm), for: .touchUpInside)
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

    // Add this method to set up the date picker
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        
        // Set minimum date to tomorrow
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())
        datePicker.minimumDate = tomorrow
        
        // Add a toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: TranslationManager.shared.getTranslation(for: "common.doneButton"), 
                                        style: .done, 
                                        target: self, 
                                        action: #selector(datePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        expiryDateTextField.inputAccessoryView = toolbar
        
        // Add target to update the text field when date changes
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }

    // Add these methods to handle date picker actions
    @objc private func datePickerDone() {
        // Update the text field with the selected date
        updateExpiryDateText()
        // Dismiss the keyboard (which hides the date picker)
        expiryDateTextField.resignFirstResponder()
        hasUnsavedChanges = true
    }

    @objc private func dateChanged() {
        // Update the text field when the date changes
        updateExpiryDateText()
    }

    private func updateExpiryDateText() {
        let selectedDate = datePicker.date
        
        // Ensure the selected date is in the future
        if selectedDate <= Date() {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                    message: TranslationManager.shared.getTranslation(for: "externalGa1Form.futureDateRequired"))
            return
        }
        
        expiryDateInMillis = selectedDate.timeIntervalSince1970 * 1000
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        expiryDateTextField.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func showDatePickerDialog() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "externalGa1Form.selectExpiryDate"), message: nil, preferredStyle: .actionSheet)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        // Add date picker to alert controller
        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.heightAnchor.constraint(equalToConstant: 200),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 0),
            datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: 0)
        ])
        
        // Set minimum date to tomorrow
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())
        datePicker.minimumDate = tomorrow
        
        // If we already have a date, set it
        if expiryDateInMillis > 0 {
            datePicker.date = Date(timeIntervalSince1970: expiryDateInMillis / 1000)
        }
        
        // Add actions
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: { _ in
            let selectedDate = datePicker.date
            
            // Ensure the selected date is in the future
            if selectedDate <= Date() {
                self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                              message: TranslationManager.shared.getTranslation(for: "externalGa1Form.futureDateRequired"))
                return
            }
            
            self.expiryDateInMillis = selectedDate.timeIntervalSince1970 * 1000
            self.updateExpiryDateButtonText()
            self.hasUnsavedChanges = true
        }))
        
        // Increase the height of the alert to accommodate the date picker
        alert.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        present(alert, animated: true, completion: nil)
    }
    
    private func updateExpiryDateButtonText() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = Date(timeIntervalSince1970: expiryDateInMillis / 1000)
        expiryDateButton.setTitle(dateFormatter.string(from: date), for: .normal)
    }
    
    @objc private func showImagePickerDialog() {
        if imageList.count >= MAX_IMAGES {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.maxImagesReached"))
            return
        }
        
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "externalGa1Form.addPhoto"),
                                     message: nil,
                                     preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "externalGa1Form.takePhoto"),
                                     style: .default,
                                     handler: { _ in self.takePicture() }))
        
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "externalGa1Form.chooseFromGallery"),
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
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.cameraNotAvailable"))
        }
    }
    
    private func chooseFromGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func uploadForm() {
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
            
            // Create a new form reference
            let formRef = self.databaseRef.child("externalGa1Forms").child(parentUid).childByAutoId()
            let formId = formRef.key ?? UUID().uuidString
            
            // Upload images
            self.uploadImages(formId: formId, parentUid: parentUid) { imageUrls in
                // Create form data
                let formData: [String: Any] = [
                    "description": self.descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    "equipmentParticulars": self.equipmentParticularsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    "expiryDate": self.expiryDateInMillis,
                    "imageUrls": imageUrls,
                    "createdAt": Date().timeIntervalSince1970 * 1000,
                    "updatedAt": Date().timeIntervalSince1970 * 1000
                ]
                
                // Save form data
                formRef.child("data").setValue(formData) { error, _ in
                    self.showLoading(false)
                    
                    if let error = error {
                        self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                      message: "\(TranslationManager.shared.getTranslation(for: "externalGa1Form.uploadError")): \(error.localizedDescription)")
                    } else {
                        self.hasUnsavedChanges = false
                        self.showSuccessAlert(message: TranslationManager.shared.getTranslation(for: "externalGa1Form.uploadSuccess"))
                    }
                }
            }
        }
    }
    
    @objc private func updateForm() {
        if !validateForm() { return }
        
        showLoading(true)
        
        guard let formId = self.formId, let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: "Missing form ID or user parent")
            return
        }
        
        // Upload any new images
        uploadImages(formId: formId, parentUid: userParent) { [weak self] imageUrls in
            guard let self = self else { return }
            
            // Combine existing and new image URLs
            let allImageUrls = imageUrls
            
            // Create updated form data
            let updatedForm: [String: Any] = [
                "description": self.descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "equipmentParticulars": self.equipmentParticularsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "expiryDate": self.expiryDateInMillis,
                "updatedAt": Date().timeIntervalSince1970 * 1000,
                "imageUrls": allImageUrls
            ]
            
            // Update form data
            self.databaseRef.child("externalGa1Forms").child(userParent).child(formId).child("data").updateChildValues(updatedForm) { error, _ in
                self.showLoading(false)
                
                if let error = error {
                    self.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                                  message: "\(TranslationManager.shared.getTranslation(for: "externalGa1Form.updateError")): \(error.localizedDescription)")
                } else {
                    self.hasUnsavedChanges = false
                    self.showSuccessAlert(message: TranslationManager.shared.getTranslation(for: "externalGa1Form.updateSuccess"))
                }
            }
        }
    }
    
    @objc private func shareForm() {
        guard !imageUrls.isEmpty else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.noImagesToShare"))
            return
        }
        
        showLoading(true)
        
        // Create text to share
        let formData = """
        Description: \(descriptionTextField.text ?? "")
        Equipment Particulars: \(equipmentParticularsTextField.text ?? "")
        Expiry Date: \(expiryDateButton.title(for: .normal) ?? "")
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
            
            let activityVC = UIActivityViewController(activityItems: [formData] + imagesToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateForm() -> Bool {
        if descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.errorEmptyDescription"))
            return false
        }
        
        if equipmentParticularsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.errorEmptyEquipmentParticulars"))
            return false
        }
        
        if expiryDateInMillis == 0 {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.errorNoExpiryDate"))
            return false
        }
        
        if imageList.isEmpty && imageUrls.isEmpty {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: TranslationManager.shared.getTranslation(for: "externalGa1Form.errorNoImages"))
            return false
        }
        
        return true
    }
    
    private func uploadImages(formId: String, parentUid: String, completion: @escaping ([String]) -> Void) {
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
            let imagePath = "externalGa1Forms/\(formId)/image_\(Date().timeIntervalSince1970)_\(index).jpg"
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
    
    private func loadFormData(formId: String) {
        showLoading(true)
        
        guard let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                     message: "User parent not found")
            return
        }
        
        let formRef = databaseRef.child("externalGa1Forms").child(userParent).child(formId).child("data")
        
        formRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, let data = snapshot.value as? [String: Any] else {
                self?.showLoading(false)
                self?.showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"),
                               message: TranslationManager.shared.getTranslation(for: "externalGa1Form.errorLoadingData"))
                return
            }
            
            // Populate form fields
            self.descriptionTextField.text = data["description"] as? String
            self.equipmentParticularsTextField.text = data["equipmentParticulars"] as? String
            
            if let expiryDate = data["expiryDate"] as? TimeInterval {
                self.expiryDateInMillis = expiryDate
                
                // Convert to seconds if in milliseconds
                // This handles both integer and decimal timestamps
                let expiryDateInSeconds = expiryDate > 10000000000 ? expiryDate / 1000 : expiryDate
                
                // Update the date picker and text field with the expiry date
                let date = Date(timeIntervalSince1970: expiryDateInSeconds)
                self.datePicker.date = date
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                self.expiryDateTextField.text = dateFormatter.string(from: date)
            }
            
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
            title: TranslationManager.shared.getTranslation(for: "externalGa1Form.unsavedChangesTitle"),
            message: TranslationManager.shared.getTranslation(for: "externalGa1Form.unsavedChangesMessage"),
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

// MARK: - Extensions for AddExternalGa1FormViewController

extension AddExternalGa1FormViewController {
    // Configure for edit mode
    func configureForEdit(formId: String) {
        self.isEditMode = true
        self.formId = formId
        
        // Update UI for edit mode
        if isViewLoaded {
            title = TranslationManager.shared.getTranslation(for: "externalGa1Form.editTitle")
            uploadButton.isHidden = true
            shareButton.isHidden = false
            updateButton.isHidden = false
        }
    }
}

// MARK: - Factory Method

extension AddExternalGa1FormViewController {
    static func createForNewForm() -> AddExternalGa1FormViewController {
        let viewController = AddExternalGa1FormViewController()
        viewController.isEditMode = false
        return viewController
    }
    
    static func createForEditForm(formId: String) -> AddExternalGa1FormViewController {
        let viewController = AddExternalGa1FormViewController()
        viewController.configureForEdit(formId: formId)
        return viewController
    }
}



