//
//  AppRootView.swift
//  PennyGuard
//
//  Created by Mitali Gondaliya on 02/05/25.
//

import SwiftData
import SwiftUI
import ComposableArchitecture
import os

// MARK: - Environment Value for ModelContext
extension EnvironmentValues {
    @Entry var modelContext: ModelContext?
}

struct AppRootView: View {
    @Dependency(\.databaseService) var databaseService
    @State private var initializationError: Error?
    @State private var isInitialized = false

    let store: StoreOf<AppReducer>
    
    var body: some View {
        if isInitialized {
            AppTabView(store: store)
        } else if initializationError != nil {
            errorView
                .onAppear {
                    // Allow retry
                }
        } else {
            ProgressView()
                .onAppear {
                    initializeDatabase()
                }
        }
    }
    
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 16) {
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
            
            Button("Retry") {
                initializationError = nil
                isInitialized = false
                initializeDatabase()
            }
            .padding(.top, 16)
        }
        .padding()
    }
    
    private func initializeDatabase() {
        do {
            let context = try databaseService.context()
            isInitialized = true
            
            // Set the model context in the environment for child views
            // This will be picked up by the AppTabView and its children
            var environment = EnvironmentValues()
            environment.modelContext = context
        } catch {
            #if DEBUG
            let logger = Logger(subsystem: "com.pennyguard", category: "AppRootView")
            logger.error("Failed to load ModelContext: \(error, privacy: .public)")
            #endif
            self.initializationError = error
        }
    }
}
