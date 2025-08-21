//
//  NewMachineViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 06/08/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseFunctions
import PhotosUI
import AVFoundation

class NewMachineViewController: UIViewController {
    
    // MARK: - Properties
    private var machine: Machine?
    private var isEditMode: Bool = false
    private var machineTypes: [(id: String, name: String)] = []
    private var selectedMachineTypeIndex: Int = -1
    private var photoURIs: [URL] = []
    private var existingImageURLs: [String] = []
    private let maxPhotos = 20
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // Form fields
    private let nameTextField = CustomTextField()
    private let typeTextField = CustomTextField()
    private let manufacturerTextField = CustomTextField()
    private let modelTextField = CustomTextField()
    private let serialNumberTextField = CustomTextField()
    private let plantEquipmentNumberTextField = CustomTextField()
    private let yearOfManufactureTextField = CustomTextField()
    private let safeWorkingLoadTextField = CustomTextField()
    private let equipParticularsTextView = UITextView()
    private let statusSegmentedControl = UISegmentedControl(items: ["Active", "Under Repair", "Out of Service"])
    
    // Photo section
    private let photoScrollView = UIScrollView()
    private let photoStackView = UIStackView()
    private let addPhotoButton = CustomButton(type: .system)
    
    // QR Code section
    private let qrCodeStatusLabel = UILabel()
    private let assignQRButton = CustomButton(type: .system)

    // Buttons
    private let saveButton = CustomButton(type: .system)
    private let cancelButton = UIBarButtonItem()

    // Picker and toolbar for machine type selection
    private let machineTypePicker = UIPickerView()
    private let pickerToolbar = UIToolbar()

    // Loading indicator
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMachineTypePicker()
        loadMachineTypes()
        
