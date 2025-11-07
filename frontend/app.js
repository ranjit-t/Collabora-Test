// ========================================
// Configuration
// ========================================
const CONFIG = {
    apiBaseUrl: 'https://app-exp.dev.lan',
    collaboraServer: 'https://app-exp.dev.lan/browser/e808afa229/cool.html',
    maxFileSize: 25 * 1024 * 1024 // 25MB
};

// ========================================
// Global Variables
// ========================================
let currentDocumentId = null;
let currentDocumentName = null;
let documents = [];
let editorModal = null;
let uploadModal = null;

// ========================================
// Initialize on Page Load
// ========================================
document.addEventListener('DOMContentLoaded', function() {
    console.log('Document Management System initialized');

    // Initialize Bootstrap modals
    editorModal = new bootstrap.Modal(document.getElementById('editorModal'));
    uploadModal = new bootstrap.Modal(document.getElementById('uploadModal'));

    // Load documents
    loadDocuments();
});

// ========================================
// Load Documents from Backend
// ========================================
async function loadDocuments() {
    try {
        console.log('Fetching documents from:', CONFIG.apiBaseUrl + '/api/documents');

        const response = await fetch(CONFIG.apiBaseUrl + '/api/documents');
        const data = await response.json();

        console.log('Response:', data);

        if (data.success) {
            documents = data.documents;
            displayDocuments(documents);
        } else {
            throw new Error(data.error || 'Failed to load documents');
        }
    } catch (error) {
        console.error('Error loading documents:', error);
        showError('Failed to load documents: ' + error.message);

        // Show empty state on error
        document.getElementById('loading').style.display = 'none';
        document.getElementById('emptyState').style.display = 'block';
        document.getElementById('documentCount').textContent = 'Error loading documents';
    }
}

// ========================================
// Display Documents in Grid
// ========================================
function displayDocuments(docs) {
    const loading = document.getElementById('loading');
    const emptyState = document.getElementById('emptyState');
    const grid = document.getElementById('documentGrid');
    const countElement = document.getElementById('documentCount');

    loading.style.display = 'none';

    if (docs.length === 0) {
        emptyState.style.display = 'block';
        grid.style.display = 'none';
        countElement.textContent = 'No documents';
        return;
    }

    emptyState.style.display = 'none';
    grid.style.display = 'flex';
    countElement.textContent = docs.length + (docs.length === 1 ? ' Document' : ' Documents');

    // Clear grid
    grid.innerHTML = '';

    // Add document cards
    docs.forEach(doc => {
        const card = createDocumentCard(doc);
        grid.appendChild(card);
    });
}

// ========================================
// Create Document Card
// ========================================
function createDocumentCard(doc) {
    const col = document.createElement('div');
    col.className = 'col';

    const icon = getFileIcon(doc.extension);
    const size = formatFileSize(doc.size);
    const date = formatDate(doc.modified);

    col.innerHTML = `
        <div class="card document-card h-100" onclick="openDocument('${doc.id}', '${escapeHtml(doc.name)}')">
            <div class="card-body text-center">
                <div class="document-icon">${icon}</div>
                <h6 class="card-title">${escapeHtml(doc.name)}</h6>
                <p class="card-text text-muted small">
                    ${size} • ${date}
                </p>
            </div>
            <div class="card-footer bg-transparent">
                <button class="btn btn-sm btn-outline-primary w-100" onclick="event.stopPropagation(); openDocument('${doc.id}', '${escapeHtml(doc.name)}')">
                    <i class="bi bi-pencil"></i> Edit
                </button>
            </div>
        </div>
    `;

    return col;
}

// ========================================
// Open Document in Editor
// ========================================
function openDocument(fileId, fileName) {
    currentDocumentId = fileId;
    currentDocumentName = fileName;

    console.log('Opening document:', fileId, fileName);

    // Set modal title
    document.getElementById('editorTitle').textContent = fileName;

    // Build Collabora URL
    const wopiSrc = encodeURIComponent(CONFIG.apiBaseUrl + '/wopi/files/' + fileId);
    const collaboraUrl = CONFIG.collaboraServer + '?WOPISrc=' + wopiSrc;

    console.log('Collabora URL:', collaboraUrl);

    // Load document in iframe
    document.getElementById('collaboraFrame').src = collaboraUrl;

    // Show modal
    editorModal.show();
}

// ========================================
// Save Document (Collabora auto-saves)
// ========================================
function saveDocument() {
    alert('Document is automatically saved by Collabora!');
}

// ========================================
// Download Document
// ========================================
function downloadDocument() {
    if (!currentDocumentId) return;

    const downloadUrl = CONFIG.apiBaseUrl + '/api/download/' + currentDocumentId;
    console.log('Downloading:', downloadUrl);

    window.open(downloadUrl, '_blank');
}

