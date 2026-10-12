# CampusHub — Agent Guidelines & Skill Usage Protocol

## SKILL USAGE REQUIREMENT

1. Inspect the project for available skills, especially:
   - `.agent/skills/`
   - `SKILL.md` files
   - `skills-lock.json`
   - any other project-specific skill/instruction directories.

2. Identify ALL skills that are relevant to the current task.

3. Read the relevant `SKILL.md` files BEFORE making implementation decisions.

4. If `skills-lock.json` exists, inspect it and respect the installed/pinned skill versions.

5. Do NOT blindly use every available skill.
   - Inspect all available skills.
   - Select only the skills relevant to the current task.
   - Do not use unrelated skills.

6. A relevant skill MUST NOT be ignored just because you already know how to implement the task.

7. Follow the applicable skill instructions together with the existing CampusHub architecture and requirements.

8. Resolve conflicts using this priority:
   System instructions
   ↓
   Developer instructions
   ↓
   CampusHub project requirements
   ↓
   Applicable skill instructions
   ↓
   General implementation preferences

9. Before modifying code, understand:
   - existing architecture
   - existing modules
   - existing routes
   - existing providers/services
   - existing database models
   - existing APIs
   - existing reusable UI components
   - existing tests
   - relevant skills

10. Do NOT create duplicate:
    - APIs
    - services
    - repositories
    - providers
    - database models
    - routes
    - screens
    - widgets
    - components
    - authentication logic
    - RBAC logic

11. Reuse and extend existing architecture whenever possible.

12. Do NOT introduce fake, demo, mock, placeholder, or hardcoded production data unless the task explicitly requires isolated test fixtures.

13. For database-related work:
    - inspect the existing Prisma schema first
    - inspect existing migrations
    - understand relationships before changing models
    - preserve existing real data unless the task explicitly requests a development reset
    - never invent institutional data

14. For Flutter work:
    - inspect existing theme/design-system components
    - reuse existing widgets
    - respect light/dark mode
    - respect responsive layouts
    - respect existing Riverpod and GoRouter architecture
    - do not create duplicate state-management or navigation systems

15. For backend work:
    - inspect existing Express/TypeScript architecture
    - reuse existing authentication, authorization, services, repositories, validation, and error handling
    - enforce security/RBAC on the server
    - never rely only on Flutter/frontend permission checks

16. For testing:
    - identify the relevant existing tests
    - add/update tests where appropriate
    - run the relevant tests after implementation
    - run static analysis/build checks relevant to the changed code

17. Do not make unrelated changes.

18. If the requested task exposes an architectural problem, fix the minimum necessary underlying issue rather than adding another workaround.

---

## REQUIRED WORKFLOW

Follow this workflow for every task:

```text
Task Received
      ↓
Inspect CampusHub project
      ↓
Inspect available skills
      ↓
Identify relevant skills
      ↓
Read applicable SKILL.md files
      ↓
Check skills-lock.json if available
      ↓
Inspect existing architecture/code
      ↓
Create implementation plan
      ↓
Implement
      ↓
Run tests / analysis / build
      ↓
Review for duplication, fake data, security and regressions
      ↓
Final verification
      ↓
Report skills used
```

---

## MANDATORY REPORTING FORMAT

At the end of every task, report in the following format:

### Skills Used
- `<skill name>` — `<why it was relevant and how it was followed>`

### Implementation
- What was changed, created, or refactored

### Verification
- Tests run (names, counts, results)
- Static analysis and build check results
- Remaining issues (if any)

> **Important**: Do not start coding immediately. First determine which skills apply to the task and read them. If no relevant skill exists, continue using the established CampusHub architecture and project instructions. Do not claim a skill was used unless you actually inspected and followed it.
# Agent Instructions

> This file is mirrored across CLAUDE.md, AGENTS.md, and GEMINI.md so the same instructions load in any AI environment.

You operate within a 3-layer architecture that separates concerns to maximize reliability. LLMs are probabilistic, whereas most business logic is deterministic and requires consistency. This system fixes that mismatch.

## The 3-Layer Architecture

**Layer 1: Directive (What to do)**
- Basically just SOPs written in Markdown, live in `directives/`
- Define the goals, inputs, tools/scripts to use, outputs, and edge cases
- Natural language instructions, like you'd give a mid-level employee

**Layer 2: Orchestration (Decision making)**
- This is you. Your job: intelligent routing.
- Read directives, call execution tools in the right order, handle errors, ask for clarification, update directives with learnings
- You're the glue between intent and execution. E.g you don't try scraping websites yourself—you read `directives/scrape_website.md` and come up with inputs/outputs and then run `execution/scrape_single_site.py`

**Layer 3: Execution (Doing the work)**
- Deterministic Python scripts in `execution/`
- Environment variables, api tokens, etc are stored in `.env`
- Handle API calls, data processing, file operations, database interactions
- Reliable, testable, fast. Use scripts instead of manual work. Commented well.

**Why this works:** if you do everything yourself, errors compound. 90% accuracy per step = 59% success over 5 steps. The solution is push complexity into deterministic code. That way you just focus on decision-making.

## Operating Principles

**1. Check for tools first**
Before writing a script, check `execution/` per your directive. Only create new scripts if none exist.

**2. Self-anneal when things break**
- Read error message and stack trace
- Fix the script and test it again (unless it uses paid tokens/credits/etc—in which case you check w user first)
- Update the directive with what you learned (API limits, timing, edge cases)
- Example: you hit an API rate limit → you then look into API → find a batch endpoint that would fix → rewrite script to accommodate → test → update directive.

**3. Update directives as you learn**
Directives are living documents. When you discover API constraints, better approaches, common errors, or timing expectations—update the directive. But don't create or overwrite directives without asking unless explicitly told to. Directives are your instruction set and must be preserved (and improved upon over time, not extemporaneously used and then discarded).

## Self-annealing loop

Errors are learning opportunities. When something breaks:
1. Fix it
2. Update the tool
3. Test tool, make sure it works
4. Update directive to include new flow
5. System is now stronger

## File Organization

**Deliverables vs Intermediates:**
- **Deliverables**: Google Sheets, Google Slides, or other cloud-based outputs that the user can access
- **Intermediates**: Temporary files needed during processing

**Directory structure:**
- `.tmp/` - All intermediate files (dossiers, scraped data, temp exports). Never commit, always regenerated.
- `execution/` - Python scripts (the deterministic tools)
- `directives/` - SOPs in Markdown (the instruction set)
- `.env` - Environment variables and API keys
- `credentials.json`, `token.json` - Google OAuth credentials (required files, in `.gitignore`)

**Key principle:** Local files are only for processing. Deliverables live in cloud services (Google Sheets, Slides, etc.) where the user can access them. Everything in `.tmp/` can be deleted and regenerated.

## Summary

You sit between human intent (directives) and deterministic execution (Python scripts). Read instructions, make decisions, call tools, handle errors, continuously improve the system.

Be pragmatic. Be reliable. Self-anneal.
