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

  /**
   * Generates sunny outdoor vista for the window: soft blue sky, warm sunlight glow,
   * lush green tree foliage, and subtle warm roof hints matching nook-room.jpeg.
   */
  static createOutdoorViewTexture(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Sky gradient with warm golden sun wash
    const skyGrad = ctx.createLinearGradient(0, 0, width, height);
    skyGrad.addColorStop(0.0, '#8ec5ed');
    skyGrad.addColorStop(0.4, '#c2e2f8');
    skyGrad.addColorStop(0.7, '#fcedd4');
    skyGrad.addColorStop(1.0, '#fae1c3');
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, width, height);

    // Distant soft warm architectural roofs
    ctx.fillStyle = '#cf896b';
    ctx.beginPath();
    ctx.moveTo(width * 0.45, height * 0.62);
    ctx.lineTo(width * 0.65, height * 0.52);
    ctx.lineTo(width * 0.85, height * 0.64);
    ctx.fill();

    // Soft dappled foliage cluster (trees outside window)
    const foliageColors = ['#5e934f', '#6ea75d', '#86bd71', '#9ecc83', '#b8df98'];
    for (let i = 0; i < 70; i++) {
      const cx = (Math.random() * 0.8 + 0.1) * width;
      const cy = (Math.random() * 0.5 + 0.45) * height;
      const radius = Math.random() * 38 + 18;
      ctx.fillStyle = foliageColors[i % foliageColors.length];
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, Math.PI * 2);
      ctx.fill();
    }

    // Atmospheric warm light bloom over treetops
    const sunGrad = ctx.createRadialGradient(width * 0.8, height * 0.2, 10, width * 0.8, height * 0.2, width * 0.7);
    sunGrad.addColorStop(0.0, 'rgba(255, 250, 230, 0.45)');
    sunGrad.addColorStop(0.5, 'rgba(255, 240, 210, 0.18)');
    sunGrad.addColorStop(1.0, 'rgba(255, 255, 255, 0.0)');
    ctx.fillStyle = sunGrad;
    ctx.fillRect(0, 0, width, height);

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates warm "hello ♡" display visual for the modern desktop monitor.
   */
  static createMonitorHelloTexture(width = 1024, height = 640) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Warm cream display background
    const bgGrad = ctx.createLinearGradient(0, 0, 0, height);
    bgGrad.addColorStop(0.0, '#faf6ee');
    bgGrad.addColorStop(0.65, '#f7f1e5');
    bgGrad.addColorStop(1.0, '#ede4d4');
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, width, height);

    // Subtle soft rolling watercolor green meadow hills at bottom
    ctx.fillStyle = '#b7d4a6';
    ctx.beginPath();
    ctx.moveTo(0, height * 0.72);
    ctx.bezierCurveTo(width * 0.25, height * 0.65, width * 0.65, height * 0.78, width, height * 0.68);
    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.fill();

    ctx.fillStyle = '#8ea87d';
    ctx.beginPath();
    ctx.moveTo(0, height * 0.80);
    ctx.bezierCurveTo(width * 0.35, height * 0.75, width * 0.75, height * 0.86, width, height * 0.78);
    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.fill();

    ctx.fillStyle = '#658256';
    ctx.beginPath();
    ctx.moveTo(0, height * 0.90);
    ctx.bezierCurveTo(width * 0.45, height * 0.88, width * 0.85, height * 0.94, width, height * 0.90);
    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.fill();

    // Elegant handwritten cursive "hello ♡"
    ctx.fillStyle = '#3a4249';
    ctx.font = 'italic bold 92px Georgia, "Times New Roman", serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('hello ♡', width * 0.5, height * 0.44);

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates woven botanical pattern rug texture for the desk area.
   */
  static createRugBotanicalTexture(width = 1024, height = 1024) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Warm ivory base
    ctx.fillStyle = '#f5ede1';
    ctx.fillRect(0, 0, width, height);

    // Woven texture noise
    ctx.globalAlpha = 0.05;
    ctx.fillStyle = '#6d5a42';
    for (let y = 0; y < height; y += 4) {
      ctx.fillRect(0, y, width, 1.5);
    }
    for (let x = 0; x < width; x += 4) {
      ctx.fillRect(x, 0, 1.5, height);
    }

    // Soft sage botanical leaf silhouettes
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = '#8ea889';

    const drawLeaf = (cx, cy, scale, angle) => {
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(angle);
      ctx.beginPath();
      ctx.ellipse(0, 0, 45 * scale, 18 * scale, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    };

    for (let i = 0; i < 28; i++) {
      const lx = (i % 6) * 170 + 80 + (Math.sin(i) * 20);
      const ly = Math.floor(i / 6) * 190 + 90 + (Math.cos(i) * 20);
      const angle = (i * 0.6) % Math.PI;
      drawLeaf(lx, ly, 1.0, angle);
      drawLeaf(lx + 30, ly + 20, 0.7, angle + 0.4);
      drawLeaf(lx - 25, ly - 20, 0.6, angle - 0.3);
    }

    // Border stitching
    ctx.globalAlpha = 0.4;
    ctx.strokeStyle = '#cbb89e';
    ctx.lineWidth = 14;
    ctx.strokeRect(30, 30, width - 60, height - 60);

    ctx.globalAlpha = 1.0;

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates realistic vinyl record texture with concentric microgrooves.
   */
  static createVinylTexture(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    const cx = width * 0.5;
    const cy = height * 0.5;
    const r = width * 0.48;

    // Dark vinyl body
    ctx.fillStyle = '#1c1c1e';
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fill();

    // Concentric sound microgrooves
    ctx.strokeStyle = '#323236';
    ctx.lineWidth = 1.2;
    for (let gr = r * 0.38; gr < r * 0.94; gr += 2.5) {
      ctx.beginPath();
      ctx.arc(cx, cy, gr, 0, Math.PI * 2);
      ctx.stroke();
    }

    // Vintage center paper label
    const labelRadius = r * 0.34;
    ctx.fillStyle = '#d89a7a';
    ctx.beginPath();
    ctx.arc(cx, cy, labelRadius, 0, Math.PI * 2);
    ctx.fill();

    ctx.strokeStyle = '#f4e2d2';
    ctx.lineWidth = 3;
    ctx.stroke();

    // Spindle hole
    ctx.fillStyle = '#0a0a0b';
    ctx.beginPath();
    ctx.arc(cx, cy, 12, 0, Math.PI * 2);
    ctx.fill();

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates soft sage green waffle/knit fabric texture for bed blanket.
   */
  static createBlanketTexture(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Muted sage base
    ctx.fillStyle = '#8ea889';
    ctx.fillRect(0, 0, width, height);

    // Waffle knit pattern
    ctx.globalAlpha = 0.08;
    ctx.fillStyle = '#5c7358';
    for (let y = 0; y < height; y += 8) {
      for (let x = 0; x < width; x += 8) {
        if ((x + y) % 16 === 0) {
          ctx.fillRect(x, y, 6, 6);
        }
      }
    }

    ctx.globalAlpha = 0.08;
    ctx.fillStyle = '#b7d4b2';
    for (let y = 0; y < height; y += 8) {
      for (let x = 0; x < width; x += 8) {
        if ((x + y) % 16 === 8) {
          ctx.fillRect(x, y, 6, 6);
        }
      }
    }

    ctx.globalAlpha = 1.0;

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    texture.repeat.set(4, 4);
    return texture;
  }

  /**
   * Generates lined notebook pages texture.
   */
  static createNotebookTexture(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    ctx.fillStyle = '#faf7f0';
    ctx.fillRect(0, 0, width, height);

    // Subtle blue/gray ruled lines
    ctx.strokeStyle = '#d5dbe0';
    ctx.lineWidth = 1.2;
    for (let y = 30; y < height - 20; y += 22) {
      ctx.beginPath();
      ctx.moveTo(35, y);
      ctx.lineTo(width - 35, y);
      ctx.stroke();
    }

    // Red left margin line
    ctx.strokeStyle = '#f2aeb5';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(70, 20);
    ctx.lineTo(70, height - 20);
    ctx.stroke();

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }
}
