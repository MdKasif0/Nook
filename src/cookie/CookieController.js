/**
 * Nook 3D - CookieController
 * Articulated 3D companion cat controller integrating:
 * - CookieModel: Articulated procedural 3D chibi model matching reference visual specifications
 * - CookieAnimationController: Centralized THREE.AnimationMixer with all 17 required feline clips
 * - CookieNavigationController: Lightweight surface navigation (Floor, Bed, Desk, WindowSill, CatBed, Ottoman)
 * - CookieStateMachine: Controlled FSM with all 11 states and multi-step routines
 * - Tactile physical dragging (cursor tracking, reactive ears, gentle drop settling)
 * - Randomized click interactions (head tilt, blink, happy face, tiny meow)
 * - Full persistence across application restarts
 */

import * as THREE from 'three';
import { InteractiveObject } from '../objects/InteractiveObject.js';
import { CookieModel } from './CookieModel.js';
import { CookieAnimationController, COOKIE_ANIM_STATES } from './CookieAnimationController.js';
import { CookieNavigationController, WALKABLE_SURFACES } from './CookieNavigationController.js';
import { CookieStateMachine, COOKIE_STATES } from './CookieStateMachine.js';
import { soundManager } from '../audio/SoundManager.js';

export class CookieController extends InteractiveObject {
  constructor(roomScene) {
    super({
      id: 'prop_cookie',
      name: 'Cookie the Cat',
      category: 'character',
      objectType: 'cat',
      isMovable: true,
      isDraggable: true,
      isSelectable: true,
      isRotatable: true,
      isDeletable: false,
      collisionRadius: 0.22,
      accessibilityLabel: 'Cookie the adorable companion cat'
    });

    this.roomScene = roomScene;

    // 1. Build and attach the articulated 3D chibi model
    const built = CookieModel.build();
    this.modelRoot = built.root;
    this.rig = built.rig;
    this.visualRoot.add(this.modelRoot);

    // 2. Animation Controller driven by THREE.AnimationMixer
    this.animController = new CookieAnimationController(this.modelRoot);

    // 3. Navigation Controller
    this.navController = new CookieNavigationController(this);

    // 4. State Machine (11 states)
    this.stateMachine = new CookieStateMachine(this);

    // 5. Click reaction history (prevents consecutive duplicates)
    this.recentReactions = [];
    this.possibleReactions = ['head_tilt', 'blink', 'happy_face', 'sweet_meow', 'playful_pounce'];

    // 6. Initial position: Bed sun spot (matching reference painting)
    this.position.set(2.0, 1.30, -0.42);
    this.rotation.y = -0.7;
    this.currentArea = 'Bed';

    // Start in peaceful sleep loaf
    this.stateMachine.transitionTo(COOKIE_STATES.SLEEPING, { force: true });

    // Wire special action for direct click
    this.specialAction = () => this.handleUserClick();

    // Attach to room scene
    if (this.roomScene && this.roomScene.cookieGroup) {
      this.roomScene.cookieGroup.add(this);
    }
  }

  // MARK: - User Click Reaction System

  /**
   * Click Cookie: Triggers one of the varied randomized reactions:
   * - head tilt
   * - blink
   * - happy face
   * - tiny meow
   * Guaranteed never to repeat the same reaction consecutively.
   */
  handleUserClick() {
    // Pick reaction not in recent history
    const available = this.possibleReactions.filter(r => !this.recentReactions.includes(r));
    const chosen = available.length > 0 
      ? available[Math.floor(Math.random() * available.length)]
      : this.possibleReactions[Math.floor(Math.random() * this.possibleReactions.length)];

    this.recentReactions.push(chosen);
    if (this.recentReactions.length > 2) {
      this.recentReactions.shift();
    }

    switch (chosen) {
      case 'head_tilt':
        this.stateMachine.transitionTo(COOKIE_STATES.CURIOUS);
        this.animController.playOnce(COOKIE_ANIM_STATES.HEAD_TILT, () => {
          this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
        });
        soundManager.playCatMeow();
        break;

      case 'blink':
        this.animController.playOnce(COOKIE_ANIM_STATES.BLINK, () => {
          this.stateMachine.transitionTo(COOKIE_STATES.IDLE);
        });
        soundManager.playPurr(2.5);
        break;

      case 'happy_face':
        this.stateMachine.transitionTo(COOKIE_STATES.HAPPY);
        setTimeout(() => {
          if (this.stateMachine.currentState === COOKIE_STATES.HAPPY) {
            this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
          }
        }, 3200);
        break;

      case 'sweet_meow':
        this.animController.playOnce(COOKIE_ANIM_STATES.YAWN, () => {
          this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
        });
        soundManager.playCatMeow();
        break;

      case 'playful_pounce':
        this.stateMachine.transitionTo(COOKIE_STATES.PLAYING);
        setTimeout(() => {
          if (this.stateMachine.currentState === COOKIE_STATES.PLAYING) {
            this.stateMachine.transitionTo(COOKIE_STATES.IDLE);
          }
        }, 3000);
        break;
    }
  }

  // MARK: - Dragging Lifecycle Handlers

