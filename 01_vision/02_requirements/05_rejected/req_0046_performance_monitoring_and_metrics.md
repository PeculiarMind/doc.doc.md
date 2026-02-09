# Requirement: Performance Monitoring and Metrics Collection

**ID**: req_0046

## Status
State: Rejected  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Rejection Reason
Performance monitoring and metrics collection is not aligned with the target use case and user profile. The toolkit is intended for offline operation on personal systems (homelabs, NAS devices, workstations) where users are unlikely to operate Application Performance Monitoring (APM) infrastructure or have sophisticated metrics collection needs. The complexity and overhead of metrics collection, export, and analysis infrastructure outweighs the value for the target audience. Users requiring performance verification can use standard Unix tools (`time`, `top`, `du`) externally. The majority of users will not benefit from built-in metrics, making this feature scope creep rather than core value.

## Overview
The system shall collect and log performance metrics during analysis execution, enabling users to monitor efficiency, identify bottlenecks, and verify compliance with quality requirements.

## Description
The Quality Requirements document (10_quality_requirements.md) defines measurable performance targets (memory usage < 200 MB, execution time < 30 min for 1K files, incremental analysis 10x faster) but there is no requirement ensuring the toolkit tracks these metrics. Users running large analyses need visibility into: total execution time, per-file processing time, plugin execution time, memory usage, files processed per second, and bottleneck identification. Metrics should be collected during normal operation with minimal overhead, logged when verbose mode enabled, and optionally output in machine-readable format (JSON) for automated monitoring. Performance data supports: optimization efforts, capacity planning, quality verification, and user troubleshooting.

## Motivation
From Quality Requirements (10_quality_requirements.md):
```
| Quality Attribute | Metric | Target | Measurement Method |
|-------------------|--------|--------|-------------------|
| Efficiency | Memory usage | < 200 MB | `top` during execution |
| | Execution time (1K files) | < 30 min | `time` command |
| | Workspace size | < 100 MB per 5K files | `du -sh workspace/` |
```

From quality scenario E2: "User analyzes large directory (10,000 files) first time. System processes all files. Measure: < 2 hours execution time, < 500 MB RAM usage."

Users cannot verify these quality goals are met without built-in metrics. External monitoring with `time`, `top` provides limited visibility into internal performance characteristics.

## Category
- Type: Non-Functional (Performance)
- Priority: Low

## Acceptance Criteria

### Timing Metrics
- [ ] System tracks total execution time from start to finish
- [ ] System tracks per-file processing time (averaged and per-file if verbose)
- [ ] System tracks per-plugin execution time (aggregated across all files)
- [ ] System tracks workspace operation time (read/write operations)
- [ ] System tracks report generation time
- [ ] Timing metrics use high-resolution timing (seconds with millisecond precision)

### Resource Metrics
- [ ] System tracks peak memory usage during execution (if available via `/proc/self/status`)
- [ ] System tracks workspace size growth during analysis
- [ ] System tracks number of files processed
- [ ] System tracks total bytes processed (sum of file sizes)
- [ ] Resource monitoring uses low-overhead methods (no continuous polling)

### Throughput Metrics
- [ ] System calculates files processed per second
- [ ] System calculates bytes processed per second
- [ ] System calculates average time per file
- [ ] Throughput metrics updated and logged at intervals (every 100 files or every minute)

### Bottleneck Detection
- [ ] System identifies slowest plugin (by total execution time)
- [ ] System identifies slowest file processing (if enabled)
- [ ] System logs warnings if processing rate drops significantly below target
- [ ] Bottleneck information included in summary metrics

### Metrics Output
- [ ] Verbose mode logs periodic performance updates during execution
- [ ] Final summary includes all collected metrics (total time, files/sec, peak memory)
- [ ] Optional JSON output file with complete metrics (`--metrics-output <file>`)
- [ ] JSON output includes: execution_time_seconds, files_processed, bytes_processed, peak_memory_mb, plugin_times, workspace_size_mb
- [ ] Metrics compatible with external monitoring tools (Prometheus, Grafana)

