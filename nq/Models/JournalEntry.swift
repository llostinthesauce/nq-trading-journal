//
//  JournalEntry.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import Foundation

/// Represents a single trading journal entry.
struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var pair: String
    var bias: TradeBias
    var entryModel: EntryModel
    var entryTimeframe: EntryTimeframe
    var riskContracts: Int
    var winLoss: WinLossState
    var profitLoss: String
    var points: String
    var entryPoints: String
    var exitPoints: String
    var riskReward: String
    var rating: TradeRating
    var analysis: String
    var psychology: String
    var imagePath: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        pair: String = "MNQ",
        bias: TradeBias = .bullish,
        entryModel: EntryModel = .market,
        entryTimeframe: EntryTimeframe = .oneMinute,
        riskContracts: Int = 10,
        winLoss: WinLossState = .breakeven,
        profitLoss: String = "",
        points: String = "",
        entryPoints: String = "",
        exitPoints: String = "",
        riskReward: String = "",
        rating: TradeRating = .notRated,
        analysis: String = "",
        psychology: String = "",
        imagePath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.pair = pair
        self.bias = bias
        self.entryModel = entryModel
        self.entryTimeframe = entryTimeframe
        self.riskContracts = riskContracts
        self.winLoss = winLoss
        self.profitLoss = profitLoss
        self.points = points
        self.entryPoints = entryPoints
        self.exitPoints = exitPoints
        self.riskReward = riskReward
        self.rating = rating
        self.analysis = analysis
        self.psychology = psychology
        self.imagePath = imagePath
        self.createdAt = createdAt
    }

    static let empty = JournalEntry()
}

enum WinLossState: String, CaseIterable, Codable, Identifiable {
    case win = "WIN"
    case loss = "LOSS"
    case breakeven = "BE"

    var id: String { rawValue }
}

enum EntryModel: String, CaseIterable, Codable, Identifiable {
    case market = "Market"
    case limit = "Limit"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum TradeBias: String, CaseIterable, Codable, Identifiable {
    case bullish = "Bullish"
    case bearish = "Bearish"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum EntryTimeframe: String, CaseIterable, Codable, Identifiable {
    case oneMinute = "1"
    case fiveMinutes = "5"
    case fifteenMinutes = "15"
    case oneHour = "1hr"
    case fourHour = "4hr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneMinute:
            return "1 min"
        case .fiveMinutes:
            return "5 min"
        case .fifteenMinutes:
            return "15 min"
        case .oneHour:
            return "1 hr"
        case .fourHour:
            return "4 hr"
        }
    }

    var formatted: String {
        switch self {
        case .oneMinute:
            return "1m"
        case .fiveMinutes:
            return "5m"
        case .fifteenMinutes:
            return "15m"
        case .oneHour:
            return "1hr"
        case .fourHour:
            return "4hr"
        }
    }
}

enum TradeRating: String, CaseIterable, Codable, Identifiable {
    case notRated = "-"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }
}
