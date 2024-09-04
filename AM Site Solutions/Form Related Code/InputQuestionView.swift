//
//  InputQuestionView.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit

class InputQuestionView: UIView, UITextViewDelegate {

    var question: FormQuestion? {
        didSet {
            guard let question = question else { return }
            questionLabel.text = question.text
            if question.answer?.isEmpty == false {
                inputTextView.text = question.answer
                inputTextView.textColor = .black
            } else {
                inputTextView.text = "Enter your answer"
                inputTextView.textColor = .lightGray
            }
            print("InputQuestionView didSet called. Question ID: \(question.id), Answer: \(question.answer ?? "")")
        }
    }

    let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    let inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5.0
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.text = "Enter your answer"
        textView.textColor = .lightGray // Placeholder color
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        inputTextView.delegate = self  // Set delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 0.9, alpha: 1) // Match the color with OkNotOkView
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        containerView.addSubview(questionLabel)
        containerView.addSubview(inputTextView)
        
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            inputTextView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            inputTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            inputTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            inputTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    // UITextViewDelegate method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter your answer"
            textView.textColor = .lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        question?.answer = textView.text
        
        // Update the corresponding question in allQuestions in the parent view controller
        if let parentVC = self.parentViewController as? FormViewController,
           let questionId = question?.id,
           let index = parentVC.allQuestions.firstIndex(where: { $0.id == questionId }) {
            parentVC.allQuestions[index].answer = textView.text
            print("Updated allQuestions with ID \(questionId) to \(textView.text ?? "")")
        } else {
            print("Failed to update allQuestions for ID \(question?.id ?? "nil")")
        }
        
        printFullAllQuestionsState()
    }
    
    private func printFullAllQuestionsState() {
        guard let parentVC = self.parentViewController as? FormViewController else {
            print("Error: Unable to find parent view controller.")
            return
        }
        print("Full state of allQuestions:")
        for question in parentVC.allQuestions {
            print("  Question ID: \(question.id), Answer: \(question.answer ?? "nil")")
        }
    }
}



//import UIKit
//
//class InputQuestionView: UIView, UITextViewDelegate {
//
//    var question: FormQuestion? {
//        didSet {
//            guard let question = question else { return }
//            questionLabel.text = question.text
//            inputTextView.text = question.answer ?? ""
//            print("InputQuestionView didSet called. Question ID: \(question.id), Answer: \(question.answer ?? "")")
//        }
//    }
//
//    let questionLabel: UILabel = {
//        let label = UILabel()
//        label.numberOfLines = 0
//        label.font = UIFont.systemFont(ofSize: 20)
//        label.isUserInteractionEnabled = false
//        return label
//    }()
//
//    let inputTextView: UITextView = {
//        let textView = UITextView()
//        textView.font = UIFont.systemFont(ofSize: 16)
//        textView.layer.borderWidth = 1.0
//        textView.layer.borderColor = UIColor.lightGray.cgColor
//        textView.layer.cornerRadius = 5.0
//        textView.isScrollEnabled = false
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
//        return textView
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayout()
//        inputTextView.delegate = self  // Set delegate
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupLayout() {
//        let containerView = UIView()
//        containerView.backgroundColor = .white
//        containerView.layer.cornerRadius = 8
//        containerView.layer.masksToBounds = true
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(containerView)
//
//        containerView.addSubview(questionLabel)
//        containerView.addSubview(inputTextView)
//
//        questionLabel.translatesAutoresizingMaskIntoConstraints = false
//        inputTextView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
//            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
//            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
//
//            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
//            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//
//            inputTextView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
//            inputTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            inputTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            inputTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
//            inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
//        ])
//    }
//
//    // UITextViewDelegate method
//    func textViewDidChange(_ textView: UITextView) {
//        question?.answer = textView.text
//
//        // Update the corresponding question in allQuestions in the parent view controller
//        if let parentVC = self.parentViewController as? FormViewController,
//           let questionId = question?.id,
//           let index = parentVC.allQuestions.firstIndex(where: { $0.id == questionId }) {
//            parentVC.allQuestions[index].answer = textView.text
//            print("Updated allQuestions with ID \(questionId) to \(textView.text ?? "")")
//        } else {
//            print("Failed to update allQuestions for ID \(question?.id ?? "nil")")
//        }
//
//        printFullAllQuestionsState()
//    }
//
//    private func printFullAllQuestionsState() {
//        guard let parentVC = self.parentViewController as? FormViewController else {
//            print("Error: Unable to find parent view controller.")
//            return
//        }
//        print("Full state of allQuestions:")
//        for question in parentVC.allQuestions {
//            print("  Question ID: \(question.id), Answer: \(question.answer ?? "nil")")
//        }
//    }
//}




// Extension to help get the parent view controller
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let responder = parentResponder {
            parentResponder = responder.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

