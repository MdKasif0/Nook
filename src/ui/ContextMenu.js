/**
 * Nook 3D - ContextMenu
 * Floating macOS-style glassmorphic context menu on right-click.
 * Provides subtle, non-intrusive actions without dominating the visual 3D experience.
 */

export class ContextMenu {
  constructor(domContainer, actions = {}) {
    this.domContainer = domContainer;
    this.actions = actions;

    this.menuEl = document.createElement('div');
    this.menuEl.className = 'nook-context-menu';
    this.menuEl.style.display = 'none';
    this.domContainer.appendChild(this.menuEl);

    this.initListeners();
  }

  initListeners() {
    window.addEventListener('click', () => this.hide());
    window.addEventListener('keydown', e => {
      if (e.key === 'Escape') this.hide();
    });
  }

  show(x, y, items) {
    this.menuEl.innerHTML = '';

    for (const item of items) {
      if (item.separator) {
        const sep = document.createElement('div');
        sep.className = 'nook-menu-separator';
        this.menuEl.appendChild(sep);
        continue;
      }

      const row = document.createElement('button');
      row.className = 'nook-menu-item';
      if (item.danger) row.classList.add('danger');

      row.innerHTML = `
        <span class="nook-menu-icon">${item.icon || '✦'}</span>
        <span class="nook-menu-label">${item.label}</span>
      `;

      row.addEventListener('click', e => {
        e.stopPropagation();
        this.hide();
        if (item.action) item.action();
      });

      this.menuEl.appendChild(row);
    }

    // Keep inside viewport bounds
    this.menuEl.style.display = 'flex';
    const rect = this.menuEl.getBoundingClientRect();
    const maxX = window.innerWidth - rect.width - 12;
    const maxY = window.innerHeight - rect.height - 12;

    this.menuEl.style.left = `${Math.min(x, maxX)}px`;
    this.menuEl.style.top = `${Math.min(y, maxY)}px`;
  }

  hide() {
    this.menuEl.style.display = 'none';
  }
}
