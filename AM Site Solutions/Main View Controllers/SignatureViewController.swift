//
//  SignatureViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 29/01/2025.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase

class SignatureViewController: UIViewController {

    var isForemanMode: Bool = true // Determines Foreman vs Operator mode
    var signatureImageView: UIImageView!
    var noteTextView: UITextView!
    var clearButton: CustomButton!
    var cancelButton: CustomButton!
    var saveButton: CustomButton!
    
    var signatureDrawView: SignatureDrawView! // Custom view for drawing signature
    var userParent: String = UserSession.shared.userParent ?? ""
    
    var existingSignatureURL: String?  // Passed from TimesheetViewController
    var existingNote: String?           // Passed from TimesheetViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Display existing note
        if let note = existingNote {
            noteTextView.text = note
        }

        // Load existing signature if available
        if let signatureURL = existingSignatureURL {
            loadSignature(from: signatureURL)
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

    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardHeight / 2 // 🔥 Shift the screen up
            }
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0 // 🔥 Reset back to normal
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true) // Dismisses the keyboard when tapping outside
    }
    

    func loadSignature(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = signatureDrawView.center
        signatureDrawView.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                    self.signatureDrawView.setSignatureImage(image) // 🔥 Update signature canvas
                }
            } else {
                DispatchQueue.main.async {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                }
            }
        }
    }
    
    func setupUI() {
        view.backgroundColor = .white
        title = isForemanMode ? TranslationManager.shared.getTranslation(for: "timesheetTab.addForemanSignatureButton") : TranslationManager.shared.getTranslation(for: "timesheetTab.addOperatorSignatureButton")
        
        // Signature Canvas
        signatureDrawView = SignatureDrawView()
        signatureDrawView.backgroundColor = UIColor.lightGray
        view.addSubview(signatureDrawView)
        
        // Note TextView
        noteTextView = UITextView()
        noteTextView.font = UIFont.systemFont(ofSize: 16)
        noteTextView.backgroundColor = UIColor.systemGray6
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.darkGray.cgColor
        noteTextView.autocapitalizationType = .sentences
        view.addSubview(noteTextView)
        
        // Buttons
        clearButton = CustomButton(type: .system)
        clearButton.setTitle(TranslationManager.shared.getTranslation(for: "timesheetTab.clearSignatureButton"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearSignature), for: .touchUpInside)
        view.addSubview(clearButton)

        cancelButton = CustomButton(type: .system)
        cancelButton.setTitle(TranslationManager.shared.getTranslation(for: "common.cancelButton"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelSignature), for: .touchUpInside)
        view.addSubview(cancelButton)

        saveButton = CustomButton(type: .system)
        saveButton.setTitle(TranslationManager.shared.getTranslation(for: "common.saveButton"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveSignature), for: .touchUpInside)
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    
    func setupConstraints() {
        signatureDrawView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Signature Canvas
            signatureDrawView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            signatureDrawView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            signatureDrawView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            signatureDrawView.heightAnchor.constraint(equalToConstant: 200),

            // Note TextView
            noteTextView.topAnchor.constraint(equalTo: signatureDrawView.bottomAnchor, constant: 16),
            noteTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            noteTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            noteTextView.heightAnchor.constraint(equalToConstant: 100),

            // Clear Button
            clearButton.topAnchor.constraint(equalTo: noteTextView.bottomAnchor, constant: 16),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.heightAnchor.constraint(equalToConstant: 44),

            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),

            // Save Button
            saveButton.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 8),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    
    @objc func clearSignature() {
        signatureDrawView.clear()
    }

    @objc func cancelSignature() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveSignature() {
        guard let image = signatureDrawView.getSignatureImage() else {
            print("No signature drawn")
            return
        }

        let note = noteTextView.text ?? ""
        uploadSignature(image, note: note)
    }
    
    func uploadSignature(_ image: UIImage, note: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let fileName = isForemanMode ? "foreman_signature.png" : "operator_signature.png"
        let storagePath = "customers/\(userParent)/timesheets/\(userID)/\(fileName)"
        
        let storageRef = Storage.storage().reference().child(storagePath)
        if let imageData = image.pngData() {
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading signature: \(error.localizedDescription)")
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.saveToFirebase(url: url.absoluteString, note: note)
                    }
                }
            }
        }
    }
    
    func saveToFirebase(url: String, note: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = isForemanMode ?
            ["foremanSignature": url, "foremanNote": note] :
            ["operatorSignature": url, "operatorNote": note]

        Database.database().reference()
            .child("customers").child(userParent)
            .child("timesheets").child(userID)
            .updateChildValues(data) { error, _ in
                if let error = error {
                    print("Error saving signature: \(error.localizedDescription)")
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
    }
}

