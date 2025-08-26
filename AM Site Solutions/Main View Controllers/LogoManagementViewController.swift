//
//  LogoManagementViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 2024-10-26.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseCrashlytics
import PhotosUI
import AVFoundation
import os.log

class LogoManagementViewController: UIViewController {

    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.amsitesolutions.app", category: "LogoManagement")

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let placeholderTextView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Please upload your logo"
        label.textColor = .lightGray
        label.textAlignment = .center
        label.isHidden = false
        return label
    }()

    private lazy var uploadLogoButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Upload Logo", for: .normal)
        button.addTarget(self, action: #selector(handleUploadLogoTapped), for: .touchUpInside)
        return button
    }()

    private lazy var removeLogoButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Remove Logo", for: .normal)
        button.customBackgroundColor = .systemRed
        button.addTarget(self, action: #selector(handleRemoveLogoTapped), for: .touchUpInside)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private var storageRef: StorageReference!
    private var parentId: String?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userParent = UserSession.shared.userParent else {
            logger.error("User parent ID is nil. Cannot proceed.")
            showAlert(title: "Error", message: "Could not determine user account. Please sign in again.")
            // Optionally, navigate the user back to a safe screen.
            // navigationController?.popViewController(animated: true)
            return
        }
        
        self.parentId = userParent
        self.storageRef = Storage.storage().reference()
        
        setupUI()
        setupConstraints()
        loadLogo()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.title = "Logo Management"
        setupCustomBackButton()
        
        view.addSubview(logoImageView)
        view.addSubview(placeholderTextView)
        view.addSubview(uploadLogoButton)
        view.addSubview(removeLogoButton)
        view.addSubview(activityIndicator)
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

    @objc func handleBack() {
        logger.info("Back button tapped")
        dismiss(animated: true, completion: nil)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),
            
            placeholderTextView.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor),
            placeholderTextView.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),

            uploadLogoButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
            uploadLogoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            uploadLogoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            removeLogoButton.topAnchor.constraint(equalTo: uploadLogoButton.bottomAnchor, constant: 20),
            removeLogoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            removeLogoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func handleUploadLogoTapped() {
        logger.info("Upload logo button tapped.")
        showImageSourceActionSheet()
    }

    @objc private func handleRemoveLogoTapped() {
        logger.info("Remove logo button tapped.")
        confirmRemoveLogo()
    }

    private func showImageSourceActionSheet() {
        let actionSheet = UIAlertController(title: "Upload Logo", message: "Choose a source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.checkCameraPermissions()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: { [weak self] _ in
            self?.checkPhotoLibraryPermissions()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }

    // MARK: - Permissions

    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.openCamera() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.openCamera() }
                }
            }
        case .denied, .restricted:
            showAlert(title: "Permission Denied", message: "Camera access is required to take a photo. Please enable it in Settings.")
        @unknown default:
            break
        }
    }

    private func checkPhotoLibraryPermissions() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
             DispatchQueue.main.async { self.openPhotoPicker() }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    DispatchQueue.main.async { self?.openPhotoPicker() }
                }
            }
        case .denied, .restricted:
            showAlert(title: "Permission Denied", message: "Photo Library access is required to select a photo. Please enable it in Settings.")
        @unknown default:
            break
        }
    }

    // MARK: - Image Picking

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            present(picker, animated: true)
        } else {
            showAlert(title: "Error", message: "Camera is not available on this device.")
        }
    }

    private func openPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Firebase Logic
    
    private func getLogoPath() -> String? {
        guard let parentId = self.parentId else { return nil }
        return "customers/\(parentId)/logo/logo.jpg"
    }

    private func loadLogo() {
        guard let logoPath = getLogoPath() else { return }
        showLoading(true)
        logger.info("Loading logo from path: \(logoPath)")
        
        let logoRef = storageRef.child(logoPath)
        logoRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                let storageError = error as NSError
                if storageError.domain == StorageErrorDomain, let errorCode = StorageErrorCode(rawValue: storageError.code) {
                    if errorCode == .objectNotFound {
                        self.logger.info("No logo found for user.")
                        self.logoImageView.isHidden = true
                        self.placeholderTextView.isHidden = false
                        return
                    }
                }
                self.logger.error("Error loading logo: \(error.localizedDescription)")
                Crashlytics.crashlytics().record(error: error)
                self.showAlert(title: "Load Failed", message: "Failed to load logo: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                self.logger.info("Logo loaded successfully.")
                self.logoImageView.image = image
                self.logoImageView.isHidden = false
                self.placeholderTextView.isHidden = true
            }
        }
    }

    private func uploadLogo(imageData: Data) {
        guard let logoPath = getLogoPath() else { return }
        showLoading(true)
        logger.info("Uploading logo to path: \(logoPath)")
        
        let logoRef = storageRef.child(logoPath)
        logoRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                self.logger.error("Error uploading logo: \(error.localizedDescription)")
                Crashlytics.crashlytics().record(error: error)
                self.showAlert(title: "Upload Failed", message: "Failed to upload logo: \(error.localizedDescription)")
                return
            }
            
            self.logger.info("Logo uploaded successfully.")
            Crashlytics.crashlytics().log("Logo uploaded for parentId: \(self.parentId ?? "unknown")")
            self.showAlert(title: "Success", message: "Logo uploaded successfully.")
            self.loadLogo()
        }
    }

    private func confirmRemoveLogo() {
        let alert = UIAlertController(title: "Remove Logo", message: "Are you sure you want to remove your logo?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            self?.removeLogo()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func removeLogo() {
        guard let logoPath = getLogoPath() else { return }
        showLoading(true)
        logger.info("Removing logo from path: \(logoPath)")
        
        let logoRef = storageRef.child(logoPath)
        logoRef.delete { [weak self] error in
            guard let self = self else { return }
            self.showLoading(false)
            
            if let error = error {
                self.logger.error("Error removing logo: \(error.localizedDescription)")
                Crashlytics.crashlytics().record(error: error)
                self.showAlert(title: "Removal Failed", message: "Failed to remove logo: \(error.localizedDescription)")
                return
            }
            
            self.logger.info("Logo removed successfully.")
            Crashlytics.crashlytics().log("Logo removed for parentId: \(self.parentId ?? "unknown")")
            self.logoImageView.image = nil
            self.logoImageView.isHidden = true
            self.placeholderTextView.isHidden = false
            self.showAlert(title: "Success", message: "Logo removed successfully.")
        }
    }

    // MARK: - Image Processing

    private func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale: CGFloat
        
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }
        
        // Avoid scaling up smaller images
        let newScale = min(scale, 1.0)
        
        let newSize = CGSize(width: size.width * newScale, height: size.height * newScale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }

    // MARK: - Helpers

    private func showLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
            self.uploadLogoButton.isEnabled = !isLoading
            self.removeLogoButton.isEnabled = !isLoading
            self.view.isUserInteractionEnabled = !isLoading
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - Delegate Extensions

extension LogoManagementViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let originalImage = info[.originalImage] as? UIImage else {
            logger.warning("No image found from UIImagePickerController.")
            return
        }
        
        let resizedImage = resizeImage(image: originalImage, maxDimension: 1024)
        
        // Convert image to compressed JPEG data
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "Error", message: "Could not process image.")
            return
        }
        
        uploadLogo(imageData: imageData)
    }
}

extension LogoManagementViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let originalImage = object as? UIImage {
                let resizedImage = self?.resizeImage(image: originalImage, maxDimension: 1024)
                // Convert image to compressed JPEG data
                guard let imageData = resizedImage?.jpegData(compressionQuality: 0.8) else {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: "Could not process image.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.uploadLogo(imageData: imageData)
                }
            }
        }
    }
}


