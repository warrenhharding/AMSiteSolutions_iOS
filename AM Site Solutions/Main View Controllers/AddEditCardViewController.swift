//
//  AddEditCardViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

class AddEditCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var isEditMode = false
    var card: Card?
    
    // MARK: - UI Components
    
    var descriptionTextField: UITextField!
    var expiryDateTextField: UITextField!   // Now a text field for expiry date
    var frontImageView: UIImageView!
    var backImageView: UIImageView!
    var uploadButton: CustomButton!         // Remains a CustomButton
    var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Date Picker Properties
    
    var expiryDatePicker: UIDatePicker!
    var selectedExpiryDate: Date?
    
    // Completion handler to signal that an add/edit operation has completed
    var completionHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        print("AddEditCardViewController: viewDidLoad")
        setupUI()
        configureExpiryDatePicker()
        if isEditMode, let card = card {
            populateFields(with: card)
        }
    }
    
    // MARK: - UI Setup
    
    func setupUI() {
        let margin: CGFloat = 20
        let elementHeight: CGFloat = 40
        
        // Description Text Field
        descriptionTextField = UITextField(frame: .zero)
        descriptionTextField.borderStyle = .roundedRect
        descriptionTextField.placeholder = "\(TranslationManager.shared.getTranslation(for: "addCardScreen.descriptionText"))"
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionTextField)
        
        // Expiry Date Text Field
        expiryDateTextField = UITextField(frame: .zero)
        expiryDateTextField.borderStyle = .roundedRect
        expiryDateTextField.placeholder = "\(TranslationManager.shared.getTranslation(for: "addCardScreen.expiryDateButton"))"
        expiryDateTextField.translatesAutoresizingMaskIntoConstraints = false
        // Hide the blinking cursor to discourage manual typing
        expiryDateTextField.tintColor = .clear
        view.addSubview(expiryDateTextField)
        
        // Front Image View
        frontImageView = UIImageView(frame: .zero)
        frontImageView.contentMode = .scaleAspectFill
        frontImageView.clipsToBounds = true
        frontImageView.backgroundColor = UIColor.lightGray
        frontImageView.isUserInteractionEnabled = true
        let frontTap = UITapGestureRecognizer(target: self, action: #selector(frontImageTapped))
        frontImageView.addGestureRecognizer(frontTap)
        frontImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frontImageView)
        
        // Back Image View
        backImageView = UIImageView(frame: .zero)
        backImageView.contentMode = .scaleAspectFill
        backImageView.clipsToBounds = true
        backImageView.backgroundColor = UIColor.lightGray
        backImageView.isUserInteractionEnabled = true
        let backTap = UITapGestureRecognizer(target: self, action: #selector(backImageTapped))
        backImageView.addGestureRecognizer(backTap)
        backImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backImageView)
        
        // Upload/Save CustomButton
        uploadButton = CustomButton(type: .system)
        let buttonTitle = isEditMode ? "\(TranslationManager.shared.getTranslation(for: "common.saveButton"))" : "\(TranslationManager.shared.getTranslation(for: "addCardScreen.uploadCardButton"))"
        uploadButton.setTitle(buttonTitle, for: .normal)
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        view.addSubview(uploadButton)
        
        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // In edit mode, disable image selection
        if isEditMode {
            frontImageView.isUserInteractionEnabled = false
            backImageView.isUserInteractionEnabled = false
        }
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            // Description field at top
            descriptionTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            descriptionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            descriptionTextField.heightAnchor.constraint(equalToConstant: elementHeight),
            
            // Expiry Date field below description
            expiryDateTextField.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 10),
            expiryDateTextField.leadingAnchor.constraint(equalTo: descriptionTextField.leadingAnchor),
            expiryDateTextField.trailingAnchor.constraint(equalTo: descriptionTextField.trailingAnchor),
            expiryDateTextField.heightAnchor.constraint(equalToConstant: elementHeight),
            
            // Front image view
            frontImageView.topAnchor.constraint(equalTo: expiryDateTextField.bottomAnchor, constant: 10),
            frontImageView.leadingAnchor.constraint(equalTo: expiryDateTextField.leadingAnchor),
            frontImageView.trailingAnchor.constraint(equalTo: expiryDateTextField.trailingAnchor),
            frontImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Back image view
            backImageView.topAnchor.constraint(equalTo: frontImageView.bottomAnchor, constant: 10),
            backImageView.leadingAnchor.constraint(equalTo: frontImageView.leadingAnchor),
            backImageView.trailingAnchor.constraint(equalTo: frontImageView.trailingAnchor),
            backImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Upload button
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Center activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Configure Expiry Date Picker
    
    func configureExpiryDatePicker() {
        expiryDatePicker = UIDatePicker()
        expiryDatePicker.datePickerMode = .date
        expiryDatePicker.minimumDate = Date()
        if #available(iOS 14.0, *) {
            expiryDatePicker.preferredDatePickerStyle = .wheels
        }
        // Assign the picker as the inputView of the text field
        expiryDateTextField.inputView = expiryDatePicker
        
        // Create a toolbar with Done and Cancel buttons
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "\(TranslationManager.shared.getTranslation(for: "common.done"))", style: .done, target: self, action: #selector(expiryDateDoneTapped))
        let cancelButton = UIBarButtonItem(title: "\(TranslationManager.shared.getTranslation(for: "common.cancelButton"))", style: .plain, target: self, action: #selector(expiryDateCancelTapped))
        toolbar.setItems([cancelButton, flexSpace, doneButton], animated: false)
        expiryDateTextField.inputAccessoryView = toolbar
    }
    
    @objc func expiryDateDoneTapped() {
        let selectedDate = expiryDatePicker.date
        selectedExpiryDate = selectedDate
        let sdf = DateFormatter()
        sdf.dateFormat = "dd/MM/yyyy"
        expiryDateTextField.text = sdf.string(from: selectedDate)
        print("AddEditCardViewController: Selected expiry date: \(sdf.string(from: selectedDate))")
        expiryDateTextField.resignFirstResponder()
    }
    
    @objc func expiryDateCancelTapped() {
        print("AddEditCardViewController: Expiry date selection cancelled")
        expiryDateTextField.resignFirstResponder()
    }
    
    // MARK: - Populate Fields for Edit Mode
    
    func populateFields(with card: Card) {
        print("AddEditCardViewController: Populating fields for edit mode")
        descriptionTextField.text = card.descriptionText
        
        let sdf = DateFormatter()
        sdf.dateFormat = "dd/MM/yyyy"
        let expiry = Date(timeIntervalSince1970: card.expiryDate / 1000) // convert ms to seconds
        expiryDateTextField.text = sdf.string(from: expiry)
        selectedExpiryDate = expiry
        
        // Load front and back images from URLs (using a helper function)
        if let frontURL = URL(string: card.frontImageURL) {
            loadImage(from: frontURL) { image in
                DispatchQueue.main.async {
                    self.frontImageView.image = image
                }
            }
        }
        if let backURL = URL(string: card.backImageURL) {
            loadImage(from: backURL) { image in
                DispatchQueue.main.async {
                    self.backImageView.image = image
                }
            }
        }
    }
    
    // MARK: - Image Selection
    
    @objc func frontImageTapped() {
        print("AddEditCardViewController: Front image tapped")
        if !isEditMode {
            showImageSourceOptions(isFront: true)
        }
    }
    
    @objc func backImageTapped() {
        print("AddEditCardViewController: Back image tapped")
        if !isEditMode {
            showImageSourceOptions(isFront: false)
        }
    }
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    func showImageSourceOptions(isFront: Bool) {
        let alertController = UIAlertController(title: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.selectImage"))", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.takePhoto"))", style: .default, handler: { _ in
                self.checkCameraPermission { granted in
                    if granted {
                        self.presentImagePicker(for: .camera, isFront: isFront)
                    } else {
                        // Present an alert that allows the user to open Settings
                        let settingsAlert = UIAlertController(title: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.cameraPermissionRequired"))", message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.goToCameraSettings"))", preferredStyle: .alert)
                        settingsAlert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "common.cancelButton"))", style: .cancel, handler: nil))
                        settingsAlert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.openSettings"))", style: .default, handler: { _ in
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                               UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                            }
                        }))
                        self.present(settingsAlert, animated: true, completion: nil)
                    }
                }
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertController.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.chooseFromLibrary"))", style: .default, handler: { _ in
                self.presentImagePicker(for: .photoLibrary, isFront: isFront)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "common.cancelButton"))", style: .cancel, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = isFront ? frontImageView : backImageView
            popoverController.sourceRect = (isFront ? frontImageView : backImageView).bounds
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentImagePicker(for sourceType: UIImagePickerController.SourceType, isFront: Bool) {
        print("AddEditCardViewController: Presenting image picker for \(isFront ? "front" : "back") image")
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Upload/Save Card
    
    @objc func uploadButtonTapped() {
        print("AddEditCardViewController: Upload button tapped")
        guard let descriptionText = descriptionTextField.text, !descriptionText.isEmpty else {
            showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.descriptionRequired"))")
            return
        }
        if descriptionText.count > 50 {
            showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.descriptionText"))")
            return
        }
        guard let expiryDate = selectedExpiryDate, expiryDate > Date() else {
            showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.futureDateRequired"))")
            return
        }
        if !isEditMode {
            guard frontImageView.image != nil, backImageView.image != nil else {
                showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.provideFrontAndBack"))")
                return
            }
        }
        
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        if isEditMode {
            updateCardInFirebase(description: descriptionText, expiryDate: expiryDate)
        } else {
            addCardToFirebase(description: descriptionText, expiryDate: expiryDate)
        }
    }
    

    
    func updateCardInFirebase(description: String, expiryDate: Date) {
        guard let card = card,
              let uid = Auth.auth().currentUser?.uid,
              !card.cardId.isEmpty else {
            print("AddEditCardViewController: Update failed - missing card info or user not authenticated")
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            return
        }
        let ref = Database.database().reference().child("users").child(uid).child("userCards").child(card.cardId)
        let updatedData: [String: Any] = [
            "description": description,
            "expiryDate": expiryDate.timeIntervalSince1970 * 1000,
            "updatedAt": ServerValue.timestamp()
        ]
        ref.updateChildValues(updatedData) { error, _ in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
            if let error = error {
                print("AddEditCardViewController: Error updating card: \(error.localizedDescription)")
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.updateFailed"))")
            } else {
                print("AddEditCardViewController: Card updated successfully")
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.successUpdate"))", completion: {
                    self.completionHandler?()
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }

    
    func addCardToFirebase(description: String, expiryDate: Date) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("AddEditCardViewController: User not authenticated")
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            return
        }
        let cardRef = Database.database().reference().child("users").child(uid).child("userCards").childByAutoId()
        guard let cardId = cardRef.key else {
            print("AddEditCardViewController: Failed to generate card ID")
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            return
        }
        uploadImage(image: frontImageView.image!, path: "users/\(uid)/userCards/\(cardId)/front.jpg") { frontURL in
            guard let frontURL = frontURL else {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.frontImageUploadFailed"))")
                return
            }
            print("AddEditCardViewController: Front image uploaded: \(frontURL)")
            self.uploadImage(image: self.backImageView.image!, path: "users/\(uid)/userCards/\(cardId)/back.jpg") { backURL in
                guard let backURL = backURL else {
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.backImageUploadFailed"))")
                    return
                }
                print("AddEditCardViewController: Back image uploaded: \(backURL)")
                let cardData: [String: Any] = [
                    "description": description,
                    "expiryDate": expiryDate.timeIntervalSince1970 * 1000,
                    "frontImageURL": frontURL,
                    "backImageURL": backURL,
                    "createdAt": ServerValue.timestamp(),
                    "updatedAt": ServerValue.timestamp()
                ]
                cardRef.setValue(cardData) { error, _ in
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                    }
                    if let error = error {
                        print("AddEditCardViewController: Error saving card: \(error.localizedDescription)")
                        self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.saveFailed"))")
                    } else {
                        print("AddEditCardViewController: Card added successfully")
                        self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.successUpload"))", completion: {
                            self.completionHandler?()
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                }
            }
        }
    }
    

    
    func uploadImage(image: UIImage, path: String, completion: @escaping (String?) -> Void) {
        print("AddEditCardViewController: Uploading image to path: \(path)")
        let storageRef = Storage.storage().reference().child(path)
        let resizedImage = image.resizedImageWithinRect(rectSize: CGSize(width: 1920, height: 1080))
        guard let imageData = resizedImage.jpegData(compressionQuality: 1.0) else {
            print("AddEditCardViewController: Failed to compress image")
            DispatchQueue.main.async {
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.imageProcFaile"))")
            }
            completion(nil)
            return
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("AddEditCardViewController: Error uploading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.uploadFailed"))")
                }
                completion(nil)
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("AddEditCardViewController: Error getting download URL: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.failedUrlRetrieval"))")
                        }
                        completion(nil)
                    } else if let url = url {
                        print("AddEditCardViewController: Download URL: \(url.absoluteString)")
                        completion(url.absoluteString)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("AddEditCardViewController: Image picked")
        if let selectedImage = info[.originalImage] as? UIImage {
            if frontImageView.image == nil {
                frontImageView.image = selectedImage
                print("AddEditCardViewController: Assigned image to frontImageView")
            } else if backImageView.image == nil {
                backImageView.image = selectedImage
                print("AddEditCardViewController: Assigned image to backImageView")
            }
        } else {
            picker.dismiss(animated: true) {
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "addCardScreen.failedImagePick"))")
            }
            return
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("AddEditCardViewController: Image picker cancelled")
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper: Show Alert
    
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        print("AddEditCardViewController: showAlert - \(message)")
        let alert = UIAlertController(title: "\(TranslationManager.shared.getTranslation(for: "common.alert"))", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "common.okButton"))", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}
