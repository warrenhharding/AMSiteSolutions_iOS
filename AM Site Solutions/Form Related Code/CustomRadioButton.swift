//
//  CustomRadioButton.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit

class CustomRadioButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        setImage(UIImage(systemName: "circle"), for: .normal)
        setImage(UIImage(systemName: "circle.inset.filled"), for: .selected)
        tintColor = .black
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        isSelected.toggle()
    }
}


