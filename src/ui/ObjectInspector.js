/**
 * Nook 3D - ObjectInspector
 * Minimalist floating inspection card for selected objects and thoughts.
 * Displays title, content, type, creation dates, and physical manipulation actions.
 * Never covers the diorama with a generic dashboard.
 */

import { MathUtils } from '../utils/MathUtils.js';
import { thoughtStore } from '../persistence/ThoughtStore.js';

export class ObjectInspector {
  constructor(domContainer, onAction = {}) {
    this.domContainer = domContainer;
    this.onAction = onAction;

    this.cardEl = document.createElement('div');
    this.cardEl.className = 'nook-inspector-card';
    this.cardEl.style.display = 'none';
    this.domContainer.appendChild(this.cardEl);

    this.currentObject = null;
  }

  formatDate(isoStr) {
    if (!isoStr) return 'Just now';
    try {
      const d = new Date(isoStr);
      return d.toLocaleDateString(undefined, { 
        month: 'short', 
        day: 'numeric', 
        hour: '2-digit', 
        minute: '2-digit' 
      });
    } catch {
      return isoStr;
    }
  }

  show(object) {
    this.currentObject = object;
    if (!object) {
      this.hide();
      return;
    }

    const typeIcons = {
      thought: '🪨',
      pebble: '🪨',
      idea: '🕊️',
      reminder: '📝',
      quote: '🏷️',
      photo: '📷',
      polaroid: '📷',
      link: '🔖',
      bookmark: '🔖',
      note: '📓',
      character: '🐾'
    };

    const isThought = object.category === 'thought' || thoughtStore.getById(object.itemId);
    const thoughtData = isThought ? thoughtStore.getById(object.itemId) : null;
    const isPinned = Boolean(thoughtData?.isPinned || object.isPinned);

    const normType = (thoughtData?.type || object.objectType || 'prop').toLowerCase();
    const icon = typeIcons[normType] || '✦';
    const coords = MathUtils.formatVector(object.position);

    const title = thoughtData?.title || object.metadata?.title || object.name;
    const content = thoughtData?.content || object.metadata?.description || '';
    const createdStr = this.formatDate(thoughtData?.createdAt);
    const updatedStr = this.formatDate(thoughtData?.updatedAt);

    this.cardEl.innerHTML = `
      <div class="nook-inspector-header">
        <div class="nook-inspector-title-row">
          <span class="nook-inspector-icon">${icon}</span>
          <div class="nook-inspector-title">${title}</div>
        </div>
        <button class="nook-inspector-close" id="inspector-close" title="Deselect (Esc)">✕</button>
      </div>

      <div class="nook-inspector-meta">
        <span class="nook-inspector-badge">${normType.toUpperCase()}</span>
        ${isPinned ? `<span class="nook-inspector-badge nook-badge-pinned">📌 PINNED</span>` : ''}
        ${thoughtData?.surface ? `<span class="nook-inspector-surface">Surface: ${thoughtData.surface}</span>` : ''}
      </div>

      ${content ? `<div class="nook-inspector-content">${content}</div>` : ''}

      ${isThought ? `
        <div class="nook-inspector-timestamps">
          <div class="nook-time-row"><span>Created:</span> <strong>${createdStr}</strong></div>
          <div class="nook-time-row"><span>Updated:</span> <strong>${updatedStr}</strong></div>
        </div>
      ` : ''}

      <div class="nook-inspector-coords">Room Position: ${coords}</div>

      <div class="nook-inspector-actions">
        <!-- Thought Actions -->
        ${isThought ? `
          <button class="nook-btn nook-btn-primary" id="btn-edit-thought">✏️ Edit</button>
          <button class="nook-btn ${isPinned ? 'active' : ''}" id="btn-pin-thought">${isPinned ? '📌 Pinned' : '📍 Pin'}</button>
          <button class="nook-btn" id="btn-change-type">🔄 Change Object</button>
          <button class="nook-btn" id="btn-move-thought">✋ Move</button>
          <button class="nook-btn nook-btn-danger" id="btn-delete-thought">🗑️ Delete</button>
        ` : ''}

        <!-- Cookie Actions -->
        ${object.itemId === 'prop_cookie' || object.objectType === 'cat' ? `
          <button class="nook-btn" id="btn-pet">Pet Cookie 🐾</button>
          <button class="nook-btn" id="btn-bed">Go to Bed 🛏️</button>
          <button class="nook-btn" id="btn-desk">Go to Desk 💻</button>
          <button class="nook-btn" id="btn-window">Window Sill 🪟</button>
          <button class="nook-btn" id="btn-catbed">Cat Bed 🌸</button>
          <button class="nook-btn" id="btn-wander">Wander 🐾</button>
        ` : ''}

        <!-- General Focus Action -->
        ${!isThought ? `<button class="nook-btn" id="btn-focus">Focus Camera</button>` : ''}
      </div>

      <!-- Change Object Type Popover (Inline) -->
      <div class="nook-change-type-popup" id="change-type-popup" style="display: none;">
        <div class="change-type-title">Select Physical Representation:</div>
        <div class="change-type-grid">
          <button class="change-type-btn" data-type="thought">🪨 Thought</button>
          <button class="change-type-btn" data-type="idea">🕊️ Idea</button>
          <button class="change-type-btn" data-type="reminder">📝 Reminder</button>
          <button class="change-type-btn" data-type="quote">🏷️ Quote</button>
          <button class="change-type-btn" data-type="photo">📷 Photo</button>
          <button class="change-type-btn" data-type="link">🔖 Link</button>
          <button class="change-type-btn" data-type="note">📓 Note</button>
        </div>
      </div>
    `;

    this.cardEl.style.display = 'block';

    // Hook listeners
    this.cardEl.querySelector('#inspector-close').addEventListener('click', () => {
      this.hide();
      if (this.onAction.onDeselect) this.onAction.onDeselect();
    });

    // Thought actions
    if (isThought) {
      const editBtn = this.cardEl.querySelector('#btn-edit-thought');
      if (editBtn) {
        editBtn.addEventListener('click', () => {
          if (this.onAction.onEditThought) this.onAction.onEditThought(this.currentObject);
        });
      }

      const pinBtn = this.cardEl.querySelector('#btn-pin-thought');
      if (pinBtn) {
        pinBtn.addEventListener('click', () => {
          if (this.onAction.onTogglePin) this.onAction.onTogglePin(this.currentObject);
        });
      }

      const moveBtn = this.cardEl.querySelector('#btn-move-thought');
      if (moveBtn) {
        moveBtn.addEventListener('click', () => {
          if (this.onAction.onMoveThought) this.onAction.onMoveThought(this.currentObject);
        });
      }

      const changeTypeBtn = this.cardEl.querySelector('#btn-change-type');
      const popup = this.cardEl.querySelector('#change-type-popup');
      if (changeTypeBtn && popup) {
        changeTypeBtn.addEventListener('click', () => {
          popup.style.display = popup.style.display === 'none' ? 'block' : 'none';
        });

        popup.querySelectorAll('.change-type-btn').forEach(btn => {
          btn.addEventListener('click', () => {
            const newType = btn.dataset.type;
            popup.style.display = 'none';
            if (this.onAction.onChangeObjectType) {
              this.onAction.onChangeObjectType(this.currentObject, newType);
            }
          });
        });
      }

      const deleteBtn = this.cardEl.querySelector('#btn-delete-thought');
      if (deleteBtn) {
        deleteBtn.addEventListener('click', () => {
          if (this.onAction.onDeleteThought) this.onAction.onDeleteThought(this.currentObject);
        });
      }
    }

    // Cookie actions
    const petBtn = this.cardEl.querySelector('#btn-pet');
    if (petBtn) petBtn.addEventListener('click', () => this.onAction.onPet && this.onAction.onPet());

    const bedBtn = this.cardEl.querySelector('#btn-bed');
    if (bedBtn) bedBtn.addEventListener('click', () => this.onAction.onGoToBed && this.onAction.onGoToBed());

    const deskBtn = this.cardEl.querySelector('#btn-desk');
    if (deskBtn) deskBtn.addEventListener('click', () => this.onAction.onGoToDesk && this.onAction.onGoToDesk());

    const windowBtn = this.cardEl.querySelector('#btn-window');
    if (windowBtn) windowBtn.addEventListener('click', () => this.onAction.onGoToWindow && this.onAction.onGoToWindow());

    const catbedBtn = this.cardEl.querySelector('#btn-catbed');
    if (catbedBtn) catbedBtn.addEventListener('click', () => this.onAction.onGoToCatBed && this.onAction.onGoToCatBed());

    const wanderBtn = this.cardEl.querySelector('#btn-wander');
    if (wanderBtn) wanderBtn.addEventListener('click', () => this.onAction.onWander && this.onAction.onWander());

    const focusBtn = this.cardEl.querySelector('#btn-focus');
    if (focusBtn) focusBtn.addEventListener('click', () => this.onAction.onFocus && this.onAction.onFocus(this.currentObject));
  }

  hide() {
    this.cardEl.style.display = 'none';
    this.currentObject = null;
  }
}
