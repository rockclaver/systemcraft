---

name: generate-prd-from-prompt
description: Turn a vague product idea into an implementation-ready PRD by running structured discovery, closing ambiguity with explicit assumptions, and producing a production-grade document with detailed user stories, acceptance criteria, functional requirements, and delivery constraints.
user-invocable: true
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Generate PRD From Prompt

## Purpose

Transform a short idea or rough prompt into a **production-grade PRD** that engineers, designers, QA, and product owners can execute with minimal stakeholder follow-up.

The standard is not "good enough for a draft." The standard is "clear enough that a delivery team can build the product from start to finish."

---

## Core Principle

Do not jump straight into writing the PRD.

First:

1. Understand the product idea
2. Run structured clarification
3. Surface missing business decisions
4. Ask only the highest-value follow-up questions
5. Make explicit assumptions where the user does not know or does not care
6. Resolve ambiguity as far as reasonably possible
7. Produce a complete PRD with testable requirements

If the user gives only a one-line idea, the skill must still drive the process forward confidently.

---

## Operating Mode

The AI must behave like a senior product manager and delivery lead combined.

That means:

* Ask smart questions, not endless questions
* Prefer grouped, high-signal discovery over long scattered interrogations
* Drive toward decisions
* Fill gaps with explicit best-practice assumptions when needed
* Produce requirements engineers can implement and QA can validate

Do not offload product thinking back to the user when the AI can infer a reasonable default.

---

## Workflow

### Step 1: Interpret the Prompt

From the initial prompt, infer:

* Product type
* Likely primary users
* Likely business goal
* Likely workflows
* Likely risks and unknowns

Start by restating the interpreted concept in one short paragraph so the user can confirm direction.

---

### Step 2: Run Structured Discovery

Ask follow-up questions in **prioritized rounds**, not all at once.

Rules:

* Ask only the questions that materially affect scope, workflows, permissions, compliance, or delivery risk
* Group questions by category
* Prefer 6-12 strong questions in the first round
* If the user says "use best practice" or gives partial answers, continue using assumptions instead of blocking
* Run additional rounds only if critical ambiguity remains

The goal is to reduce ambiguity below implementation risk, not to extract every possible preference.

---

## Required Discovery Categories

The AI must cover these categories before finalizing the PRD.

### 1. Product Goal

* What business outcome should this product improve?
* What problem is being solved?
* What does success look like?

### 2. Users and Roles

* Who are the primary users?
* Are there different roles or permission levels?
* Who approves, reviews, manages, or administers the system?

### 3. Core Workflows

* What are the main end-to-end tasks users need to complete?
* What starts each workflow?
* What ends it successfully?
* What can block or interrupt it?

### 4. Data and Records

* What records must exist in the system?
* What data must be captured, edited, viewed, exported, or deleted?
* Are there attachments, notes, comments, or history requirements?

### 5. Business Rules

* What rules govern creation, editing, approval, assignment, visibility, and deletion?
* What validations are required?
* What states can records move through?

### 6. Permissions and Access

* Who can see what?
* Who can create, edit, approve, archive, export, or delete?
* Are there location, team, office, or department boundaries?

### 7. Notifications and Automation

* What reminders, alerts, escalations, or scheduled actions are needed?
* Should anything be assigned automatically?
* What events should trigger communication?

### 8. Reporting and Analytics

* What should managers, admins, or operators be able to measure?
* What dashboards, filters, exports, or audit views are required?

### 9. Integrations

* Does the system connect to auth providers, payroll, email, calendars, HR tools, CRMs, ERPs, storage providers, or APIs?
* What systems are source-of-truth versus sync targets?

### 10. Platforms and UX

* Is this web, mobile, tablet, or internal admin tooling?
* Are there expectations around speed, accessibility, localization, offline support, or ease of use?

### 11. Compliance and Security

* Are there privacy, HR, healthcare, finance, regional, or legal constraints?
* Are audit logs, consent, retention, or access reviews required?

### 12. Delivery Boundaries

* What is in scope for v1?
* What should be explicitly out of scope?
* Are there timing, budget, staffing, or rollout constraints?

---

## Question-Asking Rules

When asking clarification questions:

* Ask in business language, not architecture language
* Do not ask the user to design schemas, tables, APIs, or technical internals
* Do not ask vague questions if a concrete version is possible
* Prefer decision-shaping prompts such as:
  * "Should managers approve employee profile changes before they take effect?"
  * "Should office admins only manage their own office, or all offices?"
* If two or three sensible options exist, present them briefly and recommend one
* If the answer is obvious from the domain, assume it and label it

Bad question:

* "What entities should be in the database?"

Good question:

* "What employee records must the office maintain beyond name and contact details, such as role, manager, department, employment status, documents, or shift schedule?"

---

## Assumption Policy

If the user does not know, does not answer, or explicitly asks the AI to decide:

* Make a reasonable production-grade assumption
* Label it clearly as:

  > Assumption: ...

* Prefer common industry standards
* Prefer auditability, security, operational clarity, and maintainability over minimalism
* Do not leave material ambiguity unresolved if a safe assumption can close it

The PRD may include open questions only when they are truly external decisions that materially require stakeholder input. Otherwise, default them.

---

## Completion Standard

A PRD is only complete when:

