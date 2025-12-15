//
//  nqApp.swift
//  nq
//

//

import SwiftUI

@main
struct nqApp: App {
    @StateObject private var store = JournalStore()
    @StateObject private var pnlStore = PnLStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pnlStore)
        }
    }
}
