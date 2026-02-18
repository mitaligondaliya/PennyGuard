//
//  AppReducer.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 18/04/25.
//

import ComposableArchitecture

// MARK: - AppReducer

struct AppReducer: Reducer {
    
    // MARK: - State

    struct State {
        var selectedTab: Tab = .dashboard
        var transactionState = TransactionReducer.State()  // Shared state for both tabs
    }

    // MARK: - Action

    @CasePathable
    enum Action {
        case transactionState(TransactionReducer.Action)  // Forward action to shared TransactionReducer
        case selectTab(Tab)                               // Tab selection action
    }

    // MARK: - Tab Enum

    enum Tab: Hashable {
        case dashboard
        case transactions
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        
        // Scope shared transaction state and actions to TransactionReducer
        Scope(state: \.transactionState, action: \.transactionState) {
            TransactionReducer()
        }

        // Reducer handling tab selection and general app-level logic
        Reduce { state, action in
            print("📬 AppReducer received action: \(action)")
            switch action {
            case .selectTab(let tab):
                state.selectedTab = tab
                return .none
            case .transactionState:
                return .none // Forwarded actions handled in scoped reducer
            }
        }
    }
}
