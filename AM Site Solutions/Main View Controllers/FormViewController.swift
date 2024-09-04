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


class FormViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let storageRef = Storage.storage().reference()
    
    var scrollView: UIScrollView!
    var contentView: UIView!
    var formStackView: UIStackView!
   
    var form: Form?
//    var tableView: UITableView!
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
        photoContainer = UIStackView()
        photoContainer.axis = .vertical
        photoContainer.spacing = 8
        photoContainer.alignment = .leading
        photoContainer.distribution = .fillEqually
        photoContainer.isHidden = true // Initially hidden until photos are added
        formStackView.addArrangedSubview(photoContainer)
    }

    
    func setupButtons() {
        // Create and configure the "Add Photo" button
        addPhotoButton = CustomButton(type: .system)
        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        
        // Create and configure the "Submit" button
        submitButton = CustomButton(type: .system)
        submitButton.setTitle("Submit", for: .normal)
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

//    func setupTableView() {
//        tableView = UITableView(frame: .zero, style: .plain)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.separatorStyle = .none
//        tableView.register(QuestionCell.self, forCellReuseIdentifier: "QuestionCell")
//        tableView.register(InputQuestionCell.self, forCellReuseIdentifier: "InputQuestionCell")
//        view.addSubview(tableView)
//
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100) // Space for buttons
//        ])
//    }

    func setupSubmitButton() {
        submitButton = CustomButton()
        submitButton.setTitle("Submit", for: .normal)
        view.addSubview(submitButton)

        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func setupAddPhotoButton() {
        addPhotoButton = CustomButton(type: .system)
        addPhotoButton.setTitle("Add Photo", for: .normal)
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
        let retryLocationItem = UIBarButtonItem(title: "Retry Location", style: .plain, target: self, action: #selector(retryLocationPermission))
        navigationItem.rightBarButtonItem = retryLocationItem
    }

    func loadQuestions() {
        // Initial predefined questions
        let initialQuestions = [
            FormQuestion(id: "additional1", text: "Plant No / Reg No:", type: .input),
            FormQuestion(id: "additional2", text: "Operation Hours on Clock", type: .input),
            FormQuestion(id: "additional3", text: "Fire Extinguisher in Place?", type: .input),
            FormQuestion(id: "additional4", text: "Location / Site", type: .input),
            FormQuestion(id: "additional5", text: "Others", type: .input)
        ]

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
            showAlert(title: "Limit Reached", message: "You can only add up to \(allowedPhotos) photos.")
        }
    }
    
    func showImagePickerOptions() {
        let alertController = UIAlertController(title: "Add Photo", message: "Choose an option", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.openCamera()
        }))
        alertController.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Error", message: "Camera is not available on this device.")
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
    
//    func addPhoto(uri: URL) {
//        photoUris.append(uri)
//        if photoUris.count >= allowedPhotos {
//            // Disable add photo button if photo limit is reached
//        }
//        photoContainer.isHidden = false
//
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.load(url: uri)
//        imageView.isUserInteractionEnabled = true
//        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
//
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(removePhoto(_:)))
//        imageView.addGestureRecognizer(tapGesture)
//
//        photoContainer.addArrangedSubview(imageView)
//    }
    
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
    }

    
