# Synthetic Internal Service Request Workflow Transition

> **Synthetic, fictional, platform-neutral design exercise—not a real implementation.** No real client, user, production system, UAT, go-live, training, support operation, SLA, adoption, ROI, or outcome is represented.

## Problem and scope

The fictional current state uses email and a shared tracker. Intake is ambiguous, routing depends on individual judgment, accountable ownership is unclear, material status communication is inconsistent, and closure does not reliably preserve support context.

Four roles cover the bounded lifecycle: Requester, Request Coordinator, Fulfiller, and Support Analyst. The model contains discovery and requirements, configuration-readiness rules, RAID and decisions, synthetic UAT, two defect/retest chains, simulated go/no-go and rollback, six smoke checks, role guidance, three modeled hypercare days, three support cases, three runbooks, and handoff.

## Two-stage intake

### Stage A — minimum submission gate

A request may move from `Draft` to `Submitted` only when all five fields are present:

1. request summary;
2. category;
3. business impact;
4. requested outcome; and
5. requester role.

If any field is absent, direct submission is rejected and the request remains `Draft`. Stage-A failure never enters `ClarificationRequested`.

### Stage B — post-submission completeness review

After `Submitted`, the Request Coordinator checks urgency, requested-by relative window, category-specific detail, and supporting context or constraints needed to route and fulfill the request. Insufficient conditional detail moves the request to `ClarificationRequested`. Once the Requester supplies the missing detail, the request returns to `Submitted` and completeness is recalculated from current values.

## Configuration matrix

| Area | Rule |
|---|---|
| Categories and routes | Access or permission → Access/Permissions; Application or workflow issue → Application/Workflow; Data or reporting request → Data/Reporting; General service request → General Service. |
| Priority | Evaluate Critical, High, Medium, then Low; the first satisfied level controls. |
| Critical | Business-critical work is fully blocked, no viable workaround exists, and immediate action is required. |
| High | Multiple users or a time-sensitive commitment are materially affected, or one requester is fully blocked without a workaround. |
| Medium | A requester or team is affected but work can continue through a workaround, or a near-term requested-by window requires coordinated attention. |
| Low | Informational, routine, minor enhancement, or no near-term operational impact. |
| Assignment | Retain coordinator responsibility while no matching Fulfiller is available. After assignment, maintain exactly one accountable Fulfiller. Every reassignment requires a reason. |
| Communication triggers | Clarification, `Blocked`, accountable-owner change, material completion-window change, `AwaitingRequesterValidation`, and closure. |
| Communication fields | Audience, reason, accountable owner, next action, and relative next-update label. Nothing is sent. |
| Closure and handoff | Retain requester decision, resolution summary, accountable owner, category, support reference, and relevant handoff note before closure. |

## Allowed states

`Draft`, `Submitted`, `ClarificationRequested`, `Assigned`, `InProgress`, `Blocked`, `AwaitingRequesterValidation`, and `Closed`.

- `Draft → Submitted` only after Stage A passes.
- `Submitted → ClarificationRequested` only for insufficient Stage-B detail.
- `ClarificationRequested → Submitted` after detail is supplied and completeness is recalculated.
- `Submitted → Assigned` after category, priority, and one accountable Fulfiller are recorded.
- `Assigned → InProgress` when the Fulfiller accepts the modeled work.
- `InProgress → Blocked` only with complete blocker metadata.
- `Blocked → InProgress` when the modeled blocker clears.
- `InProgress → AwaitingRequesterValidation` after a modeled outcome is recorded.
- `AwaitingRequesterValidation → InProgress` for rework or `Closed` after explicit synthetic acceptance.
- `Closed` is terminal.

## Representative walkthrough

| Step | Evidence and decision |
|---:|---|
| 1 | A fictional Data or reporting request asks for a department-level exception view. All five Stage-A fields are present, so it reaches `Submitted`. |
| 2 | Urgency is Near-term and the requested-by window is `T+3`; the reporting period and exception-filter definition are missing. |
| 3 | The request enters `ClarificationRequested` with a complete static communication record. |
| 4 | The Requester supplies `Current reporting cycle` and `Include records with no accountable owner or state=Blocked`. |
| 5 | Completeness is recalculated and the request returns to `Submitted`. |
| 6 | One team is affected, a workaround exists, and timing is near-term, producing Medium priority. |
| 7 | The category maps to the Data/Reporting modeled skill context. |
| 8 | Exactly one Fulfiller becomes accountable and the request reaches `InProgress`. |
| 9 | A field-definition ambiguity creates `Blocked` with owner, reason, next action, and `T+1` update label. |
| 10 | The blocker clears and work returns to `InProgress`. |
| 11 | The outcome enters `AwaitingRequesterValidation`. |
| 12 | The Requester accepts; closure retains resolution context, support reference, and handoff note. |

## Readiness sequence

All eight final synthetic UAT results must pass, both findings must have passing retests, no unresolved Critical or High item may remain, and role/runbook guidance must be ready. The passing-retest requirement precedes the simulated go/no-go review. That review produces the GO decision governing transition, smoke checks, and handoff; the later evidence is not circular input to the decision.

Six smoke checks cover submission/reference, routing and priority, single ownership, invalid-transition rejection and blocker metadata, requester-validation closure, and support-reference retention. All six modeled checks pass, so rollback is not invoked. If any required check failed, the model would pause, restore the frozen baseline, preserve evidence, record a simulated communication, and revalidate.

