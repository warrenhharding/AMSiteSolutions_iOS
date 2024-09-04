//
//  CustomButton.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//


import UIKit

@available(iOS 15.0, *)
class CustomButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        var config = UIButton.Configuration.filled()
        config.titleAlignment = .center
        config.baseBackgroundColor = ColorScheme.amBlue
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.boldSystemFont(ofSize: 16)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 16.0, leading: 32.0, bottom: 16.0, trailing: 32.0)
        
        self.configuration = config
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Set fixed height constraint
        self.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Apply corner radius directly to the layer
        self.layer.cornerRadius = 32
        self.layer.masksToBounds = true
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 60 // Fixed height
        return size
    }
    
    
}



