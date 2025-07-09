//
//  ClockOffDialogViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 28/01/2025.
//


import UIKit

protocol ClockOffDialogDelegate: AnyObject {
    func didCompleteClockOff(hadLunchBreak: Bool, lengthOfLunch: String, lengthOfHire: String, stopLocation: String)
}

class ClockOffDialogViewController: UIViewController {

    var delegate: ClockOffDialogDelegate?
    var isHireEquipmentUsed: Bool = false
    var hadLunchBreak: Bool = false
    var stopLocation: String = ""

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = TranslationManager.shared.getTranslation(for: "timesheetTab.clockOffDetails")
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = TranslationManager.shared.getTranslation(for: "timesheetTab.lunchBreakLabel")
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private let yesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TranslationManager.shared.getTranslation(for: "common.yesButton"), for: .normal)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.addTarget(self, action: #selector(didSelectYes), for: .touchUpInside)
        return button
    }()

    private let noButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TranslationManager.shared.getTranslation(for: "common.noButton"), for: .normal)
        button.setImage(UIImage(systemName: "circle.fill"), for: .normal) // Default selected
        button.addTarget(self, action: #selector(didSelectNo), for: .touchUpInside)
        return button
    }()

    private let lunchDurationLabel: UILabel = {
        let label = UILabel()
        label.text = TranslationManager.shared.getTranslation(for: "timesheetTab.lengthOfLunchLabel")
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()

    private let lunchDurationField: UITextField = {
        let textField = UITextField()
        textField.placeholder = TranslationManager.shared.getTranslation(for: "timesheetTab.lengthOfLunchFieldHint")
        textField.borderStyle = .roundedRect
        textField.isHidden = true
        textField.autocapitalizationType = .sentences
        return textField
    }()

    private let hireDurationLabel: UILabel = {
        let label = UILabel()
        label.text = TranslationManager.shared.getTranslation(for: "timesheetTab.hireDurationLabel")
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()

    private let hireDurationField: UITextField = {
        let textField = UITextField()
        textField.placeholder = TranslationManager.shared.getTranslation(for: "timesheetTab.hireDurationFieldHint")
        textField.borderStyle = .roundedRect
        textField.isHidden = true
        textField.autocapitalizationType = .sentences
        return textField
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TranslationManager.shared.getTranslation(for: "common.cancelButton"), for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    private let okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TranslationManager.shared.getTranslation(for: "common.okButton"), for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(okTapped), for: .touchUpInside)
        return button
    }()

    private var contentHeightConstraint: NSLayoutConstraint!
    private var lunchDurationFieldHeightConstraint: NSLayoutConstraint!
    private var hireDurationFieldHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        
        print("isHireEquipmentUsed: \(isHireEquipmentUsed)")

        // Show equipment hire section if applicable
        if isHireEquipmentUsed {
            hireDurationLabel.isHidden = false
            hireDurationField.isHidden = false
        }

        // Add keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Allow tapping to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        // Update size based on initial visibility
        updateContentSize()
    }

    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Dim background
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(okButton)
    }

    private func setupLayout() {
        view.addSubview(contentView)

        let buttonStack = UIStackView(arrangedSubviews: [yesButton, noButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.alignment = .center
        buttonStack.distribution = .fillEqually

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel, questionLabel, buttonStack,
            lunchDurationLabel, lunchDurationField,
            hireDurationLabel, hireDurationField,
            buttonStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 180)
        lunchDurationFieldHeightConstraint = lunchDurationField.heightAnchor.constraint(equalToConstant: 30)
        hireDurationFieldHeightConstraint = hireDurationField.heightAnchor.constraint(equalToConstant: 30)

        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            contentHeightConstraint,

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func updateContentSize() {
        var height: CGFloat = 180 // Base height

        if !lunchDurationLabel.isHidden {
            height += 60 // Add height for lunch duration section
        }

        if !hireDurationLabel.isHidden {
            height += 60 // Add height for hire duration section
        }

        contentHeightConstraint.constant = height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func didSelectYes() {
        hadLunchBreak = true
        yesButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        noButton.setImage(UIImage(systemName: "circle"), for: .normal)
        lunchDurationLabel.isHidden = false
        lunchDurationField.isHidden = false
        lunchDurationFieldHeightConstraint.isActive = true
        updateContentSize()
    }

    @objc private func didSelectNo() {
        hadLunchBreak = false
        yesButton.setImage(UIImage(systemName: "circle"), for: .normal)
        noButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        lunchDurationLabel.isHidden = true
        lunchDurationField.isHidden = true
        lunchDurationFieldHeightConstraint.isActive = false
        updateContentSize()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func okTapped() {
        delegate?.didCompleteClockOff(
            hadLunchBreak: hadLunchBreak,
            lengthOfLunch: lunchDurationField.text ?? "",
            lengthOfHire: hireDurationField.text ?? "",
            stopLocation: stopLocation)
        dismiss(animated: true, completion: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        view.frame.origin.y = -100
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
}

