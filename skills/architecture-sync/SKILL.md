---
name: architecture-sync
description: Enforce 27-section ARCHITECTURE.md generation, reverse-engineering with file:line grounding, and real-time synchronization during coding.
---

# Architecture Sync Skill (Antigravity & Codex)

## Overview
This skill guarantees architectural integrity across AI-assisted development sessions. It prevents "Vibe Coding degradation" where AI chooses the shortest path at the expense of architecture modularity.

## Capabilities
1. **Reverse-Engineering**: Scans an existing repository and generates a 27-section `ARCHITECTURE.md` grounded 100% in actual code with `file:line` citations. Missing components are explicitly marked as `> Not Found`.
2. **Architecture Planning**: Pre-designs system boundaries, request lifecycles, and database schemas with `◼ Planned` markers before any code is generated.
3. **Continuous Synchronization**: Updates the Architecture Registry (§27) and relevant sections whenever modules, routes, schemas, or integrations change.

## Execution Flow
1. **Step 1: Check Target File**
   - Look for `docs/02-ky-thuat/architecture.md` or root `ARCHITECTURE.md`.
2. **Step 2: Scan & Validate**
   - Trace HTTP/WS request lifecycle: Client ➔ Gateway ➔ Frontend ➔ Core API ➔ DB/Workers ➔ External APIs.
   - Map directory tree to domain responsibilities.
3. **Step 3: Output Specification**
   - Adhere strictly to the 27 standard sections.
   - Maintain header sync metadata (`> Last Updated: YYYY-MM-DD · Synced Commit: [hash] · Status: ✅ Confirmed`).
