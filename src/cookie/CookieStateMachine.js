/**
 * Nook 3D - CookieStateMachine
 * Finite State Machine coordinating Cookie the cat's feline behaviors.
 * States:
 * - idle: Relaxed standing/breathing
 * - walking: Moving along waypoints
 * - curious: Inquisitive head tilt / looking around
 * - sitting: Sitting on haunches
 * - sleeping: Curled loaf with deep peaceful breathing
 * - jumping: 5-phase parabolic jump arc
 * - playing: Butt wiggle and pounce
 * - beingDragged: User direct manipulation
 * - happy: Cheerful tail wag and perk
 * - sleepy: Big yawn and stretch
 * - grooming: Washing paws and face
 * 
 * Also coordinates multi-step contextual routines:
 * - Bed sequence: approach -> jump -> walk -> turn around -> sit -> lie down -> sleep
 * - Desk sequence: jump onto desk -> inspect laptop -> look at monitor -> sit -> leave
 * - Window sequence: sit near window -> look outside
 * - Cat bed sequence: walk into cat bed -> curl up
 */

import { COOKIE_ANIM_STATES } from './CookieAnimationController.js';
import { soundManager } from '../audio/SoundManager.js';

export const COOKIE_STATES = {
  IDLE: 'idle',
  WALKING: 'walking',
  CURIOUS: 'curious',
  SITTING: 'sitting',
  SLEEPING: 'sleeping',
  JUMPING: 'jumping',
  PLAYING: 'playing',
  BEING_DRAGGED: 'beingDragged',
  HAPPY: 'happy',
  SLEEPY: 'sleepy',
  GROOMING: 'grooming'
};

export class CookieStateMachine {
  constructor(cookieEntity) {
    this.cookie = cookieEntity;
    this.currentState = COOKIE_STATES.SLEEPING;
    this.stateTimer = 0;
    this.stateDuration = 8.0; // Seconds in current autonomous state

    // Autonomous behavior cycle timer
    this.autonomousTimer = 0;
    this.autonomousInterval = 12.0;

    // Sequence execution state
    this.activeSequence = null;
    this.sequenceStep = 0;
    this.sequenceTimer = 0;
  }

  /**
   * Transition to a new state with controlled enter/exit hooks.
   */
  transitionTo(newState, params = {}) {
    if (this.currentState === newState && !params.force) {
      return;
    }

    const prevState = this.currentState;
    this.onExitState(prevState);

    this.currentState = newState;
    this.stateTimer = 0;
    this.onEnterState(newState, prevState, params);
  }

  onEnterState(state, prevState, params) {
    const anim = this.cookie.animController;

    switch (state) {
      case COOKIE_STATES.IDLE:
        this.stateDuration = 4.0 + Math.random() * 5.0;
        if (anim) anim.play(COOKIE_ANIM_STATES.IDLE, 0.3);
        break;

      case COOKIE_STATES.WALKING:
        if (anim) anim.play(COOKIE_ANIM_STATES.WALK, 0.2);
        break;

      case COOKIE_STATES.CURIOUS:
        this.stateDuration = 3.6;
        if (anim) {
          const clip = Math.random() > 0.5 ? COOKIE_ANIM_STATES.CURIOUS : COOKIE_ANIM_STATES.LOOK_AROUND;
          anim.play(clip, 0.3);
        }
        break;

      case COOKIE_STATES.SITTING:
        this.stateDuration = 6.0 + Math.random() * 8.0;
        if (anim) anim.play(COOKIE_ANIM_STATES.SIT, 0.35);
        break;

      case COOKIE_STATES.SLEEPING:
        this.stateDuration = 18.0 + Math.random() * 15.0;
        if (anim) anim.play(COOKIE_ANIM_STATES.SLEEP, 0.5);
        break;

      case COOKIE_STATES.JUMPING:
        // Jump is driven by CookieNavigationController
        break;

      case COOKIE_STATES.PLAYING:
        this.stateDuration = 3.0;
        if (anim) anim.play(COOKIE_ANIM_STATES.PLAY, 0.25);
        soundManager.playCatMeow();
        break;

      case COOKIE_STATES.BEING_DRAGGED:
        // User is directly manipulating Cookie
        if (anim) anim.play(COOKIE_ANIM_STATES.CURIOUS, 0.2);
        break;

      case COOKIE_STATES.HAPPY:
        this.stateDuration = 3.5;
        if (anim) anim.play(COOKIE_ANIM_STATES.HAPPY, 0.25);
        soundManager.playCatMeow();
        soundManager.playPurr(3.5);
        break;

      case COOKIE_STATES.SLEEPY:
        this.stateDuration = 3.2;
        if (anim) {
          const clip = Math.random() > 0.5 ? COOKIE_ANIM_STATES.YAWN : COOKIE_ANIM_STATES.STRETCH;
          anim.play(clip, 0.3);
        }
        break;

      case COOKIE_STATES.GROOMING:
        this.stateDuration = 4.0;
        if (anim) anim.play(COOKIE_ANIM_STATES.GROOM, 0.35);
        break;
    }
  }

  onExitState(state) {
    // Cleanup if needed
  }

