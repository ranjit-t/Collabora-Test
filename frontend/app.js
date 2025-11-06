// =====================================================
// Configuration
// =====================================================

const CONFIG = {
    // Backend API endpoint (update if deployed to different location)
    apiBaseUrl: 'http://localhost:5001',

    // Collabora server URL (update this with your actual Collabora URL)
    // Get this from: curl http://localhost:9980/hosting/discovery | grep urlsrc | head -1
    collaboraServer: 'http://localhost:9980/browser/e808afa229/cool.html',

    // Maximum file size (25MB)
    maxFileSize: 25 * 1024 * 1024
};

// =====================================================
// State Management
// =====================================================

let currentDocuments = [];
let currentDocumentId = null;
let currentDocumentName = null;
let documentToDelete = null;

// =====================================================
// DOM Elements
// =====================================================

const elements = {
    // Main UI
    uploadBtn: document.getElementById('uploadBtn'),
    searchInput: document.getElementById('searchInput'),
    documentCount: document.getElementById('documentCount'),
    refreshBtn: document.getElementById('refreshBtn'),

    // Document Library
    loadingIndicator: document.getElementById('loadingIndicator'),
    emptyState: document.getElementById('emptyState'),
    documentsGrid: document.getElementById('documentsGrid'),

    // Upload Modal
    uploadModal: document.getElementById('uploadModal'),
    uploadZone: document.getElementById('uploadZone'),
    fileInput: document.getElementById('fileInput'),
    uploadProgress: document.getElementById('uploadProgress'),
    progressFill: document.getElementById('progressFill'),
    uploadStatus: document.getElementById('uploadStatus'),

    // Editor Modal
    editorModal: document.getElementById('editorModal'),
    editorTitle: document.getElementById('editorTitle'),
    downloadBtn: document.getElementById('downloadBtn'),
    closeEditorBtn: document.getElementById('closeEditorBtn'),
    collaboraFrame: document.getElementById('collaboraFrame'),

    // Delete Modal
    deleteModal: document.getElementById('deleteModal'),
    deleteFileName: document.getElementById('deleteFileName'),
    confirmDeleteBtn: document.getElementById('confirmDeleteBtn')
};

