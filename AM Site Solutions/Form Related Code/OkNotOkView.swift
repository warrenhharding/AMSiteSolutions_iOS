//
//  OkNotOkView.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit

class OkNotOkView: UIView {

    var question: FormQuestion? {
        didSet {
            guard let question = question else { return }
            questionLabel.text = question.text

            // Reset buttons and text field
            okButton.isSelected = false
            notOkButton.isSelected = false
            naButton.isSelected = false
            commentTextField.text = question.comment ?? ""

            // Set the correct radio button if the answer exists
            if let answer = question.answer {
                switch answer {
                    case "OK":
                        okButton.isSelected = true
                    case "NOK":
                        notOkButton.isSelected = true
                    case "NA":
                        naButton.isSelected = true
                    default:
                        break
                }
            }
        }
    }

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.9, alpha: 1) // Use the same background color as the InputQuestionView
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20)
        label.isUserInteractionEnabled = false
        return label
    }()

    let okButton: CustomRadioButton = {
        let button = CustomRadioButton()
        button.setTitle("OK", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.contentHorizontalAlignment = .left
        button.tag = 1
        button.isUserInteractionEnabled = true
        if let circleImage = UIImage(systemName: "circle")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)),
           let circleFilledImage = UIImage(systemName: "circle.inset.filled")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)) {
            button.setImage(circleImage, for: .normal)
            button.setImage(circleFilledImage, for: .selected)
        }
        return button
    }()
    
    let notOkButton: CustomRadioButton = {
        let button = CustomRadioButton()
        button.setTitle("Not OK", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.contentHorizontalAlignment = .left
        button.tag = 2
        button.isUserInteractionEnabled = true
        if let circleImage = UIImage(systemName: "circle")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)),
           let circleFilledImage = UIImage(systemName: "circle.inset.filled")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)) {
            button.setImage(circleImage, for: .normal)
            button.setImage(circleFilledImage, for: .selected)
        }
        return button
    }()
    
    let naButton: CustomRadioButton = {
        let button = CustomRadioButton()
        button.setTitle("N/A", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.contentHorizontalAlignment = .left
        button.tag = 3
        button.isUserInteractionEnabled = true
        if let circleImage = UIImage(systemName: "circle")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)),
           let circleFilledImage = UIImage(systemName: "circle.inset.filled")?.withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)) {
            button.setImage(circleImage, for: .normal)
            button.setImage(circleFilledImage, for: .selected)
        }
        return button
    }()
    
    let commentTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter comment (max 50 chars)"
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.isUserInteractionEnabled = true
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    private func setupLayout() {
//        addSubview(containerView)
//        containerView.addSubview(questionLabel)
//        containerView.addSubview(okButton)
//        containerView.addSubview(notOkButton)
//        containerView.addSubview(naButton)
//        containerView.addSubview(commentTextField)
//
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        questionLabel.translatesAutoresizingMaskIntoConstraints = false
//        okButton.translatesAutoresizingMaskIntoConstraints = false
//        notOkButton.translatesAutoresizingMaskIntoConstraints = false
//        naButton.translatesAutoresizingMaskIntoConstraints = false
//        commentTextField.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            // Constraints for the containerView within OkNotOkView
//            containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
//            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
//            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
//            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
//            
//            // Question Label Constraints
//            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
//            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//
//            // OK Button Constraints
//            okButton.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
//            okButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            okButton.trailingAnchor.constraint(lessThanOrEqualTo: notOkButton.leadingAnchor, constant: -8),
//            okButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
//
//            // Not OK Button Constraints
//            notOkButton.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
//            notOkButton.trailingAnchor.constraint(lessThanOrEqualTo: naButton.leadingAnchor, constant: -8),
//            notOkButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
//
//            // N/A Button Constraints
//            naButton.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
//            naButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            naButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
//            
//            // Comment Text Field Constraints
//            commentTextField.topAnchor.constraint(equalTo: okButton.bottomAnchor, constant: 16),
//            commentTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            commentTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            commentTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
//            commentTextField.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }

    
    private func setupLayout() {
        addSubview(containerView)
        containerView.addSubview(questionLabel)
        containerView.addSubview(commentTextField)

        // Create a horizontal stack view for the buttons
        let buttonStackView = UIStackView(arrangedSubviews: [okButton, notOkButton, naButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillProportionally
        buttonStackView.spacing = 16
        buttonStackView.alignment = .center

        containerView.addSubview(buttonStackView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        commentTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Constraints for the containerView within OkNotOkView
            containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            
            // Question Label Constraints
            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Button Stack View Constraints
            buttonStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Comment Text Field Constraints
            commentTextField.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            commentTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            commentTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            commentTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            commentTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }



    
    
    private func setupActions() {
        okButton.addTarget(self, action: #selector(radioButtonTapped(_:)), for: .touchUpInside)
        notOkButton.addTarget(self, action: #selector(radioButtonTapped(_:)), for: .touchUpInside)
        naButton.addTarget(self, action: #selector(radioButtonTapped(_:)), for: .touchUpInside)
        commentTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    @objc private func radioButtonTapped(_ sender: CustomRadioButton) {
        let buttons = [okButton, notOkButton, naButton]
        buttons.forEach { $0.isSelected = ($0 == sender) }

        // Update the answer in the FormQuestion object
        if let answer = selectedAnswer() {
            question?.answer = answer
            
            if let parentVC = self.parentViewController as? FormViewController,
               let questionId = question?.id,
               let index = parentVC.allQuestions.firstIndex(where: { $0.id == questionId }) {
                parentVC.allQuestions[index].answer = answer
                print("Updated allQuestions with ID \(questionId) to \(answer)")
            } else {
                print("Failed to update allQuestions for ID \(question?.id ?? "nil")")
            }
        }
        printFullAllQuestionsState()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        question?.comment = textField.text
        
        if let parentVC = self.parentViewController as? FormViewController,
           let questionId = question?.id,
           let index = parentVC.allQuestions.firstIndex(where: { $0.id == questionId }) {
            parentVC.allQuestions[index].comment = textField.text
            print("Updated comment in allQuestions with ID \(questionId) to \(textField.text ?? "")")
        } else {
            print("Failed to update comment in allQuestions for ID \(question?.id ?? "nil")")
        }
        
        printFullAllQuestionsState()
    }
    
    private func selectedAnswer() -> String? {
        if okButton.isSelected { return "OK" }
        if notOkButton.isSelected { return "NOK" }
        if naButton.isSelected { return "NA" }
        return nil
    }

    private func printFullAllQuestionsState() {
        guard let parentVC = self.parentViewController as? FormViewController else {
            print("Error: Unable to find parent view controller.")
            return
        }
        print("Full state of allQuestions:")
        for question in parentVC.allQuestions {
            print("  Question ID: \(question.id), Answer: \(question.answer ?? "nil"), Comment: \(question.comment ?? "nil")")
        }
    }
}



