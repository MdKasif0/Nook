/**
 * Nook 3D - CookieBehavior
 * Deterministic, calm feline behavior engine.
 * Manages moods, purring, sleeping, and vocalizations.
 */

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

    this.audioClips = {
      purr: new Audio('/audio/cookie_purr.wav'),
      softMeow: new Audio('/audio/cookie_soft_meow.wav'),
      tinyMeow: new Audio('/audio/cookie_tiny_meow.wav'),
      happyMeow: new Audio('/audio/cookie_happy_meow.wav'),
      curiousChirp: new Audio('/audio/cookie_curious_chirp.wav'),
      sleepyMurmur: new Audio('/audio/cookie_sleepy_murmur.wav')
    };

    // Low default ambient volume
    for (const audio of Object.values(this.audioClips)) {
      audio.volume = 0.35;
    }
    this.audioClips.purr.loop = true;
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

  playAudio(clipName) {
    const clip = this.audioClips[clipName];
    if (clip) {
      clip.currentTime = 0;
      clip.play().catch(() => {
        // Autoplay policy fallback: audio plays gracefully on first user click
      });
    }
  }

  startPurr() {
    if (this.isPurring) return;
    this.isPurring = true;
    this.audioClips.purr.currentTime = 0;
    this.audioClips.purr.play().catch(() => {});
  }

  stopPurr() {
    if (!this.isPurring) return;
    this.isPurring = false;
    this.audioClips.purr.pause();
  }

  pet() {
    this.setMood(COOKIE_MOODS.HAPPY);
    this.cookie.triggerPetBounce();

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
