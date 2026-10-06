/**
 * Nook 3D - UndoManager
 * Reliable command/history architecture supporting Undo/Redo for:
 * - Create Thought
 * - Move Object
 * - Rotate Object
 * - Delete Thought
 */

import * as THREE from 'three';
import { thoughtStore } from '../persistence/ThoughtStore.js';

export class CreateThoughtCommand {
  constructor(objectManager, thoughtData) {
    this.objectManager = objectManager;
    this.thoughtData = { ...thoughtData };
  }

  execute() {
    thoughtStore.saveThought(this.thoughtData);
    const obj = this.objectManager.createThoughtObject(this.thoughtData.type, {
      id: this.thoughtData.id,
      title: this.thoughtData.title,
      content: this.thoughtData.content,
      type: this.thoughtData.type,
      position: new THREE.Vector3(this.thoughtData.position.x, this.thoughtData.position.y, this.thoughtData.position.z),
      rotation: new THREE.Euler(this.thoughtData.rotation.x, this.thoughtData.rotation.y, this.thoughtData.rotation.z),
      surface: this.thoughtData.surface
    });
    this.objectManager.registerObject(obj);
    return obj;
  }

  undo() {
    thoughtStore.deleteThought(this.thoughtData.id);
    this.objectManager.removeObject(this.thoughtData.id);
  }

  redo() {
    return this.execute();
  }
}

export class MoveObjectCommand {
  constructor(objectManager, objectId, prevPos, newPos, prevRot = null, newRot = null, prevSurface = null, newSurface = null) {
    this.objectManager = objectManager;
    this.objectId = objectId;
    this.prevPos = prevPos.clone();
    this.newPos = newPos.clone();
    this.prevRot = prevRot ? prevRot.clone() : null;
    this.newRot = newRot ? newRot.clone() : null;
    this.prevSurface = prevSurface;
    this.newSurface = newSurface;
  }

  undo() {
    const obj = this.objectManager.getObjectById(this.objectId);
    if (obj) {
      obj.position.copy(this.prevPos);
      obj.previousValidPosition.copy(this.prevPos);
      if (this.prevRot) {
        obj.rotation.copy(this.prevRot);
        obj.previousValidRotation.copy(this.prevRot);
      }
      thoughtStore.updateThought(this.objectId, {
        position: this.prevPos,
        rotation: this.prevRot || obj.rotation,
        surface: this.prevSurface
      });
    }
  }

  redo() {
    const obj = this.objectManager.getObjectById(this.objectId);
    if (obj) {
      obj.position.copy(this.newPos);
      obj.previousValidPosition.copy(this.newPos);
      if (this.newRot) {
        obj.rotation.copy(this.newRot);
        obj.previousValidRotation.copy(this.newRot);
      }
      thoughtStore.updateThought(this.objectId, {
        position: this.newPos,
        rotation: this.newRot || obj.rotation,
        surface: this.newSurface
      });
    }
  }
}

export class RotateObjectCommand {
  constructor(objectManager, objectId, prevRot, newRot) {
    this.objectManager = objectManager;
    this.objectId = objectId;
    this.prevRot = prevRot.clone();
    this.newRot = newRot.clone();
  }

  undo() {
    const obj = this.objectManager.getObjectById(this.objectId);
    if (obj) {
      obj.rotation.copy(this.prevRot);
      obj.previousValidRotation.copy(this.prevRot);
      thoughtStore.updateThought(this.objectId, { rotation: this.prevRot });
    }
  }

  redo() {
    const obj = this.objectManager.getObjectById(this.objectId);
    if (obj) {
      obj.rotation.copy(this.newRot);
      obj.previousValidRotation.copy(this.newRot);
      thoughtStore.updateThought(this.objectId, { rotation: this.newRot });
    }
  }
}

export class DeleteThoughtCommand {
  constructor(objectManager, thoughtData) {
    this.objectManager = objectManager;
    this.thoughtData = { ...thoughtData };
  }

  execute() {
    thoughtStore.deleteThought(this.thoughtData.id);
    this.objectManager.removeObject(this.thoughtData.id);
  }

  undo() {
    thoughtStore.saveThought(this.thoughtData);
    const obj = this.objectManager.createThoughtObject(this.thoughtData.type, {
      id: this.thoughtData.id,
      title: this.thoughtData.title,
      content: this.thoughtData.content,
      type: this.thoughtData.type,
      position: new THREE.Vector3(this.thoughtData.position.x, this.thoughtData.position.y, this.thoughtData.position.z),
      rotation: new THREE.Euler(this.thoughtData.rotation.x, this.thoughtData.rotation.y, this.thoughtData.rotation.z),
      surface: this.thoughtData.surface
    });
    this.objectManager.registerObject(obj);
    return obj;
  }

  redo() {
    this.execute();
  }
}

export class UndoManager {
  constructor() {
    this.undoStack = [];
    this.redoStack = [];
    this.maxHistory = 50;
  }

  push(command) {
    if (!command) return;
    this.undoStack.push(command);
    if (this.undoStack.length > this.maxHistory) {
      this.undoStack.shift();
    }
    this.redoStack = []; // Clear redo stack on new action
  }

  undo() {
    if (this.undoStack.length === 0) return null;
    const cmd = this.undoStack.pop();
    cmd.undo();
    this.redoStack.push(cmd);
    return cmd;
  }

  redo() {
    if (this.redoStack.length === 0) return null;
    const cmd = this.redoStack.pop();
    cmd.redo();
    this.undoStack.push(cmd);
    return cmd;
  }

  canUndo() {
    return this.undoStack.length > 0;
  }

  canRedo() {
    return this.redoStack.length > 0;
  }

  clear() {
    this.undoStack = [];
    this.redoStack = [];
  }
}

export const undoManager = new UndoManager();
