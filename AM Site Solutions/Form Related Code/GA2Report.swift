//
//  GA2Report.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//

import Foundation

struct GA2Report {
    let id: String
    let createdAt: TimeInterval
    let formName: String
    let plantNo: String
    let originalPath: String
    
    init(id: String, dictionary: [String: Any]) {
        self.id = id
        self.createdAt = dictionary["createdAt"] as? TimeInterval ?? 0
        self.formName = dictionary["formName"] as? String ?? ""
        self.plantNo = dictionary["plantNo"] as? String ?? ""
        self.originalPath = dictionary["originalPath"] as? String ?? ""
    }
}
