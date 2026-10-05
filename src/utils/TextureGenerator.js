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

    // Base warm honey gradient
    const grad = ctx.createLinearGradient(0, 0, width, 0);
    grad.addColorStop(0.0, '#d69e60');
    grad.addColorStop(0.3, '#dca668');
    grad.addColorStop(0.6, '#cf9556');
    grad.addColorStop(1.0, '#d9a163');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, width, height);

    // Subtle longitudinal wood grain lines
    ctx.globalAlpha = 0.07;
    for (let y = 0; y < height; y += 2) {
      const lineGrad = ctx.createLinearGradient(0, y, width, y);
      const tone = Math.sin(y * 0.08) * 20;
      lineGrad.addColorStop(0.0, tone > 0 ? '#9b632e' : '#eec28b');
      lineGrad.addColorStop(0.5, tone > 0 ? '#b87c3f' : '#f4d2a3');
      lineGrad.addColorStop(1.0, tone > 0 ? '#8e5625' : '#e6b579');
      ctx.fillStyle = lineGrad;
      ctx.fillRect(0, y, width, 1.5);
    }

    // Organic wavy grain streaks
    ctx.globalAlpha = 0.04;
    ctx.strokeStyle = '#7c481d';
    ctx.lineWidth = 3;
    for (let i = 0; i < 24; i++) {
      ctx.beginPath();
      const startY = Math.random() * height;
      ctx.moveTo(0, startY);
      for (let x = 0; x < width; x += 40) {
        const wave = Math.sin(x * 0.015 + i) * 18 + Math.cos(x * 0.005) * 12;
        ctx.lineTo(x, startY + wave);
      }
      ctx.stroke();
    }

    // Fine organic fibers
    ctx.globalAlpha = 0.03;
    ctx.fillStyle = '#653a15';
    for (let i = 0; i < 3000; i++) {
      const rx = Math.random() * width;
      const ry = Math.random() * height;
      const rw = Math.random() * 24 + 6;
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
      '#d39a5c', '#c98e50', '#dcab6d', '#cf9558',
      '#d7a164', '#c58a4c', '#daa469', '#ce9457'
    ];

    for (let i = 0; i < plankCount; i++) {
      const y = i * plankHeight;
      const baseColor = plankTones[i % plankTones.length];

      // Plank base
      ctx.fillStyle = baseColor;
      ctx.fillRect(0, y, width, plankHeight);

      // Subtle internal grain
      ctx.globalAlpha = 0.06;
      ctx.fillStyle = '#6e3c14';
      for (let g = 0; g < 6; g++) {
        const gy = y + Math.random() * plankHeight;
        ctx.fillRect(0, gy, width, Math.random() * 2 + 1);
      }

      // Plank bevel / shadow groove at bottom
      ctx.globalAlpha = 0.28;
      ctx.fillStyle = '#553012';
      ctx.fillRect(0, y + plankHeight - 2.5, width, 2.5);

      // Plank top subtle highlight
      ctx.globalAlpha = 0.22;
      ctx.fillStyle = '#fbe3bf';
      ctx.fillRect(0, y, width, 1.5);

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
    ctx.fillStyle = '#f6efe3';
    ctx.fillRect(0, 0, width, height);

    // Subtle microscopic plaster stipple
    const imgData = ctx.getImageData(0, 0, width, height);
    const data = imgData.data;
    for (let i = 0; i < data.length; i += 4) {
      const noise = (Math.random() - 0.5) * 8;
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
