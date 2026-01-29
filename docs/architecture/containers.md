# Container Diagram

> Internal services and their connections within the Griot & Grits platform.

## Overview

The platform consists of 5 main containers deployed on OpenShift.

## Diagram

```mermaid
flowchart TB
    subgraph Users
        Curator[Curator/Admin]
        Public[Public User]
    end

    subgraph GNG[Griot & Grits Platform]
        Frontend[Frontend<br/>Next.js :3000]
        Backend[Backend<br/>FastAPI :8000]
        MongoDB[(MongoDB<br/>:27017)]
        MinIO[(MinIO<br/>:9000/:9001)]
        Whisper[Whisper ASR<br/>:9000]
    end

    Curator --> Frontend
    Public --> Frontend
    Frontend -->|HTTP| Backend
    Backend -->|MongoDB Protocol| MongoDB
    Backend -->|S3 Protocol| MinIO
    Backend -->|HTTP| Whisper

    style Frontend fill:#4a9eff
    style Backend fill:#4a9eff
    style MongoDB fill:#4db33d
    style MinIO fill:#c72c48
    style Whisper fill:#ff6b6b
```

## Service Details

| Service | Technology | Port | Purpose |
|---------|------------|------|---------|
| Frontend | Next.js | 3000 | Web UI for curators and public |
| Backend | FastAPI (Python) | 8000 | REST API, business logic |
| MongoDB | MongoDB 6.0 | 27017 | Document database for artifacts |
| MinIO | MinIO | 9000 (API), 9001 (Console) | S3-compatible object storage |
| Whisper | Whisper ASR | 9000 | Speech-to-text transcription |

## Communication Protocols

- **Frontend <-> Backend**: HTTPS (REST API)
- **Backend <-> MongoDB**: MongoDB Wire Protocol
- **Backend <-> MinIO**: S3 API (HTTP)
- **Backend <-> Whisper**: HTTP (multipart/form-data)

---

← [Back to Documentation Index](../README.md)
