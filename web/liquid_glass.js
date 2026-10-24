/**
 * DreamEats Liquid Glass JS Engine
 * High-performance interactive liquid glass refraction & ambient fluid orbs.
 * Renders behind Flutter Web to create a stunning glassmorphic visual experience.
 */
(function() {
  'use strict';

  // Do not run in non-browser environments
  if (typeof window === 'undefined' || typeof document === 'undefined') return;

  var canvas, ctx;
  var width, height, dpr;
  var orbs = [];
  var mouse = { x: -1000, y: -1000, targetX: -1000, targetY: -1000, isMoving: false };
  var lastMoveTime = 0;
  var isRunning = true;
  var animFrameId = null;

  // Premium Emerald & Mint Glass Palette
  var glassColors = [
    { r: 46, g: 125, b: 50, a: 0.18 },   // Emerald Green
    { r: 16, g: 185, b: 129, a: 0.14 },  // Mint Green
    { r: 5, g: 150, b: 105, a: 0.12 },   // Deep Teal
    { r: 13, g: 148, b: 136, a: 0.15 },  // Cyan Glass
    { r: 59, g: 130, b: 246, a: 0.08 }   // Sapphire highlight
  ];

  function LiquidOrb(x, y, radius, color, vx, vy) {
    this.x = x;
    this.y = y;
    this.baseRadius = radius;
    this.radius = radius;
    this.color = color;
    this.vx = vx;
    this.vy = vy;
    this.phase = Math.random() * Math.PI * 2;
    this.phaseSpeed = 0.008 + Math.random() * 0.01;
    this.wobbleAmp = 15 + Math.random() * 25;
  }

  LiquidOrb.prototype.update = function(time) {
    this.phase += this.phaseSpeed;
    this.x += this.vx + Math.sin(this.phase) * 0.4;
    this.y += this.vy + Math.cos(this.phase * 0.8) * 0.4;

    // Soft boundary bounce
    if (this.x < -this.radius) this.x = width + this.radius;
    if (this.x > width + this.radius) this.x = -this.radius;
    if (this.y < -this.radius) this.y = height + this.radius;
    if (this.y > height + this.radius) this.y = -this.radius;

    // Mouse fluid repulsion
    var dx = this.x - mouse.x;
    var dy = this.y - mouse.y;
    var dist = Math.sqrt(dx * dx + dy * dy);
    var maxDist = this.radius * 1.8;
    if (dist < maxDist && dist > 0) {
      var force = (1 - dist / maxDist) * 3.5;
      this.x += (dx / dist) * force;
      this.y += (dy / dist) * force;
    }
  };

  LiquidOrb.prototype.draw = function(ctx) {
    var wobble = Math.sin(this.phase) * this.wobbleAmp;
    var r = Math.max(20, this.radius + wobble);

    var grad = ctx.createRadialGradient(this.x, this.y, 0, this.x, this.y, r);
    var c = this.color;
    grad.addColorStop(0, 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',' + c.a + ')');
    grad.addColorStop(0.5, 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',' + (c.a * 0.5) + ')');
    grad.addColorStop(1, 'rgba(' + c.r + ',' + c.g + ',' + c.b + ', 0)');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(this.x, this.y, r, 0, Math.PI * 2);
    ctx.fill();
  };

  function initCanvas() {
    canvas = document.getElementById('liquid_glass_canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'liquid_glass_canvas';
      canvas.style.position = 'fixed';
      canvas.style.top = '0';
      canvas.style.left = '0';
      canvas.style.width = '100vw';
      canvas.style.height = '100vh';
      canvas.style.zIndex = '0';
      canvas.style.pointerEvents = 'none';
      canvas.style.opacity = '0.9';
      canvas.style.background = 'radial-gradient(ellipse at 80% 20%, #F0FDF4 0%, #F8FAFC 50%, #EDF7EE 100%)';
      document.body.insertBefore(canvas, document.body.firstChild);
    }
    ctx = canvas.getContext('2d', { alpha: true });
    resize();
    createOrbs();
  }

  function resize() {
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.scale(dpr, dpr);
  }

  function createOrbs() {
    orbs = [];
    var count = Math.max(5, Math.min(9, Math.floor(width / 220)));
    for (var i = 0; i < count; i++) {
      var radius = (width > 800 ? 180 : 120) + Math.random() * 160;
      var x = Math.random() * width;
      var y = Math.random() * height;
      var vx = (Math.random() - 0.5) * 0.6;
      var vy = (Math.random() - 0.5) * 0.6;
      var color = glassColors[i % glassColors.length];
      orbs.push(new LiquidOrb(x, y, radius, color, vx, vy));
    }
  }

  function animate(time) {
    if (!isRunning) return;

    // Smooth cursor interpolation
    mouse.x += (mouse.targetX - mouse.x) * 0.1;
    mouse.y += (mouse.targetY - mouse.y) * 0.1;

    ctx.clearRect(0, 0, width, height);

    // Subtle caustic wave backdrop
    for (var i = 0; i < orbs.length; i++) {
      orbs[i].update(time);
      orbs[i].draw(ctx);
    }

    animFrameId = requestAnimationFrame(animate);
  }

  // Mouse / Pointer Tracking
  function onPointerMove(e) {
    var x = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : -1000);
    var y = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : -1000);
    mouse.targetX = x;
    mouse.targetY = y;
    lastMoveTime = Date.now();
  }

  // Handle Visibility change to save battery
  document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
      isRunning = false;
      if (animFrameId) cancelAnimationFrame(animFrameId);
    } else {
      if (!isRunning) {
        isRunning = true;
        animFrameId = requestAnimationFrame(animate);
      }
    }
  });

  window.addEventListener('resize', function() {
    resize();
    createOrbs();
  });

  window.addEventListener('mousemove', onPointerMove, { passive: true });
  window.addEventListener('touchmove', onPointerMove, { passive: true });

  // Expose global controller
  window.liquidGlass = {
    triggerRipple: function(x, y) {
      if (orbs.length > 0) {
        var orb = orbs[Math.floor(Math.random() * orbs.length)];
        orb.x = x || (width / 2);
        orb.y = y || (height / 2);
        orb.wobbleAmp = 40;
      }
    },
    setTheme: function(isDark) {
      if (canvas) {
        canvas.style.background = isDark 
          ? 'radial-gradient(ellipse at 80% 20%, #064E3B 0%, #0F172A 50%, #022C22 100%)'
          : 'radial-gradient(ellipse at 80% 20%, #F0FDF4 0%, #F8FAFC 50%, #EDF7EE 100%)';
      }
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCanvas);
  } else {
    initCanvas();
  }
  animFrameId = requestAnimationFrame(animate);
})();
