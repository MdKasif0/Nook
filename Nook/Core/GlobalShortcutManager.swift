import AppKit
import SwiftUI

/// Coordinates macOS keyboard shortcuts across the application and system.
///
/// Implements:
/// - ⌘⇧Space: Quick Thought (floating capture window)
/// - ⌘K: Search palette
/// - ⌘N: New thought when main room is active
/// - Escape: Dismiss contextual UI (search, inspector, quick capture)
@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()
    
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    weak var appState: AppState?
    var onOpenQuickCapture: (() -> Void)?
    var onEscapePressed: (() -> Bool)? // Returns true if an overlay/context was dismissed
    
    private init() {}
    
    /// Starts monitoring for local and global shortcut events.
    func setup(appState: AppState, onOpenQuickCapture: @escaping () -> Void) {
        self.appState = appState
        self.onOpenQuickCapture = onOpenQuickCapture
        
        setupLocalMonitor()
        setupGlobalMonitor()
    }
    
    // MARK: - Local Keyboard Monitor
    
    private func setupLocalMonitor() {
        guard localMonitor == nil else { return }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            let chars = event.charactersIgnoringModifiers?.lowercased()
            
            // 1. ⌘⇧Space -> Quick Thought
            if flags.contains([.command, .shift]) && keyCode == 49 {
                self.triggerQuickCapture()
                return nil
            }
            
            // 2. ⌘K -> Command Palette / Search
            if flags == .command && chars == "k" {
                self.triggerSearch()
                return nil
            }
            
            // 3. ⌘N -> New Thought (when in room or main window)
            if flags == .command && chars == "n" {
                // If text editor or input field is NOT currently being typed in, or we open new thought sheet
                if let responder = NSApp.keyWindow?.firstResponder as? NSTextView, responder.isFieldEditor {
                    // Inside an active text editor field, allow standard behavior
                    return event
                }
                self.triggerNewThought()
                return nil
            }
            
            // 4. Escape -> Dismiss Contextual UI
            if keyCode == 53 {
                // If Search Palette is open, dismiss it
                if let appState = self.appState, appState.isSearchOpen {
                    appState.closeSearch()
                    return nil
                }
                
                // Let contextual listeners handle (e.g. room inspector or quick capture)
                if let handled = self.onEscapePressed?(), handled {
                    return nil
                }
            }
            
            return event
        }
    }
    
    // MARK: - Global Monitor (When other apps are focused)
    
    private func setupGlobalMonitor() {
        guard globalMonitor == nil else { return }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            
            // ⌘⇧Space -> Trigger Quick Thought from anywhere on macOS
            if flags.contains([.command, .shift]) && keyCode == 49 {
                DispatchQueue.main.async {
                    self.triggerQuickCapture()
                }
            }
        }
    }
    
    // MARK: - Triggers
    
    func triggerQuickCapture() {
        NSApp.activate(ignoringOtherApps: true)
        onOpenQuickCapture?()
    }
    
    func triggerSearch() {
        NSApp.activate(ignoringOtherApps: true)
        appState?.toggleSearch()
    }
    
    func triggerNewThought() {
        guard let appState else { return }
        appState.selectedSection = .room
        appState.isShowingNewThoughtSheet = true
    }
    
    deinit {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }
}
