#!/usr/bin/env bash
# Copyright (c) 2026 doc.doc.md Project
# This file is part of doc.doc.md.
#
# doc.doc.md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# doc.doc.md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with doc.doc.md. If not, see <https://www.gnu.org/licenses/>.

# Installation script for ocrmypdf plugin
# Installs ocrmypdf and its dependencies

set -euo pipefail

echo "Installing ocrmypdf and dependencies..."

# Check if running as root/sudo
if [[ $EUID -ne 0 ]]; then
    echo "This installation script requires root privileges."
    echo "Please run with sudo."
    exit 1
fi

# Update package lists
apt-get update -qq

# Install ocrmypdf and dependencies
# tesseract-ocr: OCR engine
# ghostscript: PDF processing
# unpaper: image preprocessing
apt-get install -y \
    ocrmypdf \
    tesseract-ocr \
    tesseract-ocr-eng \
    ghostscript \
    unpaper \
    python3-pip

# Verify installation
if command -v ocrmypdf >/dev/null 2>&1; then
    echo "ocrmypdf installed successfully."
    ocrmypdf --version
    exit 0
else
    echo "ERROR: ocrmypdf installation failed."
    exit 1
fi
