//
//  CustomPickerView.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//

import UIKit

class CustomPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {

    // Make pickerView public
    public let pickerView = UIPickerView()
    private let toolbar = UIToolbar()
    private let titleLabel = UILabel()
    
    var data: [String] = [] {
        didSet {
            pickerView.reloadAllComponents()
        }
    }
    
    var onSelect: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPickerView()
        setupToolbar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPickerView()
        setupToolbar()
    }
    
    private func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
        pickerView.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1).cgColor
        pickerView.layer.borderWidth = 1
        pickerView.layer.cornerRadius = 8
    }
    
    private func setupToolbar() {
        toolbar.sizeToFit()
        
        titleLabel.text = "Select Option"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.sizeToFit()
        
        let titleItem = UIBarButtonItem(customView: titleLabel)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        
        toolbar.setItems([flexibleSpace, titleItem, flexibleSpace, doneButton], animated: false)
    }
    
    @objc private func doneButtonTapped() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        let selectedValue = data[selectedRow]
        onSelect?(selectedValue)
    }
    
    // UIPickerViewDelegate and UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
    
    func getInputView() -> UIView {
        return pickerView
    }
    
    func getInputAccessoryView() -> UIView {
        return toolbar
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
