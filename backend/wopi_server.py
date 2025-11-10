#!/usr/bin/env python3
"""
WOPI Server for Collabora CODE Integration
Implements the WOPI protocol for document viewing and editing
With file upload, download, and management features
"""

from flask import Flask, request, jsonify, send_file, abort, make_response, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import time
import hashlib
import uuid

app = Flask(__name__)

# Configure CORS to be fully permissive
CORS(app, resources={r"/*": {"origins": "*"}}, send_wildcard=True)

# Configuration
DOCS_DIR = os.path.join(os.path.dirname(__file__), "documents")
os.makedirs(DOCS_DIR, exist_ok=True)

# Allowed file extensions
ALLOWED_EXTENSIONS = {'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp', 'doc', 'xls', 'ppt'}

# Maximum file size (25MB)
MAX_FILE_SIZE = 25 * 1024 * 1024
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Simple in-memory storage for file metadata
file_store = {}

# Remove security headers that block iframes
@app.after_request
def remove_security_headers(response):
    """Remove headers that prevent iframe embedding"""
    response.headers.pop('X-Frame-Options', None)
    response.headers.pop('Content-Security-Policy', None)
    response.headers.pop('X-Content-Type-Options', None)
    return response


def get_file_path(file_id):
    """Get the file path for a given file ID"""
    # Find the file with any supported extension
    for filename in os.listdir(DOCS_DIR):
        if filename.startswith(file_id + '.') and allowed_file(filename):
            return os.path.join(DOCS_DIR, filename)
    # Fallback to .docx for backward compatibility
    return os.path.join(DOCS_DIR, f"{file_id}.docx")


def get_file_version(file_path):
    """Generate version hash based on file modification time and size"""
    if not os.path.exists(file_path):
        return "0"
    stat = os.stat(file_path)
    version_string = f"{stat.st_mtime}_{stat.st_size}"
    return hashlib.md5(version_string.encode()).hexdigest()[:8]


def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def get_file_extension(filename):
    """Get file extension"""
    return filename.rsplit('.', 1)[1].lower() if '.' in filename else ''


def list_documents():
    """List all documents in the documents directory"""
    documents = []
    for filename in os.listdir(DOCS_DIR):
        if allowed_file(filename):
            file_path = os.path.join(DOCS_DIR, filename)
            file_id = filename.rsplit('.', 1)[0]
            stat = os.stat(file_path)
            documents.append({
                'id': file_id,
                'name': filename,
                'size': stat.st_size,
                'modified': stat.st_mtime,
                'extension': get_file_extension(filename)
            })
    # Sort by modified time, newest first
    documents.sort(key=lambda x: x['modified'], reverse=True)
    return documents


@app.route("/")
def root():
    """Root endpoint showing available endpoints"""
    host = request.host_url.rstrip("/")
    return f"""
    <html>
    <head><title>WOPI Server</title></head>
    <body>
        <h1>WOPI Server Running</h1>
        <p>Available endpoints:</p>
        <ul>
            <li>GET <code>{host}/wopi/files/{{file_id}}</code> - Check file info</li>
            <li>GET <code>{host}/wopi/files/{{file_id}}/contents</code> - Get file contents</li>
            <li>POST <code>{host}/wopi/files/{{file_id}}/contents</code> - Save file contents</li>
        </ul>
        <p>Sample file: <code>{host}/wopi/files/mydoc</code></p>
    </body>
    </html>
    """


@app.route("/wopi/files/<file_id>", methods=["GET"])
def check_file_info(file_id):
    """
    CheckFileInfo - WOPI endpoint
    Returns metadata about the file
    Supports permission query parameters: ?permissions=readonly or ?permissions=noprint
    """
    file_path = get_file_path(file_id)

    if not os.path.exists(file_path):
        app.logger.error(f"File not found: {file_path}")
        return abort(404, description=f"File {file_id} not found")

    try:
        size = os.path.getsize(file_path)
        version = get_file_version(file_path)
        filename = os.path.basename(file_path)

        # Get permissions from query parameters
        permissions = request.args.get('permissions', '')
        can_edit = 'readonly' not in permissions
        can_print = 'noprint' not in permissions

        info = {
            "BaseFileName": filename,
            "OwnerId": "wopi-server",
            "Size": size,
            "Version": version,
            "UserId": "demo-user",
            "UserFriendlyName": "Demo User",
            "UserCanWrite": can_edit,  # Controls editing capability
            "SupportsUpdate": can_edit,  # Controls if updates are supported
            "DisablePrint": not can_print,  # Controls printing capability
            "HidePrintOption": not can_print,  # Hides print button in Collabora UI
            "SupportsLocks": False,
            "SupportsGetLock": False,
            "SupportsExtendedLockLength": False,
            "UserCanNotWriteRelative": True,
            "PostMessageOrigin": "*"
        }

        app.logger.info(f"CheckFileInfo for {file_id}: size={size}, version={version}, can_edit={can_edit}, can_print={can_print}")

        resp = jsonify(info)
        resp.headers["Cache-Control"] = "no-store"
        return resp

    except Exception as e:
        app.logger.error(f"Error in check_file_info: {str(e)}")
        return abort(500, description=str(e))


