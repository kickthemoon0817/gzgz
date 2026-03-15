# gzgz — Thought Organizer

## Overview

gzgz is a cross-platform application that helps users organize unstructured thoughts — ideas, brainstorms, plans, todos, and more — into a structured, interactive, and visually connected graph. The app works fully without AI, but optionally integrates with AI agents (Claude, Codex, etc.) via a first-class MCP server and CLI built in Rust. Starting with Apple platforms (SwiftUI for macOS + iOS), with Windows, Linux, and Android planned.

## Core Principles

- **Standalone first** — the app is fully functional without any AI connection
- **AI as plugin** — AI enhances but is never required; integrates via MCP/CLI
- **Local first** — data lives on the user's device; custom backend support for sync
- **Cross-platform** — Apple platforms first, Windows/Linux/Android to follow

## Design

### Concept: Excalidraw Style

The visual language follows the hand-drawn, sketch aesthetic popularized by Excalidraw:

- Wobbly, marker-like lines instead of rigid geometric strokes
- Handwritten-style fonts for labels and text
- Informal, approachable feel — matches the "dump raw thoughts" use case
- Nodes, edges, and UI elements all carry the sketchy hand-drawn quality
- Feels like scribbling on a whiteboard, not operating a formal tool

### Core Color: Russian Violet

- **Primary**: `#32174D` (Russian Violet) — deep, rich purple as the identity color
- Used for primary UI accents, selected nodes, active edges, and key interactive elements
- Supporting palette derived from Russian Violet (lighter/darker tints, complementary tones) — to be refined during implementation

## Input (Agent-Facing)

When users want AI to organize their thoughts, they send unstructured input to the agent through:

- **Text box** — paste or type a brain dump for the agent to process
- **Voice-to-text** — speak thoughts, transcribed and sent to the agent
- **Chat-style** — send messages one at a time, conversationally with the agent
- **Mix** — freely combine any of the above in a single session

**Later / Optional:**

- **Image input** — send images (photos, sketches, screenshots) for the agent to extract and organize thoughts from

This is separate from the user's direct control of the application. Users can always create, organize, and manage thoughts manually without involving an agent (see Interaction Model below).

## Organization

- No categories — the app is a free-form space
- Thoughts exist as nodes in a graph; organization emerges from relationships and spatial arrangement
- Users structure their thinking through connections, nesting, and positioning — not by sorting into buckets
- When AI is connected, it suggests relationships and structure, not categories

## Canvas Experience

### First Impression

- **Pure blank canvas** — no icons, no buttons, no onboarding prompts. Like opening a fresh sketchbook.
- The canvas IS the app. Nothing stands between the user and their thoughts.

### Creating Nodes

- **Any input creates** — tap/click anywhere, just start typing, draw a shape, handwrite with Apple Pencil. Every gesture is valid.
- A node is a node — no types, no special behaviors. Meaning comes from what the user writes, where they place it, and how they connect it.
- The app must accept "garbage input instantly" — zero friction, zero structure required.

### Creating Connections

- **Draw a line** between two nodes
- **Drag nodes close** together and the app suggests a connection
- **Select two nodes** and choose a relationship type
- **Freehand line** between any two points, recognized as a connection
- Connections never block or interfere with other interactions — no modal dialogs, no forced workflows

### Navigating at Scale (50+ nodes)

- **Infinite zoom** — pinch/scroll freely, like a real infinite whiteboard
- **Focus mode** — tap a node to zoom into it and its immediate connections, dimming everything else
- **Spatial clusters** — nodes placed near each other form subtle visual groups (background shading), never forced

### Search (`Cmd+K` / `Ctrl+K`)

- Core feature, not an afterthought
- Robust search engine triggered by keyboard shortcut
- Searches across node text, connections, and canvases
- Matching nodes highlight directly on the canvas

### Multiple Canvases

- Default is one infinite canvas
- Users can create additional canvases when they want to separate concerns (work, side project, vacation)

### History (Photoshop-style)

- **Full operation history panel** — every action is recorded and visible
- **Standard undo/redo** (`Cmd+Z`) for immediate mistakes
- **Jump to any past state** — click any point in the history to rewind the canvas
- See how thinking evolved over time

### Later Features

- **Freehand drawing** — circles around node groups, annotations, doodling, raw ink strokes alongside the graph
- **Timeline view** — arrange nodes with dates along a time axis

## Interaction Model

Users can interact with nodes through:

- **Drag & drop** — move nodes freely on the canvas
- **Edit in place** — tap/click to refine or rewrite any item
- **Expand / collapse** — drill into items, add sub-items and details
- **Priority / ordering** — reorder or rank items by importance
- **Action conversion** — turn an idea into a task (with due date), a plan into steps, etc.

## Relationships & Visualization

### Relationship Model

- **Simple links** — "related to" connections between any two items
- **Typed relationships** — "depends on", "inspires", "contradicts", "part of", and custom types
- **Hierarchical** — parent-child nesting (idea -> sub-ideas)
- **Lateral links** — connections between any nodes across the graph
- AI can suggest relationship types; users can define their own

### Visualization

- **Primary view: Node graph** — mind-map style, items as nodes with typed edges, freely draggable
- Architecture supports diverse visualizations later (canvas board, list view, timeline, etc.)

## Data Architecture

### Storage

- **SQLite** (raw, not SwiftData) as the runtime database
  - Handles complex relationship/graph queries efficiently
  - Cross-platform (critical for future Windows/Android support)
- **JSON** as the interchange format for MCP/CLI communication

### Sync

- Local-first storage on device
- Custom backend support designed in from the start (API-ready data layer)
- No iCloud/CloudKit dependency

## System Architecture

```text
+-------------------+       +---------------------------+
|                   |       |                           |
|   Native App      | <---> |   Rust MCP Server / CLI   | <---> AI Agents
|   (SwiftUI first) |       |                           |       (Claude, Codex, etc.)
|                   |       |                           |
+--------+----------+       +-------------+-------------+
         |                                |
         |        SQLite (source of truth) |
         +------------->  <---------------+
                   |
         IPC notifications (Unix socket)
         for real-time change detection
```

### Communication

- **SQLite** as the single source of truth — both app and server read/write
- **IPC channel** (Unix domain socket) for real-time notifications between app and server
  - Server notifies app when AI agent adds/modifies items
  - App notifies server when user makes changes (optional)

## Technology Stack

| Component        | Technology       | Rationale                                     |
|------------------|------------------|-----------------------------------------------|
| App (Phase 1)    | SwiftUI          | Native Apple experience, macOS + iOS          |
| App (Phase 2)    | TBD              | Windows, Linux, Android — framework decided later |
| Database         | SQLite           | Cross-platform, fast graph queries            |
| MCP Server / CLI | Rust             | Best performance, low-level control, portable |
| AI Integration   | Skills 2.0 / MCP | Standard protocol for agent interoperability  |
| Interchange      | JSON             | Universal, agent-friendly                     |

## MCP Server / CLI

The Rust server is a **first-class deliverable**, not an afterthought:

### MCP Server Capabilities

- Read the thought graph (nodes and relationships)
- Create / update / delete items
- Suggest structure and relationships (delegates to connected AI)
- Suggest relationships between items
- Export/import thought graphs as JSON

### CLI Capabilities

- All MCP operations available as CLI commands
- Scriptable, pipeable, composable with other tools
- Direct SQLite access for performance

## Platforms

### Phase 1 (Current)

- macOS
- iOS

### Phase 2 (Future)

- Windows
- Linux (Ubuntu)
- Android
