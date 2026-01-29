# Data Flow Diagrams

> How data moves through the Griot & Grits system.

## 1. Artifact Ingestion Flow

When a curator uploads an oral history recording:

```mermaid
sequenceDiagram
    participant C as Curator
    participant F as Frontend
    participant B as Backend
    participant S as MinIO
    participant W as Whisper
    participant DB as MongoDB

    C->>F: Upload audio file
    F->>B: POST /artifacts
    B->>S: Store file (S3 PutObject)
    S-->>B: Object URL
    B->>DB: Create artifact record
    B->>W: POST /asr (audio file)
    W-->>B: Transcript JSON
    B->>DB: Update artifact with transcript
    B-->>F: Artifact created
    F-->>C: Success notification
```

## 2. Search Flow

When a user searches the collection:

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant B as Backend
    participant DB as MongoDB

    U->>F: Enter search query
    F->>B: GET /search?q=...
    B->>DB: Query artifacts
    DB-->>B: Matching documents
    B-->>F: Search results
    F-->>U: Display results
```

## 3. "Ask the Griot" Flow (RAG)

> **Note**: This flow is conceptual. The VectorDB and LLM components are future integrations and not currently deployed in this repository.

When a user asks a question:

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant B as Backend
    participant V as VectorDB (Conceptual)
    participant L as LLM (Conceptual)

    U->>F: Ask question
    F->>B: POST /ask
    B->>V: Similarity search
    V-->>B: Relevant chunks
    B->>L: Generate answer with context
    L-->>B: Answer + citations
    B-->>F: Response
    F-->>U: Display answer with sources
```

---

← [Back to Documentation Index](../README.md)
