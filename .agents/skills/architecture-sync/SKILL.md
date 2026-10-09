---
name: architecture-sync
description: Enforce 27-section ARCHITECTURE.md generation, reverse-engineering with file:line grounding, human approval gates, and same-turn synchronization during coding.
---

# Architecture Sync Skill (Antigravity & Codex)

## Overview
This skill guarantees architectural integrity across AI-assisted development sessions. It prevents "Vibe Coding degradation" where AI chooses the shortest path at the expense of modular boundaries and long-term maintainability.

## Core Disciplines
1. **Architecture First & Human Approval Gate**:
   - If `ARCHITECTURE.md` (or `docs/02-ky-thuat/architecture.md` / `docs/ARCHITECTURE.md`) does not exist, or its status is NOT `✅ Confirmed` / `✅ 確定済` (including initial `◼ Unconfirmed` draft):
   - Propose and generate the 27-section architecture specification and **require explicit human approval before generating any implementation code**.
   - In headless or non-interactive environments, keep status as `◼ Unconfirmed`, output only the architecture proposal/spec, and **do not generate code (AI self-approval is forbidden)**.
2. **Same-Turn Synchronization**:
   - Every structural change (services, schemas, routes, queues, external APIs, env vars) requires updating the architecture document in the exact same response turn. Zero architectural drift across commits.
3. **100% Grounding**:
   - All claims must cite real `file:line` references. Unimplemented or missing items must be declared as `> Not Found`.
4. **Unified Status Symbols**:
   - `✅` In Code (実装済み)
   - `◼` Planned (設計確定・未実装)
   - `⚠️` Drift / Review (乖離・要確認)
   - `~~Deprecated~~` (廃止・非推奨)

## Execution Flow
1. **Step 1: Check Target & Header Status**
   - Locate `docs/02-ky-thuat/architecture.md`, `docs/ARCHITECTURE.md`, or root `ARCHITECTURE.md`.
   - Inspect header: If file is absent or status is unconfirmed, trigger `/architecture-plan` or draft generation first.
2. **Step 2: Reverse-Engineering & Code Tracing**
   - Trace HTTP/WS request lifecycles: Client ➔ Gateway ➔ Frontend ➔ Core API ➔ DB/Workers ➔ External APIs.
   - Map directory tree to domain responsibilities.
3. **Step 3: Update Header & Changelog**
   - Header must include machine-readable marker:
     `<!-- archguard: synced=base-commit-hash status=confirmed date=YYYY-MM-DD -->`
     `> Last Updated: YYYY-MM-DD · Synced Commit: [base-commit-hash] · Status: ✅ Confirmed`
   - Append to §27 Changelog:
     `- YYYY-MM-DD · [commit-hash] · <Summary> · Sections: §4, §9`