* Key user roles are defined
* Core workflows are fully described
* Requirements are specific enough to implement
* Acceptance criteria are testable
* Failure cases are covered
* Permissions are clear
* Reporting, logging, and audit expectations are clear
* Non-functional requirements are concrete
* Scope boundaries are explicit
* Remaining open questions are minimal and non-blocking

If these are not true, continue discovery or add assumptions.

---

## Naming Convention

The PRD title must follow:

```text
prd-{feature-or-product-name}
```

Examples:

```text
prd-employee-office-crm
prd-inventory-management-system
prd-real-time-chat
```

---

## Required PRD Structure

Use this structure in order.

### 1. Overview

Include:

* Product summary
* Problem statement
* Business objective
* Target users
* Success metrics

---

### 2. Scope

#### In Scope

List the features, workflows, and operational capabilities included in this PRD.

#### Out of Scope

List explicit exclusions to prevent scope creep.

#### Assumptions

List all material assumptions made during discovery.

---

### 3. Users, Roles, and Permissions

Include:

* User types
* Role definitions
* Permission boundaries
* Access matrix if multiple roles exist

For each role, define what they can create, read, update, approve, export, archive, and delete.

---

### 4. User Journeys

Describe the main end-to-end workflows in narrative form.

Include:

* Trigger
* Preconditions
* Main flow
* Alternate flows
* Failure paths
* Completion state

---

### 5. Detailed User Stories

Each user story must include:

* Story ID
* User role
* Story statement using:

```text
As a [user type],
I want to [action],
So that [outcome].
```

* Priority
* Preconditions
* Acceptance criteria
* Validation or business rules
* Edge cases

Do not stop at generic stories. Cover:

* Primary flows
* Secondary flows
* Admin workflows
* Reporting workflows
* Failure and recovery flows
* Permission-sensitive flows

---

### 6. Functional Requirements

Write atomic, implementation-ready requirements with IDs such as `FR-1`, `FR-2`.

Organize by feature area:

* Core product features
* Supporting features
* Admin or backoffice features
* Reporting and audit features
* Notification and automation features

Each requirement must include:

* Requirement ID
* Title
* Description
* User or system behavior
* Validation rules
* Permission rules
* Error handling behavior
* Dependencies if relevant

Each requirement should be testable on its own.

---

### 7. Data Model and State Design

Include:

* Key entities
* Important fields
* Relationships
* Record ownership rules
* Lifecycle states
* State transitions
* Retention and archival expectations

Do not require full SQL schema, but provide enough structure to guide implementation.

---

### 8. Integrations and External Interfaces

If applicable, include:

* External systems
* Source-of-truth rules
* Sync direction
* Failure behavior
* Retry expectations
* Rate-limit or dependency considerations

If APIs are relevant, include:

* Endpoint purpose
* Request and response expectations
* Auth expectations
* Error behavior

Do not mark this optional if the product clearly requires integrations or internal APIs.

---

### 9. Edge Cases and Failure Handling

Cover:

* Invalid inputs
* Partial completion
* Duplicate actions
* Concurrency conflicts
* Permission denials
* Missing dependencies
* External integration failures
* Timeout, retry, and recovery behavior

---

### 10. Non-Functional Requirements

Write concrete requirements with IDs such as `NFR-1`, `NFR-2`.

Cover:

* Performance
* Scalability
* Security
* Reliability
* Accessibility
* Auditability
* Observability
* Data privacy
* Localization or timezone handling if relevant

Avoid vague statements such as "should be fast." Use measurable expectations where possible.

---

### 11. Analytics, Reporting, and Audit Logging

Define:

* Key events to track
* Operational metrics
* Product usage metrics
* Required reports or dashboards
* Export requirements
* Audit log expectations

Specify which actions must be logged with actor, timestamp, and before/after state where relevant.

---

### 12. Rollout, Migration, and Operational Readiness

Include when relevant:

* Rollout approach
* Data migration needs
* Backfill expectations
* Feature flags
* Training or onboarding implications
* Support and admin readiness

---

### 13. Testing and Acceptance Plan

Include:

* Critical test scenarios
* UAT coverage areas
* High-risk behaviors to validate
* Definition of done for release readiness

---

### 14. Open Questions

This section must be minimal.

Only include items that:

* materially require external stakeholder input
* cannot be responsibly defaulted
* block a final implementation decision

If no true open questions remain, explicitly state:

* No blocking open questions.

---

## Output Requirements

The final PRD must be:

* Clean markdown
* Detailed but readable
* Actionable for engineering
* Actionable for QA
* Explicit about assumptions
* Free of filler
* Free of generic PM language
* Written with enough precision to avoid repeated stakeholder clarification

---

## Behavior Rules

* Do not skip clarification unless the prompt is already highly detailed
* Do not produce shallow PRDs
* Do not ask users to define database schemas or internal architecture
* Do not assume frontend-only scope; include backend, data, security, and operations
* Prefer completeness over brevity
* Prefer concrete defaults over unresolved ambiguity
* If the domain is operationally sensitive, bias toward stronger permissions, audit logging, and approval controls
* If the product includes multiple roles, provide a permissions matrix
* If the product includes workflows, define states and transitions
* If the product includes management oversight, include reporting and audit requirements
* Every major feature must map back to user stories and functional requirements

---

## Final Goal

The final PRD should allow a delivery team to:

* start implementation immediately
* break work into epics, features, stories, and tasks
* design UX with minimal ambiguity
* build backend services and data models with clear intent
* create QA coverage from acceptance criteria
* minimize follow-up meetings with stakeholders
