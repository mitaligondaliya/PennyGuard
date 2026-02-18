//
//  RootView.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 02/05/25.
//

import SwiftData
import SwiftUI
import ComposableArchitecture
import os

struct AppRootView: View {
    @Dependency(\.databaseService) var databaseService
    @State private var modelContext: ModelContext?
    @State private var initializationError: Error?

    let store: StoreOf<AppReducer>
    
    var body: some View {
        if let modelContext = modelContext {
            AppTabView(store: store)
                .modelContext(modelContext)
        } else if initializationError != nil {
            errorView
        } else {
            ProgressView()
                .onAppear {
                    initializeDatabase()
                }
        }
    }
    
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Failed to Load")
                .font(.headline)
            
            Text("Unable to initialize the app. Please restart and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private func initializeDatabase() {
        do {
            let context = try databaseService.context()
            self.modelContext = context
        } catch {
            // Log error for debugging
            let logger = Logger(subsystem: "com.pennyguard", category: "AppRootView")
            logger.error("Failed to load ModelContext: \(error, privacy: .public)")
            self.initializationError = error
        }
    }
}