// ========================================
// Print Document
// ========================================
function printDocument() {
    const iframe = document.getElementById('collaboraFrame');

    try {
        // Focus the iframe first
        iframe.focus();
        iframe.contentWindow.focus();

        // Small delay to ensure focus is set
        setTimeout(() => {
            try {
                const iframeWindow = iframe.contentWindow;
                const iframeDoc = iframeWindow.document;

                // Create both keydown and keyup events for Ctrl+P
                const isMac = /Mac|iPod|iPhone|iPad/.test(navigator.userAgent);

                const eventInit = {
                    key: 'p',
                    code: 'KeyP',
                    keyCode: 80,
                    which: 80,
                    charCode: 112,
                    ctrlKey: !isMac,
                    metaKey: isMac,
                    bubbles: true,
                    cancelable: true,
                    composed: true,
                    view: iframeWindow
                };

                // Dispatch keydown event
                const keydownEvent = new KeyboardEvent('keydown', eventInit);
                iframeDoc.dispatchEvent(keydownEvent);

                // Also try dispatching to the body and active element
                if (iframeDoc.body) {
                    iframeDoc.body.dispatchEvent(new KeyboardEvent('keydown', eventInit));
                }
                if (iframeDoc.activeElement) {
                    iframeDoc.activeElement.dispatchEvent(new KeyboardEvent('keydown', eventInit));
                }

                // Try dispatching to window as well
                iframeWindow.dispatchEvent(new KeyboardEvent('keydown', eventInit));

                console.log('Print command sent (Ctrl+P simulation)');

            } catch (innerError) {
                console.error('Failed to simulate keypress:', innerError);
                // Try the native print as fallback
                try {
                    iframe.contentWindow.print();
                } catch (printError) {
                    console.error('Native print also failed:', printError);
                }
            }
        }, 100);

    } catch (error) {
        console.error('Print error:', error);
        alert('Unable to trigger print. Please use File > Print or press Ctrl+P (Cmd+P on Mac) inside the document.');
    }
}

// ========================================
// Upload Files
// ========================================
async function uploadFiles() {
    const fileInput = document.getElementById('fileInput');
    const files = fileInput.files;

    if (!files || files.length === 0) {
        alert('Please select files to upload');
        return;
    }

    const progressBar = document.getElementById('progressBar');
    const uploadProgress = document.getElementById('uploadProgress');
    const uploadStatus = document.getElementById('uploadStatus');

    uploadProgress.style.display = 'block';
    uploadStatus.innerHTML = '';

    let uploaded = 0;
    let failed = 0;

    for (let i = 0; i < files.length; i++) {
        const file = files[i];

        try {
            // Check file size
            if (file.size > CONFIG.maxFileSize) {
                throw new Error('File too large (max 25MB)');
            }

            // Update progress
            const percent = Math.round((i / files.length) * 100);
            progressBar.style.width = percent + '%';
            uploadStatus.innerHTML = `Uploading ${file.name}... (${i + 1}/${files.length})`;

            // Upload file
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(CONFIG.apiBaseUrl + '/api/upload', {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                uploaded++;
            } else {
                throw new Error(data.error || 'Upload failed');
            }
        } catch (error) {
            console.error('Upload error:', error);
            failed++;
        }
    }

    // Complete
    progressBar.style.width = '100%';
    uploadStatus.innerHTML = `Upload complete! ${uploaded} successful, ${failed} failed`;

    // Reload documents after 1 second
    setTimeout(() => {
        uploadModal.hide();
        loadDocuments();

        // Reset form
        fileInput.value = '';
        uploadProgress.style.display = 'none';
        uploadStatus.innerHTML = '';
        progressBar.style.width = '0%';
    }, 1500);
}

// ========================================
// Utility Functions
// ========================================

function getFileIcon(extension) {
    const icons = {
        'docx': '<i class="bi bi-file-word-fill text-primary"></i>',
        'doc': '<i class="bi bi-file-word-fill text-primary"></i>',
        'xlsx': '<i class="bi bi-file-excel-fill text-success"></i>',
        'xls': '<i class="bi bi-file-excel-fill text-success"></i>',
        'pptx': '<i class="bi bi-file-ppt-fill text-danger"></i>',
        'ppt': '<i class="bi bi-file-ppt-fill text-danger"></i>',
        'odt': '<i class="bi bi-file-text-fill text-info"></i>',
        'ods': '<i class="bi bi-file-spreadsheet-fill text-info"></i>',
        'odp': '<i class="bi bi-file-slides-fill text-info"></i>'
    };

    return icons[extension.toLowerCase()] || '<i class="bi bi-file-earmark text-secondary"></i>';
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function formatDate(timestamp) {
    const date = new Date(timestamp * 1000);
    const now = new Date();
    const diffMs = now - date;
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return diffDays + ' days ago';

    return date.toLocaleDateString();
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showError(message) {
    alert('Error: ' + message);
}

// ========================================
// Console Info
// ========================================
console.log('========================================');
console.log('Document Management System');
console.log('========================================');
console.log('API Base URL:', CONFIG.apiBaseUrl);
console.log('Collabora Server:', CONFIG.collaboraServer);
console.log('========================================');
