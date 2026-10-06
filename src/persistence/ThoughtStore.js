/**
 * Nook 3D - ThoughtStore
 * Dedicated local persistence and data layer for thought objects.
 * Saves and restores:
 * id, title, content, type, position, rotation, scale, surface, createdAt, updatedAt
 * 
 * Prepares for SwiftData bidirectional sync through WKWebView native message handlers.
 */

const STORAGE_KEY = 'nook_thoughts_v2';

export class ThoughtStore {
  constructor() {
    this.thoughts = new Map();
    this.listeners = new Set();
    this.load();
  }

  load() {
    if (typeof localStorage === 'undefined') return;
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const list = JSON.parse(raw);
        this.thoughts.clear();
        for (const item of list) {
          if (item && item.id) {
            this.thoughts.set(item.id, item);
          }
        }
      }
    } catch (e) {
      console.warn('Failed to load thoughts from localStorage:', e);
    }
  }

  save() {
    if (typeof localStorage === 'undefined') return;
    try {
      const list = Array.from(this.thoughts.values());
      localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
      this.notifyNativeBridge('thoughtsSaved', list);
      this.emitChange();
    } catch (e) {
      console.warn('Failed to save thoughts:', e);
    }
  }

  getAll() {
    return Array.from(this.thoughts.values());
  }

  getById(id) {
    return this.thoughts.get(id) || null;
  }

  saveThought(data) {
    const now = new Date().toISOString();
    const existing = this.thoughts.get(data.id);

    const record = {
      id: data.id || 'thought_' + Math.random().toString(36).substring(2, 9),
      title: data.title || 'Untitled Thought',
      content: data.content || '',
      type: (data.type || 'thought').toLowerCase(),
      position: {
        x: Number((data.position?.x ?? 0).toFixed(3)),
        y: Number((data.position?.y ?? 1.70).toFixed(3)),
        z: Number((data.position?.z ?? -2.0).toFixed(3))
      },
      rotation: {
        x: Number((data.rotation?.x ?? 0).toFixed(3)),
        y: Number((data.rotation?.y ?? 0).toFixed(3)),
        z: Number((data.rotation?.z ?? 0).toFixed(3))
      },
      scale: {
        x: Number((data.scale?.x ?? 1.0).toFixed(3)),
        y: Number((data.scale?.y ?? 1.0).toFixed(3)),
        z: Number((data.scale?.z ?? 1.0).toFixed(3))
      },
      surface: data.surface || 'desk',
      isPinned: Boolean(data.isPinned !== undefined ? data.isPinned : (existing?.isPinned || false)),
      createdAt: existing?.createdAt || data.createdAt || now,
      updatedAt: now
    };

    this.thoughts.set(record.id, record);
    this.save();
    return record;
  }

  updateThought(id, updates) {
    const existing = this.thoughts.get(id);
    if (!existing) return null;

    const updated = {
      ...existing,
      ...updates,
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: new Date().toISOString()
    };

    if (updates.position) {
      updated.position = {
        x: Number(updates.position.x.toFixed(3)),
        y: Number(updates.position.y.toFixed(3)),
        z: Number(updates.position.z.toFixed(3))
      };
    }
    if (updates.rotation) {
      updated.rotation = {
        x: Number(updates.rotation.x.toFixed(3)),
        y: Number(updates.rotation.y.toFixed(3)),
        z: Number(updates.rotation.z.toFixed(3))
      };
    }

    this.thoughts.set(id, updated);
    this.save();
    return updated;
  }

  deleteThought(id) {
    const existing = this.thoughts.get(id);
    if (existing) {
      this.thoughts.delete(id);
      this.save();
      this.notifyNativeBridge('thoughtDeleted', { id });
      return existing;
    }
    return null;
  }

  // MARK: - SwiftData Bridge Hooks

  notifyNativeBridge(action, payload) {
    if (typeof window !== 'undefined' && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nookBridge) {
      window.webkit.messageHandlers.nookBridge.postMessage({
        action,
        payload
      });
    }
  }

  exportJSON() {
    return JSON.stringify(this.getAll(), null, 2);
  }

  importJSON(jsonStr) {
    try {
      const list = JSON.parse(jsonStr);
      if (Array.isArray(list)) {
        this.thoughts.clear();
        for (const item of list) {
          if (item && item.id) {
            this.thoughts.set(item.id, item);
          }
        }
        this.save();
      }
    } catch (e) {
      console.warn('Failed to import thoughts from JSON:', e);
    }
  }

  onChange(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  emitChange() {
    for (const listener of this.listeners) {
      try {
        listener(this.getAll());
      } catch (e) {
        console.error('Error in ThoughtStore listener:', e);
      }
    }
  }
}

export const thoughtStore = new ThoughtStore();
