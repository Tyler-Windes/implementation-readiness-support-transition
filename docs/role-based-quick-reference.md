# Role-Based Quick Reference

> **Synthetic enablement aid. No real training, attendance, adoption, competency, or production outcome is represented.**

## Requester

1. Supply request summary, category, business impact, requested outcome, and requester role. Missing Stage-A content keeps the request in `Draft`.
2. After submission, answer Stage-B clarification about urgency, requested-by timing, category-specific detail, or supporting constraints.
3. Review the modeled outcome; accept it or return it for rework.
4. Expect closure only after explicit synthetic acceptance.

## Request Coordinator

1. Recalculate Stage-B completeness after every clarification response.
2. Route only to Access/Permissions, Application/Workflow, Data/Reporting, or General Service.
3. Evaluate priority Critical, High, Medium, then Low; the first satisfied rule controls.
4. Retain coordination while no skill match exists; after assignment, maintain exactly one accountable Fulfiller and record every reassignment reason.
5. For clarification, `Blocked`, owner change, material timing change, validation entry, or closure, retain audience, reason, accountable owner, next action, and relative next-update label. Nothing is sent.

## Fulfiller

1. Move `Assigned` to `InProgress` after accepting the modeled work.
2. Use `Blocked` only with complete owner, reason, next-action, and update-label metadata.
3. Record the modeled outcome and move to `AwaitingRequesterValidation`.
4. Return rejected work to `InProgress`; close only after acceptance.

## Support Analyst

1. Distinguish Stage-B completeness, requester-validation/closure, and ownership/handoff concerns.
2. Select the matching runbook; no ticket is opened.
3. Preserve requester decision, resolution summary, accountable owner, category, support reference, and handoff note.
4. Escalate unresolved rule or ownership ambiguity to the Request Coordinator.

## Knowledge check

A fictional Data or reporting request has all five Stage-A fields, one affected team with a workaround, Near-term urgency, and a `T+3` requested-by window. The reporting period and exception-filter definition are initially missing.

- It reaches `Submitted` after Stage A.
- Missing Stage-B detail creates clarification, followed by a fresh completeness calculation.
- The supplied values are `Current reporting cycle` and `Include records with no accountable owner or state=Blocked`.
- The rules produce Medium priority and the Data/Reporting route.
- Assignment or reassignment leaves exactly one accountable Fulfiller.
- Closure requires requester decision, resolution summary, owner, category, support reference, and handoff note.

This text-only guide does not depend on color, images, hover behavior, or a specific platform.

