/**
 * Nook — Official Marketing & Download Website
 * Interaction Layer:
 * - Ambient dust mote simulation (sunlight effect, respects prefers-reduced-motion)
 * - Room lighting mode switcher (Morning, Afternoon, Evening, Night)
 * - Miniature room hotspots & tactile popovers
 * - Physical object selector demonstration
 * - Cookie companion state switcher & gentle pet interaction
 * - IntersectionObserver scroll reveal
 * - Accessible mobile navigation
 * - Configurable download targets
 */

(function () {
  "use strict";

  // MARK: - Global Configuration
  window.NOOK_CONFIG = {
    // Configurable download targets
    downloadPageUrl: "downloads/index.html",
    directDmgUrl: "downloads/Nook-1.0.0-Universal.dmg",
    version: "1.0.0",
    minMacOS: "15.0",
    releaseName: "Nook-1.0.0-Universal.dmg"
  };

  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // MARK: - DOM Ready Initialization
  document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    initLightingModes();
    initRoomHotspots();
    initObjectPicker();
    initCookieCompanion();
    initScrollReveal();
    initDownloadButtons();
    if (!prefersReducedMotion) {
      initAmbientDust();
    }
  });

  // MARK: - Navigation & Mobile Drawer
  function initNavigation() {
    const mobileToggle = document.getElementById("mobile-toggle");
    const navLinks = document.getElementById("nav-links");
    const siteHeader = document.getElementById("site-header");

    if (!mobileToggle || !navLinks) return;

    function toggleMenu(isOpen) {
      const open = typeof isOpen === "boolean" ? isOpen : !navLinks.classList.contains("open");
      navLinks.classList.toggle("open", open);
      mobileToggle.setAttribute("aria-expanded", String(open));
      document.body.style.overflow = open ? "hidden" : "";
    }

    mobileToggle.addEventListener("click", () => toggleMenu());

    // Close on navigation click
    navLinks.querySelectorAll(".nav-link").forEach((link) => {
      link.addEventListener("click", () => {
        if (window.innerWidth <= 720) {
          toggleMenu(false);
        }
      });
    });

    // Close on Escape
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && navLinks.classList.contains("open")) {
        toggleMenu(false);
      }
    });

    // Subtle header border shadow on scroll
    window.addEventListener("scroll", () => {
      if (window.scrollY > 20) {
        siteHeader.classList.add("is-scrolled");
      } else {
        siteHeader.classList.remove("is-scrolled");
      }
    }, { passive: true });
  }

  // MARK: - Room Lighting Modes
  function initLightingModes() {
    const roomViewport = document.getElementById("room-viewport");
    const buttons = document.querySelectorAll(".lighting-btn");

    if (!roomViewport || !buttons.length) return;

    // Default to morning
    roomViewport.setAttribute("data-time", "morning");

    buttons.forEach((btn) => {
      btn.addEventListener("click", () => {
        const time = btn.getAttribute("data-time");
        if (!time) return;

        buttons.forEach((b) => {
          b.classList.remove("active");
          b.setAttribute("aria-pressed", "false");
        });

        btn.classList.add("active");
        btn.setAttribute("aria-pressed", "true");

        roomViewport.setAttribute("data-time", time);
      });
    });
  }

  // MARK: - Room Hotspots & Tactile Popovers
  function initRoomHotspots() {
    const hotspots = document.querySelectorAll(".hotspot");
    const popover = document.getElementById("interactive-preview-popover");
    const popoverTitle = document.getElementById("popover-title");
    const popoverBody = document.getElementById("popover-body");
    const popoverTag = document.getElementById("popover-tag");
    const popoverCloseBtn = document.getElementById("popover-close-btn");

    if (!popover || !hotspots.length) return;

    const HOTSPOT_DATA = {
      pebble: {
        tag: "Physical Thought",
        title: "Smooth River Pebble",
        body: "Your captured thought becomes an actual smooth stone resting on the oak desk. Grounded, tactile, and quietly present.",
        hint: "Press ⌘⇧Space anywhere on Mac"
      },
      cookie: {
        tag: "Room Companion",
        title: "Cookie • Sleeping",
        body: "Cookie curls up on the sage linen bed. No AI chatter, no push notifications — just a peaceful, breathing presence.",
        hint: "Scroll down to meet Cookie"
      },
      plant: {
        tag: "Atmosphere",
        title: "Potted Monstera",
        body: "Gently sways in the morning window breeze. Reminds you to take a breath and pace your day calmly.",
        hint: "Dynamic daylight & breeze"
      },
      books: {
        tag: "Local SwiftData",
        title: "Miniature Bookshelf",
        body: "Holds bookmarks and cards from past projects. Everything is stored in native SwiftData on your Mac with zero cloud lag.",
        hint: "100% offline & private"
      }
    };

    function showPopover(key) {
      const data = HOTSPOT_DATA[key];
      if (!data) return;

      if (popoverTag) popoverTag.textContent = data.tag;
      if (popoverTitle) popoverTitle.textContent = data.title;
      if (popoverBody) popoverBody.textContent = data.body;

      popover.classList.add("is-visible");
      popover.setAttribute("aria-hidden", "false");
    }

    function hidePopover() {
      popover.classList.remove("is-visible");
      popover.setAttribute("aria-hidden", "true");
    }

    hotspots.forEach((hs) => {
      hs.addEventListener("click", (e) => {
        e.stopPropagation();
        const objKey = hs.getAttribute("data-object");
        showPopover(objKey);
      });
    });

    if (popoverCloseBtn) {
      popoverCloseBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        hidePopover();
      });
    }

    // Dismiss popover on outside click
    document.addEventListener("click", (e) => {
      if (!popover.contains(e.target) && !e.target.closest(".hotspot")) {
        hidePopover();
      }
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && popover.classList.contains("is-visible")) {
        hidePopover();
      }
    });
  }

  // MARK: - Interactive Object Picker Demo
  function initObjectPicker() {
    const tabs = document.querySelectorAll(".picker-tab");
    const avatar = document.getElementById("picker-preview-avatar");
    const nameEl = document.getElementById("picker-object-name");
    const subEl = document.getElementById("picker-object-sub");

    if (!tabs.length || !avatar || !nameEl || !subEl) return;

    const OBJECT_SPECS = {
      pebble: {
        shapeClass: "shape-pebble",
        name: "Smooth River Pebble",
        sub: "A grounding, smooth river stone that settles peacefully on your desk. Heavy, natural, and calm."
      },
      paperNote: {
        shapeClass: "shape-paperNote",
        name: "Warm Paper Note",
        sub: "A crisp, folded piece of cream parchment for reflections, short essays, and intentional journaling."
      },
      stickyNote: {
        shapeClass: "shape-stickyNote",
        name: "Buttery Sticky Note",
        sub: "A soft yellow square for quick todos and lightweight reminders. Peels off easily when completed."
      },
      card: {
        shapeClass: "shape-card",
        name: "Linen Index Card",
        sub: "A sturdy index card for structured outlines, reading notes, and multi-paragraph ideas."
      },
      polaroid: {
        shapeClass: "shape-polaroid",
        name: "Instant Polaroid Print",
        sub: "A vintage white-bordered photo print capturing a moment in time, a design screenshot, or a warm memory."
      },
      bookmark: {
        shapeClass: "shape-bookmark",
        name: "Ribbon Bookmark",
        sub: "A muted sage ribbon bookmark for keeping tabs on active books, articles, or ongoing drafts."
      }
    };

    tabs.forEach((tab) => {
      tab.addEventListener("click", () => {
        const type = tab.getAttribute("data-type");
        const spec = OBJECT_SPECS[type];
        if (!spec) return;

        tabs.forEach((t) => {
          t.classList.remove("active");
          t.setAttribute("aria-selected", "false");
        });

        tab.classList.add("active");
        tab.setAttribute("aria-selected", "true");

        // Swap shape class
        avatar.innerHTML = `<div class="avatar-shape ${spec.shapeClass}"></div>`;
        nameEl.textContent = spec.name;
        subEl.textContent = spec.sub;
      });
    });
  }

  // MARK: - Cookie Companion Section
  function initCookieCompanion() {
    const imgEl = document.getElementById("cookie-display-img");
    const statusTag = document.getElementById("cookie-status-tag");
    const petBtn = document.getElementById("pet-cookie-btn");
    const feedbackBubble = document.getElementById("pet-feedback-bubble");

    const btnSleeping = document.getElementById("cookie-btn-sleeping");
    const btnCurious = document.getElementById("cookie-btn-curious");
    const btnHappy = document.getElementById("cookie-btn-happy");

    const stateButtons = [btnSleeping, btnCurious, btnHappy].filter(Boolean);

    const COOKIE_STATES = {
      sleeping: {
        src: "assets/cookie_sleeping.jpg",
        alt: "Cookie curled up asleep on a sage green linen blanket",
        text: "Cookie is sleeping soundly"
      },
      curious: {
        src: "assets/cookie_curious.jpg",
        alt: "Cookie with perked ears and curious wide eyes looking at a newly placed thought",
        text: "Cookie is curious about your thought"
      },
      happy: {
        src: "assets/cookie_happy.jpg",
        alt: "Cookie smiling with rosy cheeks and purring softly",
        text: "Cookie is purring happily"
      }
    };

    function setState(stateKey) {
      const data = COOKIE_STATES[stateKey];
      if (!data || !imgEl) return;

      // Update button styles
      stateButtons.forEach((btn) => {
        const bState = btn.getAttribute("data-state");
        const isActive = bState === stateKey;
        btn.classList.toggle("active", isActive);
      });

      // Subtle image fade
      imgEl.style.opacity = "0.7";
      setTimeout(() => {
        imgEl.src = data.src;
        imgEl.alt = data.alt;
        imgEl.style.opacity = "1";
      }, 150);

      if (statusTag) {
        const textSpan = statusTag.querySelector(".status-text");
        if (textSpan) textSpan.textContent = data.text;
      }
    }

    stateButtons.forEach((btn) => {
      btn.addEventListener("click", () => {
        const stateKey = btn.getAttribute("data-state");
        setState(stateKey);
      });
    });

    // Pet Cookie Interaction
    if (petBtn) {
      let petTimeout;
      petBtn.addEventListener("click", () => {
        setState("happy");

        if (feedbackBubble) {
          feedbackBubble.textContent = "Purr... ❤️";
          feedbackBubble.classList.add("is-visible");
          clearTimeout(petTimeout);
          petTimeout = setTimeout(() => {
            feedbackBubble.classList.remove("is-visible");
          }, 2400);
        }

        // Soft synthesized purr sound using Web Audio API (gentle & native)
        playGentlePurr();
      });
    }

    function playGentlePurr() {
      try {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;
        const ctx = new AudioCtx();
        if (ctx.state === "suspended") {
          ctx.resume();
        }

        // Create warm, low-frequency purr modulation
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        const lfo = ctx.createOscillator();
        const lfoGain = ctx.createGain();

        osc.type = "sine";
        osc.frequency.setValueAtTime(65, ctx.currentTime); // Low purr tone

        // Purr vibration rate ~25 Hz
        lfo.type = "sine";
        lfo.frequency.setValueAtTime(24, ctx.currentTime);
        lfoGain.gain.setValueAtTime(0.04, ctx.currentTime);

        lfo.connect(gain.gain);
        gain.gain.setValueAtTime(0.05, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.2);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start();
        lfo.start();

        osc.stop(ctx.currentTime + 1.2);
        lfo.stop(ctx.currentTime + 1.2);
      } catch (e) {
        // Silent graceful fallback if audio is restricted
      }
    }
  }

  // MARK: - Ambient Dust Motes Canvas Simulation
  function initAmbientDust() {
    const canvas = document.getElementById("ambient-dust");
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    window.addEventListener("resize", () => {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }, { passive: true });

    // Generate ~28 calm, warm floating particles
    const particleCount = Math.min(Math.floor(width / 45), 32);
    const particles = [];

    for (let i = 0; i < particleCount; i++) {
      particles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        radius: Math.random() * 1.5 + 0.8,
        vx: (Math.random() - 0.5) * 0.25,
        vy: -Math.random() * 0.25 - 0.08, // Slow upward drift
        alpha: Math.random() * 0.45 + 0.15,
        pulseSpeed: Math.random() * 0.02 + 0.005,
        pulseOffset: Math.random() * Math.PI * 2
      });
    }

    let animationFrameId;

    function render(timestamp) {
      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];

        p.x += p.vx;
        p.y += p.vy;

        // Wrap around viewport edges
        if (p.y < -10) p.y = height + 10;
        if (p.x < -10) p.x = width + 10;
        if (p.x > width + 10) p.x = -10;

        // Gentle breathing opacity
        const dynamicAlpha = p.alpha * (0.7 + 0.3 * Math.sin(timestamp * p.pulseSpeed + p.pulseOffset));

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(180, 168, 150, ${dynamicAlpha.toFixed(3)})`;
        ctx.fill();
      }

      animationFrameId = requestAnimationFrame(render);
    }

    animationFrameId = requestAnimationFrame(render);

    // Pause when tab hidden to conserve CPU
    document.addEventListener("visibilitychange", () => {
      if (document.hidden) {
        cancelAnimationFrame(animationFrameId);
      } else {
        animationFrameId = requestAnimationFrame(render);
      }
    });
  }

  // MARK: - IntersectionObserver Scroll Reveal
  function initScrollReveal() {
    const revealItems = document.querySelectorAll(".reveal-item");
    if (!revealItems.length) return;

    if (prefersReducedMotion || !("IntersectionObserver" in window)) {
      revealItems.forEach((el) => el.classList.add("is-revealed"));
      return;
    }

    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-revealed");
          obs.unobserve(entry.target);
        }
      });
    }, {
      rootMargin: "0px 0px -60px 0px",
      threshold: 0.1
    });

    revealItems.forEach((el) => observer.observe(el));
  }

  // MARK: - Download Buttons Wiring
  function initDownloadButtons() {
    const downloadBtns = document.querySelectorAll(".download-cta-btn");
    if (!downloadBtns.length) return;

    downloadBtns.forEach((btn) => {
      // Directs to the dedicated download landing page
      if (btn.id === "hero-download-btn" || btn.id === "nav-download-btn") {
        btn.setAttribute("href", window.NOOK_CONFIG.downloadPageUrl);
      }
    });
  }

})();