  /**
   * Main per-frame update loop.
   */
  update(delta) {
    this.stateTimer += delta;

    // Handle active multi-step routines
    if (this.activeSequence) {
      this.updateSequence(delta);
      return;
    }

    // Do not auto-cycle if being dragged or jumping
    if (this.currentState === COOKIE_STATES.BEING_DRAGGED || this.currentState === COOKIE_STATES.JUMPING) {
      return;
    }

    // Autonomous behavior cycle
    this.autonomousTimer += delta;
    if (this.autonomousTimer > this.autonomousInterval) {
      this.autonomousTimer = 0;
      this.triggerAutonomousAction();
    }
  }

  /**
   * Gentle, natural feline idle behaviors when not performing a sequence.
   */
  triggerAutonomousAction() {
    if (this.currentState === COOKIE_STATES.SLEEPING) {
      // 20% chance to wake up and stretch
      if (Math.random() < 0.25) {
        this.transitionTo(COOKIE_STATES.SLEEPY);
        setTimeout(() => {
          if (this.currentState === COOKIE_STATES.SLEEPY) {
            this.transitionTo(COOKIE_STATES.SITTING);
          }
        }, 3000);
      }
      return;
    }

    if (this.currentState === COOKIE_STATES.SITTING || this.currentState === COOKIE_STATES.IDLE) {
      const roll = Math.random();
      if (roll < 0.3) {
        this.transitionTo(COOKIE_STATES.CURIOUS);
      } else if (roll < 0.55) {
        this.transitionTo(COOKIE_STATES.GROOMING);
      } else if (roll < 0.75) {
        this.transitionTo(COOKIE_STATES.SLEEPY);
      } else {
        // Return to sitting or sleeping
        this.transitionTo(COOKIE_STATES.SLEEPING);
      }
    }
  }

  // MARK: - Specialized Multi-step Sequences

  /**
   * BED SEQUENCE:
   * 1. Approach valid floor location near bed
   * 2. Jump onto bed
   * 3. Walk short distance across bed
   * 4. Turn around
   * 5. Sit
   * 6. Lie down
   * 7. Sleep
   */
  startBedSequence(onComplete = null) {
    this.activeSequence = 'bed';
    this.sequenceStep = 1;
    this.sequenceTimer = 0;
    this.sequenceCallback = onComplete;
    this.executeBedStep();
  }

  executeBedStep() {
    const nav = this.cookie.navController;
    const anim = this.cookie.animController;

    switch (this.sequenceStep) {
      case 1:
        // Approach floor location near bed
        this.transitionTo(COOKIE_STATES.WALKING);
        nav.navigateToNode('floor_near_bed', () => {
          this.sequenceStep = 2;
          this.executeBedStep();
        });
        break;

      case 2:
        // Jump onto bed
        this.transitionTo(COOKIE_STATES.JUMPING);
        const bedEdge = nav.nodes.bed_edge.position;
        nav.initiateJump(bedEdge, () => {
          this.sequenceStep = 3;
          this.executeBedStep();
        });
        break;

      case 3:
        // Walk a short distance to the sun spot
        this.transitionTo(COOKIE_STATES.WALKING);
        const sunSpot = nav.nodes.bed_sun_spot.position;
        nav.startPath([nav.nodes.bed_sun_spot], () => {
          this.sequenceStep = 4;
          this.executeBedStep();
        });
        break;

      case 4:
        // Turn around (find cozy angle)
        this.transitionTo(COOKIE_STATES.IDLE);
        let turnTime = 0;
        const targetRotY = -0.7; // Cozy sunny angle
        const startRotY = this.cookie.rotation.y;
        const turnInterval = setInterval(() => {
          turnTime += 0.05;
          this.cookie.rotation.y = THREE.MathUtils.lerp(startRotY, targetRotY, Math.min(turnTime / 0.8, 1.0));
          if (turnTime >= 0.8) {
            clearInterval(turnInterval);
            this.sequenceStep = 5;
            this.executeBedStep();
          }
        }, 50);
        break;

      case 5:
        // Sit down
        this.transitionTo(COOKIE_STATES.SITTING);
        setTimeout(() => {
          this.sequenceStep = 6;
          this.executeBedStep();
        }, 1400);
        break;

      case 6:
        // Lie down into loaf
        if (anim) anim.play(COOKIE_ANIM_STATES.SLEEP, 0.6);
        setTimeout(() => {
          this.sequenceStep = 7;
          this.executeBedStep();
        }, 1200);
        break;

      case 7:
        // Sleep peacefully
        this.transitionTo(COOKIE_STATES.SLEEPING);
        this.activeSequence = null;
        if (this.sequenceCallback) {
          const cb = this.sequenceCallback;
          this.sequenceCallback = null;
          cb();
        }
        break;
    }
  }

  /**
   * DESK SEQUENCE:
   * 1. Approach desk
   * 2. Jump onto desk
   * 3. Inspect laptop
   * 4. Look at monitor
   * 5. Sit
   * 6. Eventually leave
   */
  startDeskSequence(onComplete = null) {
    this.activeSequence = 'desk';
    this.sequenceStep = 1;
    this.sequenceTimer = 0;
    this.sequenceCallback = onComplete;
    this.executeDeskStep();
  }

