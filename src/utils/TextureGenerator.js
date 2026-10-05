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
    grad.addColorStop(0.0, '#da9a5a');
    grad.addColorStop(0.28, '#e3a96b');
    grad.addColorStop(0.62, '#d49352');
    grad.addColorStop(1.0, '#dda061');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, width, height);

    // Subtle longitudinal wood grain lines
    ctx.globalAlpha = 0.055;
    for (let y = 0; y < height; y += 2) {
      const lineGrad = ctx.createLinearGradient(0, y, width, y);
      const tone = Math.sin(y * 0.08) * 16;
      lineGrad.addColorStop(0.0, tone > 0 ? '#ad6d2f' : '#fae0b8');
      lineGrad.addColorStop(0.5, tone > 0 ? '#be8140' : '#fcedd2');
      lineGrad.addColorStop(1.0, tone > 0 ? '#a36427' : '#f5d9ad');
      ctx.fillStyle = lineGrad;
      ctx.fillRect(0, y, width, 1.5);
    }

    // Organic wavy grain streaks
    ctx.globalAlpha = 0.032;
    ctx.strokeStyle = '#935824';
    ctx.lineWidth = 2.5;
    for (let i = 0; i < 22; i++) {
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
    ctx.fillStyle = '#7a461b';
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

    // Muted calming sage green base matching reference
    ctx.fillStyle = '#8aa685';
    ctx.fillRect(0, 0, width, height);

    // Subtle horizontal knit ribbed grain
    ctx.globalAlpha = 0.055;
    for (let y = 0; y < height; y += 4) {
      ctx.fillStyle = (y % 8 === 0) ? '#5e775a' : '#b2ccb0';
      ctx.fillRect(0, y, width, 2);
    }

    // Soft orthogonal cross-weave thread relief
    ctx.globalAlpha = 0.035;
    ctx.fillStyle = '#52694f';
    for (let x = 0; x < width; x += 4) {
      ctx.fillRect(x, 0, 1.5, height);
    }

    // Subtle tactile fabric heather noise
    const imgData = ctx.getImageData(0, 0, width, height);
    const data = imgData.data;
    for (let i = 0; i < data.length; i += 4) {
      const noise = (Math.random() - 0.5) * 8;
      data[i] = Math.min(255, Math.max(0, data[i] + noise));
      data[i + 1] = Math.min(255, Math.max(0, data[i + 1] + noise));
      data[i + 2] = Math.min(255, Math.max(0, data[i + 2] + noise));
    }
    ctx.putImageData(imgData, 0, 0);

    ctx.globalAlpha = 1.0;

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    texture.repeat.set(3, 3);
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

  /**
   * Generates vintage analog clock face with numerals, tick marks, and morning hands.
   */
  static createClockFaceTexture(size = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const cx = size * 0.5;
    const cy = size * 0.5;
    const radius = size * 0.46;

    // Warm ivory dial background
    ctx.fillStyle = '#fdfaf2';
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();

    // Outer subtle gold/brass bezel rim
    ctx.strokeStyle = '#c4a66a';
    ctx.lineWidth = size * 0.035;
    ctx.stroke();

    // Inner thin border
    ctx.strokeStyle = '#6e5e4a';
    ctx.lineWidth = size * 0.008;
    ctx.beginPath();
    ctx.arc(cx, cy, radius * 0.92, 0, Math.PI * 2);
    ctx.stroke();

    // Hour & minute tick marks
    for (let i = 0; i < 60; i++) {
      const angle = (i / 60) * Math.PI * 2;
      const isHour = i % 5 === 0;
      const r1 = radius * (isHour ? 0.82 : 0.88);
      const r2 = radius * 0.91;

      ctx.strokeStyle = isHour ? '#2d261e' : '#998c7c';
      ctx.lineWidth = isHour ? size * 0.015 : size * 0.006;
      ctx.beginPath();
      ctx.moveTo(cx + Math.sin(angle) * r1, cy - Math.cos(angle) * r1);
      ctx.lineTo(cx + Math.sin(angle) * r2, cy - Math.cos(angle) * r2);
      ctx.stroke();
    }

    // Numerals 1 to 12
    ctx.fillStyle = '#2b231a';
    ctx.font = `600 ${Math.round(size * 0.105)}px "Georgia", serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    for (let h = 1; h <= 12; h++) {
      const angle = (h / 12) * Math.PI * 2;
      const nr = radius * 0.70;
      const nx = cx + Math.sin(angle) * nr;
      const ny = cy - Math.cos(angle) * nr;
      ctx.fillText(h.toString(), nx, ny);
    }

    // Hands: set to calm morning 8:12
    // Hour hand
    const hourAngle = ((8 + 12 / 60) / 12) * Math.PI * 2;
    ctx.strokeStyle = '#221c17';
    ctx.lineWidth = size * 0.024;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(cx - Math.sin(hourAngle) * 20, cy + Math.cos(hourAngle) * 20);
    ctx.lineTo(cx + Math.sin(hourAngle) * (radius * 0.48), cy - Math.cos(hourAngle) * (radius * 0.48));
    ctx.stroke();

    // Minute hand
    const minAngle = (12 / 60) * Math.PI * 2;
    ctx.lineWidth = size * 0.016;
    ctx.beginPath();
    ctx.moveTo(cx - Math.sin(minAngle) * 25, cy + Math.cos(minAngle) * 25);
    ctx.lineTo(cx + Math.sin(minAngle) * (radius * 0.72), cy - Math.cos(minAngle) * (radius * 0.72));
    ctx.stroke();

    // Center brass cap
    ctx.fillStyle = '#c4a66a';
    ctx.beginPath();
    ctx.arc(cx, cy, size * 0.035, 0, Math.PI * 2);
    ctx.fill();

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates framed botanical watercolor art prints.
   */
  static createBotanicalArtTexture(variant = 0, width = 512, height = 640) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Warm museum paper mat
    ctx.fillStyle = '#faf6ed';
    ctx.fillRect(0, 0, width, height);

    // Subtle paper grain
    ctx.globalAlpha = 0.03;
    ctx.fillStyle = '#6d5a43';
    for (let i = 0; i < 1500; i++) {
      ctx.fillRect(Math.random() * width, Math.random() * height, 2, 2);
    }
    ctx.globalAlpha = 1.0;

    const cx = width * 0.5;
    const cy = height * 0.5;

    if (variant === 0) {
      // Monstera leaf print (lush sage green)
      ctx.fillStyle = '#5c7856';
      ctx.beginPath();
      ctx.ellipse(cx, cy - 20, 110, 160, -0.15, 0, Math.PI * 2);
      ctx.fill();

      // Stem
      ctx.strokeStyle = '#43593e';
      ctx.lineWidth = 9;
      ctx.beginPath();
      ctx.moveTo(cx - 15, cy + 120);
      ctx.quadraticCurveTo(cx - 10, cy + 190, cx - 5, cy + 240);
      ctx.stroke();

      // Cutout leaf fenestrations
      ctx.fillStyle = '#faf6ed';
      for (let i = 0; i < 5; i++) {
        const sy = cy - 100 + i * 45;
        ctx.beginPath();
        ctx.ellipse(cx - 55, sy, 18, 40, -0.4, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.ellipse(cx + 45, sy + 15, 18, 38, 0.4, 0, Math.PI * 2);
        ctx.fill();
      }
    } else if (variant === 1) {
      // Delicate fern frond
      ctx.strokeStyle = '#4e6949';
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.moveTo(cx, cy + 220);
      ctx.quadraticCurveTo(cx + 20, cy, cx - 15, cy - 200);
      ctx.stroke();

      ctx.fillStyle = '#65825f';
      for (let i = 0; i < 16; i++) {
        const t = i / 16;
        const fy = cy + 180 - t * 360;
        const fx = cx + Math.sin(t * Math.PI) * 15;
        const len = Math.sin(t * Math.PI) * 75 + 10;

        // Left leaflet
        ctx.beginPath();
        ctx.ellipse(fx - len * 0.5, fy, len * 0.5, 9, -0.3, 0, Math.PI * 2);
        ctx.fill();

        // Right leaflet
        ctx.beginPath();
        ctx.ellipse(fx + len * 0.5, fy - 6, len * 0.5, 9, 0.3, 0, Math.PI * 2);
        ctx.fill();
      }
    } else if (variant === 2) {
      // Eucalyptus coin leaves (muted blue-green/sage)
      ctx.strokeStyle = '#5a7065';
      ctx.lineWidth = 5;
      ctx.beginPath();
      ctx.moveTo(cx - 30, cy + 230);
      ctx.quadraticCurveTo(cx + 40, cy + 50, cx - 20, cy - 210);
      ctx.stroke();

      ctx.fillStyle = '#7a9688';
      for (let i = 0; i < 11; i++) {
        const t = i / 11;
        const ey = cy + 190 - t * 380;
        const ex = cx + (i % 2 === 0 ? -45 : 45);
        ctx.beginPath();
        ctx.arc(ex, ey, 32 - t * 10, 0, Math.PI * 2);
        ctx.fill();
      }
    } else {
      // Golden sunny landscape
      const grad = ctx.createLinearGradient(0, cy - 140, 0, cy + 140);
      grad.addColorStop(0, '#f2d096');
      grad.addColorStop(0.5, '#e8aa78');
      grad.addColorStop(1, '#8ea889');

      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.ellipse(cx, cy, 140, 140, 0, 0, Math.PI * 2);
      ctx.fill();

      // Rolling pine hills
      ctx.fillStyle = '#4c634b';
      ctx.beginPath();
      ctx.arc(cx - 40, cy + 110, 90, Math.PI, 0);
      ctx.fill();
      ctx.fillStyle = '#3a4e39';
      ctx.beginPath();
      ctx.arc(cx + 50, cy + 115, 80, Math.PI, 0);
      ctx.fill();
    }

    // Border matting line
    ctx.strokeStyle = '#dfd6c6';
    ctx.lineWidth = 3;
    ctx.strokeRect(35, 35, width - 70, height - 70);

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates miniature Polaroid snapshot textures with white borders.
   */
  static createPolaroidTexture(variant = 0, width = 360, height = 440) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Classic white Polaroid paper
    ctx.fillStyle = '#fdfbf7';
    ctx.fillRect(0, 0, width, height);

    // Photo window area
    const pX = 26;
    const pY = 26;
    const pW = width - 52;
    const pH = height - 110;

    const scenes = [
      // 0: Sunny window & plant
      () => {
        const bg = ctx.createLinearGradient(pX, pY, pX, pY + pH);
        bg.addColorStop(0, '#a5d2eb');
        bg.addColorStop(0.6, '#fcedcb');
        bg.addColorStop(1, '#e3b586');
        ctx.fillStyle = bg;
        ctx.fillRect(pX, pY, pW, pH);

        ctx.fillStyle = '#5c8052';
        ctx.beginPath();
        ctx.arc(pX + pW * 0.5, pY + pH * 0.85, 45, Math.PI, 0);
        ctx.fill();
      },
      // 1: Calico cat curled
      () => {
        ctx.fillStyle = '#ebe1d1';
        ctx.fillRect(pX, pY, pW, pH);

        // Blanket
        ctx.fillStyle = '#8ea889';
        ctx.fillRect(pX, pY + pH * 0.6, pW, pH * 0.4);

        // Cat loaf
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.ellipse(pX + pW * 0.5, pY + pH * 0.6, 50, 32, 0, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = '#d48648';
        ctx.beginPath();
        ctx.ellipse(pX + pW * 0.58, pY + pH * 0.58, 24, 18, 0.4, 0, Math.PI * 2);
        ctx.fill();
      },
      // 2: Golden morning sunbeam
      () => {
        const bg = ctx.createLinearGradient(pX, pY, pX + pW, pY + pH);
        bg.addColorStop(0, '#fcdfa7');
        bg.addColorStop(0.5, '#e8b27f');
        bg.addColorStop(1, '#a67252');
        ctx.fillStyle = bg;
        ctx.fillRect(pX, pY, pW, pH);

        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
        ctx.beginPath();
        ctx.moveTo(pX, pY);
        ctx.lineTo(pX + pW * 0.6, pY);
        ctx.lineTo(pX + pW, pY + pH * 0.7);
        ctx.lineTo(pX + pW * 0.4, pY + pH);
        ctx.fill();
      },
      // 3: Coffee mug on desk
      () => {
        ctx.fillStyle = '#f0ebe1';
        ctx.fillRect(pX, pY, pW, pH);

        // Table
        ctx.fillStyle = '#caa36e';
        ctx.fillRect(pX, pY + pH * 0.65, pW, pH * 0.35);

        // Mug
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.roundRect(pX + pW * 0.4, pY + pH * 0.45, 55, 55, [4, 4, 12, 12]);
        ctx.fill();
        ctx.fillStyle = '#593923';
        ctx.beginPath();
        ctx.ellipse(pX + pW * 0.4 + 27, pY + pH * 0.45, 24, 8, 0, 0, Math.PI * 2);
        ctx.fill();
      }
    ];

    scenes[variant % scenes.length]();

    // Subtle handwritten caption or heart at bottom
    ctx.fillStyle = '#8f8373';
    ctx.font = '500 16px "Comic Sans MS", cursive, sans-serif';
    ctx.textAlign = 'center';
    const captions = ['nook ♡', 'cozy morning', 'sunshine ☀️', 'cookie 🐾'];
    ctx.fillText(captions[variant % captions.length], width * 0.5, height - 38);

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  }

  /**
   * Generates soft cream linen curtain fabric with subtle vertical pleat shading.
   */
  static createCurtainFabricTexture(width = 512, height = 1024) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Warm cream linen base
    ctx.fillStyle = '#f7f2e7';
    ctx.fillRect(0, 0, width, height);

    // Subtle vertical fold shading lines
    ctx.globalAlpha = 0.08;
    for (let x = 0; x < width; x += 18) {
      const grad = ctx.createLinearGradient(x, 0, x + 18, 0);
      grad.addColorStop(0, '#000000');
      grad.addColorStop(0.5, '#ffffff');
      grad.addColorStop(1, '#000000');
      ctx.fillStyle = grad;
      ctx.fillRect(x, 0, 18, height);
    }

    // Linen horizontal cross-hatch fibers
    ctx.globalAlpha = 0.025;
    ctx.fillStyle = '#8a775f';
    for (let y = 0; y < height; y += 4) {
      ctx.fillRect(0, y, width, 1.5);
    }

    ctx.globalAlpha = 1.0;

    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }

  /**
   * Generates procedural tangent-space normal map from a height field function.
   */
  static createHeightToNormalMap(heightFunc, width = 512, height = 512, scale = 2.0) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    const imgData = ctx.createImageData(width, height);
    const data = imgData.data;

    const grid = new Float32Array(width * height);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        grid[y * width + x] = heightFunc(x, y, width, height);
      }
    }

    for (let y = 0; y < height; y++) {
      const y0 = (y - 1 + height) % height;
      const y1 = (y + 1) % height;
      for (let x = 0; x < width; x++) {
        const x0 = (x - 1 + width) % width;
        const x1 = (x + 1) % width;

        const dx = (grid[y * width + x1] - grid[y * width + x0]) * scale;
        const dy = (grid[y1 * width + x] - grid[y0 * width + x]) * scale;
        const dz = 1.0;

        const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1.0;
        const nx = -dx / len;
        const ny = -dy / len;
        const nz = dz / len;

        const idx = (y * width + x) * 4;
        data[idx] = Math.floor((nx * 0.5 + 0.5) * 255);
        data[idx + 1] = Math.floor((ny * 0.5 + 0.5) * 255);
        data[idx + 2] = Math.floor((nz * 0.5 + 0.5) * 255);
        data[idx + 3] = 255;
      }
    }

    ctx.putImageData(imgData, 0, 0);
    const texture = new THREE.CanvasTexture(canvas);
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }

  /**
   * Generates directional wood grain normal map for tactile micro-relief.
   */
  static createWoodNormalMap(width = 512, height = 512) {
    return this.createHeightToNormalMap((x, y, w, h) => {
      const u = x / w;
      const v = y / h;
      // Smooth longitudinal wood fibers running along Y
      const fiber = Math.sin(u * Math.PI * 40 + Math.sin(v * Math.PI * 4) * 1.2) * 0.35;
      const subFiber = Math.sin(u * Math.PI * 80 + Math.cos(v * Math.PI * 8) * 0.8) * 0.15;
      const wave = Math.sin(v * Math.PI * 2 + u * Math.PI * 2) * 0.08;
      return fiber + subFiber + wave;
    }, width, height, 1.0);
  }

  /**
   * Generates wood roughness map with matte/semi-matte pore variation.
   */
  static createWoodRoughnessMap(width = 512, height = 512) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Base semi-matte roughness (~0.52)
    ctx.fillStyle = '#858585';
    ctx.fillRect(0, 0, width, height);

    // Subtle organic longitudinal grain roughness variation
    ctx.globalAlpha = 0.08;
    for (let x = 0; x < width; x += 4) {
      const tone = Math.sin(x * 0.15) * 20 + Math.sin(x * 0.05) * 15;
      ctx.fillStyle = tone > 0 ? '#9c9c9c' : '#707070';
      ctx.fillRect(x, 0, 3, height);
    }

    ctx.globalAlpha = 1.0;
    const texture = new THREE.CanvasTexture(canvas);
    texture.wrapS = THREE.RepeatWrapping;
    texture.wrapT = THREE.RepeatWrapping;
    return texture;
  }

  /**
   * Generates woven fabric normal map for soft tactile linen/cotton cloth.
   */
  static createFabricNormalMap(width = 512, height = 512) {
    return this.createHeightToNormalMap((x, y, w, h) => {
      const threadX = Math.sin(x * 0.65) * 0.5;
      const threadY = Math.cos(y * 0.65) * 0.5;
      const cross = Math.sin((x + y) * 0.32) * 0.2;
      return threadX + threadY + cross;
    }, width, height, 1.8);
  }

  /**
   * Generates fluffy looped bouclé normal map for the cat bed pouf.
   */
  static createBoucleNormalMap(width = 512, height = 512) {
    return this.createHeightToNormalMap((x, y, w, h) => {
      const loop1 = Math.sin(x * 0.35 + Math.sin(y * 0.28) * 3.0);
      const loop2 = Math.cos(y * 0.32 + Math.cos(x * 0.26) * 3.0);
      const nub = Math.sin(x * 0.8) * Math.sin(y * 0.8) * 0.4;
      return (loop1 + loop2 + nub) * 0.5;
    }, width, height, 2.2);
  }

  /**
   * Generates subtle chalky plaster normal map for cream walls.
   */
  static createPlasterNormalMap(width = 512, height = 512) {
    return this.createHeightToNormalMap((x, y, w, h) => {
      return (Math.sin(x * 0.15) * Math.sin(y * 0.15) * 0.4) +
             (Math.sin(x * 0.42 + y * 0.38) * 0.3) +
             (Math.sin(x * 0.95 - y * 0.85) * 0.2);
    }, width, height, 1.2);
  }
}
