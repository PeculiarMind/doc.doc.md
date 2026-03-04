# Tesseract OCR Plugin

- **ID:** FEATURE_0006
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-02
- **Created by:** Product Owner
- **Status:** REJECTED
- **Rejected at:** 2026-03-04
- **Rejected by:** Product Owner
- **Reason for rejection:** The ocrmypdf plugin will provide equivalent OCR functionality for images embedded in PDFs and standalone images, making a separate Tesseract plugin redundant.

## Overview

This feature proposed implementing a Tesseract-based OCR plugin for extracting text from images. However, the ocrmypdf plugin now covers the same use case, including direct image OCR support. Maintaining two separate plugins for the same function would increase maintenance burden without additional value.

## Related Links

- ocrmypdf plugin feature: [FEATURE_0005](../01_funnel/FEATURE_0005_ocrmypdf_plugin.md)