@app.route("/wopi/files/<file_id>/contents", methods=["GET"])
def get_contents(file_id):
    """
    GetFile - WOPI endpoint
    Returns the file contents
    """
    file_path = get_file_path(file_id)

    if not os.path.exists(file_path):
        app.logger.error(f"File not found: {file_path}")
        return abort(404, description=f"File {file_id} not found")

    try:
        app.logger.info(f"Sending file contents for {file_id}")
        return send_file(
            file_path,
            mimetype="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            as_attachment=False
        )
    except Exception as e:
        app.logger.error(f"Error sending file: {str(e)}")
        return abort(500, description=str(e))


@app.route("/wopi/files/<file_id>/contents", methods=["POST", "PUT"])
def save_contents(file_id):
    """
    PutFile - WOPI endpoint
    Saves the updated file contents
    """
    file_path = get_file_path(file_id)

    try:
        # Get the raw bytes from the request
        data = request.get_data()

        if not data:
            app.logger.error("No data received in PUT request")
            return abort(400, description="No file data received")

        # Save the file
        with open(file_path, "wb") as f:
            f.write(data)

        app.logger.info(f"File saved: {file_id}, size: {len(data)} bytes")

        # Return success with updated file info
        return jsonify({
            "Name": f"{file_id}.docx",
            "Size": len(data),
            "Version": get_file_version(file_path)
        }), 200

    except Exception as e:
        app.logger.error(f"Error saving file: {str(e)}")
        return abort(500, description=str(e))


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "wopi-server",
        "timestamp": time.time()
    })


# =====================================================
# Document Management API Endpoints
# =====================================================

@app.route("/api/documents", methods=["GET"])
def get_documents():
    """List all documents"""
    try:
        documents = list_documents()
        return jsonify({
            "success": True,
            "documents": documents,
            "count": len(documents)
        })
    except Exception as e:
        app.logger.error(f"Error listing documents: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route("/api/upload", methods=["POST"])
def upload_document():
    """Upload a new document"""
    try:
        # Check if file part exists
        if 'file' not in request.files:
            return jsonify({
                "success": False,
                "error": "No file part in request"
            }), 400

        file = request.files['file']

        # Check if file is selected
        if file.filename == '':
            return jsonify({
                "success": False,
                "error": "No file selected"
            }), 400

        # Check if file is allowed
        if not allowed_file(file.filename):
            return jsonify({
                "success": False,
                "error": f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
            }), 400

        # Secure the filename
        filename = secure_filename(file.filename)

        # Generate unique filename if file already exists
        base_name, extension = filename.rsplit('.', 1)
        counter = 1
        while os.path.exists(os.path.join(DOCS_DIR, filename)):
            filename = f"{base_name}_{counter}.{extension}"
            counter += 1

        # Save file
        file_path = os.path.join(DOCS_DIR, filename)
        file.save(file_path)

        # Get file info
        file_id = filename.rsplit('.', 1)[0]
        stat = os.stat(file_path)

        app.logger.info(f"File uploaded: {filename}, size: {stat.st_size}")

        return jsonify({
            "success": True,
            "message": "File uploaded successfully",
            "document": {
                'id': file_id,
                'name': filename,
                'size': stat.st_size,
                'modified': stat.st_mtime,
                'extension': get_file_extension(filename)
            }
        })

    except Exception as e:
        app.logger.error(f"Error uploading file: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route("/api/download/<file_id>", methods=["GET"])
def download_document(file_id):
    """Download a document"""
    try:
        # Find the file
        matching_files = [f for f in os.listdir(DOCS_DIR) if f.startswith(file_id + '.')]

        if not matching_files:
            return jsonify({
                "success": False,
                "error": "File not found"
            }), 404

        filename = matching_files[0]
        file_path = os.path.join(DOCS_DIR, filename)

        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename
        )

    except Exception as e:
        app.logger.error(f"Error downloading file: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route("/api/delete/<file_id>", methods=["DELETE"])
def delete_document(file_id):
    """Delete a document"""
    try:
        # Find the file
        matching_files = [f for f in os.listdir(DOCS_DIR) if f.startswith(file_id + '.')]

        if not matching_files:
            return jsonify({
                "success": False,
                "error": "File not found"
            }), 404

        filename = matching_files[0]
        file_path = os.path.join(DOCS_DIR, filename)

        os.remove(file_path)

        app.logger.info(f"File deleted: {filename}")

        return jsonify({
            "success": True,
            "message": "File deleted successfully"
        })

    except Exception as e:
        app.logger.error(f"Error deleting file: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


if __name__ == "__main__":
    # Run on port 5001
    print("Starting WOPI Server on port 5001...")
    print(f"Documents directory: {DOCS_DIR}")
    print("Supported file types:", ', '.join(ALLOWED_EXTENSIONS))
    app.run(host="0.0.0.0", port=5001, debug=True)
