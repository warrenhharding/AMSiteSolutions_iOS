//
//  Card.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import FirebaseDatabase

struct Card {
    var cardId: String = ""
    var descriptionText: String
    var expiryDate: TimeInterval
    var frontImageURL: String
    var backImageURL: String
    var updatedAt: TimeInterval // add this property if needed

    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String: Any],
              let descriptionText = dict["description"] as? String,
              let expiryDate = dict["expiryDate"] as? TimeInterval,
              let frontImageURL = dict["frontImageURL"] as? String,
              let backImageURL = dict["backImageURL"] as? String,
              let updatedAt = dict["updatedAt"] as? TimeInterval else {
            return nil
        }
        self.descriptionText = descriptionText
        self.expiryDate = expiryDate
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.updatedAt = updatedAt
        // Now assign the key from snapshot to cardId:
        self.cardId = snapshot.key
    }
}
