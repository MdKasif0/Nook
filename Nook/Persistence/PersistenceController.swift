import Foundation
import SwiftData
import os

/// Manages the local SwiftData model container for Nook.
///
/// Designed with strict local-first reliability:
/// - 100% offline with zero external network connectivity.
/// - Never crashes silently on database errors.
/// - Recovers gracefully without losing existing saved files.
/// - Provides safe save operations with user-friendly retry paths.
@MainActor
final class PersistenceController: Sendable {
    
    static let shared = PersistenceController()
    
    private static let logger = Logger(subsystem: "com.nook.app", category: "Persistence")
    
    let container: ModelContainer
    let isFallbackStore: Bool
    
    static let schema = Schema([
        NookItem.self,
        RoomState.self
    ])
    
    private init() {
        let schema = Self.schema
        let storeURL = Self.defaultStoreURL()
        
        let configuration = ModelConfiguration(
            "NookStore",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
            self.isFallbackStore = false
            Self.logger.info("Nook SwiftData container successfully loaded at: \(storeURL.path)")
        } catch {
            Self.logger.error("Primary ModelContainer initialization failed: \(error.localizedDescription)")
            
            // Backup corrupt or unreadable store before attempting recovery so user data is never lost
            Self.backupExistingStoreIfNeeded(at: storeURL)
            
            // Attempt secondary recovery: re-initialize with fresh store configuration
            do {
                let recoveryConfig = ModelConfiguration(
                    "NookStore_Recovered",
                    schema: schema,
                    allowsSave: true,
                    cloudKitDatabase: .none
                )
                self.container = try ModelContainer(for: schema, configurations: [recoveryConfig])
                self.isFallbackStore = true
                Self.logger.warning("Initialized recovered store configuration.")
            } catch {
                Self.logger.fault("Fatal persistence error, falling back to in-memory container: \(error.localizedDescription)")
                // Final safety fallback: in-memory store so the app never crashes
                let inMemoryConfig = ModelConfiguration(
                    "NookStore_InMemory",
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                guard let memoryContainer = try? ModelContainer(for: schema, configurations: [inMemoryConfig]) else {
                    fatalError("Critical system failure: Unable to allocate in-memory model container: \(error.localizedDescription)")
                }
                self.container = memoryContainer
                self.isFallbackStore = true
            }
        }
        
        // Ensure primary room state is seeded
        Self.ensureInitialRoomState(in: container.mainContext)
    }
    
    /// Returns the standard local Application Support URL for the Nook database.
    static func defaultStoreURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let nookDir = appSupport.appendingPathComponent("com.nook.app", isDirectory: true)
        
        if !fileManager.fileExists(atPath: nookDir.path) {
            try? fileManager.createDirectory(at: nookDir, withIntermediateDirectories: true)
        }
        
        return nookDir.appendingPathComponent("NookStore.store")
    }
    
    /// Safely backups an existing store file before migration or recovery so data can never be destroyed.
    private static func backupExistingStoreIfNeeded(at storeURL: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupURL = storeURL.deletingPathExtension().appendingPathExtension("corrupt-backup-\(timestamp).store")
        
        do {
            try fileManager.copyItem(at: storeURL, to: backupURL)
            logger.info("Preserved database backup at: \(backupURL.path)")
        } catch {
            logger.error("Failed to backup store file: \(error.localizedDescription)")
        }
    }
    
    /// Seeds the single persistent RoomState instance if not yet present.
    private static func ensureInitialRoomState(in context: ModelContext) {
        var descriptor = FetchDescriptor<RoomState>()
        descriptor.fetchLimit = 1
        
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return
        }
        
        let initialRoom = RoomState()
        context.insert(initialRoom)
        try? context.save()
    }
    
    // MARK: - Safe Save Utility
    
    /// Executes a safe database save with user-friendly error reporting.
    ///
    /// If an error occurs, it does not crash or lose in-memory edits.
    /// It invokes `AppState.reportPersistenceError` allowing the user to click "Try Again".
    @discardableResult
    func safeSave(context: ModelContext, appState: AppState? = nil) -> Bool {
        guard context.hasChanges else { return true }
        
        do {
            try context.save()
            appState?.clearPersistenceError()
            return true
        } catch {
            Self.logger.error("SwiftData safeSave failed: \(error.localizedDescription)")
            
            appState?.reportPersistenceError(
                message: "Something went wrong while saving your Nook.",
                retry: { [weak self, weak context, weak appState] in
                    guard let self, let context else { return }
                    self.safeSave(context: context, appState: appState)
                }
            )
            return false
        }
    }
}
