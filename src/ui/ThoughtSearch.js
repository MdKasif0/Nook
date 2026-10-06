/**
 * Nook 3D - ThoughtSearch
 * In-room Spotlight-style search overlay.
 * Searches thoughts in real-time by title, content, and type.
 * Selecting a result gently focuses the 3D camera on the object and opens its inspector.
 */

import { thoughtStore } from '../persistence/ThoughtStore.js';

export class ThoughtSearch {
  constructor(containerEl, onSelectCallback = null) {
    this.container = containerEl;
    this.onSelect = onSelectCallback;
    this.isOpen = false;

    this.overlayEl = document.createElement('div');
    this.overlayEl.className = 'nook-search-overlay';
    this.overlayEl.style.display = 'none';

    this.render();
    this.container.appendChild(this.overlayEl);
    this.initListeners();
  }

  render() {
    this.overlayEl.innerHTML = `
      <div class="nook-search-panel">
        <div class="nook-search-bar">
          <span class="nook-search-icon">🔍</span>
          <input 
            type="text" 
            id="search-input" 
            class="nook-search-input" 
            placeholder="Search thoughts in room (title, content, type)..." 
            autocomplete="off"
            spellcheck="false"
          />
          <button class="nook-search-close" id="search-close" title="Close (Esc)">✕</button>
        </div>
        <div class="nook-search-results" id="search-results">
          <!-- Dynamic results list -->
        </div>
        <div class="nook-search-footer">
          <span>Navigate with <kbd>↑</kbd> <kbd>↓</kbd></span>
          <span>Open with <kbd>↵</kbd></span>
          <span>Close with <kbd>esc</kbd></span>
        </div>
      </div>
    `;
  }

  initListeners() {
    this.input = this.overlayEl.querySelector('#search-input');
    this.resultsContainer = this.overlayEl.querySelector('#search-results');
    this.closeBtn = this.overlayEl.querySelector('#search-close');

    this.input.addEventListener('input', () => this.handleQuery(this.input.value));

    this.closeBtn.addEventListener('click', () => this.hide());
    this.overlayEl.addEventListener('click', e => {
      if (e.target === this.overlayEl) this.hide();
    });

    this.overlayEl.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        this.hide();
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        this.moveSelection(1);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        this.moveSelection(-1);
      } else if (e.key === 'Enter') {
        e.preventDefault();
        this.selectActiveItem();
      }
    });
  }

  show() {
    this.isOpen = true;
    this.overlayEl.style.display = 'flex';
    this.input.value = '';
    this.handleQuery('');
    setTimeout(() => this.input.focus(), 80);
  }

  hide() {
    this.isOpen = false;
    this.overlayEl.style.display = 'none';
  }

  toggle() {
    if (this.isOpen) {
      this.hide();
    } else {
      this.show();
    }
  }

  handleQuery(query) {
    const q = query.trim().toLowerCase();
    const all = thoughtStore.getAll();

    const filtered = all.filter(item => {
      if (!q) return true;
      const titleMatch = item.title && item.title.toLowerCase().includes(q);
      const contentMatch = item.content && item.content.toLowerCase().includes(q);
      const typeMatch = item.type && item.type.toLowerCase().includes(q);
      const surfaceMatch = item.surface && item.surface.toLowerCase().includes(q);
      return titleMatch || contentMatch || typeMatch || surfaceMatch;
    });

    this.renderResults(filtered);
  }

  renderResults(items) {
    const typeIcons = {
      thought: '🪨',
      idea: '🕊️',
      reminder: '📝',
      quote: '🏷️',
      photo: '📷',
      link: '🔖',
      note: '📓'
    };

    if (items.length === 0) {
      this.resultsContainer.innerHTML = `
        <div class="nook-search-empty">
          <span>No thoughts found matching that phrase in this room.</span>
        </div>
      `;
      return;
    }

    this.resultsContainer.innerHTML = items.map((item, index) => {
      const icon = typeIcons[item.type] || '✦';
      const snippet = item.content ? (item.content.length > 70 ? item.content.slice(0, 70) + '…' : item.content) : '';
      return `
        <div class="nook-search-item ${index === 0 ? 'active' : ''}" data-id="${item.id}">
          <span class="nook-search-item-icon">${icon}</span>
          <div class="nook-search-item-text">
            <div class="nook-search-item-title">${item.title}</div>
            ${snippet ? `<div class="nook-search-item-snippet">${snippet}</div>` : ''}
          </div>
          <span class="nook-search-item-badge">${item.type.toUpperCase()}</span>
        </div>
      `;
    }).join('');

    // Attach click handlers
    const resultEls = this.resultsContainer.querySelectorAll('.nook-search-item');
    resultEls.forEach(el => {
      el.addEventListener('click', () => {
        const id = el.dataset.id;
        this.chooseItem(id);
      });
      el.addEventListener('mouseenter', () => {
        resultEls.forEach(r => r.classList.remove('active'));
        el.classList.add('active');
      });
    });
  }

  moveSelection(delta) {
    const items = Array.from(this.resultsContainer.querySelectorAll('.nook-search-item'));
    if (items.length === 0) return;

    let currentIndex = items.findIndex(el => el.classList.contains('active'));
    if (currentIndex === -1) currentIndex = 0;

    let nextIndex = currentIndex + delta;
    if (nextIndex < 0) nextIndex = items.length - 1;
    if (nextIndex >= items.length) nextIndex = 0;

    items.forEach((el, idx) => el.classList.toggle('active', idx === nextIndex));
    items[nextIndex].scrollIntoView({ block: 'nearest' });
  }

  selectActiveItem() {
    const active = this.resultsContainer.querySelector('.nook-search-item.active');
    if (active && active.dataset.id) {
      this.chooseItem(active.dataset.id);
    }
  }

  chooseItem(id) {
    this.hide();
    if (this.onSelect) {
      this.onSelect(id);
    }
  }
}
