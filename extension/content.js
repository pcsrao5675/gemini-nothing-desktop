// Gemini Floating Assistant - Android Style Attach Screen Pill
(function() {
  const SERVER_URL = "http://127.0.0.1:8765/screenshot";
  const DEFAULT_LABEL = "Attach Screen";
  let isCapturing = false;

  function createScreenPill() {
    if (document.getElementById("gemini-screen-pill-btn")) {
      return;
    }

    // Locate the prompt input container
    const composer = document.querySelector(".input-area-container") ||
                     document.querySelector("rich-textarea")?.closest(".bottom-container") ||
                     document.querySelector("rich-textarea")?.parentElement ||
                     document.querySelector(".chat-history-container") ||
                     document.querySelector("form");

    if (!composer) {
      return;
    }

    const container = document.createElement("div");
    container.id = "gemini-screen-pill-container";
    container.className = "gemini-screen-pill-container";

    const button = document.createElement("button");
    button.id = "gemini-screen-pill-btn";
    button.className = "gemini-screen-pill";
    button.type = "button";
    button.innerHTML = `
      <span class="gemini-screen-pill-icon">
        <svg viewBox="0 0 24 24">
          <path d="M20 3H4c-1.11 0-2 .89-2 2v12a2 2 0 0 0 2 2h4v2h8v-2h4a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zm0 14H4V5h16v12zm-2-2h-3v-2h3v2zm-5 0h-2v-2h2v2zm-4 0H6v-2h3v2z"/>
        </svg>
      </span>
      <span class="gemini-screen-pill-label">${DEFAULT_LABEL}</span>
    `;

    button.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (isCapturing) return;
      await handleAttachScreen(button);
    });

    container.appendChild(button);

    // Insert above rich-textarea
    const richTextarea = composer.querySelector("rich-textarea") || composer;
    if (richTextarea && richTextarea.parentElement) {
      richTextarea.parentElement.insertBefore(container, richTextarea);
    } else {
      composer.prepend(container);
    }
  }

  async function handleAttachScreen(button) {
    isCapturing = true;
    const label = button.querySelector(".gemini-screen-pill-label");

    button.className = "gemini-screen-pill loading";
    label.textContent = "Capturing screen...";

    try {
      const resp = await fetch(SERVER_URL);
      if (!resp.ok) {
        throw new Error(`Server returned HTTP ${resp.status}`);
      }

      const blob = await resp.blob();
      const file = new File([blob], `desktop_capture_${Date.now()}.png`, { type: "image/png" });

      await injectImageToGemini(file);

      button.className = "gemini-screen-pill success";
      label.textContent = "Screen Attached!";
      setTimeout(() => {
        button.className = "gemini-screen-pill";
        label.textContent = DEFAULT_LABEL;
        isCapturing = false;
      }, 2000);
    } catch (err) {
      console.error("[Gemini Assistant] Error capturing/attaching screen:", err);
      button.className = "gemini-screen-pill error";
      label.textContent = "Failed to attach";
      setTimeout(() => {
        button.className = "gemini-screen-pill";
        label.textContent = DEFAULT_LABEL;
        isCapturing = false;
      }, 3000);
    }
  }

  async function injectImageToGemini(file) {
    const editor = document.querySelector("rich-textarea [contenteditable='true']") ||
                   document.querySelector("[contenteditable='true']") ||
                   document.querySelector("rich-textarea") ||
                   document.querySelector("textarea");

    if (editor) {
      editor.focus();
    }

    const dt = new DataTransfer();
    dt.items.add(file);

    // Strategy 1: Look for existing file input
    const fileInputs = document.querySelectorAll('input[type="file"]');
    for (const input of fileInputs) {
      try {
        input.files = dt.files;
        input.dispatchEvent(new Event("change", { bubbles: true, composed: true }));
        input.dispatchEvent(new Event("input", { bubbles: true, composed: true }));
        return true;
      } catch (e) {}
    }

    // Strategy 2: Drop Event
    try {
      const dropTarget = editor || document.querySelector(".input-area-container") || document.body;
      dropTarget.dispatchEvent(new DragEvent("dragenter", { bubbles: true, cancelable: true, dataTransfer: dt }));
      dropTarget.dispatchEvent(new DragEvent("dragover", { bubbles: true, cancelable: true, dataTransfer: dt }));
      dropTarget.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, composed: true, dataTransfer: dt }));
    } catch (e) {}

    // Strategy 3: Paste Event
    try {
      const pasteEvent = new ClipboardEvent("paste", {
        bubbles: true,
        cancelable: true,
        composed: true,
        clipboardData: dt
      });
      const target = editor || document.activeElement || document.body;
      target.dispatchEvent(pasteEvent);
    } catch (e) {}

    return true;
  }

  function createWindowControls() {
    if (document.getElementById("gemini-window-controls")) {
      return;
    }

    const controls = document.createElement("div");
    controls.id = "gemini-window-controls";
    controls.className = "gemini-window-controls";

    const maxBtn = document.createElement("button");
    maxBtn.id = "gemini-maximize-btn";
    maxBtn.className = "gemini-ctrl-btn";
    maxBtn.title = "Maximize / Restore";
    maxBtn.type = "button";
    maxBtn.innerHTML = `
      <svg viewBox="0 0 24 24">
        <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>
      </svg>
    `;

    maxBtn.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      try {
        await fetch("http://127.0.0.1:8765/maximize");
      } catch (err) {
        console.error("[Gemini Assistant] Maximize error:", err);
      }
    });

    const closeBtn = document.createElement("button");
    closeBtn.id = "gemini-close-btn";
    closeBtn.className = "gemini-ctrl-btn gemini-close-btn";
    closeBtn.title = "Close (Esc / Meta+Space)";
    closeBtn.type = "button";
    closeBtn.innerHTML = `
      <svg viewBox="0 0 24 24">
        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
      </svg>
    `;

    closeBtn.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      try {
        await fetch("http://127.0.0.1:8765/close");
      } catch (err) {
        console.error("[Gemini Assistant] Close error:", err);
      }
    });

    controls.appendChild(maxBtn);
    controls.appendChild(closeBtn);
    document.body.appendChild(controls);
  }

  // Pressing Escape inside Gemini closes/minimizes it
  window.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      fetch("http://127.0.0.1:8765/close").catch(() => {});
    }
  });

  // Observer to keep pill & controls visible across navigation / DOM changes
  const observer = new MutationObserver(() => {
    createScreenPill();
    createWindowControls();
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

  setTimeout(() => {
    createScreenPill();
    createWindowControls();
  }, 500);
  setTimeout(() => {
    createScreenPill();
    createWindowControls();
  }, 1800);
})();

  // Active state reporting to helper daemon
  function reportActive(val) {
    fetch(`http://127.0.0.1:8765/active?val=${val ? 1 : 0}`).catch(() => {});
  }

  window.addEventListener("focus", () => reportActive(true));
  window.addEventListener("blur", () => {
    if (document.hidden) reportActive(false);
  });
  document.addEventListener("visibilitychange", () => {
    reportActive(!document.hidden);
  });
  window.addEventListener("beforeunload", () => reportActive(false));
  setTimeout(() => reportActive(!document.hidden), 1000);
