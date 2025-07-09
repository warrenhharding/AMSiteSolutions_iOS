//
//  LanguageManager.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 18/12/2024.
//

import Foundation


class LanguageManager {
    static let shared = LanguageManager()
    private init() {}

    var availableLanguages: [Language] = []
}