### Performance Overhead
- [ ] Metrics collection adds < 2% overhead to total execution time
- [ ] Metrics collection uses < 10 MB additional memory
- [ ] Metrics collection can be disabled if overhead is concern (`--no-metrics`)

### Integration
- [ ] Metrics included in workspace metadata for historical tracking
- [ ] Metrics visible in verbose output showing progress and bottlenecks
- [ ] Metrics accessible via command-line flag for automated monitoring
- [ ] Performance regression detection possible by comparing metrics across runs

## Related Requirements
- req_0006 (Verbose Logging Mode) - metrics logged in verbose mode
- req_0025 (Incremental Analysis) - metrics show incremental vs full analysis performance
- req_0032 (Workspace Directory Management) - workspace size metrics tracked

## Technical Considerations

### Timing Implementation
```bash
# Track overall execution time
SCRIPT_START_TIME=$(date +%s.%N)

# Track per-operation timing
operation_start=$(date +%s.%N)
# ... perform operation ...
operation_end=$(date +%s.%N)
operation_duration=$(echo "$operation_end - $operation_start" | bc)

# Final summary
SCRIPT_END_TIME=$(date +%s.%N)
total_duration=$(echo "$SCRIPT_END_TIME - $SCRIPT_START_TIME" | bc)
```

### Memory Usage Tracking
```bash
get_memory_usage() {
  if [ -f /proc/self/status ]; then
    grep VmRSS /proc/self/status | awk '{print $2}'  # KB
  else
    echo "0"  # Not available
  fi
}

PEAK_MEMORY=0
current_memory=$(get_memory_usage)
if [ "$current_memory" -gt "$PEAK_MEMORY" ]; then
  PEAK_MEMORY=$current_memory
fi
```

### Metrics Summary Example
```
================================================================================
Performance Summary
================================================================================
Total Execution Time:      15m 32s (932 seconds)
Files Processed:           1,247
Total Size Processed:      3.2 GB
Throughput:                1.34 files/sec, 3.5 MB/sec
Peak Memory Usage:         187 MB
Workspace Size:            42 MB

Plugin Execution Times:
  - stat:                  12s (1%)
  - file:                  23s (2%)
  - content-analyzer:      892s (96%)

Slowest Files:
  1. large_document.pdf    45s
  2. scan.tiff            38s
  3. archive.zip          29s

Target Compliance:
  ✓ Memory usage < 200 MB (187 MB)
  ✓ Execution time < 30 min for 1K files (15m for 1.2K files)
  ✓ Throughput acceptable
================================================================================
```

### JSON Metrics Output
```json
{
  "execution_time_seconds": 932,
  "execution_time_human": "15m 32s",
  "timestamp": "2026-02-09T14:45:32Z",
  "files_processed": 1247,
  "bytes_processed": 3435973632,
  "bytes_processed_human": "3.2 GB",
  "peak_memory_kb": 191488,
  "peak_memory_mb": 187,
  "workspace_size_bytes": 44040192,
  "workspace_size_mb": 42,
  "throughput": {
    "files_per_second": 1.34,
    "bytes_per_second": 3685438,
    "bytes_per_second_human": "3.5 MB/s",
    "avg_seconds_per_file": 0.75
  },
  "plugin_times": {
    "stat": 12.3,
    "file": 23.1,
    "content-analyzer": 892.4
  },
  "slowest_files": [
    {"path": "large_document.pdf", "time": 45.2},
    {"path": "scan.tiff", "time": 38.1},
    {"path": "archive.zip", "time": 29.4}
  ],
  "quality_compliance": {
    "memory_under_200mb": true,
    "time_under_30min_per_1k": true
  }
}
```

### Command-Line Interface
```bash
# Enable metrics output to file
./doc.doc.sh -d docs/ -t reports/ -w workspace/ --metrics-output metrics.json

# Disable metrics collection (minimal overhead mode)
./doc.doc.sh -d docs/ -t reports/ -w workspace/ --no-metrics

# Verbose mode shows metrics during execution
./doc.doc.sh -d docs/ -t reports/ -w workspace/ -v
```

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from Quality Requirements analysis
- [2026-02-09] Moved to rejected - not aligned with target use case (offline operation, homelab/NAS usage, no APM infrastructure assumption)
