/**
 * Collabora CODE Frontend Application
 * Handles document loading and editor integration
 */

// Configuration - CHANGE THESE TO MATCH YOUR SERVER
const CONFIG = {
  // Your server domain
  serverDomain: "https://app-exp.dev.lan",

  // WOPI server endpoint
  wopiBase: "https://app-exp.dev.lan/wopi/files",

  // Collabora CODE editor URL (get from discovery endpoint)
  // To find this, run: curl -k https://app-exp.dev.lan/hosting/discovery | grep urlsrc
  collaboraServer: "https://app-exp.dev.lan/browser/e808afa229/cool.html",

  // File to open (must exist in backend/documents/)
  fileId: "mydoc",

  // Access token (for demo purposes, use a simple token)
  accessToken: "demo_token",
};

// DOM Elements
const openDocBtn = document.getElementById("openDocBtn");
const closeDocBtn = document.getElementById("closeDocBtn");
const collaboraFrame = document.getElementById("collaboraFrame");
const placeholder = document.getElementById("placeholder");
const statusText = document.getElementById("statusText");
const statusDot = document.querySelector(".status-dot");

// State
let isDocumentOpen = false;

/**
 * Update status message and indicator
 */
function updateStatus(message, type = "success") {
  statusText.textContent = message;

  // Remove all status classes
  statusDot.classList.remove("loading", "error");

  // Add appropriate class
  if (type === "loading") {
    statusDot.classList.add("loading");
  } else if (type === "error") {
    statusDot.classList.add("error");
  }
}

/**
 * Open document in Collabora editor
 */
function openDocument() {
  try {
    updateStatus("Loading document...", "loading");

    // Construct WOPI URL
    const wopiUrl = `${CONFIG.wopiBase}/${CONFIG.fileId}`;

    // Construct Collabora URL with parameters
    const collaboraUrl = `${CONFIG.collaboraServer}?WOPISrc=${encodeURIComponent(
      wopiUrl
    )}&access_token=${CONFIG.accessToken}`;

    console.log("Opening document:");
    console.log("  WOPI URL:", wopiUrl);
    console.log("  Collabora URL:", collaboraUrl);

    // Hide placeholder, show iframe
    placeholder.style.display = "none";
    collaboraFrame.style.display = "block";

    // Load Collabora editor
    collaboraFrame.src = collaboraUrl;

    // Update UI
    openDocBtn.style.display = "none";
    closeDocBtn.style.display = "inline-flex";
    isDocumentOpen = true;

    // Update status when iframe loads
    collaboraFrame.onload = () => {
      updateStatus("Document loaded", "success");
    };

    // Handle iframe errors
    collaboraFrame.onerror = () => {
      updateStatus("Failed to load editor", "error");
      console.error("Failed to load Collabora iframe");
    };
  } catch (error) {
    console.error("Error opening document:", error);
    updateStatus("Error opening document", "error");
  }
}

/**
 * Close document and reset UI
 */
function closeDocument() {
  // Clear iframe
  collaboraFrame.src = "about:blank";

  // Show placeholder, hide iframe
  collaboraFrame.style.display = "none";
  placeholder.style.display = "flex";

  // Update UI
  closeDocBtn.style.display = "none";
  openDocBtn.style.display = "inline-flex";
  isDocumentOpen = false;

  updateStatus("Ready", "success");
}

/**
 * Verify WOPI server is accessible
 */
async function verifyWopiServer() {
  try {
    const wopiUrl = `${CONFIG.wopiBase}/${CONFIG.fileId}`;
    const response = await fetch(wopiUrl);

    if (!response.ok) {
      console.warn("WOPI server check failed:", response.status);
      updateStatus("WOPI server not accessible", "error");
      return false;
    }

    const data = await response.json();
    console.log("WOPI server accessible, file info:", data);
    return true;
  } catch (error) {
    console.error("Error checking WOPI server:", error);
    updateStatus("Cannot connect to WOPI server", "error");
    return false;
  }
}

/**
 * Initialize application
 */
function init() {
  console.log("Initializing Collabora CODE frontend");
  console.log("Configuration:", CONFIG);

  // Event listeners
  openDocBtn.addEventListener("click", openDocument);
  closeDocBtn.addEventListener("click", closeDocument);

  // Verify WOPI server on startup (optional)
  // verifyWopiServer();

  updateStatus("Ready", "success");
}

// Initialize when DOM is ready
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}

// Listen for messages from Collabora (optional - for advanced integration)
window.addEventListener("message", (event) => {
  // Only accept messages from our Collabora server
  if (event.origin !== CONFIG.serverDomain) {
    return;
  }

  console.log("Message from Collabora:", event.data);

  // Handle Collabora messages here
  // Examples: document_loaded, document_saved, etc.
});
