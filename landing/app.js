/**
 * Oreo AI Landing Page Interactive Script
 * - Three.js 3D Knowledge Network in Hero
 * - Glassmorphic Navbar Scroll Effects & Mobile Drawer
 * - Smooth Scroll Anchors & Intersection Observer Animations
 */

document.addEventListener('DOMContentLoaded', () => {
  initNavbar();
  initThreeJSHero();
  initScrollAnimations();
  initBackToTop();
});

/* ==========================================================================
   1. Navbar & Mobile Drawer
   ========================================================================== */
function initNavbar() {
  const navbar = document.getElementById('main-nav');
  const mobileToggle = document.getElementById('mobile-toggle');
  const mobileMenu = document.getElementById('mobile-menu');
  const mobileLinks = document.querySelectorAll('.mobile-link');

  // Scroll effect on navbar
  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      navbar.style.boxShadow = '0 14px 34px -10px rgba(0, 0, 0, 0.12), inset 0 1px 0 rgba(255, 255, 255, 0.95)';
      navbar.style.background = 'rgba(255, 255, 255, 0.92)';
    } else {
      navbar.style.boxShadow = '0 10px 30px -10px rgba(0, 0, 0, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.9)';
      navbar.style.background = 'rgba(255, 255, 255, 0.82)';
    }
  });

  // Mobile menu toggle
  if (mobileToggle && mobileMenu) {
    mobileToggle.addEventListener('click', () => {
      mobileMenu.classList.toggle('open');
      const spans = mobileToggle.querySelectorAll('span');
      if (mobileMenu.classList.contains('open')) {
        spans[0].style.transform = 'translateY(8px) rotate(45deg)';
        spans[1].style.opacity = '0';
        spans[2].style.transform = 'translateY(-8px) rotate(-45deg)';
      } else {
        spans[0].style.transform = 'none';
        spans[1].style.opacity = '1';
        spans[2].style.transform = 'none';
      }
    });

    mobileLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileMenu.classList.remove('open');
        const spans = mobileToggle.querySelectorAll('span');
        spans[0].style.transform = 'none';
        spans[1].style.opacity = '1';
        spans[2].style.transform = 'none';
      });
    });
  }
}

/* ==========================================================================
   2. Three.js 3D Knowledge Network Graphic
   ========================================================================== */
