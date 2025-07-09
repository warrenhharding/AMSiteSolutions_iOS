//
//  DatePickerViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import UIKit

class DatePickerViewController: UIViewController {
    var datePicker = UIDatePicker()
    var completion: ((Date?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Toolbar at the top with Cancel and Done
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        toolbar.setItems([cancelButton, flexSpace, doneButton], animated: false)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.minimumDate = Date()
        
        view.addSubview(toolbar)
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            datePicker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true) {
            self.completion?(nil)  // signal that user cancelled
        }
    }
    
    @objc func doneTapped() {
        dismiss(animated: true) {
            self.completion?(self.datePicker.date)
        }
    }
}

