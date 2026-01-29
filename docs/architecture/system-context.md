# System Context Diagram

> High-level view of Griot & Grits and its external interactions.

## Overview

The Griot & Grits system preserves minority oral history through AI-powered transcription and semantic search.

## Diagram

```mermaid
flowchart TB
    %% Users
    Curator("Curator/Admin<br/>(User)")
    Public("Public User<br/>(User)")

    %% Core System
    subgraph GNG [Griot & Grits System]
        CoreSystem["Griot & Grits Platform<br/>(AI-powered oral history preservation)"]
    end

    %% External Systems
    OpenShift["OpenShift/RHOAI<br/>(Container Platform)"]
    Whisper["Whisper ASR<br/>(Speech-to-Text Service)"]
    LLM["LLM Service<br/>(RAG Question Answering)"]

    %% Relationships
    Curator -->|"Uploads artifacts, reviews transcripts"| CoreSystem
    Public -->|"Searches collection, asks questions"| CoreSystem
    
    CoreSystem -->|"Deployed on"| OpenShift
    CoreSystem -->|"Transcribes audio"| Whisper
    CoreSystem -->|"Answers questions via RAG"| LLM

    %% Styling
    classDef person fill:#08427b,color:#fff,stroke:#000
    classDef system fill:#1168bd,color:#fff,stroke:#000
    classDef external fill:#999999,color:#fff,stroke:#000

    class Curator,Public person
    class CoreSystem system
    class OpenShift,Whisper,LLM external
```

## Actors

| Actor | Description |
|-------|-------------|
| Curator/Admin | Museum staff who upload and curate oral history recordings |
| Public User | Researchers and public exploring the collection |

## External Systems

| System | Purpose |
|--------|---------|
| OpenShift/RHOAI | Hosts all containerized services |
| Whisper ASR | Converts audio to text transcripts |
| LLM Service | Provides "Ask the Griot" RAG functionality |

---

← [Back to Documentation Index](../README.md)
