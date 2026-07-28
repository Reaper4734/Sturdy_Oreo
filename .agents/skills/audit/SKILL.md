---
name: audit
description: Performs an exhaustive, file-by-file security and architecture audit of the backend. Will not stop or summarize until every single file is processed.
---

# Mission
Conduct a meticulous, file-by-file audit of the backend repository. Your primary constraint: **Do not summarize, conclude, or stop until EVERY backend file has been individually reviewed.**

# Instructions
1. **Initialize State:** 
   - Use your terminal tools to find all backend source files (e.g., `find src/ -type f -name "*.py"`).
   - Write this list to a temporary file called `.audit_checklist.txt`.
   - Create an empty `.audit_report.md`.

2. **The Audit Loop (STRICT ENFORCEMENT):**
   - Read exactly **ONE** file from `.audit_checklist.txt`.
   - Analyze it thoroughly for security vulnerabilities, logic bugs, unhandled edge cases, and performance bottlenecks.
   - Append your detailed findings for that specific file to `.audit_report.md`.
   - Remove that file's name from `.audit_checklist.txt`.

3. **Anti-Skipping Constraint:** 
   - DO NOT process more than 2 files per step. 
   - DO NOT write a summary or conclude the audit if `.audit_checklist.txt` has any remaining lines.
   - If you hit a token limit or timeout, output exactly: "Continuing audit, [X] files remaining."

4. **Finalization:** 
   - ONLY when `.audit_checklist.txt` is completely empty, you may read `.audit_report.md` and prepend a high-level executive summary to it.