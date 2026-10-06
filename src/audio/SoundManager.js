/**
 * Nook 3D - SoundManager
 * Procedural Web Audio API sound synthesizer for tactile, cozy immersion.
 * 
 * Generates all physical audio in real-time with zero external asset dependencies:
 * - Mechanical desk lamp toggle clicks
 * - Subtle vinyl turntable needle drop, continuous warm crackle, and 33-RPM hum
 * - Tactile drop/settle thuds for wood, paper, ceramic, cloth, and metal
 * - Skateboard deck rock & polyurethane bushing clicks
 * - Soft Cookie kitten meow and rhythmic deep purr
 * - Keyboard & decorative laptop taps
 * 
 * All sound is strictly optional, polite, and never blocks functionality.
 */

export class SoundManager {
  constructor() {
    this.audioCtx = null;
    this.isMuted = false;
    this.sfxEnabled = true;
    this.ambientEnabled = true;
    this.vinylNode = null;
    this.vinylGain = null;
    this.purrNode = null;
    this.purrGain = null;

    // Master volume (gentle, warm, non-intrusive)
    this.masterVolume = 0.32;
    this.masterGain = null;

    // Load persisted audio settings
    this.loadSettings();

    // Audio unlock listener on first user interaction
    this.unlocked = false;
    this.initUnlockTriggers();
  }

