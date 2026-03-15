# gzgz — Thought Organizer

## Overview

gzgz is a standalone SwiftUI application that helps users organize unstructured thoughts — ideas, brainstorms, plans, todos, and more — into a structured, interactive, and visually connected graph. The app works fully without AI, but optionally integrates with AI agents (Claude, Codex, etc.) via a first-class MCP server and CLI built in Rust.

## Core Principles

- **Standalone first** — the app is fully functional without any AI connection
- **AI as plugin** — AI enhances but is never required; integrates via MCP/CLI
- **Local first** — data lives on the user's device; custom backend support for sync
- **Cross-platform trajectory** — Apple platforms (macOS + iOS) first, Windows/Linux/Android later

## Input

Users can input thoughts through multiple channels:
- **Text box** — paste or type a brain dump
- **Voice-to-text** — speak thoughts, transcribed into text
- **Chat-style** — send messages one at a time, conversationally
- **Mix** — freely combine any of the above in a single session

## Organization & Categories

- If the user defines categories, use them
- If no category is specified, AI (when connected) or the app auto-generates categories based on content
- Categories are always editable — rename, merge, split, delete at any time
- Without AI, users create and assign categories manually

## Interaction Model

Users can interact with organized thoughts through:
- **Drag & drop** — move items between categories
- **Edit in place** — tap/click to refine or rewrite any item
- **Expand / collapse** — drill into items, add sub-items and details
- **Priority / ordering** — reorder items within a category by importance
- **Action conversion** — turn an idea into a task (with due date), a plan into steps, etc.

## Relationships & Visualization

### Relationship Model
- **Simple links** — "related to" connections between any two items
- **Typed relationships** — "depends on", "inspires", "contradicts", "part of", and custom types
- **Hierarchical** — parent-child nesting (idea -> sub-ideas)
- **Lateral links** — connections across categories
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

```
+-------------------+       +---------------------------+
|                   |       |                           |
|   SwiftUI App     | <---> |   Rust MCP Server / CLI   | <---> AI Agents
|   (macOS + iOS)   |       |                           |       (Claude, Codex, etc.)
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

| Component         | Technology       | Rationale                                      |
|-------------------|------------------|-------------------------------------------------|
| App               | SwiftUI          | Native Apple experience, macOS + iOS            |
| Database          | SQLite           | Cross-platform, fast graph queries              |
| MCP Server / CLI  | Rust             | Best performance, low-level control, portable   |
| AI Integration    | Skills 2.0 / MCP | Standard protocol for agent interoperability    |
| Interchange       | JSON             | Universal, agent-friendly                       |

## MCP Server / CLI

The Rust server is a **first-class deliverable**, not an afterthought:

### MCP Server Capabilities
- Read the thought graph (items, categories, relationships)
- Create / update / delete items
- Auto-categorize items (delegates to connected AI)
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

## Name

**gzgz**
