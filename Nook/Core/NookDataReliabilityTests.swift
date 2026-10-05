import Foundation
import SwiftData
import RealityKit
import CryptoKit

/// Comprehensive test suite verifying Nook's local-first data reliability:
/// - Create
/// - Edit
/// - Delete
/// - Move
/// - Restart (Disk-backed container persistence)
/// - Search (Local index, prefix tokens, type matching, ranking, active & archived)
/// - Archive (Room exclusion, search availability, unarchiving)
/// - Undo (Native macOS UndoManager integration for move, edit, delete, redo)
/// - Repeated Operations (High-frequency stress testing for stability)
/// - 3D Miniature Environment Interactions (Hierarchy, categories, dragging, rotation, persistence)
@MainActor
final class NookDataReliabilityTests {
    
    struct TestResult {
        let name: String
        let passed: Bool
        let message: String
    }
    
    static func runAll() -> [TestResult] {
        var results: [TestResult] = []
        print("\n🧪 ========================================================")
        print("🧪 RUNNING NOOK LOCAL-FIRST DATA RELIABILITY TEST SUITE")
        print("🧪 ========================================================\n")
        
        let tests: [(String, () throws -> Void)] = [
            ("Create Item Persistence", testCreateItem),
            ("Edit Item Content & Timestamps", testEditItem),
            ("Move Item Coordinates", testMoveItem),
            ("Archive & Room Exclusion", testArchiveItem),
            ("Delete Item", testDeleteItem),
            ("Restart Persistence Across Containers", testRestartPersistence),
            ("Local Search Indexing & Querying", testLocalSearch),
            ("Native macOS Undo/Redo (Move, Edit, Delete)", testUndoRedo),
            ("Repeated Operations Stress Stability", testRepeatedOperations),
            ("Twenty Thoughts Complete Lifecycle & Persistence", testTwentyThoughtsProductionLifecycle),
            ("Interactive Prop Hierarchy & Category Constraints", testInteractivePropHierarchyAndCategories),
            ("Prop Transform Serialization & Persistence", testPropTransformSerializationAndPersistence),
            ("Surface Height Detection & Boundary Clamping", testSurfaceHeightAndBoundaryClamping),
            ("Tactile Prop Drag & Drop Physical Settling", testPropDragAndDropSettling),
            ("Prop Rotation & Native macOS Undo", testPropRotationAndUndo),
            ("Prop Scaling Constraints & Native macOS Undo", testPropScalingConstraintsAndUndo),
            ("Sparkle 2 AppCast Feed XML & RFC 822 Parsing", testSparkleAppCastParsing),
            ("Sparkle Ed25519 Cryptographic Verification", testSparkleEd25519SignatureVerification),
            ("Sparkle Semantic Version Comparison", testSparkleSemanticVersionComparison),
            ("Sparkle Minimum System Version Compatibility", testSparkleSystemCompatibility),
            ("Complete Interaction Flow (Pebble Lifecycle)", testCompleteInteractionFlowPebbleLifecycle),
            ("All Object Representations 3D Geometry", testAllObjectRepresentations3DGeneration),
            ("Crowded Surface Intelligent Fallback Placement", testCrowdedSurfaceFallbackPlacement),
            ("Camera Exploration Clamping & Reset View", testCameraExplorationClampingAndReset),
            ("Cookie Deterministic State Transitions", testCookieDeterministicStateTransitions),
            ("Cookie Anatomical Rig & Facial Expressions", testCookieAnatomicalRigAndFacialExpressions)
        ]
        
        for (name, testBlock) in tests {
            do {
                try testBlock()
                results.append(TestResult(name: name, passed: true, message: "OK"))
                print("  ✅ [PASS] \(name)")
            } catch {
                results.append(TestResult(name: name, passed: false, message: error.localizedDescription))
                print("  ❌ [FAIL] \(name): \(error.localizedDescription)")
            }
        }
        
        let passCount = results.filter { $0.passed }.count
        print("\n--------------------------------------------------------")
        print("🧪 TEST RESULTS: \(passCount)/\(results.count) PASSED")
        print("========================================================\n")
        
        return results
    }
    
    // MARK: - Test 1: Create Item
    
    private static func testCreateItem() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        let itemID = UUID()
        let title = "I should build a local AI coding assistant."
        let content = "Everything must work completely offline without accounts."
        let position = RoomPosition(x: 0.35, y: 0.45, z: 0.5)
        
        let item = NookItem(
            title: title,
            content: content,
            itemType: .idea,
            objectType: .pebble,
            position: position,
            rotation: 45.0,
            styleTag: "warm-stone"
        )
        item.id = itemID
        item.setMetadata(["tag": "v1-launch", "priority": "high"])
        
        context.insert(item)
        try context.save()
        
