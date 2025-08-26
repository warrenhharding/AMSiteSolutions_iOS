//
//  CustomTextField.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//

import UIKit

class CustomTextField: UITextField {

    var shouldCapitalizeWords: Bool = false {
        didSet {
            if shouldCapitalizeWords {
                autocapitalizationType = .words
            } else {
                autocapitalizationType = .sentences
            }
        }
    }
    
    private let textPadding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    // Initializer for programmatic use
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    // Initializer for use in Interface Builder
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    // Setup the text field with specified attributes
    private func setupTextField() {
        self.layer.cornerRadius = 10
        self.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
        self.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1).cgColor
        self.layer.borderWidth = 1
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Placeholder settings
        let placeholderColor = UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 1)
        if let placeholderText = self.placeholder {
            self.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [
                .foregroundColor: placeholderColor,
                .font: UIFont.systemFont(ofSize: 16)
            ])
        }
        
        // Text color when user types
        self.textColor = UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1)
        self.font = UIFont.systemFont(ofSize: 16)
    }
    
    // Function to set the placeholder text
    func setPlaceholder(_ text: String) {
        let placeholderColor = UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 1)
        self.attributedPlaceholder = NSAttributedString(string: text, attributes: [
            .foregroundColor: placeholderColor,
            .font: UIFont.systemFont(ofSize: 16)
        ])
    }

    // Override to add padding
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 40 // Fixed height
        return size
    }
}

