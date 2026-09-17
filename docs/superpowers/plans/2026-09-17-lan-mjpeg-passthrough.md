# LAN MJPEG Passthrough Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Serve silent live LAN preview as raw UVC JPEG over `/live.mjpeg` without H.264 transcode.

**Architecture:** `MjpegHub` keeps the latest JPEG. UVC `PIXEL_FORMAT_RAW` while LAN is on and RTMP is off. NanoHTTPD chunked `multipart/x-mixed-replace`. Home page uses `<img>`. Stop HLS-only encoder.

**Tech Stack:** Kotlin, NanoHTTPD, UVCAndroid, lan_http/index.html

## Global Constraints

- No live audio
- MJPEG format only for live
- RTMP switches callback to NV21; MJPEG pauses until ingest stops
- Do not revert unrelated uncommitted stream-bitrate / about WIP except where the same files must be edited
- Do not commit unless asked

---
