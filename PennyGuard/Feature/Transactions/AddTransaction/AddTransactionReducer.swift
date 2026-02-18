//
//  AddTransactionReducer.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 18/04/25.
//

import ComposableArchitecture
import Foundation
import SwiftData
import os.log

// MARK: - Logging Configuration
extension OSLog {
    static let addTransaction = OSLog(subsystem: "com.pennyguard.app", category: "AddTransaction")
}

// MARK: - AddTransactionReducer
/// Reducer for managing the state and actions related to adding or editing a transaction.
struct AddTransactionReducer: Reducer {
    
    // MARK: - State
    /// The state representing the data for adding or editing a transaction.
    @ObservableState
    struct State: Equatable {
        var transaction: Transaction? // Existing transaction, if any
        var title: String = ""
        var amount: Double = 0.0
        var date: Date = .now
        var notes: String = ""
        var type: TransactionType = .income
        var selectedCategory: CategoryType = .salary
        var errorMessage: String? // Error message for failed saves
        
        var isEditing: Bool { transaction != nil } // Whether editing an existing transaction
        
        init() {}
        
        /// Initializer for editing an existing transaction.
        init(existing transaction: Transaction) {
            self.transaction = transaction
            self.title = transaction.title
            self.amount = transaction.amount
            self.date = transaction.date
            self.notes = transaction.notes ?? ""
            self.type = transaction.type
            self.selectedCategory = transaction.category
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        case titleChanged(String)
        case amountChanged(Double)
        case dateChanged(Date)
        case notesChanged(String)
        case typeChanged(TransactionType)
        case categorySelected(CategoryType)
        case cancelTapped
        case saveTapped
        case saveCompleted
        case saveFailed(String)
    }
    
    // MARK: - Dependencies
    @Dependency(\.swiftData) var transactionDB
 
    // MARK: - Reducer Logic
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .titleChanged(newTitle):
                state.title = newTitle
                return .none
                
            case let .amountChanged(newAmount):
                state.amount = newAmount
                return .none
                
            case let .dateChanged(newDate):
                state.date = newDate
                return .none
                
            case let .notesChanged(newNotes):
                state.notes = newNotes
                return .none
                
            case let .typeChanged(newType):
                state.type = newType
                
                // Only reset category if it doesn’t match the new type
                    if state.selectedCategory.type != newType {
                        if let firstCategory = CategoryType.allCases.first(where: { $0.type == newType }) {
                            state.selectedCategory = firstCategory
                        } else {
                            state.selectedCategory = .salary
                        }
                    }
                   return .none
            case let .categorySelected(category):
                state.selectedCategory = category // Update selected category
                return .none
            case .saveTapped:
                 // ✅ Validate input before attempting to save
                 // This is a safety net check - UI also disables save button, but we validate here too for:
                 // 1. Defense in depth - protects against unexpected UI state changes
                 // 2. Data integrity - ensures category type matches transaction type
                 // 3. Programmatic safety - catches errors if saveTapped is called directly
                 let trimmedTitle = state.title.trimmingCharacters(in: .whitespaces)
                 if trimmedTitle.isEmpty {
                     return .send(.saveFailed("Title cannot be empty"))
                 }
                 if state.amount <= 0 {
                     return .send(.saveFailed("Amount must be greater than 0"))
                 }
                 if state.selectedCategory.type != state.type {
                     return .send(.saveFailed("Category type does not match transaction type"))
                 }
                
                return .run { [state] send in
                    do {
                        if let editing = state.transaction {
                            // Create an update configuration with new values
                            @Dependency(\.swiftData) var transactionDB
                            let updateData = TransactionUpdate(
                                title: state.title,
                                amount: state.amount,
                                date: state.date,
                                notes: state.notes.isEmpty ? nil : state.notes,
                                category: state.selectedCategory,
                                type: state.type
                            )
                            try await transactionDB.update(editing.id, updateData)
                        } else {
                            let new = Transaction(
                                title: state.title,
                                amount: state.amount,
                                date: state.date,
                                notes: state.notes.isEmpty ? nil : state.notes,
                                category: state.selectedCategory,
                                type: state.type
                            )
                            try await transactionDB.add(new)
                        }
                        await send(.saveCompleted)
                    } catch {
                        #if DEBUG
                        os_log("Failed to save transaction: %@", log: .addTransaction, type: .error, error.localizedDescription)
                        #endif
                        await send(.saveFailed("Failed to save transaction: \(error.localizedDescription)"))
                    }
                }
            case .saveCompleted, .cancelTapped:
                return .none // No action needed for cancel or save completion
                
            case let .saveFailed(errorMessage):
                state.errorMessage = errorMessage
                return .none
            }
        }
    }
}