function initThreeJSHero() {
  const canvas = document.getElementById('hero-3d-canvas');
  if (!canvas || typeof THREE === 'undefined') return;

  const container = canvas.parentElement;
  const width = container.clientWidth || 500;
  const height = container.clientHeight || 480;

  // Scene, Camera, Renderer
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
  camera.position.z = 8;

  const renderer = new THREE.WebGLRenderer({
    canvas: canvas,
    alpha: true,
    antialias: true,
    powerPreference: 'high-performance'
  });
  renderer.setSize(width, height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  // Main Knowledge Crystal (Icosahedron)
  const geometry = new THREE.IcosahedronGeometry(2.4, 0);
  
  // Faceted Material with high sheen
  const material = new THREE.MeshPhysicalMaterial({
    color: 0x171719,
    metalness: 0.2,
    roughness: 0.15,
    transmission: 0.6,
    thickness: 1.2,
    reflectivity: 0.9,
    clearcoat: 1.0,
    clearcoatRoughness: 0.1,
    flatShading: true,
  });
  const mainMesh = new THREE.Mesh(geometry, material);
  scene.add(mainMesh);

  // Glowing Outer Wireframe
  const wireframeGeo = new THREE.WireframeGeometry(geometry);
  const wireframeMat = new THREE.LineBasicMaterial({
    color: 0x06B6D4,
    transparent: true,
    opacity: 0.75,
    linewidth: 2
  });
  const wireframe = new THREE.LineSegments(wireframeGeo, wireframeMat);
  mainMesh.add(wireframe);

  // Core Inner Crystal with Coral Sheen
  const coreGeo = new THREE.IcosahedronGeometry(1.2, 1);
  const coreMat = new THREE.MeshStandardMaterial({
    color: 0xE34A32,
    emissive: 0xE34A32,
    emissiveIntensity: 0.4,
    roughness: 0.3,
    metalness: 0.8,
    wireframe: true
  });
  const coreMesh = new THREE.Mesh(coreGeo, coreMat);
  mainMesh.add(coreMesh);

  // Orbiting Knowledge Nodes (Particles)
  const nodeCount = 48;
  const nodePositions = new Float32Array(nodeCount * 3);
  const nodeColors = new Float32Array(nodeCount * 3);

  const colors = [
    new THREE.Color(0x06B6D4), // Cyan
    new THREE.Color(0x10B981), // Emerald
    new THREE.Color(0xF59E0B), // Amber
    new THREE.Color(0xE34A32)  // Coral
  ];

  for (let i = 0; i < nodeCount; i++) {
    const radius = 3.2 + Math.random() * 1.5;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos((Math.random() * 2) - 1);

    nodePositions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
    nodePositions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
    nodePositions[i * 3 + 2] = radius * Math.cos(phi);

    const c = colors[Math.floor(Math.random() * colors.length)];
    nodeColors[i * 3] = c.r;
    nodeColors[i * 3 + 1] = c.g;
    nodeColors[i * 3 + 2] = c.b;
  }

  const nodesGeometry = new THREE.BufferGeometry();
  nodesGeometry.setAttribute('position', new THREE.BufferAttribute(nodePositions, 3));
  nodesGeometry.setAttribute('color', new THREE.BufferAttribute(nodeColors, 3));

  const nodesMaterial = new THREE.PointsMaterial({
    size: 0.14,
    vertexColors: true,
    transparent: true,
    opacity: 0.85
  });

  const particles = new THREE.Points(nodesGeometry, nodesMaterial);
  scene.add(particles);

  // Studio Lighting
  const ambientLight = new THREE.AmbientLight(0xFFFFFF, 1.2);
  scene.add(ambientLight);

  const keyLight = new THREE.DirectionalLight(0x06B6D4, 2.5);
  keyLight.position.set(5, 5, 4);
  scene.add(keyLight);

  const fillLight = new THREE.DirectionalLight(0xE34A32, 2.0);
  fillLight.position.set(-5, -3, 3);
  scene.add(fillLight);

  const rimLight = new THREE.PointLight(0xFFFFFF, 1.5, 10);
  rimLight.position.set(0, 4, -4);
  scene.add(rimLight);

  // Mouse Interactivity
  let mouseX = 0;
  let mouseY = 0;
  let targetRotationX = 0;
  let targetRotationY = 0;

  window.addEventListener('mousemove', (e) => {
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left - (rect.width / 2);
    const y = e.clientY - rect.top - (rect.height / 2);
    mouseX = (x / rect.width) * 2;
    mouseY = (y / rect.height) * 2;
  });

  // Responsive Resize
  window.addEventListener('resize', () => {
    const newWidth = container.clientWidth || 500;
    const newHeight = container.clientHeight || 480;
    camera.aspect = newWidth / newHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(newWidth, newHeight);
  });

  // Animation Loop
  let clock = new THREE.Clock();

  function animate() {
    requestAnimationFrame(animate);
    const elapsedTime = clock.getElapsedTime();

    // Constant smooth rotation
    mainMesh.rotation.y += 0.005;
    mainMesh.rotation.x += 0.003;

    // Mouse inertia tracking
    targetRotationY = mouseX * 0.6;
    targetRotationX = -mouseY * 0.6;

    mainMesh.rotation.y += (targetRotationY - mainMesh.rotation.y) * 0.05;
    mainMesh.rotation.x += (targetRotationX - mainMesh.rotation.x) * 0.05;

    // Orbiting particles
    particles.rotation.y = elapsedTime * 0.08;
    particles.rotation.x = elapsedTime * 0.04;

    // Gentle vertical hover breathing
    mainMesh.position.y = Math.sin(elapsedTime * 1.5) * 0.15;

    renderer.render(scene, camera);
  }

  animate();
}

/* ==========================================================================
   3. Scroll Reveal Animations
   ========================================================================== */
function initScrollAnimations() {
  const cards = document.querySelectorAll('.card, .pipeline-step, .teachers-card, .why-oreo-card, .final-cta-card');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  });

  cards.forEach(card => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(24px)';
    card.style.transition = 'opacity 0.6s cubic-bezier(0.16, 1, 0.3, 1), transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)';
    observer.observe(card);
  });
}

/* ==========================================================================
   4. Back to Top Smooth Scroll
   ========================================================================== */
function initBackToTop() {
  const backToTop = document.getElementById('back-to-top');
  if (backToTop) {
    backToTop.addEventListener('click', (e) => {
      e.preventDefault();
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }
}
