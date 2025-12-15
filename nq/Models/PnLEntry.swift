//
//  PnLEntry.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import Foundation

struct PnLEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amount: Double
    var note: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double = 0,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.note = note
        self.createdAt = createdAt
    }

    static let placeholder = PnLEntry()
}
