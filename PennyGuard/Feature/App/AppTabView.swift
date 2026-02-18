//
//  AppTabView.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 18/04/25.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

// MARK: - AppTabView

struct AppTabView: View {
    @Environment(\.modelContext) var modelContext
    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            TabView(
                selection: viewStore.binding(
                    get: \.selectedTab,
                    send: AppReducer.Action.selectTab
                )
            ) {
                // MARK: - Dashboard Tab
                DashboardView(
                    store: store.scope(
                        state: \.transactionState,     // Scope to shared transaction state
                        action: \.transactionState     // Scope to shared transaction actions
                    )
                )
                .environment(\.modelContext, modelContext)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
                .tag(AppReducer.Tab.dashboard)

                // MARK: - Transactions Tab
                TransactionListView(
                    store: store.scope(
                        state: \.transactionState,     // Scope to shared transaction state
                        action: \.transactionState     // Scope to shared transaction actions
                    )
                )
                .environment(\.modelContext, modelContext)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(AppReducer.Tab.transactions)
            }
            // MARK: - Centralized Sheet (at tab level to avoid duplicate bindings)
            .sheet(
                isPresented: viewStore.binding(
                    get: \.transactionState.isPresentingSheet,
                    send: { _ in AppReducer.Action.transactionState(.sheetDismissed) }
                )
            ) {
                IfLetStore(
                    store.scope(
                        state: \.transactionState.editorState,
                        action: \.transactionState.editor
                    ),
                    then: AddTransactionView.init(store:)
                )
            }
            // MARK: - Load data once when tabs first appear
            .onAppear {
                viewStore.send(.transactionState(.loadTransactions))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AppTabView(
        store: Store(
            initialState: AppReducer.State(),
            reducer: {
                AppReducer()
            }
        )
    )
}
