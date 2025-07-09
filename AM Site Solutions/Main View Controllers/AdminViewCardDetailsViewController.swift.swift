//
//  AdminViewCardDetailsViewController.swift.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import UIKit
import FirebaseStorage

class AdminViewCardDetailsViewController: UIViewController {
    
    // Card data passed from the admin list view
    var cardDescription: String?
    var expiryDate: TimeInterval = 0
    var updatedAt: TimeInterval = 0
    var frontImageURL: String?
    var backImageURL: String?
    
    // UI Components
    var scrollView: UIScrollView!
    var contentView: UIView!
    var headerLabel: UILabel!
    var descriptionLabel: UILabel!
    var expiryLabel: UILabel!
    var updatedAtLabel: UILabel!
    var frontImageView: UIImageView!
    var backImageView: UIImageView!
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        displayCardDetails()
        loadImages()
    }
    
    func setupUI() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = TranslationManager.shared.getTranslation(for: "adminCards.adminCardListTitle")
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        headerLabel.textAlignment = .center
        contentView.addSubview(headerLabel)
        
        descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        
        expiryLabel = UILabel()
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(expiryLabel)
        
        updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(updatedAtLabel)
        
        frontImageView = UIImageView()
        frontImageView.translatesAutoresizingMaskIntoConstraints = false
        frontImageView.contentMode = .scaleAspectFill
        frontImageView.clipsToBounds = true
        frontImageView.backgroundColor = .lightGray
        contentView.addSubview(frontImageView)
        
        backImageView = UIImageView()
        backImageView.translatesAutoresizingMaskIntoConstraints = false
        backImageView.contentMode = .scaleAspectFill
        backImageView.clipsToBounds = true
        backImageView.backgroundColor = .lightGray
        contentView.addSubview(backImageView)
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
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
            
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            expiryLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            expiryLabel.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            expiryLabel.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            
            updatedAtLabel.topAnchor.constraint(equalTo: expiryLabel.bottomAnchor, constant: 10),
            updatedAtLabel.leadingAnchor.constraint(equalTo: expiryLabel.leadingAnchor),
            updatedAtLabel.trailingAnchor.constraint(equalTo: expiryLabel.trailingAnchor),
            
            frontImageView.topAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor, constant: 20),
            frontImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            frontImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            frontImageView.heightAnchor.constraint(equalToConstant: 200),
            
            backImageView.topAnchor.constraint(equalTo: frontImageView.bottomAnchor, constant: 20),
            backImageView.leadingAnchor.constraint(equalTo: frontImageView.leadingAnchor),
            backImageView.trailingAnchor.constraint(equalTo: frontImageView.trailingAnchor),
            backImageView.heightAnchor.constraint(equalToConstant: 200),
            backImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func displayCardDetails() {
        descriptionLabel.text = cardDescription ?? "No description available."
        let sdf = DateFormatter()
        sdf.dateFormat = "dd/MM/yyyy"
        if expiryDate > 0 {
            expiryLabel.text = "\(TranslationManager.shared.getTranslation(for: "myCards.expiryDateLabel")): \(sdf.string(from: Date(timeIntervalSince1970: expiryDate / 1000)))"
        } else {
            expiryLabel.text = "\(TranslationManager.shared.getTranslation(for: "myCards.expiryDateLabel")): N/A"
        }
        if updatedAt > 0 {
            updatedAtLabel.text = "\(TranslationManager.shared.getTranslation(for: "myCards.lastUpdatedLabel")): \(sdf.string(from: Date(timeIntervalSince1970: updatedAt / 1000)))"
        } else {
            updatedAtLabel.text = "\(TranslationManager.shared.getTranslation(for: "myCards.lastUpdatedLabel")): N/A"
        }
    }
    

    func loadImages() {
        activityIndicator.startAnimating()
        var imagesLoaded = 0

        func checkAndHandleError(for imageType: String) {
            let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "myCards.imageLoadError"), message: "\(imageType)\(TranslationManager.shared.getTranslation(for: "myCards.failedToLoadCards"))", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.retry"), style: .default, handler: { [weak self] _ in
                self?.loadImages()  // Optionally retry loading images
            }))
            alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        func checkAndHideSpinner() {
            imagesLoaded += 1
            if imagesLoaded == 2 {
                activityIndicator.stopAnimating()
            }
        }
        
        // Load front image using URLSession
        if let frontURLString = frontImageURL, let frontURL = URL(string: frontURLString) {
            URLSession.shared.dataTask(with: frontURL) { [weak self] data, response, error in
                guard let self = self else { return }
                if let error = error {
                    print("AdminViewCardDetailsViewController: Error loading front image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        checkAndHandleError(for: "Front image")
                        checkAndHideSpinner()
                    }
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.frontImageView.image = image
                        checkAndHideSpinner()
                    }
                } else {
                    DispatchQueue.main.async {
                        checkAndHandleError(for: "Front image")
                        checkAndHideSpinner()
                    }
                }
            }.resume()
        } else {
            checkAndHandleError(for: "Front image URL")
            checkAndHideSpinner()
        }
        
        // Load back image using URLSession
        if let backURLString = backImageURL, let backURL = URL(string: backURLString) {
            URLSession.shared.dataTask(with: backURL) { [weak self] data, response, error in
                guard let self = self else { return }
                if let error = error {
                    print("AdminViewCardDetailsViewController: Error loading back image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        checkAndHandleError(for: "Back image")
                        checkAndHideSpinner()
                    }
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.backImageView.image = image
                        checkAndHideSpinner()
                    }
                } else {
                    DispatchQueue.main.async {
                        checkAndHandleError(for: "Back image")
                        checkAndHideSpinner()
                    }
                }
            }.resume()
        } else {
            checkAndHandleError(for: "Back image URL")
            checkAndHideSpinner()
        }
    }

}

