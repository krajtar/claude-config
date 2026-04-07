---
name: explore
description: Deep read-only codebase exploration — dispatches parallel agents to investigate a question, returns structured answers with file:line references. Never modifies files.
model: haiku
allowed-tools: Read, Grep, Glob, Agent
argument-hint: <question about the codebase>
---

Deep codebase exploration. Read-only — never modify any files.

## Process

1. **Parse the question** from `$ARGUMENTS`. Identify:
   - What specifically is being asked (how does X work? where is Y defined? what calls Z?)
   - Which areas of the codebase are likely relevant

2. **Dispatch parallel exploration agents** across relevant domains:

   Choose 2-4 agents from these categories based on the question:
   - **Backend**: API routes, services, business logic, database queries
   - **Frontend**: Components, pages, state management, API calls
   - **Data**: Models, schemas, migrations, types/interfaces
   - **Config/Infra**: Build config, CI/CD, environment, deployment

   Each agent should:
   - Search for relevant files using Glob and Grep
   - Read the key files found
   - Report findings with exact `file:line` references

3. **Synthesize results** from all agents into a structured answer:
   - Direct answer to the question
   - Key files involved (with `file:line` references)
   - How the pieces connect (data flow, call chain, dependency graph)
   - Any surprises or gotchas discovered

4. **Completeness check**: Does the answer fully address the question? If agents found conflicting information or gaps, note them explicitly.

## Rules

- **Read-only**: Do NOT modify, create, or delete any files
- **Evidence-based**: Every claim must have a `file:line` reference
- **No assumptions**: If you can't find it in the code, say so — don't guess
- **Prefer depth over breadth**: It's better to thoroughly understand 3 key files than to skim 20
