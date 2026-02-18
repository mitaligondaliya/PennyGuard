//
//  DatabaseClient.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 25/04/25.
//
import ComposableArchitecture
import SwiftData
import Foundation
import os.log

// MARK: - Logging Configuration
extension OSLog {
    static let database = OSLog(subsystem: "com.pennyguard.app", category: "Database")
}

// MARK: - Dependency Injection Key for SwiftData-based Transaction Database
extension DependencyValues {
    var swiftData: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}

// MARK: - Transaction Update Configuration
struct TransactionUpdate {
    let title: String
    let amount: Double
    let date: Date
    let notes: String?
    let category: CategoryType
    let type: TransactionType
}

// MARK: - TransactionDatabase Interface
struct DatabaseClient {
    var fetchAll: () async throws -> [Transaction]       // Fetch all transactions
    var fetch: (FetchDescriptor<Transaction>) async throws -> [Transaction] // Fetch with a descriptor
    var add: (Transaction) async throws -> Void           // Add a transaction
    var deleteByID: (UUID) async throws -> Void  // Delete a transaction by ID
    var update: (UUID, TransactionUpdate) async throws -> Void  // Update transaction with new values
    
    // MARK: - Transaction Errors
    enum TransactionError: Error {
        case add
        case delete
        case update
        case fetchFailed
        
        var localizedDescription: String {
            switch self {
            case .add:
                return "Failed to add transaction"
            case .delete:
                return "Failed to delete transaction"
            case .update:
                return "Failed to update transaction"
            case .fetchFailed:
                return "Failed to fetch transaction"
            }
        }
    }
}

// MARK: - Live Implementation
extension DatabaseClient: DependencyKey {
    public static let liveValue = Self(
        fetchAll: {
            // Access the SwiftData context and fetch all transactions sorted by date
            @Dependency(\.databaseService.context) var context
            let transactionContext = try context()
            
            let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)])
            return try transactionContext.fetch(descriptor)
        },
        fetch: { descriptor in
            // Fetch using a provided FetchDescriptor
            @Dependency(\.databaseService.context) var context
            let transactionContext = try context()
            return try transactionContext.fetch(descriptor)
        },
        add: { model in
            do {
                // Insert a new transaction model into the context
                @Dependency(\.databaseService.context) var context
                let transactionContext = try context()
                transactionContext.insert(model)
                try transactionContext.save()  // Ensure save is called after adding
            } catch {
                #if DEBUG
                os_log("Failed to add transaction: %@", log: .database, type: .error, error.localizedDescription)
                #endif
                throw TransactionError.add
            }
        },
        deleteByID: { id in
            do {
                @Dependency(\.databaseService.context) var context
                let transactionContext = try context()  // Single context call
                let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
                if let transaction = try transactionContext.fetch(descriptor).first {
                    transactionContext.delete(transaction)
                    try transactionContext.save()
                } else {
                    throw TransactionError.delete
                }
            } catch {
                #if DEBUG
                os_log("Failed to delete transaction: %@", log: .database, type: .error, error.localizedDescription)
                #endif
                throw error is TransactionError ? error : TransactionError.delete
            }
        },
        update: { id, updateData in
            do {
                // Fetch and update the transaction in a single context operation
                @Dependency(\.databaseService.context) var context
                let transactionContext = try context()
                
                let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
                if let transaction = try transactionContext.fetch(descriptor).first {
                    // Update the transaction's properties in-place
                    transaction.title = updateData.title
                    transaction.amount = updateData.amount
                    transaction.date = updateData.date
                    transaction.notes = updateData.notes
                    transaction.category = updateData.category
                    transaction.type = updateData.type
                    // SwiftData automatically tracks changes to @Model objects
                    try transactionContext.save()
                } else {
                    throw TransactionError.fetchFailed
                }
            } catch {
                #if DEBUG
                os_log("Failed to update transaction: %@", log: .database, type: .error, error.localizedDescription)
                #endif
                throw TransactionError.update
            }
        }
    )
}

// MARK: - Preview / Test Implementation
extension DatabaseClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        fetchAll: { [] },
        fetch: { _ in [] },
        add: { _ in },
        deleteByID: { _ in },
        update: { _, _ in }
    )
    
    /// No-op mock version used for previews
    static let noop = Self(
        fetchAll: { [] },
        fetch: { _ in [] },
        add: { _ in },
        deleteByID: { _ in },
        update: { _, _ in }
    )
 }
