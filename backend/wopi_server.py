#!/usr/bin/env python3
"""
WOPI Server for Collabora CODE Integration
Implements the WOPI protocol for document viewing and editing
"""

from flask import Flask, request, jsonify, send_file, abort, make_response
from flask_cors import CORS
import os
import time
import hashlib

app = Flask(__name__)

# Configure CORS to be fully permissive
CORS(app, resources={r"/*": {"origins": "*"}}, send_wildcard=True)

# Configuration
DOCS_DIR = os.path.join(os.path.dirname(__file__), "documents")
os.makedirs(DOCS_DIR, exist_ok=True)

# Ensure sample document exists
SAMPLE_DOC = os.path.join(DOCS_DIR, "mydoc.docx")

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
    return os.path.join(DOCS_DIR, f"{file_id}.docx")


def get_file_version(file_path):
    """Generate version hash based on file modification time and size"""
    if not os.path.exists(file_path):
        return "0"
    stat = os.stat(file_path)
    version_string = f"{stat.st_mtime}_{stat.st_size}"
    return hashlib.md5(version_string.encode()).hexdigest()[:8]


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
    """
    file_path = get_file_path(file_id)

    if not os.path.exists(file_path):
        app.logger.error(f"File not found: {file_path}")
        return abort(404, description=f"File {file_id} not found")

    try:
        size = os.path.getsize(file_path)
        version = get_file_version(file_path)

        info = {
            "BaseFileName": f"{file_id}.docx",
            "OwnerId": "wopi-server",
            "Size": size,
            "Version": version,
            "UserId": "demo-user",
            "UserFriendlyName": "Demo User",
            "UserCanWrite": True,
            "SupportsUpdate": True,
            "SupportsLocks": False,
            "SupportsGetLock": False,
            "SupportsExtendedLockLength": False,
            "UserCanNotWriteRelative": True,
            "PostMessageOrigin": "*"
        }

        app.logger.info(f"CheckFileInfo for {file_id}: size={size}, version={version}")

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


if __name__ == "__main__":
    # Check if sample document exists
    if not os.path.exists(SAMPLE_DOC):
        print(f"WARNING: Sample document not found at {SAMPLE_DOC}")
        print("Please copy mydoc.docx to the documents/ directory")

    # Run on port 5001
    print("Starting WOPI Server on port 5001...")
    print(f"Documents directory: {DOCS_DIR}")
    app.run(host="0.0.0.0", port=5001, debug=True)
