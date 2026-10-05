/**
 * Nook 3D - ObjectInspector
 * Minimalist floating inspection card for selected objects.
 * Never obscures the 3D room diorama.
 */

import { MathUtils } from '../utils/MathUtils.js';

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

  show(object) {
    this.currentObject = object;
    if (!object) {
      this.hide();
      return;
    }

    const typeIcons = {
      pebble: '🪨',
      journal: '📖',
      mug: '☕',
      record_player: '📻',
      skateboard: '🛹',
      daisy_pillow: '🌼',
      plant: '🌿',
      character: '🐾'
    };

    const icon = typeIcons[object.objectType] || '✦';
    const coords = MathUtils.formatVector(object.position);

    this.cardEl.innerHTML = `
      <div class="nook-inspector-header">
        <div class="nook-inspector-title-row">
          <span class="nook-inspector-icon">${icon}</span>
          <div class="nook-inspector-title">${object.name}</div>
        </div>
        <button class="nook-inspector-close" id="inspector-close" title="Deselect (Esc)">✕</button>
      </div>

      <div class="nook-inspector-badge">${object.category.toUpperCase()}</div>

      ${object.title ? `<div class="nook-inspector-content-title">${object.title}</div>` : ''}
      ${object.content ? `<div class="nook-inspector-content">${object.content}</div>` : ''}

      <div class="nook-inspector-coords">Position: ${coords}</div>

      <div class="nook-inspector-actions">
        <button class="nook-btn nook-btn-primary" id="btn-focus">Focus Camera</button>
        ${object.itemId === 'prop_cookie' ? '<button class="nook-btn" id="btn-pet">Pet Cookie 🐾</button>' : ''}
      </div>
    `;

    this.cardEl.style.display = 'block';

    // Hook buttons
    this.cardEl.querySelector('#inspector-close').addEventListener('click', () => {
      this.hide();
      if (this.onAction.onDeselect) this.onAction.onDeselect();
    });

    const focusBtn = this.cardEl.querySelector('#btn-focus');
    if (focusBtn) {
      focusBtn.addEventListener('click', () => {
        if (this.onAction.onFocus) this.onAction.onFocus(this.currentObject);
      });
    }

    const petBtn = this.cardEl.querySelector('#btn-pet');
    if (petBtn) {
      petBtn.addEventListener('click', () => {
        if (this.onAction.onPet) this.onAction.onPet();
      });
    }
  }

  hide() {
    this.cardEl.style.display = 'none';
    this.currentObject = null;
  }
}