//    @objc func removePhoto(_ sender: UITapGestureRecognizer) {
//        if let imageView = sender.view as? UIImageView, let index = photoContainer.arrangedSubviews.firstIndex(of: imageView) {
//            photoUris.remove(at: index)
//            photoContainer.removeArrangedSubview(imageView)
//            imageView.removeFromSuperview()
//        }
//    }
    
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
                showAlert(title: "Unknown Error", message: "An unknown error occurred with location permissions.")
            }
        } else {
            showAlert(title: "Location Services Disabled", message: "Please enable location services in your device settings.")
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
            showAlert(title: "Unknown Error", message: "An unknown error occurred with location permissions.")
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
        let alert = UIAlertController(title: "Location Required", message: "You declined location permissions. Please enter the location manually.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

//    func updateLocationField(with location: String) {
//        // Log the location being set
////        print("Updating location field with: \(location)")
//
//        // Check if "additional4" is present in allQuestions
//        if let index = allQuestions.firstIndex(where: { $0.id == "additional4" }) {
//            let question = allQuestions[index]
//
//            // Log details about the question
////            print("Found question with id 'additional4':")
////            print("  Text: \(question.text)")
////            print("  Type: \(question.type)")
//
//            // Update the answers dictionary
//            answers["additional4"] = [
//                "type": "input",
//                "answer": location
//            ]
//
//            // Log the current state of the answers dictionary
//            if let answer = answers["additional4"] {
////                print("Updated answer for 'additional4':")
////                print("  Type: \(answer["type"] ?? "nil")")
////                print("  Answer: \(answer["answer"] ?? "nil")")
//            } else {
////                print("No answer found for 'additional4' after update.")
//            }
//
//            // Ensure the table view cell is updated
//            let indexPath = IndexPath(row: index, section: 0)
//            tableView.reloadRows(at: [indexPath], with: .automatic)
//
//            // Log whether the cell was found and updated
//            if let cell = tableView.cellForRow(at: indexPath) as? InputQuestionCell {
////                print("Updating InputQuestionCell with new location.")
//                cell.inputTextView.text = location
//            } else {
////                print("InputQuestionCell for 'additional4' not found or not visible.")
//            }
//        } else {
////            print("'additional4' question not found in allQuestions.")
//        }
//    }
    
    func updateLocationField(with location: String) {
        // Check if "additional4" is present in allQuestions
        if let index = allQuestions.firstIndex(where: { $0.id == "additional4" }) {
            // Update the question in allQuestions
            allQuestions[index].answer = location

            // Find the corresponding view in the stack view
            if let inputQuestionView = formStackView.arrangedSubviews[index] as? InputQuestionView {
                inputQuestionView.inputTextView.text = location
            }
        }
    }

    
    func startSavingData() {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false  // Disable user interaction
    }
    
    func stopSavingData() {
        spinner.stopAnimating()
        view.isUserInteractionEnabled = true  // Re-enable user interaction
    }
    
    @objc func submitForm() {
        guard allQuestionsAnswered() else {
            showAlert(title: "Incomplete Form", message: "Please answer all questions before submitting.")
            return
        }
        
        startSavingData()
        saveFormData()
    }



//    @objc func submitForm() {
//        guard allQuestionsAnswered() else {
//            showAlert(title: "Incomplete Form", message: "Please answer all questions before submitting.")
//            return
//        }
//
//        saveFormData()
//    }

//    func allQuestionsAnswered() -> Bool {
//        for (index, question) in form?.questions.enumerated() ?? [].enumerated() {
//            let indexPath = IndexPath(row: index, section: 0)
//            if let cell = tableView.cellForRow(at: indexPath) as? QuestionCell, question.type == .okNotOkNa {
//                if !(cell.okButton.isSelected || cell.notOkButton.isSelected || cell.naButton.isSelected) {
//                    return false
//                }
//            } else if let cell = tableView.cellForRow(at: indexPath) as? InputQuestionCell, question.type == .input {
//                if cell.inputTextView.text.isEmpty {
//                    return false
//                }
//            }
//        }
//        return true
//    }
    
    func allQuestionsAnswered() -> Bool {
        for (index, question) in allQuestions.enumerated() {
            let view = formStackView.arrangedSubviews[index]

            if let inputQuestionView = view as? InputQuestionView, question.type == .input {
                if inputQuestionView.inputTextView.text.isEmpty {
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


    
//    func gatherAnswers() -> [String: Any] {
//        var answers: [String: Any] = [:]
//
//        for question in allQuestions {
//            var answer: [String: Any] = ["type": question.type.rawValue]
//
//            if question.type == .okNotOkNa {
//                answer["answer"] = question.answer ?? ""
//                answer["comment"] = question.comment ?? ""
//            } else if question.type == .input {
//                answer["answer"] = question.answer ?? ""
//            }
//
//            answers[question.id] = answer
//        }
//
//        print("All answers gathered: \(answers)")
//        return answers
//    }

    
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
                key = "q\(firebaseQuestionCounter)"
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
        let invalidCharacters: Set<Character> = [".", "#", "$", "[", "]"]
        return key.filter { !invalidCharacters.contains($0) }
    }

    func getCurrentDateTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: Date())
    }

//    func saveFormData() {
//        uploadPhotosAndGetUrls { photoUrls in
//            print("Starting to save form data...")
//
//            guard let userParent = UserSession.shared.userParent else {
//                print("Error: User parent not found.")
//                return
//            }
//            guard let formName = self.form?.name else {
//                print("Error: Form name not found.")
//                return
//            }
//
//            print("User Parent: \(userParent)")
//            print("Form Name: \(formName)")
//
//            let sanitizedFormName = self.sanitizeFirebaseKey(formName)
//            let dateString = self.getCurrentDateTimeString()
//            guard let uid = Auth.auth().currentUser?.uid else {
//                print("Error: User ID not found.")
//                return
//            }
//
//            print("Sanitized Form Name: \(sanitizedFormName)")
//            print("Date String: \(dateString)")
//            print("User ID: \(uid)")
//
//            let basePath = "completedForms/\(userParent)/\(sanitizedFormName)/\(dateString)/\(uid)"
//            let ref = Database.database().reference(withPath: basePath)
//
//            let answers = self.gatherAnswers()
//
//            print("Gathered answers: \(answers)")
//
//            let additionalData: [String: Any] = [
//                "plantNo": (answers["additional1"] as? [String: Any])?["answer"] as? String ?? "",
//                "opHours": (answers["additional2"] as? [String: Any])?["answer"] as? String ?? "",
//                "spotter": (answers["additional3"] as? [String: Any])?["answer"] as? String ?? "",
//                "location": self.locationAnswer ?? ((answers["additional4"] as? [String: Any])?["answer"] as? String ?? ""),
//                "others": (answers["additional5"] as? [String: Any])?["answer"] as? String ?? "",
//                "photoUrls": photoUrls
//            ]
//
//            print("Additional data to be saved: \(additionalData)")
//
//            ref.child("answers").setValue(answers) { error, _ in
//                if let error = error {
//                    print("Error saving answers: \(error.localizedDescription)")
//                    self.showAlert(title: "Error", message: "Failed to save the form: \(error.localizedDescription)")
//                } else {
//                    print("Answers saved successfully.")
//                    ref.child("additionalData").setValue(additionalData) { additionalError, _ in
//                        if let additionalError = additionalError {
//                            print("Error saving additional data: \(additionalError.localizedDescription)")
//                            self.showAlert(title: "Error", message: "Error submitting additional data: \(additionalError.localizedDescription)")
//                        } else {
//                            print("Additional data saved successfully.")
//                            self.showAlert(title: "Success", message: "Form submitted successfully.") {
//                                self.navigationController?.popViewController(animated: true)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    
    func saveFormData() {
        uploadPhotosAndGetUrls { photoUrls in
            print("Starting to save form data...")

            guard let userParent = UserSession.shared.userParent else {
                print("Error: User parent not found.")
                return
            }
            guard let formName = self.form?.name else {
                print("Error: Form name not found.")
                return
            }

            print("User Parent: \(userParent)")
            print("Form Name: \(formName)")

            let sanitizedFormName = self.sanitizeFirebaseKey(formName)
            let dateString = self.getCurrentDateTimeString()
            guard let uid = Auth.auth().currentUser?.uid else {
                print("Error: User ID not found.")
                return
            }

            print("Sanitized Form Name: \(sanitizedFormName)")
            print("Date String: \(dateString)")
            print("User ID: \(uid)")

            let basePath = "completedForms/\(userParent)/\(sanitizedFormName)/\(dateString)/\(uid)"
            let ref = Database.database().reference(withPath: basePath)

            let answers = self.gatherAnswers()

            print("Gathered answers: \(answers)")

            // Build the data structure to be saved to Firebase
            let firebaseAnswers = answers.mapValues { answerData -> [String: Any] in
                guard let answerDict = answerData as? [String: Any] else {
                    return [:] // Handle the case where answerData is not the expected dictionary type
                }

                var questionData: [String: Any] = [
                    "questionType": answerDict["type"] as? String ?? "",
                    "questionText": answerDict["text"] as? String ?? "", // Include questionText
                    "answer": answerDict["answer"] ?? ""
                ]

                if let comment = answerDict["comment"] as? String {
                    questionData["comment"] = comment
                }

                return questionData
            }


            let additionalData: [String: Any] = [
                "plantNo": (answers["additional1"] as? [String: Any])?["answer"] as? String ?? "",
                "opHours": (answers["additional2"] as? [String: Any])?["answer"] as? String ?? "",
                "spotter": (answers["additional3"] as? [String: Any])?["answer"] as? String ?? "",
                "location": self.locationAnswer ?? ((answers["additional4"] as? [String: Any])?["answer"] as? String ?? ""),
                "others": (answers["additional5"] as? [String: Any])?["answer"] as? String ?? "",
                "photoUrls": photoUrls
            ]

            print("Firebase answers to be saved: \(firebaseAnswers)")
            print("Additional data to be saved: \(additionalData)")

            ref.child("answers").setValue(firebaseAnswers) { error, _ in
                if let error = error {
                    print("Error saving answers: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to save the form: \(error.localizedDescription)")
                } else {
                    print("Answers saved successfully.")
                    ref.child("additionalData").setValue(additionalData) { additionalError, _ in
                        if let additionalError = additionalError {
                            print("Error saving additional data: \(additionalError.localizedDescription)")
                            self.showAlert(title: "Error", message: "Error submitting additional data: \(additionalError.localizedDescription)")
                        } else {
                            print("Additional data saved successfully.")
                            self.showAlert(title: "Success", message: "Form submitted successfully.") {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
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


