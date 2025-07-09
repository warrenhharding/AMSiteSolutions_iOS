//
//  Timesheet.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 23/05/2025.
//

import Foundation

struct Timesheet {
    let id: String
    let createdAt: TimeInterval
    let startDateString: String
    let endDateString: String
    let originalPath: String
    
    init(id: String, dictionary: [String: Any]) {
        self.id = id
        self.createdAt = dictionary["createdAt"] as? TimeInterval ?? 0
        self.startDateString = dictionary["startDateString"] as? String ?? ""
        self.endDateString = dictionary["endDateString"] as? String ?? ""
        self.originalPath = dictionary["originalPath"] as? String ?? ""
    }
}
