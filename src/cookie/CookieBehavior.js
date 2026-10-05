/**
 * Nook 3D - CookieBehavior
 * Deterministic, calm feline behavior engine.
 * Manages moods, purring, sleeping, and vocalizations.
 */

import { soundManager } from '../audio/SoundManager.js';

export const COOKIE_MOODS = {
  SLEEPING: 'sleeping',
  SETTLING: 'settling',
  WAKING: 'waking',
  IDLE: 'idle',
  HAPPY: 'happy',
  CURIOUS: 'curious'
};

export class CookieBehavior {
  constructor(cookieEntity) {
    this.cookie = cookieEntity;
    this.currentMood = COOKIE_MOODS.SLEEPING; // Starts sleeping in the sun as in the reference!
    this.moodTimer = 0;
    this.isPurring = false;
  }

  setMood(newMood) {
    this.currentMood = newMood;
    this.moodTimer = 0;
    this.applyMoodVisuals();
  }

  applyMoodVisuals() {
    switch (this.currentMood) {
      case COOKIE_MOODS.SLEEPING:
        this.cookie.setEyesClosed(true);
        this.cookie.setCurledPose(true);
        break;
      case COOKIE_MOODS.HAPPY:
        this.cookie.setEyesClosed(true);
        this.cookie.setCurledPose(false);
        this.playAudio('happyMeow');
        this.startPurr();
        break;
      case COOKIE_MOODS.CURIOUS:
        this.cookie.setEyesClosed(false);
        this.cookie.setCurledPose(false);
        this.playAudio('curiousChirp');
        break;
      case COOKIE_MOODS.IDLE:
      default:
        this.cookie.setEyesClosed(false);
        this.cookie.setCurledPose(false);
        this.stopPurr();
        break;
    }
  }

  playAudio() {
    soundManager.playCatMeow();
  }

  startPurr() {
    if (this.isPurring) return;
    this.isPurring = true;
    soundManager.playPurr(4.0);
  }

  stopPurr() {
    this.isPurring = false;
  }

  pet() {
    this.setMood(COOKIE_MOODS.HAPPY);
    this.cookie.triggerPetBounce();
    soundManager.playCatMeow();
    soundManager.playPurr(3.2);

    setTimeout(() => {
      if (this.currentMood === COOKIE_MOODS.HAPPY) {
        this.setMood(COOKIE_MOODS.IDLE);
      }
    }, 2800);
  }

  update(delta) {
    this.moodTimer += delta;

    // Organic breathing motion when sleeping
    if (this.currentMood === COOKIE_MOODS.SLEEPING) {
      const breath = Math.sin(performance.now() * 0.002) * 0.02;
      this.cookie.bodyMesh.scale.set(1.0 + breath, 1.0 + breath * 0.6, 1.0 + breath);
    }
  }
}
