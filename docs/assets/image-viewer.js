(() => {
  "use strict";

  const diaryImages = Array.from(document.querySelectorAll("img"));
  if (diaryImages.length === 0) return;

  const viewer = document.createElement("div");
  viewer.className = "image-viewer";
  viewer.hidden = true;
  viewer.setAttribute("role", "dialog");
  viewer.setAttribute("aria-modal", "true");
  viewer.setAttribute("aria-label", "Full-resolution image viewer");
  viewer.innerHTML = `
    <div class="image-viewer__toolbar">
      <span class="image-viewer__title"></span>
      <button class="image-viewer__button" type="button" data-action="zoom-out" aria-label="Zoom out">−</button>
      <button class="image-viewer__button" type="button" data-action="reset">Fit</button>
      <button class="image-viewer__button" type="button" data-action="actual-size">100%</button>
      <button class="image-viewer__button" type="button" data-action="zoom-in" aria-label="Zoom in">+</button>
      <a class="image-viewer__original-link" target="_blank" rel="noopener">Open original</a>
      <button class="image-viewer__button" type="button" data-action="close" aria-label="Close image viewer">×</button>
    </div>
    <div class="image-viewer__canvas">
      <div class="image-viewer__transform">
        <img class="image-viewer__image" alt="">
      </div>
    </div>`;
  document.body.appendChild(viewer);

  const canvas = viewer.querySelector(".image-viewer__canvas");
  const transformLayer = viewer.querySelector(".image-viewer__transform");
  const fullImage = viewer.querySelector(".image-viewer__image");
  const title = viewer.querySelector(".image-viewer__title");
  const originalLink = viewer.querySelector(".image-viewer__original-link");
  const closeButton = viewer.querySelector('[data-action="close"]');

  const pointers = new Map();
  const MIN_ZOOM = 1;
  const MAX_ZOOM = 16;
  let zoom = 1;
  let panX = 0;
  let panY = 0;
  let previousFocus = null;
  let dragStart = null;
  let pinchStart = null;

  function renderTransform() {
    transformLayer.style.transform = `translate(${panX}px, ${panY}px) scale(${zoom})`;
    canvas.classList.toggle("is-zoomed", zoom > MIN_ZOOM);
  }

  function resetView() {
    zoom = MIN_ZOOM;
    panX = 0;
    panY = 0;
    renderTransform();
  }

  function setZoom(nextZoom, clientX, clientY) {
    const boundedZoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, nextZoom));
    const rect = canvas.getBoundingClientRect();
    const focalX = clientX ?? rect.left + rect.width / 2;
    const focalY = clientY ?? rect.top + rect.height / 2;
    const relativeX = focalX - (rect.left + rect.width / 2);
    const relativeY = focalY - (rect.top + rect.height / 2);
    const ratio = boundedZoom / zoom;

    panX = relativeX - (relativeX - panX) * ratio;
    panY = relativeY - (relativeY - panY) * ratio;
    zoom = boundedZoom;

    if (zoom === MIN_ZOOM) {
      panX = 0;
      panY = 0;
    }
    renderTransform();
  }

  function showActualSize() {
    const displayedWidth = fullImage.getBoundingClientRect().width / zoom;
    const actualSizeZoom = displayedWidth > 0 ? fullImage.naturalWidth / displayedWidth : 1;
    setZoom(actualSizeZoom);
  }

  function openViewer(sourceImage) {
    previousFocus = sourceImage;
    resetView();
    fullImage.src = sourceImage.currentSrc || sourceImage.src;
    fullImage.alt = sourceImage.alt || "Expanded diary image";
    title.textContent = sourceImage.alt || "Diary image";
    originalLink.href = fullImage.src;
    viewer.hidden = false;
    document.body.classList.add("image-viewer-open");
    closeButton.focus();
  }

  function closeViewer() {
    if (viewer.hidden) return;
    viewer.hidden = true;
    document.body.classList.remove("image-viewer-open");
    pointers.clear();
    fullImage.removeAttribute("src");
    previousFocus?.focus();
  }

  diaryImages.forEach((image) => {
    image.dataset.imageViewerReady = "";
    image.tabIndex = 0;
    image.setAttribute("role", "button");
    image.setAttribute("aria-label", `Open full-resolution view: ${image.alt || "diary image"}`);

    image.addEventListener("click", () => openViewer(image));
    image.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openViewer(image);
      }
    });
  });

  viewer.addEventListener("click", (event) => {
    const action = event.target.closest("[data-action]")?.dataset.action;
    if (action === "close") closeViewer();
    if (action === "reset") resetView();
    if (action === "actual-size") showActualSize();
    if (action === "zoom-in") setZoom(zoom * 1.4);
    if (action === "zoom-out") setZoom(zoom / 1.4);
    if (event.target === canvas) closeViewer();
  });

  canvas.addEventListener("wheel", (event) => {
    event.preventDefault();
    setZoom(zoom * (event.deltaY < 0 ? 1.15 : 1 / 1.15), event.clientX, event.clientY);
  }, { passive: false });

  canvas.addEventListener("pointerdown", (event) => {
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    canvas.setPointerCapture(event.pointerId);

    if (pointers.size === 1 && zoom > MIN_ZOOM) {
      dragStart = { x: event.clientX, y: event.clientY, panX, panY };
      canvas.classList.add("is-dragging");
    } else if (pointers.size === 2) {
      const [a, b] = Array.from(pointers.values());
      pinchStart = {
        distance: Math.hypot(a.x - b.x, a.y - b.y),
        zoom
      };
      dragStart = null;
    }
  });

  canvas.addEventListener("pointermove", (event) => {
    if (!pointers.has(event.pointerId)) return;
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });

    if (pointers.size === 2 && pinchStart) {
      const [a, b] = Array.from(pointers.values());
      const distance = Math.hypot(a.x - b.x, a.y - b.y);
      const midpointX = (a.x + b.x) / 2;
      const midpointY = (a.y + b.y) / 2;
      setZoom(pinchStart.zoom * distance / Math.max(1, pinchStart.distance), midpointX, midpointY);
    } else if (pointers.size === 1 && dragStart && zoom > MIN_ZOOM) {
      panX = dragStart.panX + event.clientX - dragStart.x;
      panY = dragStart.panY + event.clientY - dragStart.y;
      renderTransform();
    }
  });

  function releasePointer(event) {
    pointers.delete(event.pointerId);
    dragStart = null;
    pinchStart = null;
    canvas.classList.remove("is-dragging");
  }

  canvas.addEventListener("pointerup", releasePointer);
  canvas.addEventListener("pointercancel", releasePointer);

  document.addEventListener("keydown", (event) => {
    if (viewer.hidden) return;
    if (event.key === "Escape") closeViewer();
    if (event.key === "+" || event.key === "=") setZoom(zoom * 1.4);
    if (event.key === "-") setZoom(zoom / 1.4);
    if (event.key === "0") resetView();
  });
})();