        if isEditMode, let machine = machine {
            populateFields(with: machine)
            title = "Edit Machine"
        } else {
            title = "New Machine"
        }
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        // Setup form fields
        setupFormFields()
        setupPhotoSection()
        setupQRSection()
        setupButtons()
        setupActivityIndicator()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Tap to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupFormFields() {
        // Name field
        let nameLabel = createLabel(text: "Machine Name *")
        nameTextField.placeholder = "Enter machine name"
        nameTextField.autocapitalizationType = .words
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(nameTextField)
        
        // Machine type field
        let typeLabel = createLabel(text: "Machine Type *")
        typeTextField.placeholder = "Select machine type"
        typeTextField.isUserInteractionEnabled = true
        typeTextField.addTarget(self, action: #selector(machineTypeFieldTapped), for: .editingDidBegin)
        stackView.addArrangedSubview(typeLabel)
        stackView.addArrangedSubview(typeTextField)
        
        // Manufacturer field
        let manufacturerLabel = createLabel(text: "Manufacturer")
        manufacturerTextField.placeholder = "Enter manufacturer"
        manufacturerTextField.autocapitalizationType = .words
        stackView.addArrangedSubview(manufacturerLabel)
        stackView.addArrangedSubview(manufacturerTextField)
        
        // Model field
        let modelLabel = createLabel(text: "Model")
        modelTextField.placeholder = "Enter model"
        modelTextField.autocapitalizationType = .words
        stackView.addArrangedSubview(modelLabel)
        stackView.addArrangedSubview(modelTextField)
        
        // Serial number field
        let serialLabel = createLabel(text: "Serial Number")
        serialNumberTextField.placeholder = "Enter serial number"
        serialNumberTextField.autocapitalizationType = .allCharacters
        stackView.addArrangedSubview(serialLabel)
        stackView.addArrangedSubview(serialNumberTextField)
        
        // Plant equipment number field
        let plantLabel = createLabel(text: "Plant Equipment Number")
        plantEquipmentNumberTextField.placeholder = "Enter plant equipment number"
        plantEquipmentNumberTextField.autocapitalizationType = .allCharacters
        stackView.addArrangedSubview(plantLabel)
        stackView.addArrangedSubview(plantEquipmentNumberTextField)
        
        // Year of manufacture field
        let yearLabel = createLabel(text: "Year of Manufacture")
        yearOfManufactureTextField.placeholder = "Enter year"
        yearOfManufactureTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(yearLabel)
        stackView.addArrangedSubview(yearOfManufactureTextField)
        
        // Safe working load field
        let loadLabel = createLabel(text: "Safe Working Load")
        safeWorkingLoadTextField.placeholder = "Enter safe working load"
        stackView.addArrangedSubview(loadLabel)
        stackView.addArrangedSubview(safeWorkingLoadTextField)
        
        // Equipment particulars field
        let particularsLabel = createLabel(text: "Equipment Particulars")
        equipParticularsTextView.font = UIFont.systemFont(ofSize: 16)
        equipParticularsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        equipParticularsTextView.layer.borderWidth = 1
        equipParticularsTextView.layer.cornerRadius = 8
        equipParticularsTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        equipParticularsTextView.translatesAutoresizingMaskIntoConstraints = false
        equipParticularsTextView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        stackView.addArrangedSubview(particularsLabel)
        stackView.addArrangedSubview(equipParticularsTextView)
        
        // Status field
        let statusLabel = createLabel(text: "Status")
        statusSegmentedControl.selectedSegmentIndex = 0 // Default to "Active"
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(statusSegmentedControl)
    }

    private func setupPhotoSection() {
        let photoLabel = createLabel(text: "Photos (up to \(maxPhotos))")
        stackView.addArrangedSubview(photoLabel)
        
        // Photo scroll view setup
        photoScrollView.translatesAutoresizingMaskIntoConstraints = false
        photoScrollView.showsHorizontalScrollIndicator = false
        photoScrollView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        photoStackView.axis = .horizontal
        photoStackView.spacing = 8
        photoStackView.alignment = .center
        photoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        photoScrollView.addSubview(photoStackView)
        stackView.addArrangedSubview(photoScrollView)
        
        NSLayoutConstraint.activate([
            photoStackView.topAnchor.constraint(equalTo: photoScrollView.topAnchor),
            photoStackView.leadingAnchor.constraint(equalTo: photoScrollView.leadingAnchor),
            photoStackView.trailingAnchor.constraint(equalTo: photoScrollView.trailingAnchor),
            photoStackView.bottomAnchor.constraint(equalTo: photoScrollView.bottomAnchor),
            photoStackView.heightAnchor.constraint(equalTo: photoScrollView.heightAnchor)
        ])
        
        // Add photo button
        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        stackView.addArrangedSubview(addPhotoButton)
    }

    private func setupQRSection() {
        let qrLabel = createLabel(text: "QR Code Assignment")
        stackView.addArrangedSubview(qrLabel)
        
        qrCodeStatusLabel.text = "QR Code Status: Not Assigned"
        qrCodeStatusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        qrCodeStatusLabel.textAlignment = .center
        qrCodeStatusLabel.backgroundColor = UIColor.systemGray6
        qrCodeStatusLabel.layer.cornerRadius = 8
        qrCodeStatusLabel.layer.masksToBounds = true
        qrCodeStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        qrCodeStatusLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stackView.addArrangedSubview(qrCodeStatusLabel)
        
        assignQRButton.setTitle("Assign QR Code", for: .normal)
        assignQRButton.addTarget(self, action: #selector(assignQRTapped), for: .touchUpInside)
        assignQRButton.isEnabled = false
        assignQRButton.alpha = 0.5
        stackView.addArrangedSubview(assignQRButton)
    }

    private func setupButtons() {
        saveButton.setTitle(isEditMode ? "Update Machine" : "Save Machine", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stackView.addArrangedSubview(saveButton)
        
        // Add some bottom spacing
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        stackView.addArrangedSubview(spacer)
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupMachineTypePicker() {
        machineTypePicker.delegate = self
        machineTypePicker.dataSource = self
        
        pickerToolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(machineTypePickerDone))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(machineTypePickerCancel))
        pickerToolbar.setItems([cancelButton, flexSpace, doneButton], animated: false)
        
        typeTextField.inputView = machineTypePicker
        typeTextField.inputAccessoryView = pickerToolbar
    }

    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }

    // MARK: - Data Loading

    private func loadMachineTypes() {
        showLoading(true)
        
        MachineTypeDataManager.shared.loadMachineTypesIfNeeded { [weak self] success in
            DispatchQueue.main.async {
                self?.showLoading(false)
                if success {
                    self?.machineTypes = MachineTypeDataManager.shared.getMachineTypes()
                    self?.machineTypePicker.reloadAllComponents()
                    
                    // If we're in edit mode and have a machine, populate the machine type field now
                    if let self = self, self.isEditMode, let machine = self.machine {
                        self.setMachineTypeFromMachine(machine)
                    }
                } else {
                    self?.showAlert(title: "Error", message: "Failed to load machine types. Please try again.")
                }
            }
        }
    }
    
    
    private func setMachineTypeFromMachine(_ machine: Machine) {
        // Set machine type after machine types are loaded
        if let typeIndex = machineTypes.firstIndex(where: { $0.id == machine.type }) {
            selectedMachineTypeIndex = typeIndex
            typeTextField.text = machineTypes[typeIndex].name
            // Also update the picker selection
            machineTypePicker.selectRow(typeIndex, inComponent: 0, animated: false)
        } else {
            print("Machine type '\(machine.type)' not found in available machine types")
        }
    }
    
    

    private func populateFields(with machine: Machine) {
        nameTextField.text = machine.name
        manufacturerTextField.text = machine.manufacturer
        modelTextField.text = machine.model
        serialNumberTextField.text = machine.serialNumber
        plantEquipmentNumberTextField.text = machine.plantEquipmentNumber
        yearOfManufactureTextField.text = machine.yearOfManufacture
        safeWorkingLoadTextField.text = machine.safeWorkingLoad
        equipParticularsTextView.text = machine.equipParticulars
        
        // Set status
        switch machine.status {
        case "Active":
            statusSegmentedControl.selectedSegmentIndex = 0
        case "Under Repair":
            statusSegmentedControl.selectedSegmentIndex = 1
        case "Out of Service":
            statusSegmentedControl.selectedSegmentIndex = 2
        default:
            statusSegmentedControl.selectedSegmentIndex = 0
        }
        
        // Load existing images
        existingImageURLs = machine.images
        loadExistingImages()
        
        // Update QR status
        updateQRCodeStatus(machine.qrCodeId)
    }

    private func loadExistingImages() {
        for imageURL in existingImageURLs {
            addExistingImageThumbnail(imageURL: imageURL)
        }
    }

    // MARK: - Photo Management

    @objc private func addPhotoTapped() {
        let totalPhotos = photoURIs.count + existingImageURLs.count
        if totalPhotos >= maxPhotos {
            showAlert(title: "Photo Limit Reached", message: "You can only add up to \(maxPhotos) photos.")
            return
        }
        
        showImagePickerOptions()
    }

    private func showImagePickerOptions() {
        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            })
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
                self.presentImagePicker(sourceType: .photoLibrary)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addPhotoButton
            popover.sourceRect = addPhotoButton.bounds
        }
        
        present(alert, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func addPhotoThumbnail(image: UIImage) {
        // Save image locally and get URL
        guard let imageURL = saveImageLocally(image: image) else {
            showAlert(title: "Error", message: "Failed to save image")
            return
        }
        
        photoURIs.append(imageURL)
        createImageThumbnail(image: image, isExisting: false, identifier: imageURL.absoluteString)
    }

    private func addExistingImageThumbnail(imageURL: String) {
        // Load image from URL and create thumbnail
        guard let url = URL(string: imageURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                print("Failed to load existing image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.createImageThumbnail(image: image, isExisting: true, identifier: imageURL)
            }
        }.resume()
    }

    private func createImageThumbnail(image: UIImage, isExisting: Bool, identifier: String) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageView)
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 100),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -8),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 8),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Store identifier for deletion
        containerView.accessibilityIdentifier = identifier
        
        deleteButton.addAction(UIAction { [weak self] _ in
            self?.removePhoto(containerView: containerView, isExisting: isExisting, identifier: identifier)
        }, for: .touchUpInside)
        
        photoStackView.addArrangedSubview(containerView)
    }

    private func removePhoto(containerView: UIView, isExisting: Bool, identifier: String) {
        if isExisting {
            // Remove from existing images array
            existingImageURLs.removeAll { $0 == identifier }
        } else {
            // Remove from new photos array
            photoURIs.removeAll { $0.absoluteString == identifier }
        }
        
        photoStackView.removeArrangedSubview(containerView)
        containerView.removeFromSuperview()
    }

    private func saveImageLocally(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    // MARK: - QR Code Management

    @objc private func assignQRTapped() {
        guard machine != nil else {
            showAlert(title: "Save Required", message: "Please save the machine first before assigning a QR code.")
            return
        }
        
        // Check camera permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.presentQRScanner()
                } else {
                    self?.showAlert(title: "Camera Permission Required", message: "Please allow camera access to scan QR codes.")
                }
            }
        }
    }

    private func presentQRScanner() {
        let scanner = QRCodeScannerViewController()
        scanner.delegate = self
        let navController = UINavigationController(rootViewController: scanner)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func updateQRCodeStatus(_ qrCodeId: String?) {
        if let qrCodeId = qrCodeId, !qrCodeId.isEmpty {
            qrCodeStatusLabel.text = "QR Code Assigned: \(qrCodeId)"
            qrCodeStatusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            assignQRButton.isEnabled = false
            assignQRButton.alpha = 0.5
        } else if machine != nil {
            qrCodeStatusLabel.text = "QR Code Status: Not Assigned"
            qrCodeStatusLabel.backgroundColor = UIColor.systemGray6
            assignQRButton.isEnabled = true
            assignQRButton.alpha = 1.0
        } else {
            qrCodeStatusLabel.text = "QR Code Status: Not Available"
            qrCodeStatusLabel.backgroundColor = UIColor.systemGray6
            assignQRButton.isEnabled = false
            assignQRButton.alpha = 0.5
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard validateForm() else { return }
        
        showLoading(true)
        
        if isEditMode {
            updateMachine()
        } else {
            createMachine()
        }
    }

    @objc private func machineTypeFieldTapped() {
        typeTextField.becomeFirstResponder()
    }

    @objc private func machineTypePickerDone() {
        let selectedIndex = machineTypePicker.selectedRow(inComponent: 0)
        if selectedIndex >= 0 && selectedIndex < machineTypes.count {
            selectedMachineTypeIndex = selectedIndex
            typeTextField.text = machineTypes[selectedIndex].name
        }
        typeTextField.resignFirstResponder()
    }

    @objc private func machineTypePickerCancel() {
        typeTextField.resignFirstResponder()
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        var isValid = true
        var errorMessage = ""
        
        if nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            errorMessage += "Machine name is required.\n"
            isValid = false
        }
        
        if selectedMachineTypeIndex < 0 {
            errorMessage += "Machine type selection is required.\n"
            isValid = false
        }
        
        if !isValid {
            showAlert(title: "Validation Error", message: errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return isValid
    }

    // MARK: - Firebase Operations

    private func createMachine() {
        uploadPhotos { [weak self] imageURLs in
            self?.saveMachineToFirebase(imageURLs: imageURLs)
        }
    }

    private func updateMachine() {
        uploadPhotos { [weak self] newImageURLs in
            let allImageURLs = (self?.existingImageURLs ?? []) + newImageURLs
            self?.updateMachineInFirebase(imageURLs: allImageURLs)
        }
    }

    private func uploadPhotos(completion: @escaping ([String]) -> Void) {
        guard !photoURIs.isEmpty else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var uploadedURLs: [String] = []
        
        for (index, photoURI) in photoURIs.enumerated() {
            group.enter()
            
            let machineId = machine?.machineId ?? UUID().uuidString
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let imagePath = "machines/\(machineId)/image_\(timestamp)_\(index).jpg"
            
            let storageRef = Storage.storage().reference().child(imagePath)
            
            storageRef.putFile(from: photoURI, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error)")
                    group.leave()
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let url = url {
                        uploadedURLs.append(url.absoluteString)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedURLs)
        }
    }

    private func saveMachineToFirebase(imageURLs: [String]) {
        guard let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: "Error", message: "User session not found")
            return
        }
        
        let functions = Functions.functions()
        let machineTypeId = machineTypes[selectedMachineTypeIndex].id
        
        let machineData: [String: Any] = [
            "name": nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "type": machineTypeId,
            "manufacturer": manufacturerTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "model": modelTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "serialNumber": serialNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "plantEquipmentNumber": plantEquipmentNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "yearOfManufacture": yearOfManufactureTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "safeWorkingLoad": safeWorkingLoadTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "equipParticulars": equipParticularsTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "status": getSelectedStatus(),
            "appCustomerId": userParent,
            "images": imageURLs
        ]
        
        functions.httpsCallable("createMachine").call(machineData) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.showLoading(false)
                
                if let error = error {
                    print("Error creating machine: \(error)")
                    self?.showAlert(title: "Error", message: "Failed to create machine. Please try again.")
                    return
                }
                
                if let data = result?.data as? [String: Any],
                   let success = data["success"] as? Bool,
                   success {
                    
                    // Update machine object with returned data
                    if let machineId = data["machineId"] as? String {
                        // Create a new Machine struct directly
                        var newMachine = Machine()
                        newMachine.machineId = machineId
                        newMachine.name = self?.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.type = machineTypeId
                        newMachine.manufacturer = self?.manufacturerTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.model = self?.modelTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.serialNumber = self?.serialNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.plantEquipmentNumber = self?.plantEquipmentNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.yearOfManufacture = self?.yearOfManufactureTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.safeWorkingLoad = self?.safeWorkingLoadTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.equipParticulars = self?.equipParticularsTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        newMachine.status = self?.getSelectedStatus() ?? "Active"
                        newMachine.customerId = userParent
                        newMachine.images = imageURLs
                        newMachine.qrCodeId = "" // Initially empty
                        
                        // Generate derived machine ID (like Android version)
                        let derivedId = self?.generateDerivedId(
                            serialNumber: newMachine.serialNumber,
                            plantEquipmentNumber: newMachine.plantEquipmentNumber
                        ) ?? ""
                        newMachine.derivedMachineId = derivedId
                        
                        self?.machine = newMachine
                        self?.isEditMode = true
                        self?.updateQRCodeStatus(nil)
                    }
                    
                    self?.showAlert(title: "Success", message: "Machine created successfully!") {
                        self?.dismiss(animated: true)
                    }
                } else {
                    self?.showAlert(title: "Error", message: "Failed to create machine. Please try again.")
                }
            }
        }
    }
    
    
    private func generateDerivedId(serialNumber: String, plantEquipmentNumber: String) -> String {
        let serial = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let plant = plantEquipmentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !serial.isEmpty && !plant.isEmpty {
            return "\(serial)_\(plant)"
        } else if !serial.isEmpty {
            return serial
        } else if !plant.isEmpty {
            return plant
        } else {
            return UUID().uuidString
        }
    }
    
    
    

    private func updateMachineInFirebase(imageURLs: [String]) {
        guard let machine = machine,
              let userParent = UserSession.shared.userParent else {
            showLoading(false)
            showAlert(title: "Error", message: "Machine or user session not found")
            return
        }
        
        let functions = Functions.functions()
        let machineTypeId = machineTypes[selectedMachineTypeIndex].id
        
        let machineData: [String: Any] = [
            "machineId": machine.machineId,
            "name": nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "type": machineTypeId,
            "manufacturer": manufacturerTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "model": modelTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "serialNumber": serialNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "plantEquipmentNumber": plantEquipmentNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "yearOfManufacture": yearOfManufactureTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "safeWorkingLoad": safeWorkingLoadTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "equipParticulars": equipParticularsTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            "status": getSelectedStatus(),
            "appCustomerId": userParent,
            "images": imageURLs
        ]
        
        functions.httpsCallable("updateMachine").call(machineData) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.showLoading(false)
                
                if let error = error {
                    print("Error updating machine: \(error)")
                    self?.showAlert(title: "Error", message: "Failed to update machine. Please try again.")
                    return
                }
                
                if let data = result?.data as? [String: Any],
                   let success = data["success"] as? Bool,
                   success {
                    
                    self?.showAlert(title: "Success", message: "Machine updated successfully!") {
                        self?.dismiss(animated: true)
                    }
                } else {
                    self?.showAlert(title: "Error", message: "Failed to update machine. Please try again.")
                }
            }
        }
    }

    private func getSelectedStatus() -> String {
        switch statusSegmentedControl.selectedSegmentIndex {
        case 0: return "Active"
        case 1: return "Under Repair"
        case 2: return "Out of Service"
        default: return "Active"
        }
    }

    // MARK: - QR Code Assignment

    private func validateAndAssignQRCode(_ qrCodeId: String) {
        showLoading(true)
        
        let functions = Functions.functions()
        let data = ["scannedQrCodeId": qrCodeId]
        
        functions.httpsCallable("checkQrCodeStatus").call(data) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.showLoading(false)
                
                if let error = error {
                    print("Error checking QR code status: \(error)")
                    self?.showAlert(title: "Error", message: "Failed to validate QR code. Please try again.")
                    return
                }
                
                guard let resultData = result?.data as? [String: Any],
                      let status = resultData["status"] as? String else {
                    self?.showAlert(title: "Error", message: "Invalid response from server.")
                    return
                }
                
                if status == "assigned" {
                    if let assignedAt = resultData["assignedAt"] as? String {
                        self?.showAlert(title: "QR Code Already Assigned",
                                       message: "This QR Code was first assigned on \(assignedAt). Please use a different QR Code.")
                    } else {
                        self?.showAlert(title: "QR Code Already Assigned",
                                       message: "This QR Code is already assigned to another machine. Please use a different QR Code.")
                    }
                } else if status == "unassigned" {
                    self?.assignQRCodeToMachine(qrCodeId)
                }
            }
        }
    }

    private func assignQRCodeToMachine(_ qrCodeId: String) {
        guard let machine = machine else { return }
        
        showLoading(true)
        
        let functions = Functions.functions()
        let data = [
            "machineId": machine.machineId,
            "qrCodeId": qrCodeId
        ]
        
        functions.httpsCallable("assignQrCodeToMachine").call(data) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.showLoading(false)
                
                if let error = error {
                    print("Error assigning QR code: \(error)")
                    self?.showAlert(title: "Assignment Failed", message: "Failed to assign QR code. Please try again.")
                    return
                }
                
                if let resultData = result?.data as? [String: Any],
                   let success = resultData["success"] as? Bool,
                   success {
                    
                    self?.machine?.qrCodeId = qrCodeId
                    self?.updateQRCodeStatus(qrCodeId)
                    self?.showAlert(title: "Success", message: "QR Code assigned successfully!")
                } else {
                    let message = (result?.data as? [String: Any])?["message"] as? String ?? "Unknown error occurred"
                    self?.showAlert(title: "Assignment Failed", message: message)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func showLoading(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // MARK: - Static Methods for Presentation

    static func createForNewMachine() -> UINavigationController {
        let viewController = NewMachineViewController()
        viewController.isEditMode = false
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .formSheet
        return navController
    }

    static func createForEditMachine(_ machine: Machine) -> UINavigationController {
        let viewController = NewMachineViewController()
        viewController.machine = machine
        viewController.isEditMode = true
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .formSheet
        return navController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    }

    // MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

    extension NewMachineViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            showAlert(title: "Error", message: "Failed to get selected image")
            return
        }
        
        addPhotoThumbnail(image: image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    }

    // MARK: - UIPickerViewDataSource & UIPickerViewDelegate

    extension NewMachineViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return machineTypes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return machineTypes[row].name
    }
    }

    // MARK: - QRCodeScannerDelegate

    extension NewMachineViewController: QRCodeScannerDelegate {

    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String) {
        scanner.dismiss(animated: true) { [weak self] in
            // Parse QR code to extract qrCodeId
            if let url = URL(string: code),
               let qrCodeId = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "qrCodeId" })?.value {
                self?.validateAndAssignQRCode(qrCodeId)
            } else {
                self?.showAlert(title: "Invalid QR Code", message: "The scanned QR code is not valid for machine assignment.")
            }
        }
    }

    func qrCodeScannerDidCancel(_ scanner: QRCodeScannerViewController) {
        scanner.dismiss(animated: true)
    }
    }
    