  loadSettings() {
    if (typeof window === 'undefined' || !window.localStorage) return;
    try {
      const saved = localStorage.getItem('nook_audio_settings');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (typeof parsed.isMuted === 'boolean') this.isMuted = parsed.isMuted;
        if (typeof parsed.sfxEnabled === 'boolean') this.sfxEnabled = parsed.sfxEnabled;
        if (typeof parsed.ambientEnabled === 'boolean') this.ambientEnabled = parsed.ambientEnabled;
      }
    } catch (e) {
      console.warn('Could not read audio settings from localStorage', e);
    }
  }

  saveSettings() {
    if (typeof window === 'undefined' || !window.localStorage) return;
    try {
      localStorage.setItem('nook_audio_settings', JSON.stringify({
        isMuted: this.isMuted,
        sfxEnabled: this.sfxEnabled,
        ambientEnabled: this.ambientEnabled
      }));
    } catch (e) {}
  }

  initUnlockTriggers() {
    if (typeof window === 'undefined') return;
    const unlock = () => {
      if (!this.unlocked) {
        this.ensureContext();
        if (this.audioCtx && this.audioCtx.state === 'suspended') {
          this.audioCtx.resume();
        }
        this.unlocked = true;
      }
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };

    window.addEventListener('pointerdown', unlock, { once: true });
    window.addEventListener('keydown', unlock, { once: true });
  }

  ensureContext() {
    if (typeof window === 'undefined') return null;
    if (!this.audioCtx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (!AudioContextClass) return null;
      this.audioCtx = new AudioContextClass();

      this.masterGain = this.audioCtx.createGain();
      this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.masterVolume, this.audioCtx.currentTime);
      this.masterGain.connect(this.audioCtx.destination);
    }

    if (this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }

    return this.audioCtx;
  }

  setMuted(muted) {
    this.isMuted = !!muted;
    if (this.masterGain && this.audioCtx) {
      this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.masterVolume, this.audioCtx.currentTime);
    }
    if (this.isMuted) {
      this.stopVinyl();
    }
    this.saveSettings();
  }

  toggleMute() {
    this.setMuted(!this.isMuted);
    return this.isMuted;
  }

  setSfxEnabled(enabled) {
    this.sfxEnabled = !!enabled;
    this.saveSettings();
  }

  setSoundEffectsEnabled(enabled) {
    this.setSfxEnabled(enabled);
  }

  isSfxEnabled() {
    return !this.isMuted && this.sfxEnabled;
  }

  isSoundEffectsEnabled() {
    return this.isSfxEnabled();
  }

  toggleSfx() {
    this.setSfxEnabled(!this.sfxEnabled);
    return this.sfxEnabled;
  }

  setAmbientEnabled(enabled) {
    this.ambientEnabled = !!enabled;
    if (!this.ambientEnabled) {
      this.stopVinyl();
    }
    this.saveSettings();
  }

  setAmbientSoundEnabled(enabled) {
    this.setAmbientEnabled(enabled);
  }

  isAmbientEnabled() {
    return !this.isMuted && this.ambientEnabled;
  }

  isAmbientSoundEnabled() {
    return this.isAmbientEnabled();
  }

  toggleAmbient() {
    this.setAmbientEnabled(!this.ambientEnabled);
    return this.ambientEnabled;
  }

  // MARK: - 1. Desk Lamp Toggle Click
  playLampClick() {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    // Dual-click mechanical switch transient (vintage rotary/rocker switch)
    // 1st initial metallic snap
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    const filter1 = ctx.createBiquadFilter();

    filter1.type = 'bandpass';
    filter1.frequency.setValueAtTime(2400, t);
    filter1.Q.setValueAtTime(3.5, t);

    osc1.type = 'triangle';
    osc1.frequency.setValueAtTime(1400, t);
    osc1.frequency.exponentialRampToValueAtTime(320, t + 0.025);

    gain1.gain.setValueAtTime(0.5, t);
    gain1.gain.exponentialRampToValueAtTime(0.001, t + 0.03);

    osc1.connect(filter1);
    filter1.connect(gain1);
    gain1.connect(this.masterGain);

    osc1.start(t);
    osc1.stop(t + 0.035);

    // 2nd resonant switch casing thud (40ms later)
    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(380, t + 0.03);
    osc2.frequency.exponentialRampToValueAtTime(80, t + 0.075);

    gain2.gain.setValueAtTime(0.0, t);
    gain2.gain.setValueAtTime(0.4, t + 0.03);
    gain2.gain.exponentialRampToValueAtTime(0.001, t + 0.08);

    osc2.connect(gain2);
    gain2.connect(this.masterGain);

    osc2.start(t + 0.03);
    osc2.stop(t + 0.085);
  }

  // MARK: - 2. Record Player Vinyl Crackle & Hum
  startVinyl() {
    if (this.isMuted || this.vinylNode) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    // Buffer for realistic vinyl micro-crackle and surface dust noise
    const bufferSize = ctx.sampleRate * 2.0;
    const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const output = noiseBuffer.getChannelData(0);

    let lastOut = 0.0;
    for (let i = 0; i < bufferSize; i++) {
      // Pink-ish filtered noise
      const white = Math.random() * 2 - 1;
      output[i] = (lastOut + 0.02 * white) / 1.02;
      lastOut = output[i];

      // Occasional gentle vinyl groove pops
      if (Math.random() < 0.0006) {
        output[i] += (Math.random() - 0.5) * 0.85;
      }
    }

    const noiseSource = ctx.createBufferSource();
    noiseSource.buffer = noiseBuffer;
    noiseSource.loop = true;

    // Filter to warm analog low-mids
    const bandpass = ctx.createBiquadFilter();
    bandpass.type = 'bandpass';
    bandpass.frequency.setValueAtTime(1200, t);
    bandpass.Q.setValueAtTime(1.2, t);

    // Warm 33 RPM turntable motor low hum (60Hz + 120Hz harmonic)
    const humOsc = ctx.createOscillator();
    humOsc.type = 'sine';
    humOsc.frequency.setValueAtTime(58, t);

    const humGain = ctx.createGain();
    humGain.gain.setValueAtTime(0.08, t);
    humOsc.connect(humGain);

    // Gentle lo-fi warm Rhodes-like chord drone (Cmaj7: C3, G3, B3, E4)
    const chordGain = ctx.createGain();
    chordGain.gain.setValueAtTime(0.045, t);

    const chordFreqs = [130.81, 196.00, 246.94, 329.63];
    const chordOscs = chordFreqs.map(f => {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(f, t);
      osc.connect(chordGain);
      return osc;
    });

    // Master vinyl sub-mix gain
    this.vinylGain = ctx.createGain();
    this.vinylGain.gain.setValueAtTime(0.0001, t);
    // Smooth 1.2s fade-in
    this.vinylGain.gain.linearRampToValueAtTime(0.28, t + 1.2);

    noiseSource.connect(bandpass);
    bandpass.connect(this.vinylGain);
    humGain.connect(this.vinylGain);
    chordGain.connect(this.vinylGain);

    this.vinylGain.connect(this.masterGain);

    noiseSource.start(t);
    humOsc.start(t);
    chordOscs.forEach(o => o.start(t));

    this.vinylNode = {
      noiseSource,
      humOsc,
      chordOscs,
      stop: () => {
        const stopTime = ctx.currentTime;
        if (this.vinylGain) {
          this.vinylGain.gain.linearRampToValueAtTime(0.0001, stopTime + 0.6);
          setTimeout(() => {
            try {
              noiseSource.stop();
              humOsc.stop();
              chordOscs.forEach(o => o.stop());
            } catch (e) {}
            this.vinylNode = null;
            this.vinylGain = null;
          }, 700);
        }
      }
    };
  }

  stopVinyl() {
    if (this.vinylNode) {
      this.vinylNode.stop();
    }
  }

  // MARK: - 3. Skateboard Deck Rock
  playSkateboardRock() {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    // Polyurethane bushing squeak/click + maple deck hollow knock
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const filter = ctx.createBiquadFilter();

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(450, t);

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(180, t);
    osc.frequency.exponentialRampToValueAtTime(65, t + 0.05);

    gain.gain.setValueAtTime(0.35, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.06);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    osc.start(t);
    osc.stop(t + 0.065);

    // Subtle rebound tap 75ms later
    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(140, t + 0.075);
    osc2.frequency.exponentialRampToValueAtTime(50, t + 0.12);

    gain2.gain.setValueAtTime(0.0, t);
    gain2.gain.setValueAtTime(0.18, t + 0.075);
    gain2.gain.exponentialRampToValueAtTime(0.001, t + 0.13);

    osc2.connect(gain2);
    gain2.connect(this.masterGain);

    osc2.start(t + 0.075);
    osc2.stop(t + 0.135);
  }

  // MARK: - 4. Physical Drop / Placement Settle Sound
  playPlacementSound(objectType = 'prop') {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    switch (objectType) {
      case 'book':
      case 'paper_note':
      case 'bookmark':
      case 'sticky_note': {
        // Soft matte paper tap / book page settle
        const noise = this.createNoiseBurst(ctx, 0.045, 650, 0.22);
        break;
      }
      case 'pebble':
      case 'mug':
      case 'clock': {
        // Ceramic / stone subtle click-thump
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(540, t);
        osc.frequency.exponentialRampToValueAtTime(220, t + 0.04);
        gain.gain.setValueAtTime(0.25, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.05);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(t);
        osc.stop(t + 0.055);
        break;
      }
      case 'skateboard': {
        this.playSkateboardRock();
        break;
      }
      case 'plant': {
        // Clay terracotta pot placement
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(260, t);
        osc.frequency.exponentialRampToValueAtTime(95, t + 0.06);
        gain.gain.setValueAtTime(0.28, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.07);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(t);
        osc.stop(t + 0.075);
        break;
      }
      default: {
        // Default warm wood surface contact thump
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(220, t);
        osc.frequency.exponentialRampToValueAtTime(70, t + 0.05);
        gain.gain.setValueAtTime(0.22, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.06);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(t);
        osc.stop(t + 0.065);
      }
    }
  }

  // MARK: - 5. Laptop / Tech Miniature Tap
  playLaptopTap() {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(1100, t);
    osc.frequency.exponentialRampToValueAtTime(400, t + 0.025);

    gain.gain.setValueAtTime(0.18, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.03);

    osc.connect(gain);
    gain.connect(this.masterGain);

    osc.start(t);
    osc.stop(t + 0.035);
  }

  // MARK: - 6. Cookie Calico Cat Meow
  playCatMeow() {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    // Sweet, soft miniature kitten meow (gliding sine wave 540Hz -> 720Hz -> 480Hz)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const filter = ctx.createBiquadFilter();

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(1800, t);

    osc.type = 'sine';
    osc.frequency.setValueAtTime(540, t);
    osc.frequency.linearRampToValueAtTime(740, t + 0.12);
    osc.frequency.exponentialRampToValueAtTime(460, t + 0.32);

    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.linearRampToValueAtTime(0.22, t + 0.06);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.35);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    osc.start(t);
    osc.stop(t + 0.36);
  }

  // MARK: - 7. Cookie Purr (Warm rhythmic rumble)
  playPurr(duration = 2.4) {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;

    // Low carrier oscillator (~26Hz) modulated by a 22Hz trembling LFO
    const carrier = ctx.createOscillator();
    carrier.type = 'sine';
    carrier.frequency.setValueAtTime(28, t);

    const lfo = ctx.createOscillator();
    lfo.type = 'sine';
    lfo.frequency.setValueAtTime(22, t);

    const lfoGain = ctx.createGain();
    lfoGain.gain.setValueAtTime(14, t);
    lfo.connect(carrier.frequency);

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(120, t);

    const purrGain = ctx.createGain();
    purrGain.gain.setValueAtTime(0.0001, t);
    purrGain.gain.linearRampToValueAtTime(0.35, t + 0.4);
    purrGain.gain.setValueAtTime(0.35, t + duration - 0.4);
    purrGain.gain.exponentialRampToValueAtTime(0.0001, t + duration);

    carrier.connect(filter);
    filter.connect(purrGain);
    purrGain.connect(this.masterGain);

    carrier.start(t);
    lfo.start(t);
    carrier.stop(t + duration);
    lfo.stop(t + duration);
  }

  createNoiseBurst(ctx, duration, freq, maxGain) {
    const t = ctx.currentTime;
    const bufferSize = Math.floor(ctx.sampleRate * duration);
    const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const output = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.3));
    }

    const whiteNoise = ctx.createBufferSource();
    whiteNoise.buffer = noiseBuffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(freq, t);
    filter.Q.setValueAtTime(1.5, t);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(maxGain, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + duration);

    whiteNoise.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    whiteNoise.start(t);
    whiteNoise.stop(t + duration);
  }

  // MARK: - 9. Brass Pin / Thought Favorite Chime
  playPinSound(isPinned = true) {
    if (this.isMuted) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    const startFreq = isPinned ? 1760 : 2349;
    const endFreq = isPinned ? 2637 : 1760;

    osc.frequency.setValueAtTime(startFreq, t);
    osc.frequency.exponentialRampToValueAtTime(endFreq, t + 0.08);

    gain.gain.setValueAtTime(0.18, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);

    osc.connect(gain);
    gain.connect(this.masterGain);

    osc.start(t);
    osc.stop(t + 0.24);
  }
}

// Global Sound Instance
export const soundManager = new SoundManager();
