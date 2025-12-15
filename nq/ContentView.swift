//
//  ContentView.swift
//  nq
//

//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: JournalStore
    @EnvironmentObject private var pnlStore: PnLStore

    var body: some View {
        ZStack {
            Theme.surface
                .ignoresSafeArea()

            TabView {
            HomeEntryView()
                .tabItem {
                    Label("Home", systemImage: "square.and.pencil")
                }
                .environmentObject(store)

            CalendarJournalView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .environmentObject(store)

            PnLView()
                    .tabItem {
                        Label("P&L", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .environmentObject(pnlStore)
            }
            .tint(Color.accentColor)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(JournalStore(fileName: "content_preview.json"))
        .environmentObject(PnLStore(fileName: "content_preview_pnl.json"))
}