  onDragStart(hitPoint) {
    super.onDragStart(hitPoint);

    // Enter beingDragged state
    this.stateMachine.transitionTo(COOKIE_STATES.BEING_DRAGGED);

    // Body lifts slightly
    this.targetElevation = 0.24;

    // Ears react (tilt back slightly in surprised airplane pose)
    if (this.rig.earLGroup) this.rig.earLGroup.rotation.z = 0.65;
    if (this.rig.earRGroup) this.rig.earRGroup.rotation.z = -0.65;

    // Play soft inquisitive chirp / purr
    soundManager.playCatMeow();
  }

  onDragUpdate(targetPos) {
    const prevPos = this.position.clone();
    super.onDragUpdate(targetPos);

    // Cookie looks toward cursor motion direction
    const vx = targetPos.x - prevPos.x;
    const vz = targetPos.z - prevPos.z;

    if (Math.hypot(vx, vz) > 0.005) {
      const angle = Math.atan2(vx, vz);
      // Turn head smoothly towards drag motion
      if (this.rig.headGroup) {
        this.rig.headGroup.rotation.y = THREE.MathUtils.lerp(
          this.rig.headGroup.rotation.y,
          (angle - this.rotation.y) * 0.4,
          0.2
        );
      }
    }
  }

  onDragEnd(finalSurfacePosition, isValid = true, targetRotation = null) {
    super.onDragEnd(finalSurfacePosition, isValid, targetRotation);

    // Reset ear pose
    if (this.rig.earLGroup) this.rig.earLGroup.rotation.z = 0.35;
    if (this.rig.earRGroup) this.rig.earRGroup.rotation.z = -0.35;
    if (this.rig.headGroup) this.rig.headGroup.rotation.y = 0;

    // Cookie lands gently
    this.targetElevation = 0.0;

    // Detect which surface Cookie was placed on
    const detectedSurface = this.navController.getSurfaceForPosition(finalSurfacePosition || this.position);
    this.currentArea = detectedSurface;

    // Play gentle landing animation
    if (this.animController) {
      this.animController.playOnce(COOKIE_ANIM_STATES.LAND, () => {
        // Contextual surface reaction on drop
        if (detectedSurface === 'Bed') {
          // If placed on bed, settle into sleep after a moment
          this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
          setTimeout(() => {
            if (this.currentArea === 'Bed' && this.stateMachine.currentState === COOKIE_STATES.SITTING) {
              this.stateMachine.transitionTo(COOKIE_STATES.SLEEPING);
            }
          }, 2400);
        } else if (detectedSurface === 'CatBed') {
          // If placed on bouclé cat bed, curl up
          this.stateMachine.transitionTo(COOKIE_STATES.SLEEPING);
        } else if (detectedSurface === 'Desk') {
          // On desk: sit and look curious
          this.stateMachine.transitionTo(COOKIE_STATES.CURIOUS);
        } else {
          // On floor or ottoman: sit comfortably
          this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
        }
      });
    }

    soundManager.playPlacementSound('cat');
  }

  // MARK: - Specialized Sequence Triggers

  goToBed() {
    this.currentArea = 'Bed';
    this.stateMachine.startBedSequence();
  }

  goToDesk() {
    this.currentArea = 'Desk';
    this.stateMachine.startDeskSequence();
  }

  goToWindow() {
    this.currentArea = 'WindowSill';
    this.stateMachine.startWindowSequence();
  }

  goToCatBed() {
    this.currentArea = 'CatBed';
    this.stateMachine.startCatBedSequence();
  }

  wander() {
    const randomNodes = ['floor_rug', 'floor_center', 'floor_near_ottoman', 'floor_near_bed'];
    const chosen = randomNodes[Math.floor(Math.random() * randomNodes.length)];
    this.navController.navigateToNode(chosen, () => {
      this.stateMachine.transitionTo(COOKIE_STATES.SITTING);
    });
  }

  // MARK: - Persistence Serialization

  serializeState() {
    return {
      position: {
        x: Number(this.position.x.toFixed(3)),
        y: Number(this.position.y.toFixed(3)),
        z: Number(this.position.z.toFixed(3))
      },
      rotationY: Number(this.rotation.y.toFixed(3)),
      preferredArea: this.currentArea || 'Bed',
      basicState: this.stateMachine.currentState || 'sleeping'
    };
  }

  restoreState(saved) {
    if (!saved) return;

    if (saved.position) {
      this.position.set(saved.position.x, saved.position.y, saved.position.z);
      this.previousValidPosition.copy(this.position);
    }

    if (saved.rotationY !== undefined) {
      this.rotation.y = saved.rotationY;
      this.previousValidRotation.copy(this.rotation);
    }

    if (saved.preferredArea) {
      this.currentArea = saved.preferredArea;
    }

    if (saved.basicState && this.stateMachine) {
      this.stateMachine.transitionTo(saved.basicState, { force: true });
    }
  }

  // MARK: - Frame Update Loop

  update(delta) {
    super.update(delta);

    // 1. Advance THREE.AnimationMixer
    if (this.animController) {
      this.animController.update(delta);
    }

    // 2. Update navigation and path motion
    if (this.navController) {
      this.navController.update(delta);
    }

    // 3. Update behavioral state machine
    if (this.stateMachine) {
      this.stateMachine.update(delta);
    }
  }
}
