# {{filename}}

## File Information
- **Path:** {{filepath_relative}}
- **Size:** {{file_size}} bytes ({{file_size_human}})
- **Owner:** {{file_owner}}
- **Last Modified:** {{file_last_modified}}

## Analysis
- **Last Analyzed:** {{generation_time}}

{{#if ocr_status}}
## OCR Results
- **Status:** {{ocr_status}}
- **Confidence:** {{ocr_confidence}}%

### Extracted Text
{{ocr_text_content}}
{{/if}}