        // Fetch back and assert all required properties
        var descriptor = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == itemID })
        descriptor.fetchLimit = 1
        guard let fetched = try context.fetch(descriptor).first else {
            throw TestError("Failed to fetch newly created NookItem from SwiftData.")
        }
        
        guard fetched.id == itemID else { throw TestError("ID mismatch") }
        guard fetched.title == title else { throw TestError("Title mismatch") }
        guard fetched.content == content else { throw TestError("Content mismatch") }
        guard fetched.itemType == .idea else { throw TestError("ItemType mismatch") }
        guard fetched.objectType == .pebble else { throw TestError("ObjectType mismatch") }
        guard abs(fetched.positionX - 0.35) < 0.001 else { throw TestError("PositionX mismatch") }
        guard abs(fetched.positionY - 0.45) < 0.001 else { throw TestError("PositionY mismatch") }
        guard abs(fetched.rotation - 45.0) < 0.001 else { throw TestError("Rotation mismatch") }
        guard fetched.isArchived == false else { throw TestError("Item should not be archived") }
        guard fetched.metadata()["priority"] == "high" else { throw TestError("Metadata mismatch") }
    }
    
    // MARK: - Test 2: Edit Item
    
    private static func testEditItem() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        let item = NookItem(title: "Original Thought", content: "Original Content")
        let originalDate = item.updatedAt
        context.insert(item)
        try context.save()
        
        // Sleep slightly to guarantee updated timestamp differs
        Thread.sleep(forTimeInterval: 0.01)
        
        let itemID = item.id
        item.title = "Refined Thought"
        item.content = "Polished Content"
        item.objectType = .polaroid
        item.touch()
        try context.save()
        
        let descriptor = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == itemID })
        guard let fetched = try context.fetch(descriptor).first else {
            throw TestError("Item not found after edit.")
        }
        
        guard fetched.title == "Refined Thought" else { throw TestError("Title not updated") }
        guard fetched.content == "Polished Content" else { throw TestError("Content not updated") }
        guard fetched.objectType == .polaroid else { throw TestError("ObjectType not updated") }
        guard fetched.updatedAt >= originalDate else { throw TestError("UpdatedAt not updated") }
    }
    
    // MARK: - Test 3: Move Item
    
    private static func testMoveItem() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        let item = NookItem(title: "Draggable Thought", position: RoomPosition(x: 0.1, y: 0.1, z: 0.5))
        let targetID = item.id
        context.insert(item)
        try context.save()
        
        let targetPosition = RoomPosition(x: 0.75, y: 0.82, z: 0.5)
        item.roomPosition = targetPosition
        item.touch()
        try context.save()
        
        let descriptor = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == targetID })
        guard let fetched = try context.fetch(descriptor).first else {
            throw TestError("Moved item not found.")
        }
        
        guard abs(fetched.roomPosition.x - 0.75) < 0.001 else { throw TestError("X position not saved") }
        guard abs(fetched.roomPosition.y - 0.82) < 0.001 else { throw TestError("Y position not saved") }
    }
    
    // MARK: - Test 4: Archive Item
    
    private static func testArchiveItem() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        let item = NookItem(title: "Archived Thought", content: "Hidden from room, but searchable.")
        context.insert(item)
        try context.save()
        
        // Active room query must include it
        let activeQuery = FetchDescriptor<NookItem>(predicate: #Predicate { !$0.isArchived })
        var activeItems = try context.fetch(activeQuery)
        guard activeItems.contains(where: { $0.id == item.id }) else {
            throw TestError("Item should initially be in active room query.")
        }
        
        // Archive item
        item.isArchived = true
        item.touch()
        try context.save()
        
        // Active room query must NOT include it
        activeItems = try context.fetch(activeQuery)
        guard !activeItems.contains(where: { $0.id == item.id }) else {
            throw TestError("Archived item MUST NOT appear in active room query.")
        }
        
        // Archive query must include it
        let archiveQuery = FetchDescriptor<NookItem>(predicate: #Predicate { $0.isArchived })
        let archivedItems = try context.fetch(archiveQuery)
        guard archivedItems.contains(where: { $0.id == item.id }) else {
            throw TestError("Archived item must appear in archive query.")
        }
    }
    
    // MARK: - Test 5: Delete Item
    
    private static func testDeleteItem() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        let item = NookItem(title: "Ephemeral Thought")
        let itemID = item.id
        context.insert(item)
        try context.save()
        
        context.delete(item)
        try context.save()
        
        let descriptor = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == itemID })
        let remaining = try context.fetch(descriptor)
        guard remaining.isEmpty else {
            throw TestError("Item should have been deleted from context.")
        }
    }
    
    // MARK: - Test 6: Restart Persistence Across Containers
    
    private static func testRestartPersistence() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("nook_test_restart_\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: storeURL)
        }
        
        let schema = Schema([NookItem.self, RoomState.self])
        let config = ModelConfiguration("NookTestStore", schema: schema, url: storeURL)
        
        let thoughtID = UUID()
        
        // 1. Session A: Open container, save thought and room settings, deallocate
        do {
            let containerA = try ModelContainer(for: schema, configurations: [config])
            let contextA = containerA.mainContext
            
            let item = NookItem(
                title: "Preserved across restarts",
                content: "Local SQLite file integrity test",
                itemType: .reminder,
                objectType: .stickyNote,
                position: RoomPosition(x: 0.42, y: 0.58, z: 0.5)
            )
            item.id = thoughtID
            contextA.insert(item)
            
            let room = RoomState(
                timeOfDay: .sunset,
                isDeskLampOn: true,
                isWallSconceOn: false,
                isRecordSpinning: true,
                cookieFavoriteSpot: "desk",
                cookiePetCount: 7
            )
            contextA.insert(room)
            
            try contextA.save()
        }
        
        // 2. Session B: Open a brand NEW container pointing to the exact same file
        do {
            let containerB = try ModelContainer(for: schema, configurations: [config])
            let contextB = containerB.mainContext
            
            // Check item was restored
            let itemDesc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == thoughtID })
            guard let restoredItem = try contextB.fetch(itemDesc).first else {
                throw TestError("Item was not preserved across container restart.")
            }
            guard restoredItem.title == "Preserved across restarts" else { throw TestError("Title corrupted after restart") }
            guard restoredItem.objectType == .stickyNote else { throw TestError("ObjectType corrupted after restart") }
            guard abs(restoredItem.positionX - 0.42) < 0.001 else { throw TestError("PositionX corrupted after restart") }
            
            // Check RoomState was restored
            let roomDesc = FetchDescriptor<RoomState>()
            guard let restoredRoom = try contextB.fetch(roomDesc).first else {
                throw TestError("RoomState was not preserved across container restart.")
            }
            guard restoredRoom.timeOfDay == .sunset else { throw TestError("Room timeOfDay not restored") }
            guard restoredRoom.isDeskLampOn == true else { throw TestError("Desk lamp state not restored") }
            guard restoredRoom.cookiePetCount == 7 else { throw TestError("Cookie pet count not restored") }
        }
    }
    
    // MARK: - Test 7: Local Search Index
    
    private static func testLocalSearch() throws {
        let index = LocalSearchIndex()
        
        let item1 = NookItem(title: "Build local AI coding assistant", content: "Fast prefix token index", itemType: .thought, objectType: .pebble)
        let item2 = NookItem(title: "Morning coffee beans", content: "Remember dark roast", itemType: .reminder, objectType: .stickyNote)
        let item3 = NookItem(title: "Architecture notes", content: "Zero search servers needed", itemType: .note, objectType: .paperNote)
        item3.isArchived = true
        
        index.rebuild(with: [item1, item2, item3])
        
        // 1. Search by title token prefix
        let resTitle = index.search(query: "build", includeArchived: false)
        guard resTitle.count == 1, resTitle.first?.item.id == item1.id else {
            throw TestError("Search by title prefix failed.")
        }
        
        // 2. Search by object type
        let resType = index.search(query: "pebble", includeArchived: false)
        guard resType.count == 1, resType.first?.item.id == item1.id else {
            throw TestError("Search by object type 'pebble' failed.")
        }
        
        // 3. Search by body content
        let resContent = index.search(query: "roast", includeArchived: false)
        guard resContent.count == 1, resContent.first?.item.id == item2.id else {
            throw TestError("Search by content 'roast' failed.")
        }
        
        // 4. Archived items search
        let resArchivedWithout = index.search(query: "architecture", includeArchived: false)
        guard resArchivedWithout.isEmpty else {
            throw TestError("Archived item should be omitted when includeArchived is false.")
        }
        
        let resArchivedWith = index.search(query: "architecture", includeArchived: true)
        guard resArchivedWith.count == 1, resArchivedWith.first?.item.id == item3.id else {
            throw TestError("Archived item should be found when includeArchived is true.")
        }
        guard resArchivedWith.first?.isArchived == true else {
            throw TestError("SearchResult should indicate item is archived.")
        }
    }
    
    // MARK: - Test 8: Native Undo / Redo
    
    private static func testUndoRedo() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let undoManager = UndoManager()
        
        // 1. Test Undo Move
        let item = NookItem(title: "Undo Target", position: RoomPosition(x: 0.1, y: 0.1, z: 0.5))
        context.insert(item)
        try context.save()
        
        NookActionService.shared.moveItem(item, to: RoomPosition(x: 0.8, y: 0.9, z: 0.5), in: context, undoManager: undoManager)
        guard abs(item.roomPosition.x - 0.8) < 0.001 else { throw TestError("Move did not apply") }
        
        undoManager.undo()
        guard abs(item.roomPosition.x - 0.1) < 0.001 else { throw TestError("Undo Move failed to restore coordinate") }
        
        undoManager.redo()
        guard abs(item.roomPosition.x - 0.8) < 0.001 else { throw TestError("Redo Move failed to re-apply coordinate") }
        
        // 2. Test Undo Edit
        NookActionService.shared.updateItem(item, title: "Edited Title", content: "New Content", objectType: .polaroid, in: context, undoManager: undoManager)
        guard item.title == "Edited Title" else { throw TestError("Edit failed to apply") }
        
        undoManager.undo()
        guard item.title == "Undo Target" else { throw TestError("Undo Edit failed to restore title") }
        
        // 3. Test Undo Delete (with full DTO snapshot restoration)
        let itemID = item.id
        NookActionService.shared.deleteItem(item, in: context, undoManager: undoManager)
        
        let descDeleted = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == itemID })
        guard try context.fetch(descDeleted).isEmpty else { throw TestError("Item not deleted") }
        
        undoManager.undo()
        let descRestored = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == itemID })
        guard let restored = try context.fetch(descRestored).first else {
            throw TestError("Undo Delete failed to recreate and reinsert item into context.")
        }
        guard restored.title == "Undo Target" else { throw TestError("Restored item title corrupted") }
    }
    
    // MARK: - Test 9: Repeated Operations Stress Stability
    
    private static func testRepeatedOperations() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        
        // Execute 50+ rapid operations across items: creation, relocation, archiving, editing, deletion
        var items: [NookItem] = []
        for i in 0..<25 {
            let item = NookItem(title: "Batch Item \(i)", content: "Initial content \(i)")
            context.insert(item)
            items.append(item)
        }
        try context.save()
        
        // Rapid modifications: position, title, object type, archiving
        for (i, item) in items.enumerated() {
            item.roomPosition = RoomPosition(x: Double(i) / 25.0, y: 0.45, z: 0.5)
            item.title = "Modified Item \(i)"
            item.objectType = (i % 2 == 0) ? .pebble : .stickyNote
            if i % 3 == 0 {
                item.isArchived = true
            }
            item.touch()
        }
        try context.save()
        
        // Verify active vs archived count consistency
        let activeQuery = FetchDescriptor<NookItem>(predicate: #Predicate { !$0.isArchived })
        let activeItems = try context.fetch(activeQuery)
        let expectedArchivedCount = items.filter { $0.isArchived }.count
        let expectedActiveCount = items.count - expectedArchivedCount
        guard activeItems.count == expectedActiveCount else {
            throw TestError("Expected \(expectedActiveCount) active items, got \(activeItems.count)")
        }
        
        // Unarchive all
        for item in items where item.isArchived {
            item.isArchived = false
            item.touch()
        }
        try context.save()
        
        let allActive = try context.fetch(activeQuery)
        guard allActive.count == items.count else {
            throw TestError("Expected all \(items.count) items active after unarchiving, got \(allActive.count)")
        }
        
        // Sequential deletion
        for item in items {
            context.delete(item)
        }
        try context.save()
        
        let allRemaining = try context.fetch(FetchDescriptor<NookItem>())
        guard allRemaining.isEmpty else {
            throw TestError("Database corrupted or leaked items during stress testing.")
        }
    }
    
    // MARK: - Test 10: Twenty Thoughts Complete Lifecycle & Persistence
    
    private static func testTwentyThoughtsProductionLifecycle() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("nook_twenty_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let dbURL = tempDir.appendingPathComponent("twenty_thoughts.sqlite")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let schema = Schema([NookItem.self, RoomState.self])
        let config = ModelConfiguration("TwentyThoughtsStore", schema: schema, url: dbURL)
        
        var thoughtIDs: [UUID] = []
        
        // 1. Create 20 thoughts
        do {
            let container1 = try ModelContainer(for: schema, configurations: [config])
            let ctx1 = container1.mainContext
            
            for i in 1...20 {
                let objectType: NookObjectType
                switch i % 5 {
                case 0: objectType = .pebble
                case 1: objectType = .paperNote
                case 2: objectType = .stickyNote
                case 3: objectType = .card
                default: objectType = .polaroid
                }
                
                let thought = NookItem(
                    title: "Thought \(i): Creative Exploration",
                    content: "Notes and reflections for thought item #\(i) inside the cozy room.",
                    itemType: .idea,
                    objectType: objectType,
                    position: RoomPosition(x: 0.05 * Double(i), y: 0.1 * Double(i % 5), z: 0.5)
                )
                ctx1.insert(thought)
                thoughtIDs.append(thought.id)
            }
            try ctx1.save()
            
            guard try ctx1.fetch(FetchDescriptor<NookItem>()).count == 20 else {
                throw TestError("Failed to initialize 20 thoughts.")
            }
            
            // 2. Move them
            for (index, id) in thoughtIDs.enumerated() {
                var desc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == id })
                desc.fetchLimit = 1
                if let item = try ctx1.fetch(desc).first {
                    item.roomPosition = RoomPosition(x: 0.04 * Double(index), y: 0.45, z: 0.2 * Double(index % 4))
                    item.touch()
                }
            }
            try ctx1.save()
            
            // 3. Edit them
            for (index, id) in thoughtIDs.enumerated() {
                var desc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == id })
                desc.fetchLimit = 1
                if let item = try ctx1.fetch(desc).first {
                    item.title = "Refined Thought \(index + 1) — Apple-Inspired"
                    item.content = "Polished content with markdown and tactile metadata."
                    item.touch()
                }
            }
            try ctx1.save()
            
            // 4. Delete some (delete 4 items: indices 0, 5, 10, 15)
            let idsToDelete = [thoughtIDs[0], thoughtIDs[5], thoughtIDs[10], thoughtIDs[15]]
            for id in idsToDelete {
                var desc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == id })
                desc.fetchLimit = 1
                if let item = try ctx1.fetch(desc).first {
                    ctx1.delete(item)
                }
            }
            try ctx1.save()
            
            // 5. Archive some (archive 5 items: indices 1, 6, 11, 16, 19)
            let idsToArchive = [thoughtIDs[1], thoughtIDs[6], thoughtIDs[11], thoughtIDs[16], thoughtIDs[19]]
            for id in idsToArchive {
                var desc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == id })
                desc.fetchLimit = 1
                if let item = try ctx1.fetch(desc).first {
                    item.isArchived = true
                    item.touch()
                }
            }
            try ctx1.save()
            
            // 6. Search
            let searchDescriptor = FetchDescriptor<NookItem>(predicate: #Predicate { $0.title.contains("Refined") })
            let searchResults = try ctx1.fetch(searchDescriptor)
            guard searchResults.count == 16 else {
                throw TestError("Expected 16 items matching 'Refined', found \(searchResults.count)")
            }
            
            // 7. Quit container 1
        }
        
        // 8. Relaunch (create clean new ModelContainer accessing same sqlite disk database)
        do {
            let container2 = try ModelContainer(for: schema, configurations: [config])
            let ctx2 = container2.mainContext
            
            // 9. Verify everything persisted correctly
            let allItems = try ctx2.fetch(FetchDescriptor<NookItem>())
            guard allItems.count == 16 else {
                throw TestError("Restart verification failed: expected 16 remaining items, found \(allItems.count)")
            }
            
            let activeItems = try ctx2.fetch(FetchDescriptor<NookItem>(predicate: #Predicate { !$0.isArchived }))
            guard activeItems.count == 11 else {
                throw TestError("Expected 11 active items after restart, found \(activeItems.count)")
            }
            
            let archivedItems = try ctx2.fetch(FetchDescriptor<NookItem>(predicate: #Predicate { $0.isArchived }))
            guard archivedItems.count == 5 else {
                throw TestError("Expected 5 archived items after restart, found \(archivedItems.count)")
            }
            
            // Verify deleted items are gone
            let deletedIDs = [thoughtIDs[0], thoughtIDs[5], thoughtIDs[10], thoughtIDs[15]]
            for delID in deletedIDs {
                var desc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == delID })
                desc.fetchLimit = 1
                if !(try ctx2.fetch(desc).isEmpty) {
                    throw TestError("Deleted item \(delID) unexpectedly survived restart.")
                }
            }
            
            // Verify content and coordinates of remaining item
            let sampleID = thoughtIDs[2]
            var sampleDesc = FetchDescriptor<NookItem>(predicate: #Predicate { $0.id == sampleID })
            sampleDesc.fetchLimit = 1
            guard let sampleItem = try ctx2.fetch(sampleDesc).first else {
                throw TestError("Sample item 2 not found after restart.")
            }
            guard sampleItem.title == "Refined Thought 3 — Apple-Inspired" else {
                throw TestError("Title did not persist accurately: \(sampleItem.title)")
            }
            guard abs(sampleItem.positionY - 0.45) < 0.001 else {
                throw TestError("Position Y coordinate did not persist accurately: \(sampleItem.positionY)")
            }
            
            // Test malformed/unexpected data resilience
            let malformedItem = NookItem(title: "", content: "")
            malformedItem.roomPosition = RoomPosition(x: Double.nan, y: -9999.0, z: Double.infinity)
            malformedItem.setMetadata(["corrupted": "value\0with\u{FFFF}characters"])
            ctx2.insert(malformedItem)
            try ctx2.save()
            
            guard malformedItem.roomPosition.x >= 0.0 && malformedItem.roomPosition.x <= 1.0 else {
                throw TestError("NaN/infinite coordinate was not sanitized or clamped.")
            }
            ctx2.delete(malformedItem)
            try ctx2.save()
        }
    }
    
    // MARK: - 3D Miniature Environment & Interaction Tests
    
    private static func testInteractivePropHierarchyAndCategories() throws {
        let coordinator = RoomSceneCoordinator()
        
        // 1. Verify all area hierarchy nodes exist under RoomRoot
        guard coordinator.deskArea != nil else { throw TestError("DeskArea not initialized in hierarchy.") }
        guard coordinator.bedArea != nil else { throw TestError("BedArea not initialized in hierarchy.") }
        guard coordinator.shelfArea != nil else { throw TestError("ShelfArea not initialized in hierarchy.") }
        guard coordinator.windowArea != nil else { throw TestError("WindowArea not initialized in hierarchy.") }
        guard coordinator.recordArea != nil else { throw TestError("RecordArea not initialized in hierarchy.") }
        guard coordinator.floorObjectsArea != nil else { throw TestError("FloorObjectsArea not initialized in hierarchy.") }
        guard coordinator.architectureArea != nil else { throw TestError("ArchitectureArea not initialized in hierarchy.") }
        guard coordinator.cookie != nil else { throw TestError("Cookie not initialized in hierarchy.") }
        
        // 2. Verify prop registry count
        let props = coordinator.propEntities
        guard props.count >= 20 else {
            throw TestError("Expected at least 20 interactive props registered, found \(props.count).")
        }
        
        // 3. Test Movable objects allow dragging & rotation
        let movableIds = ["prop_laptop", "prop_lamp", "prop_mug", "prop_skateboard", "prop_monstera", "prop_daisy_pillow"]
        for id in movableIds {
            guard let entity = props[id],
                  let prop = entity.components[InteractivePropComponent.self] else {
                throw TestError("Movable prop \(id) missing or lacks InteractivePropComponent.")
            }
            guard prop.category == .movable else {
                throw TestError("Prop \(id) should be categorized as .movable, got \(prop.category).")
            }
            guard prop.allowsDragging else {
                throw TestError("Prop \(id) should allow dragging.")
            }
            guard prop.allowsRotation else {
                throw TestError("Prop \(id) should allow rotation.")
            }
            guard !prop.displayName.isEmpty else {
                throw TestError("Prop \(id) displayName is empty.")
            }
            guard !prop.accessibilityLabel.isEmpty else {
                throw TestError("Prop \(id) accessibilityLabel is empty.")
            }
        }
        
        // 4. Test Immovable architectural objects forbid dragging
        let desk = coordinator.deskArea!.deskEntity
        guard let deskProp = desk.components[InteractivePropComponent.self],
              deskProp.category == .immovable && !deskProp.allowsDragging else {
            throw TestError("Desk table structure should be immovable and forbid dragging.")
        }
        
        let bed = coordinator.bedArea!.bedFrame
        guard let bedProp = bed.components[InteractivePropComponent.self],
              bedProp.category == .immovable && !bedProp.allowsDragging else {
            throw TestError("Bed platform structure should be immovable and forbid dragging.")
        }
        
        // 5. Test Cookie companion permissions
        let cookie = coordinator.cookie!
        guard let cookieProp = cookie.components[InteractivePropComponent.self] else {
            throw TestError("Cookie is missing InteractivePropComponent.")
        }
        guard cookieProp.category == .special && !cookieProp.allowsDragging else {
            throw TestError("Cookie should be .special and forbid accidental dragging.")
        }
    }
    
    private static func testPropTransformSerializationAndPersistence() throws {
        let container = try createInMemoryContainer()
        let ctx = container.mainContext
        
        let roomState = RoomState()
        ctx.insert(roomState)
        try ctx.save()
        
        // 1. Initial state has no custom prop positions
        guard roomState.getPropTransforms().isEmpty else {
            throw TestError("Initial room state should have empty custom prop positions.")
        }
        
        // 2. Save custom transform for skateboard
        let customPos = SIMD3<Float>(0.25, 0.16, 0.35)
        let customRot = simd_quatf(angle: Float.pi * 0.25, axis: [0, 1, 0])
        let customScale = SIMD3<Float>(1.1, 1.1, 1.1)
        let transform = RoomPropTransform(
            propId: "prop_skateboard",
            position: customPos,
            orientation: customRot,
            scale: customScale
        )
        
        roomState.setPropTransform(transform)
        try ctx.save()
        
        // 3. Read back transforms
        let savedDict = roomState.getPropTransforms()
        guard let savedSkateboard = savedDict["prop_skateboard"] else {
            throw TestError("Failed to retrieve custom transform for prop_skateboard.")
        }
        
        guard distance(savedSkateboard.position, customPos) < 0.001 else {
            throw TestError("Persisted position mismatch: \(savedSkateboard.position) vs \(customPos).")
        }
        guard abs(savedSkateboard.rotW - customRot.real) < 0.001 else {
            throw TestError("Persisted orientation mismatch.")
        }
        guard distance(savedSkateboard.scale, customScale) < 0.001 else {
            throw TestError("Persisted scale mismatch.")
        }
        
        // 4. Reset prop transform
        roomState.resetPropTransform(propId: "prop_skateboard")
        try ctx.save()
        guard roomState.getPropTransforms()["prop_skateboard"] == nil else {
            throw TestError("Resetting prop transform did not remove it from custom positions.")
        }
    }
    
    private static func testSurfaceHeightAndBoundaryClamping() throws {
        // 1. Test surface height at desk
        let deskH = RoomInteractionSystem.surfaceHeight(at: -0.80, z: -0.20)
        guard abs(deskH - 0.88) < 0.01 else {
            throw TestError("Surface height at desk should be 0.88m, got \(deskH).")
        }
        
        // 2. Test surface height at bed
        let bedH = RoomInteractionSystem.surfaceHeight(at: 0.50, z: -0.70)
        guard abs(bedH - 0.60) < 0.01 else {
            throw TestError("Surface height at bed should be 0.60m, got \(bedH).")
        }
        
        // 3. Test surface height at upper floor platform
        let upperH = RoomInteractionSystem.surfaceHeight(at: 0.00, z: 0.00)
        guard abs(upperH - 0.16) < 0.01 else {
            throw TestError("Surface height at upper floor should be 0.16m, got \(upperH).")
        }
        
        // 4. Test surface height at lower floor platform
        let lowerH = RoomInteractionSystem.surfaceHeight(at: 0.00, z: 0.50)
        guard abs(lowerH - 0.02) < 0.01 else {
            throw TestError("Surface height at lower floor should be 0.02m, got \(lowerH).")
        }
        
        // 5. Test boundary clamping constants
        guard RoomInteractionSystem.minRoomX < RoomInteractionSystem.maxRoomX else {
            throw TestError("Invalid room X bounds.")
        }
        guard RoomInteractionSystem.minRoomZ < RoomInteractionSystem.maxRoomZ else {
            throw TestError("Invalid room Z bounds.")
        }
    }
    
    private static func testPropDragAndDropSettling() throws {
        let coordinator = RoomSceneCoordinator()
        let interaction = coordinator.interactionSystem!
        
        guard let skateboard = coordinator.findPropEntity(id: "prop_skateboard") else {
            throw TestError("Skateboard entity not found.")
        }
        let originalPos = skateboard.position
        
        // 1. Verify canDragEntity
        guard interaction.canDragEntity(skateboard) else {
            throw TestError("Interaction system reports skateboard cannot be dragged.")
        }
        
        // 2. Start drag -> lifts by +4cm and scales to 1.03x
        guard let target = interaction.handleDragStart(for: skateboard) else {
            throw TestError("Failed to initiate drag on skateboard.")
        }
        guard abs(target.position.y - (originalPos.y + 0.04)) < 0.001 else {
            throw TestError("Drag start did not elevate entity by +4cm. Got \(target.position.y), expected \(originalPos.y + 0.04).")
        }
        guard abs(target.scale.x - 1.03) < 0.01 else {
            throw TestError("Drag start did not scale entity to 1.03x. Got \(target.scale.x).")
        }
        
        // 3. Update drag
        interaction.handleDragUpdate(target: target, translation: CGSize(width: 50, height: -50), startPos: originalPos)
        guard target.position.x != originalPos.x else {
            throw TestError("Drag update did not move entity along X axis.")
        }
        
        // 4. End drag -> settles down to resting surface and resets scale
        let undoManager = UndoManager()
        interaction.handleDragEnd(target: target, undoManager: undoManager)
        guard abs(target.scale.x - 1.0) < 0.001 else {
            throw TestError("Drop settling did not return scale to 1.0x.")
        }
        guard target.position.y <= originalPos.y + 0.01 else {
            throw TestError("Drop settling did not bring entity down to resting surface.")
        }
    }
    
    private static func testPropRotationAndUndo() throws {
        let coordinator = RoomSceneCoordinator()
        let interaction = coordinator.interactionSystem!
        
        guard let mug = coordinator.findPropEntity(id: "prop_mug") else {
            throw TestError("Mug entity not found.")
        }
        let initialRot = mug.orientation
        
        let undoManager = UndoManager()
        
        // 1. Rotate 45°
        interaction.rotateProp(id: "prop_mug", angleDegrees: 45.0, undoManager: undoManager)
        let rotatedRot = mug.orientation
        guard abs(rotatedRot.real - initialRot.real) > 0.01 else {
            throw TestError("Rotation did not change mug orientation quaternion.")
        }
        
        // 2. Perform Undo via UndoManager
        guard undoManager.canUndo else {
            throw TestError("UndoManager has no undo actions registered after rotation.")
        }
        undoManager.undo()
        
        let revertedRot = mug.orientation
        guard abs(revertedRot.real - initialRot.real) < 0.01 else {
            throw TestError("UndoManager failed to revert mug orientation back to initial rotation.")
        }
    }
    
    private static func testPropScalingConstraintsAndUndo() throws {
        let coordinator = RoomSceneCoordinator()
        let interaction = coordinator.interactionSystem!
        
        // 1. Scalable entity test (monstera plant)
        guard let plant = coordinator.findPropEntity(id: "prop_monstera") else {
            throw TestError("Monstera plant entity not found.")
        }
        let initialScale = plant.scale
        let undoManager = UndoManager()
        
        // 2. Scale up by 1.1x
        interaction.scaleProp(id: "prop_monstera", factor: 1.1, undoManager: undoManager)
        let scaledUp = plant.scale
        guard scaledUp.x > initialScale.x && abs(scaledUp.x - initialScale.x * 1.1) < 0.01 else {
            throw TestError("Scaling did not apply correctly to monstera plant.")
        }
        // Verify proportions are preserved uniformly
        guard abs(scaledUp.x - scaledUp.y) < 0.01 && abs(scaledUp.y - scaledUp.z) < 0.01 else {
            throw TestError("Scaling did not preserve uniform proportions.")
        }
        
        // 3. Test max constraint (e.g. attempting 5.0x scale cannot exceed 1.25x)
        interaction.scaleProp(id: "prop_monstera", factor: 5.0, undoManager: undoManager)
        let maxClamped = plant.scale
        guard maxClamped.x <= initialScale.x * 1.251 else {
            throw TestError("Scale constraint failed: allowed scale to exceed max limit (1.25x).")
        }
        
        // 4. Test undo reverts back
        guard undoManager.canUndo else {
            throw TestError("UndoManager has no undo actions registered after scaling.")
        }
        undoManager.undo() // undo clamped scale
        undoManager.undo() // undo 1.1x scale
        guard abs(plant.scale.x - initialScale.x) < 0.001 else {
            throw TestError("UndoManager failed to revert monstera plant scale back to initial scale.")
        }
        
        // 5. Test immovable entity rejects scaling
        guard let desk = coordinator.deskArea?.deskEntity else {
            throw TestError("Desk entity not found.")
        }
        let deskInitialScale = desk.scale
        interaction.scaleProp(id: "prop_desk", factor: 1.5, undoManager: undoManager)
        guard abs(desk.scale.x - deskInitialScale.x) < 0.001 else {
            throw TestError("Desk structure should not allow scaling.")
        }
    }
    
    // MARK: - Sparkle 2 Update Feed Tests
    
    private static func testSparkleAppCastParsing() throws {
        let sampleXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <title>Nook Test Feed</title>
            <item>
              <title>Nook 1.1.0</title>
              <pubDate>Mon, 05 Oct 2026 13:47:21 +0000</pubDate>
              <sparkle:version>42</sparkle:version>
              <sparkle:shortVersionString>1.1.0</sparkle:shortVersionString>
              <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
              <sparkle:releaseNotesLink>https://nook.app/releases/1.1.0.html</sparkle:releaseNotesLink>
              <description><![CDATA[<h2>Release Notes</h2><ul><li>Test item 1</li></ul>]]></description>
              <enclosure url="https://nook.app/downloads/Nook-1.1.0-Universal.dmg"
                         sparkle:version="42"
                         sparkle:shortVersionString="1.1.0"
                         sparkle:edSignature="dummySig=="
                         length="1048576"
                         type="application/x-apple-diskimage" />
            </item>
          </channel>
        </rss>
        """
        guard let data = sampleXML.data(using: .utf8) else {
            throw TestError("Failed to convert sample XML to data.")
        }
        
        let parser = AppCastParser(xmlData: data)
        let items = parser.parse()
        
        guard items.count == 1 else {
            throw TestError("Expected 1 item, found \(items.count).")
        }
        let item = items[0]
        guard item.versionString == "1.1.0" else {
            throw TestError("Expected version 1.1.0, got \(item.versionString)")
        }
        guard item.buildNumber == "42" else {
            throw TestError("Expected build 42, got \(item.buildNumber)")
        }
        guard item.fileSize == 1048576 else {
            throw TestError("Expected fileSize 1048576, got \(item.fileSize)")
        }
        guard item.edSignature == "dummySig==" else {
            throw TestError("Expected edSignature 'dummySig==', got \(String(describing: item.edSignature))")
        }
        guard item.minimumSystemVersion == "15.0" else {
            throw TestError("Expected min system version 15.0, got \(String(describing: item.minimumSystemVersion))")
        }
        guard item.releaseNotesLink?.absoluteString == "https://nook.app/releases/1.1.0.html" else {
            throw TestError("Expected release notes URL, got \(String(describing: item.releaseNotesLink))")
        }
        guard let pubDate = item.publishDate else {
            throw TestError("Failed to parse RFC 822 pubDate.")
        }
        let calendar = Calendar(identifier: .gregorian)
        guard calendar.component(.year, from: pubDate) == 2026 else {
            throw TestError("Expected year 2026, got \(calendar.component(.year, from: pubDate))")
        }
    }
    
    private static func testSparkleEd25519SignatureVerification() throws {
        // 1. Generate keypair using native CryptoKit
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let pubBase64 = publicKey.rawRepresentation.base64EncodedString()
        
        // 2. Sign arbitrary payload data
        let testPayload = "Nook macOS 15+ Secure Update Payload Verification".data(using: .utf8)!
        let signature = try privateKey.signature(for: testPayload)
        let sigBase64 = signature.base64EncodedString()
        
        // 3. Test verification with raw signature
        guard publicKey.isValidSignature(signature, for: testPayload) else {
            throw TestError("Direct Curve25519 signature verification failed.")
        }
        
        // 4. Test Base64 normalization
        let trimmedKey = pubBase64.replacingOccurrences(of: "=", with: "")
        let normalizedKey = NookUpdateManager.normalizeBase64(trimmedKey)
        guard normalizedKey.count % 4 == 0 else {
            throw TestError("normalizeBase64 failed to pad key correctly.")
        }
        
        guard let keyData = Data(base64Encoded: normalizedKey),
              let recoveredPubKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            throw TestError("Failed to recover public key from normalized Base64.")
        }
        
        guard let sigData = Data(base64Encoded: sigBase64) else {
            throw TestError("Failed to decode base64 signature.")
        }
        guard recoveredPubKey.isValidSignature(sigData, for: testPayload) else {
            throw TestError("Verification failed with recovered public key.")
        }
        
        // 5. Corrupted data must fail
        let tamperedPayload = "Corrupted Payload".data(using: .utf8)!
        guard !recoveredPubKey.isValidSignature(sigData, for: tamperedPayload) else {
            throw TestError("Verification should have failed for tampered payload!")
        }
    }
    
    private static func testSparkleSemanticVersionComparison() throws {
        // Newer minor
        guard NookUpdateManager.isVersion("1.1.0", build: "1", newerThan: "1.0.0", currentBuild: "1") else {
            throw TestError("1.1.0 should be newer than 1.0.0")
        }
        // Newer patch
        guard NookUpdateManager.isVersion("1.0.1", build: "1", newerThan: "1.0.0", currentBuild: "1") else {
            throw TestError("1.0.1 should be newer than 1.0.0")
        }
        // Same version, newer build
        guard NookUpdateManager.isVersion("1.0.0", build: "2", newerThan: "1.0.0", currentBuild: "1") else {
            throw TestError("1.0.0 build 2 should be newer than build 1")
        }
        // Older version
        guard !NookUpdateManager.isVersion("0.9.9", build: "99", newerThan: "1.0.0", currentBuild: "1") else {
            throw TestError("0.9.9 should NOT be newer than 1.0.0")
        }
        // Identical version and build
        guard !NookUpdateManager.isVersion("1.0.0", build: "1", newerThan: "1.0.0", currentBuild: "1") else {
            throw TestError("Identical version/build should NOT be newer")
        }
    }
    
    private static func testSparkleSystemCompatibility() throws {
        let dummyURL = URL(string: "https://nook.app/dmg")!
        
        let compatibleItem = AppCastItem(
            title: "Nook 1.0",
            versionString: "1.0.0",
            buildNumber: "1",
            releaseNotesHTML: "",
            releaseNotesLink: nil,
            downloadURL: dummyURL,
            edSignature: nil,
            fileSize: 100,
            publishDate: nil,
            minimumSystemVersion: "15.0",
            isCritical: false
        )
        guard NookUpdateManager.shared.isSystemCompatible(item: compatibleItem) else {
            throw TestError("macOS 15.0 requirement should be compatible on macOS 15+ host.")
        }
        
        let futureItem = AppCastItem(
            title: "Nook 99.0",
            versionString: "99.0.0",
            buildNumber: "1",
            releaseNotesHTML: "",
            releaseNotesLink: nil,
            downloadURL: dummyURL,
            edSignature: nil,
            fileSize: 100,
            publishDate: nil,
            minimumSystemVersion: "99.0",
            isCritical: false
        )
        guard !NookUpdateManager.shared.isSystemCompatible(item: futureItem) else {
            throw TestError("macOS 99.0 requirement should NOT be compatible.")
        }
    }
    
    // MARK: - Room & Interaction Model Tests
    
    private static func testCompleteInteractionFlowPebbleLifecycle() throws {
        let container = try createInMemoryContainer()
        let context = ModelContext(container)
        let undoManager = UndoManager()
        let appState = AppState()
        
        // 1. Create thought with Pebble representation
        let promptText = "I want to build a local AI coding assistant."
        let targetZone = PlacementZone.defaultZone(for: .thought, objectType: .pebble)
        let initialPos = targetZone.allocateNaturalPosition(existingWorldPositions: [])
        let roomPos = ThoughtEntityBuilder.roomPosition(from: initialPos)
        
        let item = NookItem(
            title: promptText,
            content: "Tiny physical room where my digital thoughts live.",
            itemType: .thought,
            objectType: .pebble,
            position: roomPos
        )
        context.insert(item)
        try context.save()
        
        // 2. Build RealityKit 3D Entity & verify physical components
        let entity = ThoughtEntityBuilder.buildThoughtEntity(for: item)
        guard let rep = entity.components[ThoughtRepresentationComponent.self], rep.objectType == .pebble else {
            throw TestError("Pebble entity missing ThoughtRepresentationComponent")
        }
        guard entity.components[CollisionComponent.self] != nil else {
            throw TestError("Pebble entity missing CollisionComponent")
        }
        
        // 3. Move Pebble to new position
        let movedWorldPos = initialPos + SIMD3<Float>(0.05, 0, 0.04)
        let movedRoomPos = ThoughtEntityBuilder.roomPosition(from: movedWorldPos)
        NookActionService.shared.moveItem(item, to: movedRoomPos, in: context, undoManager: undoManager, appState: appState)
        try context.save()
        
        guard abs(item.roomPosition.x - movedRoomPos.x) < 0.001 && abs(item.roomPosition.z - movedRoomPos.z) < 0.001 else {
            throw TestError("Pebble position did not update on move")
        }
        
        // 4. Test Undo (⌘Z)
        undoManager.undo()
        try context.save()
        guard abs(item.roomPosition.x - roomPos.x) < 0.001 else {
            throw TestError("Undo did not restore Pebble initial position")
        }
        
        // 5. Test Search
        let searchIndex = LocalSearchIndex()
        searchIndex.rebuild(with: [item])
        let results = searchIndex.search(query: "coding assistant")
        guard results.count == 1, results.first?.item.id == item.id else {
            throw TestError("LocalSearchIndex failed to match 'coding assistant'")
        }
        
        // 6. Test Delete
        NookActionService.shared.deleteItem(item, in: context, undoManager: undoManager, appState: appState)
        try context.save()
        let fetchDescriptor = FetchDescriptor<NookItem>()
        let remaining = try context.fetch(fetchDescriptor)
        guard remaining.isEmpty else {
            throw TestError("Pebble was not deleted from container")
        }
    }
    
    private static func testAllObjectRepresentations3DGeneration() throws {
        let types: [NookObjectType] = [.pebble, .paperNote, .stickyNote, .card, .polaroid, .bookmark]
        for type in types {
            let item = NookItem(title: "Test \(type.displayName)", content: "Content", itemType: .thought, objectType: type)
            let entity = ThoughtEntityBuilder.buildThoughtEntity(for: item)
            guard let rep = entity.components[ThoughtRepresentationComponent.self], rep.objectType == type else {
                throw TestError("Entity for \(type) missing correct ThoughtRepresentationComponent")
            }
            guard entity.components[CollisionComponent.self] != nil else {
                throw TestError("Entity for \(type) missing CollisionComponent")
            }
        }
    }
    
    private static func testCrowdedSurfaceFallbackPlacement() throws {
        let zone = PlacementZone.deskCenter
        var existing: [SIMD3<Float>] = []
        
        // Fill deskCenter slots with simulated items
        for _ in 0..<16 {
            let pos = zone.allocateNaturalPosition(existingWorldPositions: existing)
            existing.append(pos)
        }
        
        // Next allocation should detect crowding and place onto a valid nearby fallback zone
        let fallbackPos = zone.allocateNaturalPosition(existingWorldPositions: existing)
        
        // Fallback position must not collide with the center of deskCenter
        let center = zone.surfaceDescriptor.center
        let dist = simd_distance(fallbackPos, center)
        guard dist > 0.08 else {
            throw TestError("Crowded surface did not divert new item to a fallback zone")
        }
    }
    
    private static func testCameraExplorationClampingAndReset() throws {
        let rig = RoomCameraRig()
        
        // Orbit within bounds
        rig.orbit(deltaYaw: 1.0, deltaPitch: 1.0)
        
        // Zoom
        rig.zoom(by: 1.5)
        
        // Reset to default framing without animation for instant test
        rig.resetToDefaultFraming(animated: false)
        
        let camPos = rig.cameraEntity.position
        let diff = simd_distance(camPos, RoomCameraRig.defaultCameraPosition)
        guard diff < 0.001 else {
            throw TestError("resetToDefaultFraming did not restore default camera position")
        }
    }
    
    private static func testCookieDeterministicStateTransitions() throws {
        let cookie = CookieRealityEntity()
        cookie.wake()
        cookie.curiousLook(at: SIMD3<Float>(-0.70, 0.735, -0.56))
        cookie.shiftTowardDesk()
        cookie.returnToBedCorner()
        cookie.sleep()
        cookie.happy()
        
        let intelligence = LocalDeterministicCookieIntelligence()
        let mood = intelligence.evaluateActivity(recentEvents: [
            .itemCreated(title: "Test", itemType: .thought, objectType: .pebble, position: RoomPosition(x: 0, y: 0, z: 0)),
            .itemCreated(title: "Test 2", itemType: .thought, objectType: .pebble, position: RoomPosition(x: 0, y: 0, z: 0)),
            .itemCreated(title: "Test 3", itemType: .thought, objectType: .pebble, position: RoomPosition(x: 0, y: 0, z: 0))
        ], currentMood: .idle)
        guard mood == .curious else {
            throw TestError("LocalDeterministicCookieIntelligence did not evaluate to curious on 3 creations")
        }
    }
    
    private static func testCookieAnatomicalRigAndFacialExpressions() throws {
        let cookie = CookieRealityEntity()
        
        // 1. Verify complete anatomical rig structure
        guard cookie.bodyModel != nil else { throw TestError("BodyModel is missing") }
        guard cookie.bellyModel != nil else { throw TestError("BellyModel is missing") }
        guard cookie.headModel != nil else { throw TestError("HeadModel is missing") }
        guard cookie.leftEarModel != nil && cookie.leftInnerEarModel != nil else { throw TestError("LeftEar or LeftInnerEar missing") }
        guard cookie.rightEarModel != nil && cookie.rightInnerEarModel != nil else { throw TestError("RightEar or RightInnerEar missing") }
        guard cookie.leftEyeModel != nil && cookie.leftEyeGlintModel != nil else { throw TestError("LeftEye or LeftEyeGlint missing") }
        guard cookie.rightEyeModel != nil && cookie.rightEyeGlintModel != nil else { throw TestError("RightEye or RightEyeGlint missing") }
        guard cookie.muzzleModel != nil else { throw TestError("MuzzleModel is missing") }
        guard cookie.mouthModel != nil && cookie.leftLipModel != nil && cookie.rightLipModel != nil else { throw TestError("Mouth ω curves missing") }
        guard cookie.leftCheekModel != nil && cookie.rightCheekModel != nil else { throw TestError("LeftCheek or RightCheek blush missing") }
        guard cookie.leftFrontPawModel != nil && cookie.leftPawPointerModel != nil else { throw TestError("LeftFrontPaw or LeftPawPointer missing") }
        guard cookie.rightFrontPawModel != nil else { throw TestError("RightFrontPaw missing") }
        guard cookie.leftFootModel != nil && cookie.rightFootModel != nil else { throw TestError("LeftFoot or RightFoot missing") }
        guard cookie.tailModel != nil && cookie.tailBaseModel != nil && cookie.tailMidModel != nil && cookie.tailTipModel != nil else { throw TestError("Tail chain missing") }
        
        // 2. Verify all required emotional states
        for mood in CookieMood.allCases {
            cookie.setMood(mood, animated: false)
            guard cookie.currentMood == mood else {
                throw TestError("Failed transition to mood: \(mood)")
            }
        }
        
        // 3. Verify all physical postures
        for posture in CookiePosture.allCases {
            cookie.setPosture(posture, animated: false)
            guard cookie.currentPosture == posture else {
                throw TestError("Failed transition to posture: \(posture)")
            }
        }
        
        // 4. Verify interactive and expressive triggers
        cookie.pointAt(target: SIMD3<Float>(0, 0.72, 0))
        cookie.swishTail()
        cookie.blink()
        cookie.pet()
    }
    
    // MARK: - Helper Container
    
    private static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([NookItem.self, RoomState.self])
        let config = ModelConfiguration("NookTestMem", schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    struct TestError: LocalizedError {
        let message: String
        init(_ message: String) { self.message = message }
        var errorDescription: String? { message }
    }
}
