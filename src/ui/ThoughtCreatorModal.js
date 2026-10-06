/**
 * Nook 3D - ThoughtCreatorModal
 * Minimalist, native macOS-feeling modal for creating and editing thoughts.
 * Simple, warm, and elegant — keeps the miniature diorama front and center.
 * 
 * Fields:
 * - Title
 * - Content
 * - Type: Thought 🪨, Idea 🕊️, Reminder 📝, Quote 🏷️, Photo 📷, Link 🔖, Note 📓
 */

export class ThoughtCreatorModal {
  constructor(containerEl, onSaveCallback = null) {
    this.container = containerEl;
    this.onSave = onSaveCallback;
    this.editingThoughtId = null;

    this.modalEl = document.createElement('div');
    this.modalEl.className = 'nook-modal-overlay';
    this.modalEl.style.display = 'none';

    this.render();
    this.container.appendChild(this.modalEl);
    this.initListeners();
  }

  render() {
    this.modalEl.innerHTML = `
      <div class="nook-modal-card">
        <div class="nook-modal-header">
          <div class="nook-modal-title" id="modal-title">Leave a Thought in Nook</div>
          <button class="nook-modal-close" id="modal-close" title="Close (Esc)">✕</button>
        </div>

        <div class="nook-modal-body">
          <!-- Type Picker (7 representations) -->
          <div class="nook-field-group">
            <label class="nook-label">Physical Object</label>
            <div class="nook-type-selector" id="type-selector">
              <button type="button" class="nook-type-btn active" data-type="thought">
                <span class="type-icon">🪨</span>
                <span class="type-name">Thought</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="idea">
                <span class="type-icon">🕊️</span>
                <span class="type-name">Idea</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="reminder">
                <span class="type-icon">📝</span>
                <span class="type-name">Reminder</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="quote">
                <span class="type-icon">🏷️</span>
                <span class="type-name">Quote</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="photo">
                <span class="type-icon">📷</span>
                <span class="type-name">Photo</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="link">
                <span class="type-icon">🔖</span>
                <span class="type-name">Link</span>
              </button>
              <button type="button" class="nook-type-btn" data-type="note">
                <span class="type-icon">📓</span>
                <span class="type-name">Note</span>
              </button>
            </div>
          </div>

          <!-- Title Input -->
          <div class="nook-field-group">
            <label class="nook-label" for="input-title">Title</label>
            <input 
              type="text" 
              id="input-title" 
              class="nook-input" 
              placeholder="A short title or essence..." 
              maxlength="80" 
              autocomplete="off"
            />
          </div>

          <!-- Content Input -->
          <div class="nook-field-group">
            <label class="nook-label" for="input-content">Content</label>
            <textarea 
              id="input-content" 
              class="nook-textarea" 
              placeholder="What would you like to leave in this room?..."
              rows="4"
            ></textarea>
          </div>
        </div>

        <div class="nook-modal-footer">
          <button type="button" class="nook-btn nook-btn-ghost" id="btn-cancel">Cancel</button>
          <button type="button" class="nook-btn nook-btn-primary" id="btn-submit">
            Leave in Nook ✨
          </button>
        </div>
      </div>
    `;
  }

  initListeners() {
    this.titleInput = this.modalEl.querySelector('#input-title');
    this.contentInput = this.modalEl.querySelector('#input-content');
    this.modalTitle = this.modalEl.querySelector('#modal-title');
    this.submitBtn = this.modalEl.querySelector('#btn-submit');

    // Type selection toggle
    const typeButtons = this.modalEl.querySelectorAll('.nook-type-btn');
    typeButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        typeButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
      });
    });

    // Close buttons
    this.modalEl.querySelector('#modal-close').addEventListener('click', () => this.hide());
    this.modalEl.querySelector('#btn-cancel').addEventListener('click', () => this.hide());

    // Click outside backdrop
    this.modalEl.addEventListener('click', e => {
      if (e.target === this.modalEl) this.hide();
    });

    // Submit handler
    this.submitBtn.addEventListener('click', () => this.handleSubmit());

    // Keyboard shortcuts
    this.modalEl.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        this.hide();
      } else if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
        this.handleSubmit();
      }
    });
  }

  getSelectedType() {
    const active = this.modalEl.querySelector('.nook-type-btn.active');
    return active ? active.dataset.type : 'thought';
  }

  setSelectedType(type) {
    const norm = (type || 'thought').toLowerCase();
    const typeButtons = this.modalEl.querySelectorAll('.nook-type-btn');
    typeButtons.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.type === norm);
    });
  }

  show(initialData = null) {
    this.editingThoughtId = initialData?.id || null;

    if (this.editingThoughtId) {
      this.modalTitle.textContent = 'Edit Thought';
      this.submitBtn.textContent = 'Save Changes';
      this.titleInput.value = initialData.title || '';
      this.contentInput.value = initialData.content || '';
      this.setSelectedType(initialData.type || 'thought');
    } else {
      this.modalTitle.textContent = 'Leave a Thought in Nook';
      this.submitBtn.textContent = 'Leave in Nook ✨';
      this.titleInput.value = '';
      this.contentInput.value = '';
      this.setSelectedType('thought');
    }

    this.modalEl.style.display = 'flex';
    setTimeout(() => this.titleInput.focus(), 80);
  }

  hide() {
    this.modalEl.style.display = 'none';
    this.editingThoughtId = null;
  }

  handleSubmit() {
    const title = this.titleInput.value.trim() || 'Untitled Thought';
    const content = this.contentInput.value.trim();
    const type = this.getSelectedType();

    if (this.onSave) {
      this.onSave({
        id: this.editingThoughtId,
        title,
        content,
        type
      });
    }

    this.hide();
  }
}