  executeDeskStep() {
    const nav = this.cookie.navController;
    const anim = this.cookie.animController;

    switch (this.sequenceStep) {
      case 1:
        // Approach floor location near desk
        this.transitionTo(COOKIE_STATES.WALKING);
        nav.navigateToNode('floor_near_desk', () => {
          this.sequenceStep = 2;
          this.executeDeskStep();
        });
        break;

      case 2:
        // Jump onto desk edge
        this.transitionTo(COOKIE_STATES.JUMPING);
        const deskEdge = nav.nodes.desk_edge.position;
        nav.initiateJump(deskEdge, () => {
          this.sequenceStep = 3;
          this.executeDeskStep();
        });
        break;

      case 3:
        // Walk over to inspect laptop
        this.transitionTo(COOKIE_STATES.WALKING);
        nav.startPath([nav.nodes.desk_laptop], () => {
          this.sequenceStep = 4;
          this.executeDeskStep();
        });
        break;

      case 4:
        // Inspect laptop (curious sniff)
        this.transitionTo(COOKIE_STATES.CURIOUS);
        if (anim) anim.play(COOKIE_ANIM_STATES.CURIOUS, 0.25);
        setTimeout(() => {
          this.sequenceStep = 5;
          this.executeDeskStep();
        }, 2500);
        break;

      case 5:
        // Look up at monitor
        if (anim) anim.play(COOKIE_ANIM_STATES.LOOK_AROUND, 0.3);
        setTimeout(() => {
          this.sequenceStep = 6;
          this.executeDeskStep();
        }, 2800);
        break;

      case 6:
        // Sit companionably next to keyboard
        this.transitionTo(COOKIE_STATES.SITTING);
        this.activeSequence = null;
        if (this.sequenceCallback) {
          const cb = this.sequenceCallback;
          this.sequenceCallback = null;
          cb();
        }
        break;
    }
  }

  /**
   * WINDOW SEQUENCE:
   * 1. Navigate towards window (via bed or sill)
   * 2. Step onto window sill
   * 3. Sit near window
   * 4. Look outside
   */
  startWindowSequence(onComplete = null) {
    this.activeSequence = 'window';
    this.sequenceStep = 1;
    this.sequenceTimer = 0;
    this.sequenceCallback = onComplete;
    this.executeWindowStep();
  }

  executeWindowStep() {
    const nav = this.cookie.navController;
    const anim = this.cookie.animController;

    switch (this.sequenceStep) {
      case 1:
        // Go to bed approach to window
        this.transitionTo(COOKIE_STATES.WALKING);
        nav.navigateToNode('bed_window_approach', () => {
          this.sequenceStep = 2;
          this.executeWindowStep();
        });
        break;

      case 2:
        // Jump onto window sill
        this.transitionTo(COOKIE_STATES.JUMPING);
        const sillPos = nav.nodes.window_sill.position;
        nav.initiateJump(sillPos, () => {
          this.sequenceStep = 3;
          this.executeWindowStep();
        });
        break;

      case 3:
        // Sit and face the window
        this.transitionTo(COOKIE_STATES.SITTING);
        this.cookie.rotation.y = Math.PI * 0.5; // Look out the window to the right
        setTimeout(() => {
          this.sequenceStep = 4;
          this.executeWindowStep();
        }, 1500);
        break;

      case 4:
        // Look outside at the sunlight / birds
        this.transitionTo(COOKIE_STATES.CURIOUS);
        if (anim) anim.play(COOKIE_ANIM_STATES.LOOK_AROUND, 0.3);
        this.activeSequence = null;
        if (this.sequenceCallback) {
          const cb = this.sequenceCallback;
          this.sequenceCallback = null;
          cb();
        }
        break;
    }
  }

  /**
   * CAT BED SEQUENCE:
   * 1. Walk into cat bed
   * 2. Curl up into bouclé pouf
   */
  startCatBedSequence(onComplete = null) {
    this.activeSequence = 'catbed';
    this.sequenceStep = 1;
    this.sequenceTimer = 0;
    this.sequenceCallback = onComplete;
    this.executeCatBedStep();
  }

  executeCatBedStep() {
    const nav = this.cookie.navController;
    const anim = this.cookie.animController;

    switch (this.sequenceStep) {
      case 1:
        // Navigate down to cat bed
        this.transitionTo(COOKIE_STATES.WALKING);
        nav.navigateToNode('catbed_center', () => {
          this.sequenceStep = 2;
          this.executeCatBedStep();
        });
        break;

      case 2:
        // Settle and curl up
        this.transitionTo(COOKIE_STATES.SITTING);
        this.cookie.rotation.y = -1.2;
        setTimeout(() => {
          this.transitionTo(COOKIE_STATES.SLEEPING);
          this.activeSequence = null;
          if (this.sequenceCallback) {
            const cb = this.sequenceCallback;
            this.sequenceCallback = null;
            cb();
          }
        }, 1600);
        break;
    }
  }

  updateSequence(delta) {
    this.sequenceTimer += delta;
  }
}
