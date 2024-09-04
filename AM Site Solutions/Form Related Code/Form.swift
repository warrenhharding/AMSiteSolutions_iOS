//
//  Form.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import Foundation

struct Form {
    let id: String
    let name: String
    let iconName: String
    let questions: [Question]
}


struct Question {
    let id: String
    let text: String
    let type: QuestionType
}

struct FormQuestion {
    var id: String
    var text: String
    var type: QuestionType
    var answer: String? // Mutable property for storing the user's answer
    var comment: String? // Mutable property for storing the user's comment
}


enum QuestionType: String {
    case okNotOkNa = "ok_not_ok_na"
    case input = "input"
    // Add other question types if needed

    init?(rawValue: String) {
        switch rawValue {
        case "ok_not_ok_na": self = .okNotOkNa
        case "input": self = .input
        // Add other cases matching your database values
        default: return nil
        }
    }
}
