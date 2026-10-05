/**
 * Nook 3D - TextureGenerator
 * Procedural PBR canvas texture generation for warm honey wood, floor planks,
 * and ivory wall plaster. Ensures realistic tactile semi-matte appearance
 * matching nook-room.jpeg without external asset dependencies.
 */

import * as THREE from 'three';

export class TextureGenerator {
  /**
   * Generates warm natural honey-colored wood texture with subtle grain lines.
   */
  static createHoneyWoodTexture(width = 1024, height = 1024) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Base warm natural honey oak gradient
    const grad = ctx.createLinearGradient(0, 0, width, 0);
    grad.addColorStop(0.0, '#e0aa6a');
    grad.addColorStop(0.3, '#e7b679');
    grad.addColorStop(0.6, '#dba361');
    grad.addColorStop(1.0, '#e3af70');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, width, height);

    // Subtle longitudinal wood grain lines
    ctx.globalAlpha = 0.055;
    for (let y = 0; y < height; y += 2) {
      const lineGrad = ctx.createLinearGradient(0, y, width, y);
      const tone = Math.sin(y * 0.08) * 16;
      lineGrad.addColorStop(0.0, tone > 0 ? '#b27838' : '#f5d5a8');
      lineGrad.addColorStop(0.5, tone > 0 ? '#c78f4f' : '#fce3be');
      lineGrad.addColorStop(1.0, tone > 0 ? '#a86c2e' : '#f2cfa0');
      ctx.fillStyle = lineGrad;
      ctx.fillRect(0, y, width, 1.5);
    }

    // Organic wavy grain streaks
    ctx.globalAlpha = 0.03;
    ctx.strokeStyle = '#996029';
    ctx.lineWidth = 2.5;
    for (let i = 0; i < 20; i++) {
      ctx.beginPath();
      const startY = Math.random() * height;
      ctx.moveTo(0, startY);
      for (let x = 0; x < width; x += 40) {
        const wave = Math.sin(x * 0.015 + i) * 16 + Math.cos(x * 0.005) * 10;
        ctx.lineTo(x, startY + wave);
      }
      ctx.stroke();
    }

    // Delicate organic wood pores
    ctx.globalAlpha = 0.02;
    ctx.fillStyle = '#824e1e';
    for (let i = 0; i < 2200; i++) {
      const rx = Math.random() * width;
      const ry = Math.random() * height;
      const rw = Math.random() * 20 + 4;
      ctx.fillRect(rx, ry, rw, 1);
    }

    ctx.globalAlpha = 1.0;

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }

  /**
   * Generates wooden floor planks with distinct board grooves and tone variations.
   */
  static createFloorPlanksTexture(width = 1024, height = 1024, plankCount = 12) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    const plankHeight = height / plankCount;
    const plankTones = [
      '#dda464', '#d59b58', '#e5b275', '#d99f5e',
      '#e1a96c', '#d29653', '#e3ac70', '#d79d5b'
    ];

    for (let i = 0; i < plankCount; i++) {
      const y = i * plankHeight;
      const baseColor = plankTones[i % plankTones.length];

      // Plank base
      ctx.fillStyle = baseColor;
      ctx.fillRect(0, y, width, plankHeight);

      // Subtle internal grain
      ctx.globalAlpha = 0.045;
      ctx.fillStyle = '#8f5724';
      for (let g = 0; g < 5; g++) {
        const gy = y + Math.random() * plankHeight;
        ctx.fillRect(0, gy, width, Math.random() * 2 + 1);
      }

      // Plank bevel / shadow groove at bottom
      ctx.globalAlpha = 0.20;
      ctx.fillStyle = '#7a4a1f';
      ctx.fillRect(0, y + plankHeight - 2.0, width, 2.0);

      // Plank top subtle highlight
      ctx.globalAlpha = 0.18;
      ctx.fillStyle = '#fffaea';
      ctx.fillRect(0, y, width, 1.2);

      ctx.globalAlpha = 1.0;
    }

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }

  /**
   * Generates warm ivory/cream wall texture (#F4EBDD / #F7F0E5) with subtle matte plaster micro-texture.
   */
  static createWallCreamTexture(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Warm ivory base
    ctx.fillStyle = '#f8f2e7';
    ctx.fillRect(0, 0, width, height);

    // Subtle microscopic plaster stipple
    const imgData = ctx.getImageData(0, 0, width, height);
    const data = imgData.data;
    for (let i = 0; i < data.length; i += 4) {
      const noise = (Math.random() - 0.5) * 6;
      data[i] = Math.min(255, Math.max(0, data[i] + noise));
      data[i + 1] = Math.min(255, Math.max(0, data[i + 1] + noise * 0.9));
      data[i + 2] = Math.min(255, Math.max(0, data[i + 2] + noise * 0.8));
    }
    ctx.putImageData(imgData, 0, 0);

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }
}
