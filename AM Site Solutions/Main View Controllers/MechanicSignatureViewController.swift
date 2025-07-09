//
//  MechanicSignatureViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/03/2025.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class MechanicSignatureViewController: UIViewController {
    
    weak var signatureDelegate: SignatureDelegate?
    
    // UI Elements
    var signatureDrawView: SignatureDrawView!
    let clearButton = CustomButton(type: .system)
    let cancelButton = CustomButton(type: .system)
    let saveButton = CustomButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("SignatureViewController loaded.")
        view.backgroundColor = .white
        setupUI()
    }
    
    func setupUI() {
        // Setup signature drawing view
        signatureDrawView = SignatureDrawView()
        signatureDrawView.backgroundColor = UIColor.lightGray
        signatureDrawView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signatureDrawView)
        
        // Setup buttons
        [clearButton, cancelButton, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        clearButton.setTitle(TranslationManager.shared.getTranslation(for: "mechanicReports.clearButton"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearSignature), for: .touchUpInside)
        
        cancelButton.setTitle(TranslationManager.shared.getTranslation(for: "common.cancelButton"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelSignature), for: .touchUpInside)
        
        saveButton.setTitle(TranslationManager.shared.getTranslation(for: "common.saveButton"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveSignature), for: .touchUpInside)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            signatureDrawView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            signatureDrawView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            signatureDrawView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            signatureDrawView.heightAnchor.constraint(equalToConstant: 200),
            
            clearButton.topAnchor.constraint(equalTo: signatureDrawView.bottomAnchor, constant: 16),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: clearButton.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: clearButton.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 8),
            saveButton.leadingAnchor.constraint(equalTo: clearButton.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: clearButton.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func clearSignature() {
        print("Clear signature tapped.")
        signatureDrawView.clear()
    }
    
    @objc func cancelSignature() {
        print("Cancel signature tapped.")
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveSignature() {
        print("Save signature tapped.")
        signatureDrawView.backgroundColor = .clear
        guard let image = signatureDrawView.getSignatureImage() else {
            showAlert(title: TranslationManager.shared.getTranslation(for: "common.errorHeader"), message: TranslationManager.shared.getTranslation(for: "mechanicReports.pleaseAddSig"))
            return
        }
        signatureDelegate?.didCaptureSignature(image)
        dismiss(animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        print("Signature Alert: \(title) - \(message)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

