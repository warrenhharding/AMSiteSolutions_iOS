//
//  FormViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import CoreLocation
import Photos


class FormViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    let storageRef = Storage.storage().reference()
    
    private var instructionLabel: UILabel?
    
    var scrollView: UIScrollView!
    var contentView: UIView!
    var formStackView: UIStackView!
   
    var form: Form?
    var englishForm: Form?
    
    var machineId: String?
    var plantEquipmentNumber: String?
    
    var submitButton: CustomButton!
    var addPhotoButton: CustomButton!
    var progressBar: UIActivityIndicatorView!
    var photoContainer: UIStackView!
    var photoUris: [URL] = []
    var allowedPhotos: Int = 3
    var locationAnswer: String?
    var locationManager = CLLocationManager()
    var hasShownLocationAlert = false
    
    var spinner: UIActivityIndicatorView!


    var allQuestions: [FormQuestion] = []
    var answers: [String: [String: Any]] = [:]
    var isUpdating = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = form?.name
        view.backgroundColor = .white

        setupScrollView()
        setupFormContent()
        setupProgressBar()
        setupNavigationBar()

        fetchAllowedPhotos()
        checkPermissionsAndInitializeLocation()
        loadQuestions()
        
        setupDismissKeyboardGesture()
        
        setupSpinner()

        submitButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
               
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTranslations), name: .languageChanged, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            
            // Adjust the content inset of the scroll view
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            // Scroll to the active text field if necessary
            if let activeField = view.findFirstResponder() as? UITextField {
                let fieldFrame = activeField.convert(activeField.bounds, to: scrollView)
                scrollView.scrollRectToVisible(fieldFrame, animated: true)
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc func reloadTranslations() {
//        navigationItem.title = TranslationManager.shared.getTranslation(for: "operatorTab.opHeader")
//        self.fetchForms()
    }
    
    
    func setupSpinner() {
        spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .gray
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func setupFormContent() {
        formStackView = UIStackView()
        formStackView.axis = .vertical
        formStackView.spacing = 16
        contentView.addSubview(formStackView)
        formStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            formStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            formStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Add your questions to the stack view
        addQuestionsToStackView()
    }
        
    func setupPhotoContainer() {
        // Create a new vertical stack to contain the label and the photo container
        let photoStackContainer = UIStackView()
        photoStackContainer.axis = .vertical
        photoStackContainer.spacing = 8
        photoStackContainer.alignment = .leading
        photoStackContainer.distribution = .fill

        // Create a label for the instruction text
        instructionLabel = UILabel()
        instructionLabel?.text = TranslationManager.shared.getTranslation(for: "formScreen.tapToDelete")
        instructionLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        instructionLabel?.textColor = .gray
        instructionLabel?.textAlignment = .left
        instructionLabel?.isHidden = true  // Initially hidden

        // Add the instruction label to the photo stack container
        if let instructionLabel = instructionLabel {
            photoStackContainer.addArrangedSubview(instructionLabel)
        }

        // Setup the photo container as before
        photoContainer = UIStackView()
        photoContainer.axis = .vertical
        photoContainer.spacing = 8
        photoContainer.alignment = .leading
        photoContainer.distribution = .fillEqually
        photoContainer.isHidden = true // Initially hidden until photos are added

        // Add the photo container to the photo stack container
        photoStackContainer.addArrangedSubview(photoContainer)

        // Add the photoStackContainer to the formStackView
        formStackView.addArrangedSubview(photoStackContainer)
    }
    
    // Call this function whenever a photo is added or removed
    func updatePhotoContainerVisibility(hasPhotos: Bool) {
        // Show the instruction label only if there are photos
        instructionLabel?.isHidden = !hasPhotos
        photoContainer.isHidden = !hasPhotos
    }

    
    func setupButtons() {
        // Create and configure the "Add Photo" button
        addPhotoButton = CustomButton(type: .system)
        addPhotoButton.setTitle(TranslationManager.shared.getTranslation(for: "formScreen.addPhotoButton"), for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        
        // Create and configure the "Submit" button
        submitButton = CustomButton(type: .system)
//        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitle(NSLocalizedString(TranslationManager.shared.getTranslation(for: "common.submitButton"), comment: "Button title for submit action"), for: .normal)
        submitButton.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
        
        // Add the buttons to the formStackView
        formStackView.addArrangedSubview(addPhotoButton)
        formStackView.addArrangedSubview(submitButton)
        
        // Add some spacing at the bottom to prevent the last button from being too close to the screen edge
        let bottomSpacer = UIView()
        formStackView.addArrangedSubview(bottomSpacer)
    }

    
    func addQuestionsToStackView() {
        // Iterate through your questions and add them to the stack view
        print("allQuestions: \(allQuestions)")
        for question in allQuestions {
            let questionView = createQuestionView(for: question)
            formStackView.addArrangedSubview(questionView)
        }
    }
    
    

    
    func createQuestionView(for question: FormQuestion) -> UIView {
        switch question.type {
        case .input:
            let inputQuestionView = InputQuestionView()
            inputQuestionView.question = question
            
//            if question.id == "additional2" {
//                // Set keyboard to number pad
//                inputQuestionView.inputTextField.keyboardType = .numberPad
//            } else if question.id == "additional1" {
//                // Ensure uppercase behavior and delegate set
//                inputQuestionView.inputTextField.autocapitalizationType = .allCharacters
//                inputQuestionView.inputTextField.delegate = inputQuestionView
//            }
            // MARK: - Add this block to make the plant number field read-only
            // If this is the plant number question AND it was pre-filled via QR scan
            if question.id == "additional1" && self.plantEquipmentNumber != nil {
                inputQuestionView.inputTextField.isEnabled = false
                inputQuestionView.inputTextField.backgroundColor = UIColor.systemGray6 // Visual cue
                inputQuestionView.inputTextField.textColor = .gray
            } else if question.id == "additional2" {
                // Set keyboard to number pad for other specific questions
                inputQuestionView.inputTextField.keyboardType = .numberPad
            } else if question.id == "additional1" {
                // Ensure uppercase behavior for manual entry
                inputQuestionView.inputTextField.autocapitalizationType = .allCharacters
                inputQuestionView.inputTextField.delegate = inputQuestionView
            }
            
            return inputQuestionView
            
        case .okNotOkNa:
            let okNotOkView = OkNotOkView()
            okNotOkView.question = question
            return okNotOkView
        }
    }



        
    
    func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Allows other touches to pass through (e.g., to interact with the table view)
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }


    func setupSubmitButton() {
        submitButton = CustomButton()
        submitButton.setTitle(TranslationManager.shared.getTranslation(for: "common.submitButton"), for: .normal)
        view.addSubview(submitButton)

        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func setupAddPhotoButton() {
        addPhotoButton = CustomButton(type: .system)
        addPhotoButton.setTitle(TranslationManager.shared.getTranslation(for: "formScreen.addPhotoButton"), for: .normal)
        view.addSubview(addPhotoButton)

        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            addPhotoButton.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -10),
            addPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func setupProgressBar() {
        progressBar = UIActivityIndicatorView(style: .large)
        progressBar.hidesWhenStopped = true
        view.addSubview(progressBar)

        progressBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBar.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func setupNavigationBar() {
        let retryLocationItem = UIBarButtonItem(title: TranslationManager.shared.getTranslation(for: "formScreen.retryLocation"), style: .plain, target: self, action: #selector(retryLocationPermission))
        navigationItem.rightBarButtonItem = retryLocationItem
    }

    func loadQuestions() {
        // Initial predefined questions
        var initialQuestions = [
            FormQuestion(id: "additional1", text: TranslationManager.shared.getTranslation(for: "formScreen.plantNo"), type: .input),
            FormQuestion(id: "additional2", text: TranslationManager.shared.getTranslation(for: "formScreen.operationHours"), type: .input),
            FormQuestion(id: "additional3", text: TranslationManager.shared.getTranslation(for: "formScreen.locationSite"), type: .input),
        ]
        
        // MARK: - Add this block to pre-fill the plant number
        // Check if a plantEquipmentNumber was passed from the QR code scan
        if let plantNumber = self.plantEquipmentNumber, !plantNumber.isEmpty {
            // Find the index of the 'plantNo' question (which is 'additional1')
            if let index = initialQuestions.firstIndex(where: { $0.id == "additional1" }) {
                // Update the answer for that question
                initialQuestions[index].answer = plantNumber
                print("Successfully pre-filled plant number: \(plantNumber)")
            }
        }

        // Append initial questions to allQuestions
        allQuestions.append(contentsOf: initialQuestions)

        // Append form-specific questions
        if let formQuestions = form?.questions {
            let formQuestionModels = formQuestions.map {
                FormQuestion(id: $0.id, text: $0.text, type: $0.type)
            }
            allQuestions.append(contentsOf: formQuestionModels)
        }

        // Clear any existing views
        formStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add questions to the stack view
        addQuestionsToStackView()

        // Setup the photo container and buttons after adding questions
        setupPhotoContainer()
        setupButtons()
    }



    @objc func addPhotoTapped() {
        if photoUris.count < allowedPhotos {
            showImagePickerOptions()
        } else {
//            showAlert(title: TranslationManager.shared.getTranslation(for: "formScreen.limitReached"), message: "You can only add up to \(allowedPhotos) photos.")
            showAlert(title: TranslationManager.shared.getTranslation(for: "formScreen.limitReached"), message: "\(TranslationManager.shared.getTranslation(for: "formScreen.onlyAddXPhotos"))\(allowedPhotos)\(TranslationManager.shared.getTranslation(for: "formScreen.finishPhotos"))")
        }
    }
    
    func showImagePickerOptions() {
        let alertController = UIAlertController(title: TranslationManager.shared.getTranslation(for: "formScreen.addPhotoButton"), message: TranslationManager.shared.getTranslation(for: "formScreen.chooseOption"), preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "formScreen.takePhotoButton"), style: .default, handler: { _ in
            self.openCamera()
        }))
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "formScreen.chooseFromGalleryButton"), style: .default, handler: { _ in
            self.openGallery()
        }))
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.cancelButton"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "formScreen.cameraNotAvailable"))
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let imageUrl = info[.imageURL] as? URL {
            addPhoto(uri: imageUrl)
        } else if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            let fileUrl = saveImageLocally(imageData)
            if let url = fileUrl {
                addPhoto(uri: url)
            }
        }
    }
    
    func saveImageLocally(_ data: Data) -> URL? {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent(UUID().uuidString + ".jpg")
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image locally: \(error)")
            return nil
        }
    }
    
    
    func addPhoto(uri: URL) {
        photoUris.append(uri)
        photoContainer.isHidden = false
        
        // Create an image view for the photo thumbnail
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.load(url: uri)
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Add tap gesture to remove photo
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(removePhoto(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        // Determine if we need to add a new row
        let currentRow = photoContainer.arrangedSubviews.last as? UIStackView
        let rowHasSpace = currentRow?.arrangedSubviews.count ?? 0 < 3
        
        if rowHasSpace, let row = currentRow {
            row.addArrangedSubview(imageView)
        } else {
            // Create a new row for the images
            let newRow = UIStackView()
            newRow.axis = .horizontal
            newRow.spacing = 8
            newRow.alignment = .leading
            photoContainer.addArrangedSubview(newRow)
            newRow.addArrangedSubview(imageView)
        }
        
        updatePhotoContainerVisibility(hasPhotos: true)
    }

    
    
    @objc func removePhoto(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        
        // Remove the image URI and the thumbnail view
        if let rowStackView = imageView.superview as? UIStackView, let index = rowStackView.arrangedSubviews.firstIndex(of: imageView) {
            photoUris.remove(at: index)
            rowStackView.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
            
            // If the row is empty after removing the image, remove the row
            if rowStackView.arrangedSubviews.isEmpty {
                photoContainer.removeArrangedSubview(rowStackView)
                rowStackView.removeFromSuperview()
            }
            
            // If all images are removed, hide the container
            if photoUris.isEmpty {
                photoContainer.isHidden = true
            }
            
            // Update visibility based on the remaining photos
            updatePhotoContainerVisibility(hasPhotos: photoContainer.arrangedSubviews.count > 0)
        }
    }

    
    func uploadPhotosAndGetUrls(completion: @escaping ([String]) -> Void) {
        guard let userParent = UserSession.shared.userParent else { return }
        guard let formName = form?.name else { return }
        
        let sanitizedFormName = sanitizeFirebaseKey(formName)
        let dateString = getCurrentDateTimeString()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = Storage.storage().reference().child("photos/\(userParent)/\(sanitizedFormName)/\(dateString)/\(uid)")
        var uploadedUrls: [String] = []
        
        let dispatchGroup = DispatchGroup()
        
        for (index, uri) in photoUris.enumerated() {
            dispatchGroup.enter()
            let photoRef = storageRef.child("photo_\(index).jpg")
            photoRef.putFile(from: uri, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading photo: \(error)")
                    dispatchGroup.leave()
                } else {
                    photoRef.downloadURL { url, error in
                        if let url = url {
                            uploadedUrls.append(url.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(uploadedUrls)
        }
    }

    func fetchAllowedPhotos() {
        let ref = Database.database().reference(withPath: "staticData/allowedPhotos")
        ref.getData { error, snapshot in
            if let error = error {
                print("Error fetching allowed photos: \(error)")
            } else if let value = snapshot?.value as? Int {
                self.allowedPhotos = value
            }
        }
    }

    func checkPermissionsAndInitializeLocation() {
        locationManager.delegate = self

        if CLLocationManager.locationServicesEnabled() {
            let status = locationManager.authorizationStatus  // Use the instance property for iOS 14+
            
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                showLocationManualEntryAlert()
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            @unknown default:
                showAlert(title: TranslationManager.shared.getTranslation(for: "common.anUnknownError"), message: TranslationManager.shared.getTranslation(for: "formScreen.errorLocationPermissions"))
            }
        } else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "formScreen.locationServicesDisabled"), message: "Please enable location services in your device settings.")
        }
    }


    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showLocationManualEntryAlert()
        case .notDetermined:
            break
        @unknown default:
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.anUnknownError"), message: TranslationManager.shared.getTranslation(for: "formScreen.errorLocationPermissions"))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    var locationString = ""
                    if let name = placemark.name {
                        locationString += name
                    }
                    if let locality = placemark.locality {
                        locationString += ", \(locality)"
                    }
                    if let country = placemark.country {
                        locationString += ", \(country)"
                    }
                    
                    self.locationAnswer = locationString
                    
                    DispatchQueue.main.async {
                        self.updateLocationField(with: locationString)
                    }
                }
            }
        }
    }


    
    @objc func retryLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func showLocationManualEntryAlert() {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "formScreen.locationRequired"), message: TranslationManager.shared.getTranslation(for: "formScreen.enterLocationManually"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    func updateLocationField(with location: String) {
        // Check if "additional4" is present in allQuestions
        if let index = allQuestions.firstIndex(where: { $0.id == "additional3" }) {
            // Update the question in allQuestions
            allQuestions[index].answer = location

            // Find the corresponding view in the stack view
            if let inputQuestionView = formStackView.arrangedSubviews[index] as? InputQuestionView {
                inputQuestionView.inputTextField.text = location
            }
        }
    }

        
    func startSavingData() {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false  // Disable user interaction
        
        // Disable navigation bar interactions to prevent back navigation
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
    }
    
   
    func stopSavingData() {
        spinner.stopAnimating()
        view.isUserInteractionEnabled = true  // Re-enable user interaction
        
        // Re-enable navigation bar interactions
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
    }
    
    @objc func submitForm() {
        guard allQuestionsAnswered() else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "formScreen.incompleteForm"), message: TranslationManager.shared.getTranslation(for: "formScreen.answerAllQuestions"))
            return
        }
        
        startSavingData()
        saveFormData()
    }



    
    func allQuestionsAnswered() -> Bool {
        for (index, question) in allQuestions.enumerated() {
            let view = formStackView.arrangedSubviews[index]

            if let inputQuestionView = view as? InputQuestionView, question.type == .input {
                if inputQuestionView.inputTextField.text?.isEmpty ?? true {
                    return false
                }
            } else if let okNotOkView = view as? OkNotOkView, question.type == .okNotOkNa {
                if !(okNotOkView.okButton.isSelected || okNotOkView.notOkButton.isSelected || okNotOkView.naButton.isSelected) {
                    return false
                }
            }
        }
        return true
    }


    
    func gatherAnswers() -> [String: Any] {
        var answers: [String: Any] = [:]

        var firebaseQuestionCounter = 1

        for question in allQuestions {
            // Determine the question type to save
            let questionTypeToSave: String
            if question.type == .okNotOkNa {
                questionTypeToSave = "OkNotOkNa"
            } else {
                questionTypeToSave = question.type.rawValue
            }

            // Prepare the answer data dictionary
            var answerData: [String: Any] = [
                "type": questionTypeToSave,
                "text": question.text,
                "answer": question.answer ?? ""
            ]
            
            // Include comment if available
            if let comment = question.comment {
                answerData["comment"] = comment
            }

            // Determine the key to store the question (either `additionalX` or `qX`)
            let key: String
            if question.id.starts(with: "additional") {
                key = question.id
            } else {
                key = "id\(firebaseQuestionCounter)"
                firebaseQuestionCounter += 1
            }

            // Store the answer data in the answers dictionary
            answers[key] = answerData
            print("Stored question \(key) with text: \(question.text), type: \(questionTypeToSave)")
        }

        print("All answers gathered: \(answers)")
        return answers
    }


    
    func sanitizeFirebaseKey(_ key: String) -> String {
        let invalidCharacters: Set<Character> = [".", "#", "$", "[", "]", "/"] // Include '/' in invalid characters
        return key.map { invalidCharacters.contains($0) ? "-" : String($0) }.joined()
    }



    func getCurrentDateTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: Date())
    }




    
    func saveFormData() {
        uploadPhotosAndGetUrls { [self] photoUrls in
            guard let userParent = UserSession.shared.userParent else {
                print("Error: User parent not found.")
                self.stopSavingData()
                return
            }
            guard let formName = self.form?.name else {
                print("Error: Form name not found.")
                self.stopSavingData()
                return
            }

            let sanitizedFormName = self.sanitizeFirebaseKey(formName)
            let dateString = self.getCurrentDateTimeString()
            guard let uid = Auth.auth().currentUser?.uid else {
                print("Error: User ID not found.")
                self.stopSavingData()
                return
            }
            
            print("englishForm: \(englishForm)")

            let basePath = "completedForms/\(userParent)/\(sanitizedFormName)/\(dateString)/\(uid)"
            let ref = Database.database().reference(withPath: basePath)
            
            let answers = self.gatherAnswers()
            let displayedLanguage = TranslationManager.shared.getSelectedLanguage()

            var firebaseAnswers = [String: Any]()
            let dispatchGroup = DispatchGroup()

            for (key, answerData) in answers {
                guard let answerDict = answerData as? [String: Any] else { continue }

                var questionData: [String: Any] = [
                    "questionType": answerDict["type"] as? String ?? "",
                    "answer": answerDict["answer"] ?? ""
                ]
                
                // Find English version of the question
                if let questionText = answerDict["text"] as? String {
                    questionData["questionText_\(displayedLanguage)"] = questionText
                    if let englishText = englishForm?.questions.first(where: { $0.id == key })?.text {
                        questionData["questionText"] = englishText
                    }

                }
                
                // Translate and save the comment
                if let comment = answerDict["comment"] as? String {
                    questionData["comment_\(displayedLanguage)"] = comment
                    dispatchGroup.enter()
                    TranslationManager.shared.translateTextUsingCloudFunction(comment, sourceLanguage: displayedLanguage, targetLanguage: "en") { translatedComment in
                        print("Translated comment: \(translatedComment)")
                        questionData["comment"] = translatedComment
                        firebaseAnswers[key] = questionData // Moved inside the closure
                        dispatchGroup.leave()
                    }
                } else {
                    firebaseAnswers[key] = questionData // Added to handle no comment case
                }
            }

            dispatchGroup.notify(queue: .main) {
                var additionalData: [String: Any] = [
                    "plantNo": (answers["additional1"] as? [String: Any])?["answer"] as? String ?? "",
                    "opHours": (answers["additional2"] as? [String: Any])?["answer"] as? String ?? "",
                    "spotter": (answers["additional3"] as? [String: Any])?["answer"] as? String ?? "",
                    "location": self.locationAnswer ?? ((answers["additional4"] as? [String: Any])?["answer"] as? String ?? ""),
                    "others": (answers["additional5"] as? [String: Any])?["answer"] as? String ?? "",
                    "photoUrls": photoUrls
                ]
                
                // Add the machineId to the dictionary if it exists
                if let machineId = self.machineId, !machineId.isEmpty {
                    additionalData["machineId"] = machineId
                }


                ref.child("isComplete").setValue(false) { isCompleteError, _ in
                    if let isCompleteError = isCompleteError {
                        print("Error setting 'isComplete' flag: \(isCompleteError.localizedDescription)")
                        self.stopSavingData()
                        return
                    }

                    ref.child("answers").setValue(firebaseAnswers) { error, _ in
                        if let error = error {
                            print("Error saving answers: \(error.localizedDescription)")
                            self.stopSavingData()
                        } else {
                            ref.child("additionalData").setValue(additionalData) { additionalError, _ in
                                if let additionalError = additionalError {
                                    print("Error saving additional data: \(additionalError.localizedDescription)")
                                    self.stopSavingData()
                                } else {
                                    ref.child("isComplete").setValue(true) { completeError, _ in
                                        if let completeError = completeError {
                                            print("Error setting 'isComplete' to true: \(completeError.localizedDescription)")
                                        } else {
                                            self.showAlert(title: "Success", message: "Form submitted successfully.") {
                                                self.navigationController?.popViewController(animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }




    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default) { _ in
            completion?()
        })
        present(alertController, animated: true, completion: nil)
    }
}



extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }
    }
}

extension UIView {
    func findFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }
        for subview in self.subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }
}