// =====================================================
// Utility Functions
// =====================================================

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
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min ago`;
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;

    return date.toLocaleDateString();
}

function getFileIcon(extension) {
    const icons = {
        'docx': '📄', 'doc': '📄',
        'xlsx': '📊', 'xls': '📊',
        'pptx': '📽️', 'ppt': '📽️',
        'odt': '📝',
        'ods': '📈',
        'odp': '🎞️'
    };
    return icons[extension.toLowerCase()] || '📄';
}

function showNotification(message, type = 'info') {
    // Simple notification - can be enhanced with a toast library
    console.log(`[${type.toUpperCase()}] ${message}`);
    alert(message);
}

// =====================================================
// API Functions
// =====================================================

async function fetchDocuments() {
    try {
        const response = await fetch(`${CONFIG.apiBaseUrl}/api/documents`);
        const data = await response.json();

        if (data.success) {
            return data.documents;
        } else {
            throw new Error(data.error || 'Failed to fetch documents');
        }
    } catch (error) {
        console.error('Error fetching documents:', error);
        showNotification('Failed to load documents: ' + error.message, 'error');
        return [];
    }
}

async function uploadFile(file) {
    try {
        // Validate file size
        if (file.size > CONFIG.maxFileSize) {
            throw new Error(`File size exceeds maximum limit of ${formatFileSize(CONFIG.maxFileSize)}`);
        }

        const formData = new FormData();
        formData.append('file', file);

        const response = await fetch(`${CONFIG.apiBaseUrl}/api/upload`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (data.success) {
            return data.document;
        } else {
            throw new Error(data.error || 'Upload failed');
        }
    } catch (error) {
        console.error('Error uploading file:', error);
        throw error;
    }
}

async function deleteDocument(fileId) {
    try {
        const response = await fetch(`${CONFIG.apiBaseUrl}/api/delete/${fileId}`, {
            method: 'DELETE'
        });

        const data = await response.json();

        if (data.success) {
            return true;
        } else {
            throw new Error(data.error || 'Delete failed');
        }
    } catch (error) {
        console.error('Error deleting document:', error);
        throw error;
    }
}

function getDownloadUrl(fileId) {
    return `${CONFIG.apiBaseUrl}/api/download/${fileId}`;
}

function getCollaboraUrl(fileId, filename) {
    const wopiSrc = encodeURIComponent(`${CONFIG.apiBaseUrl}/wopi/files/${fileId}`);
    return `${CONFIG.collaboraServer}?WOPISrc=${wopiSrc}`;
}

// =====================================================
// UI Rendering Functions
// =====================================================

function renderDocuments(documents) {
    elements.documentsGrid.innerHTML = '';

    if (documents.length === 0) {
        elements.loadingIndicator.style.display = 'none';
        elements.emptyState.style.display = 'flex';
        elements.documentsGrid.style.display = 'none';
        elements.documentCount.textContent = '0 documents';
        return;
    }

    elements.loadingIndicator.style.display = 'none';
    elements.emptyState.style.display = 'none';
    elements.documentsGrid.style.display = 'grid';

    documents.forEach(doc => {
        const card = createDocumentCard(doc);
        elements.documentsGrid.appendChild(card);
    });

    elements.documentCount.textContent = `${documents.length} document${documents.length !== 1 ? 's' : ''}`;
}

function createDocumentCard(doc) {
    const card = document.createElement('div');
    card.className = 'document-card';
    card.innerHTML = `
        <div class="document-icon">${getFileIcon(doc.extension)}</div>
        <div class="document-info">
            <h3 class="document-name" title="${doc.name}">${doc.name}</h3>
            <p class="document-meta">${formatFileSize(doc.size)} • ${formatDate(doc.modified)}</p>
        </div>
        <div class="document-actions">
            <button class="btn btn-icon" onclick="openDocument('${doc.id}', '${doc.name}')" title="Edit">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                    <path d="M15.502 1.94a.5.5 0 0 1 0 .706L14.459 3.69l-2-2L13.502.646a.5.5 0 0 1 .707 0l1.293 1.293zm-1.75 2.456-2-2L4.939 9.21a.5.5 0 0 0-.121.196l-.805 2.414a.25.25 0 0 0 .316.316l2.414-.805a.5.5 0 0 0 .196-.12l6.813-6.814z"/>
                    <path fill-rule="evenodd" d="M1 13.5A1.5 1.5 0 0 0 2.5 15h11a1.5 1.5 0 0 0 1.5-1.5v-6a.5.5 0 0 0-1 0v6a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5H9a.5.5 0 0 0 0-1H2.5A1.5 1.5 0 0 0 1 2.5v11z"/>
                </svg>
            </button>
            <button class="btn btn-icon" onclick="downloadDocument('${doc.id}')" title="Download">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                    <path d="M.5 9.9a.5.5 0 0 1 .5.5v2.5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-2.5a.5.5 0 0 1 1 0v2.5a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2v-2.5a.5.5 0 0 1 .5-.5z"/>
                    <path d="M7.646 11.854a.5.5 0 0 0 .708 0l3-3a.5.5 0 0 0-.708-.708L8.5 10.293V1.5a.5.5 0 0 0-1 0v8.793L5.354 8.146a.5.5 0 1 0-.708.708l3 3z"/>
                </svg>
            </button>
            <button class="btn btn-icon btn-danger" onclick="confirmDelete('${doc.id}', '${doc.name}')" title="Delete">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                    <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/>
                    <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/>
                </svg>
            </button>
        </div>
    `;

    // Make entire card clickable to open document
    card.style.cursor = 'pointer';
    card.addEventListener('click', (e) => {
        // Don't open if clicking on action buttons
        if (!e.target.closest('.document-actions')) {
            openDocument(doc.id, doc.name);
        }
    });

    return card;
}

// =====================================================
// Document Management Functions
// =====================================================

async function loadDocuments() {
    elements.loadingIndicator.style.display = 'flex';
    elements.emptyState.style.display = 'none';
    elements.documentsGrid.style.display = 'none';

    currentDocuments = await fetchDocuments();
    renderDocuments(currentDocuments);
}

function openDocument(fileId, filename) {
    currentDocumentId = fileId;
    currentDocumentName = filename;

    elements.editorTitle.textContent = filename;

    const collaboraUrl = getCollaboraUrl(fileId, filename);
    elements.collaboraFrame.src = collaboraUrl;

    elements.editorModal.style.display = 'flex';

    // Add fade-in animation
    setTimeout(() => {
        elements.editorModal.classList.add('modal-open');
    }, 10);
}

function closeEditor() {
    elements.editorModal.classList.remove('modal-open');

    setTimeout(() => {
        elements.editorModal.style.display = 'none';
        elements.collaboraFrame.src = '';
        currentDocumentId = null;
        currentDocumentName = null;

        // Reload documents to show any changes
        loadDocuments();
    }, 300);
}

function downloadDocument(fileId) {
    const url = getDownloadUrl(fileId);
    window.open(url, '_blank');
}

function confirmDelete(fileId, filename) {
    documentToDelete = fileId;
    elements.deleteFileName.textContent = filename;
    elements.deleteModal.style.display = 'flex';
}

async function performDelete() {
    if (!documentToDelete) return;

    try {
        await deleteDocument(documentToDelete);
        showNotification('Document deleted successfully', 'success');
        closeDeleteModal();
        loadDocuments();
    } catch (error) {
        showNotification('Failed to delete document: ' + error.message, 'error');
    }
}

// =====================================================
// Upload Functions
// =====================================================

function openUploadModal() {
    elements.uploadModal.style.display = 'flex';
    elements.uploadZone.style.display = 'flex';
    elements.uploadProgress.style.display = 'none';
}

function closeUploadModal() {
    elements.uploadModal.style.display = 'none';
    elements.fileInput.value = '';
}

async function handleFileUpload(files) {
    if (!files || files.length === 0) return;

    elements.uploadZone.style.display = 'none';
    elements.uploadProgress.style.display = 'block';

    const totalFiles = files.length;
    let uploadedFiles = 0;
    let failedFiles = 0;

    for (let i = 0; i < files.length; i++) {
        const file = files[i];

        try {
            elements.uploadStatus.textContent = `Uploading ${file.name}... (${i + 1}/${totalFiles})`;
            elements.progressFill.style.width = `${((i) / totalFiles) * 100}%`;

            await uploadFile(file);
            uploadedFiles++;

            elements.progressFill.style.width = `${((i + 1) / totalFiles) * 100}%`;
        } catch (error) {
            console.error(`Failed to upload ${file.name}:`, error);
            failedFiles++;
        }
    }

    // Show completion
    elements.uploadStatus.textContent = `Upload complete! ${uploadedFiles} successful, ${failedFiles} failed`;
    elements.progressFill.style.width = '100%';

    setTimeout(() => {
        closeUploadModal();
        loadDocuments();

        if (uploadedFiles > 0) {
            showNotification(`Successfully uploaded ${uploadedFiles} file${uploadedFiles !== 1 ? 's' : ''}`, 'success');
        }
        if (failedFiles > 0) {
            showNotification(`Failed to upload ${failedFiles} file${failedFiles !== 1 ? 's' : ''}`, 'error');
        }
    }, 1500);
}

// =====================================================
// Search/Filter Functions
// =====================================================

function filterDocuments(searchTerm) {
    const filtered = currentDocuments.filter(doc =>
        doc.name.toLowerCase().includes(searchTerm.toLowerCase())
    );
    renderDocuments(filtered);
}

// =====================================================
// Modal Management Functions
// =====================================================

function closeDeleteModal() {
    elements.deleteModal.style.display = 'none';
    documentToDelete = null;
}

// =====================================================
// Event Listeners
// =====================================================

// Upload button
elements.uploadBtn.addEventListener('click', openUploadModal);

// File input change
elements.fileInput.addEventListener('change', (e) => {
    handleFileUpload(e.target.files);
});

// Drag and drop
elements.uploadZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    elements.uploadZone.classList.add('drag-over');
});

elements.uploadZone.addEventListener('dragleave', (e) => {
    e.preventDefault();
    elements.uploadZone.classList.remove('drag-over');
});

elements.uploadZone.addEventListener('drop', (e) => {
    e.preventDefault();
    elements.uploadZone.classList.remove('drag-over');
    handleFileUpload(e.dataTransfer.files);
});

// Editor modal controls
elements.closeEditorBtn.addEventListener('click', closeEditor);
elements.downloadBtn.addEventListener('click', () => {
    if (currentDocumentId) {
        downloadDocument(currentDocumentId);
    }
});

// Delete confirmation
elements.confirmDeleteBtn.addEventListener('click', performDelete);

// Refresh button
elements.refreshBtn.addEventListener('click', loadDocuments);

// Search input
elements.searchInput.addEventListener('input', (e) => {
    filterDocuments(e.target.value);
});

// Close modals when clicking outside
window.addEventListener('click', (e) => {
    if (e.target === elements.uploadModal) {
        closeUploadModal();
    }
    if (e.target === elements.deleteModal) {
        closeDeleteModal();
    }
    if (e.target === elements.editorModal) {
        closeEditor();
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    // Escape key closes modals
    if (e.key === 'Escape') {
        if (elements.editorModal.style.display === 'flex') {
            closeEditor();
        } else if (elements.uploadModal.style.display === 'flex') {
            closeUploadModal();
        } else if (elements.deleteModal.style.display === 'flex') {
            closeDeleteModal();
        }
    }
});

// =====================================================
// Global Functions (for inline onclick handlers)
// =====================================================

window.openDocument = openDocument;
window.downloadDocument = downloadDocument;
window.confirmDelete = confirmDelete;
window.closeUploadModal = closeUploadModal;
window.closeDeleteModal = closeDeleteModal;

// =====================================================
// Initialize Application
// =====================================================

document.addEventListener('DOMContentLoaded', () => {
    console.log('Document Management System initialized');
    console.log('API Base URL:', CONFIG.apiBaseUrl);
    console.log('Collabora Server:', CONFIG.collaboraServer);

    // Load documents on startup
    loadDocuments();
});
