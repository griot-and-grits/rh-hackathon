# Glossary

> Definitions of terms and acronyms used in the Griot & Grits project.

## A

### API (Application Programming Interface)
A set of rules that allows different software entities to communicate with each other. We use a REST API built with FastAPI.

### ASR (Automatic Speech Recognition)
The technology that converts spoken language into text. We use OpenAI's Whisper model for this.

## C

### C4 Model
"Context, Containers, Components, and Code". A visual notation technique for modelling software architecture. We use Context (Level 1) and Container (Level 2) diagrams.

### ConfigMap
A Kubernetes object used to store non-confidential data in key-value pairs. Used to inject environment variables into Pods.

### Container
A lightweight, standalone, executable package of software that includes everything needed to run an application: code, runtime, system tools, system libraries and settings.

## D

### Deployment
A Kubernetes object that manages a set of replicated Pods. It ensures the desired number of Pods are running and manages updates (rollouts).

## F

### FastAPI
A modern, fast (high-performance), web framework for building APIs with Python 3.8+ based on standard Python type hints.

## G

### GitOps
A set of practices to manage infrastructure and application configurations using Git, an open-source version control system.

## H

### Hot-reload
A development feature where code changes are automatically detected and applied to the running application without a manual restart.

## K

### Kubernetes
An open-source container orchestration system for automating software deployment, scaling, and management. OpenShift is a distribution of Kubernetes.

## L

### LLM (Large Language Model)
A type of AI model designed to understand and generate human-like text. Used in our "Ask the Griot" feature.

## M

### Mermaid.js
A JavaScript-based diagramming and charting tool that renders Markdown-inspired text definitions to create and modify diagrams dynamically.

### MinIO
A high-performance, S3 compatible object storage. We use it to store audio files and artifacts.

### MongoDB
A source-available cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with optional schemas.

## N

### Namespace
A Kubernetes mechanism to isolate resources within a single cluster. In this project, each user gets their own namespace (e.g., `gng-jdoe`).

## O

### OpenShift
Red Hat's enterprise Kubernetes platform. It adds developer-friendly features like source-to-image builds, routes, and a web console.

## P

### Pod
The smallest deployable unit of computing that you can create and manage in Kubernetes. A Pod contains one or more containers.

### PVC (Persistent Volume Claim)
A request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources.

## R

### RAG (Retrieval-Augmented Generation)
An AI framework for retrieving facts from an external knowledge base to ground large language models (LLMs) on the most accurate, up-to-date information.

### REST (Representational State Transfer)
An architectural style that defines a set of constraints to be used for creating web services.

### RHOAI (Red Hat OpenShift AI)
A platform for building, training, and deploying AI models on OpenShift.

### Route
An OpenShift-specific object that exposes a Service at a host name, allowing external clients to reach it by name (like an Ingress).

## S

### S3 (Simple Storage Service)
An object storage service offering industry-leading scalability, data availability, security, and performance. MinIO provides an S3-compatible API.

## V

### Vector Database
A database that stores data as high-dimensional vectors, which are mathematical representations of features or attributes. Used for semantic search.

## W

### Whisper
A general-purpose speech recognition model. It is trained on a large dataset of diverse audio and is also a multitasking model that can perform multilingual speech recognition, speech translation, and language identification.

---

← [Back to Documentation Index](../README.md)
