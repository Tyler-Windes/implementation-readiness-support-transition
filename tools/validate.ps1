[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$WriteReadback
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Terminal = 'PASS_IMPLEMENTATION_READINESS_SUPPORT_TRANSITION_VALIDATION'
$Boundary = 'SYNTHETIC_EXERCISE_ONLY; NO_REAL_IMPLEMENTATION_OR_OUTCOME; NOT_PUBLICLY_APPROVED'
$ReadbackRelative = 'evidence/validation-readback.json'
$ExpectedFiles = @(
    '.gitattributes',
    '.gitignore',
    'CASE_STUDY.md',
    'LIMITATIONS.md',
    'README.md',
    'docs/role-based-quick-reference.md',
    'docs/scenario-and-configuration.md',
    'docs/support-runbooks-and-handoff.md',
    'evidence/cutover-go-no-go-rollback-smoke-checks.csv',
    'evidence/defect-retests.csv',
    'evidence/needs-requirements-acceptance-readiness.csv',
    'evidence/raid-decisions.csv',
    'evidence/uat-cases-results.csv',
    'evidence/validation-readback.json',
    'evidence/validation-summary.json',
    'tools/validate.ps1'
)

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Get-RelativePath([string]$BasePath, [string]$FullPath) {
    $base = [IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
    $full = [IO.Path]::GetFullPath($FullPath)
    return $full.Substring($base.Length).Replace('\', '/')
}

function Get-Sha256([byte[]]$Bytes) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-', '') }
    finally { $algorithm.Dispose() }
}

function Read-StrictUtf8([string]$Path) {
    $encoding = [Text.UTF8Encoding]::new($false, $true)
    return [IO.File]::ReadAllText($Path, $encoding)
}

function Read-CsvRows([string]$RelativePath, [int]$ExpectedRows, [string[]]$ExpectedHeaders) {
    $path = Join-Path $script:Root $RelativePath
    $text = Read-StrictUtf8 $path
    Add-Type -AssemblyName Microsoft.VisualBasic
    $parser = [Microsoft.VisualBasic.FileIO.TextFieldParser]::new($path, [Text.Encoding]::UTF8, $true)
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $physicalRows = New-Object 'System.Collections.Generic.List[object]'
    try {
        while (-not $parser.EndOfData) { [void]$physicalRows.Add($parser.ReadFields()) }
    } finally { $parser.Dispose() }
    Assert-True ($physicalRows.Count -eq ($ExpectedRows + 1)) "$RelativePath physical row count mismatch"
    foreach ($physicalRow in $physicalRows) {
        Assert-True ($physicalRow.Count -eq $ExpectedHeaders.Count) "$RelativePath physical row width mismatch"
    }
    $rows = @($text | ConvertFrom-Csv)
    Assert-True ($rows.Count -eq $ExpectedRows) "$RelativePath expected $ExpectedRows rows; found $($rows.Count)"
    $headers = @($rows[0].PSObject.Properties.Name)
    Assert-True (($headers -join '|') -ceq ($ExpectedHeaders -join '|')) "$RelativePath header mismatch"
    foreach ($row in $rows) {
        foreach ($property in $row.PSObject.Properties) {
            $value = [string]$property.Value
            Assert-True (-not [string]::IsNullOrWhiteSpace($value)) "$RelativePath has a blank $($property.Name) value"
            $trimmed = $value.TrimStart()
            Assert-True ($trimmed.Length -eq 0 -or '=+-@'.IndexOf($trimmed[0]) -lt 0) "$RelativePath contains a formula-like value"
        }
        Assert-True ($row.Exercise_Boundary -ceq $Boundary) "$RelativePath has an unexpected exercise boundary"
    }
    return ,$rows
}

function Get-Inventory {
    return @(
        Get-ChildItem -LiteralPath $script:Root -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
            ForEach-Object { Get-RelativePath $script:Root $_.FullName } |
            Sort-Object
    )
}

function Get-CandidateDigest([string[]]$Inventory) {
    $records = foreach ($relative in ($Inventory | Where-Object { $_ -ne $ReadbackRelative } | Sort-Object)) {
        $path = Join-Path $script:Root ($relative.Replace('/', '\'))
        $bytes = [IO.File]::ReadAllBytes($path)
        '{0}|{1}|{2}' -f $relative, $bytes.Length, (Get-Sha256 $bytes)
    }
    return Get-Sha256 ([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))
}

$Root = [IO.Path]::GetFullPath($RepositoryRoot)
Assert-True (Test-Path -LiteralPath $Root -PathType Container) 'Repository root does not exist'
$readbackPath = Join-Path $Root ($ReadbackRelative.Replace('/', '\'))

$inventory = Get-Inventory
$allowedBeforeReadback = @($ExpectedFiles | Where-Object { $_ -ne $ReadbackRelative })
if ($WriteReadback -and -not (Test-Path -LiteralPath (Join-Path $Root $ReadbackRelative))) {
    Assert-True (($inventory -join '|') -ceq (($allowedBeforeReadback | Sort-Object) -join '|')) 'Repository topology differs before readback generation'
} else {
    Assert-True (($inventory -join '|') -ceq (($ExpectedFiles | Sort-Object) -join '|')) 'Repository topology differs from the exact public candidate allowlist'
}

$allText = New-Object Text.StringBuilder
$surfaceText = New-Object Text.StringBuilder
foreach ($relative in $inventory) {
    $path = Join-Path $Root ($relative.Replace('/', '\'))
    Assert-True ((Get-Item -LiteralPath $path).Length -gt 0) "$relative is zero bytes"
    $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($extension -in @('.md', '.csv', '.json', '.ps1', '.txt', '')) {
        $content = Read-StrictUtf8 $path
        [void]$allText.AppendLine($content)
        if ($relative -notin @('tools/validate.ps1', $ReadbackRelative)) {
            [void]$surfaceText.AppendLine($content)
        }
    }
}

$requirements = Read-CsvRows 'evidence/needs-requirements-acceptance-readiness.csv' 24 @(
    'Record_Type','Controlled_ID','Title','Statement','Parent_IDs','Owner_Role','Priority','Configuration_Rule','Readiness_State','Validation_Method','Expected_Result','Traceability_Targets','Assumptions','Status','Notes','Exercise_Boundary'
)
$raid = Read-CsvRows 'evidence/raid-decisions.csv' 9 @(
    'Record_Type','Controlled_ID','Title','Statement','RAID_Type','Severity_Impact','Owner_Role','Mitigation_or_Resolution','Status','Related_IDs','Decision_Rationale','Relative_Timing','Next_Action','Traceability_Targets','Exercise_Boundary'
)
$uat = Read-CsvRows 'evidence/uat-cases-results.csv' 8 @(
    'Controlled_ID','Title','Scenario_or_Precondition','Steps','Expected_Result','Initial_Result','Evidence','Related_REQ_IDs','Related_ACC_IDs','Defect_ID','Retest_Result','Final_Result','Readiness_Implication','Owner_Role','Status','Notes','Exercise_Boundary'
)
$defects = Read-CsvRows 'evidence/defect-retests.csv' 2 @(
    'Controlled_ID','Failed_UAT_ID','Severity','Observed_Result','Expected_Result','Synthetic_Reproduction_Steps','Root_Cause_Hypothesis','Disposition','Bounded_Correction','Retest_UAT_ID','Retest_Result','Final_State','Decision_ID','Support_Runbook_Implication','Owner_Role','Notes','Exercise_Boundary'
)
$cutover = Read-CsvRows 'evidence/cutover-go-no-go-rollback-smoke-checks.csv' 7 @(
    'Controlled_ID','Title','Item_Type','Sequence','Relative_Time','Action_or_Check','Owner_Role','Predecessor_IDs','Readiness_Evidence','Status','Decision_or_Requirement_Links','Rollback_Relevance','Rollback_Trigger','Rollback_Action','Communication_Audience','Smoke_Check_Outcome','Notes','Exercise_Boundary'
)

$expectedFamilies = [ordered]@{ NEED=6; REQ=8; ACC=10; RAID=6; DEC=3; UAT=8; DEF=2; CUT=7; SUP=3; RUN=3 }
$expectedIds = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($family in $expectedFamilies.Keys) {
    for ($index = 1; $index -le $expectedFamilies[$family]; $index++) {
        [void]$expectedIds.Add(('{0}-{1:D3}' -f $family, $index))
    }
}
$observedIds = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($match in [regex]::Matches($allText.ToString(), '\b(?:NEED|REQ|ACC|RAID|DEC|UAT|DEF|CUT|SUP|RUN)-\d{3}\b')) {
    [void]$observedIds.Add($match.Value)
}
Assert-True ($observedIds.Count -eq 56) "Expected 56 unique evidence IDs; found $($observedIds.Count)"
Assert-True (@($observedIds | Where-Object { -not $expectedIds.Contains($_) }).Count -eq 0) 'Unexpected evidence ID found'
Assert-True (@($expectedIds | Where-Object { -not $observedIds.Contains($_) }).Count -eq 0) 'Expected evidence ID missing'

Assert-True (@($uat | Where-Object Initial_Result -eq 'PASS').Count -eq 6) 'Initial UAT PASS count must be 6'
Assert-True (@($uat | Where-Object Initial_Result -eq 'FAIL').Count -eq 2) 'Initial UAT FAIL count must be 2'
Assert-True (@($uat | Where-Object Retest_Result -eq 'PASS').Count -eq 2) 'Passing retest count must be 2'
Assert-True (@($uat | Where-Object Final_Result -eq 'PASS').Count -eq 8) 'Final UAT PASS count must be 8'
Assert-True (@($defects | Where-Object Retest_Result -eq 'PASS').Count -eq 2) 'Both defect retests must pass'
Assert-True (@($defects | Where-Object { $_.Final_State -notlike 'Resolved*' }).Count -eq 0) 'Both defects must be resolved after retest'

$raidById = @{}; foreach ($row in $raid) { $raidById[$row.Controlled_ID] = $row }
Assert-True ($raidById['DEC-002'].Statement -match 'before CUT-004') 'DEC-002 must require retests before CUT-004'
Assert-True ($raidById['DEC-003'].Statement -match 'produced by CUT-004') 'DEC-003 must result from CUT-004'
Assert-True ($raidById['DEC-003'].Statement -match 'CUT-005 through CUT-007') 'DEC-003 must govern CUT-005 through CUT-007'

$cutById = @{}; foreach ($row in $cutover) { $cutById[$row.Controlled_ID] = $row }
Assert-True ($cutById.Count -eq 7) 'Cutover must contain seven unique records'
Assert-True ($cutById['CUT-004'].Status -eq 'SimulatedGO') 'CUT-004 must record simulated GO'
$smokeExpected = @('SubmissionReference=PASS','RoutingPriority=PASS','SingleOwner=PASS','TransitionBlocker=PASS','ValidationClosure=PASS','SupportReference=PASS')
foreach ($token in $smokeExpected) {
    Assert-True ($cutById['CUT-006'].Smoke_Check_Outcome.Contains($token)) "CUT-006 missing $token"
}
Assert-True ($cutById['CUT-006'].Smoke_Check_Outcome -match 'rollback not invoked') 'Rollback must remain available and not invoked after passing smoke checks'

$scenarioText = Read-StrictUtf8 (Join-Path $Root 'docs/scenario-and-configuration.md')
foreach ($token in @(
    'Stage A — minimum submission gate','Stage B — post-submission completeness review',
    'Access or permission','Application or workflow issue','Data or reporting request','General service request',
    'Critical, High, Medium, then Low','exactly one accountable Fulfiller',
    'Current reporting cycle','Include records with no accountable owner or state=Blocked',
    'Data/Reporting modeled skill context','Medium priority','T+3','T+1'
)) {
    Assert-True ($scenarioText.Contains($token)) "Scenario is missing: $token"
}

$supportText = Read-StrictUtf8 (Join-Path $Root 'docs/support-runbooks-and-handoff.md')
Assert-True ([regex]::Matches($supportText, '(?m)^\| SUP-00[1-3] \|').Count -eq 3) 'Support guide must contain three case rows'
Assert-True ([regex]::Matches($supportText, '(?m)^## RUN-00[1-3] ').Count -eq 3) 'Support guide must contain three runbooks'
Assert-True ($supportText.Contains('three relative business days')) 'Support guide must retain the three-day model'

$caseStudy = Read-StrictUtf8 (Join-Path $Root 'CASE_STUDY.md')
Assert-True ([regex]::Matches($caseStudy, '(?m)^```mermaid\s*$').Count -eq 2) 'Case study must contain two Mermaid visuals'
Assert-True ([regex]::Matches($caseStudy, '(?m)^\*\*Text alternative:\*\*').Count -eq 2) 'Each visual must have an immediate text alternative'

$markdownFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md'
foreach ($markdown in $markdownFiles) {
    $text = Read-StrictUtf8 $markdown.FullName
    foreach ($link in [regex]::Matches($text, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')) {
        $destination = $link.Groups[1].Value.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($destination) -or $destination -match '^(?:https?:|mailto:)') { continue }
        $resolved = [IO.Path]::GetFullPath((Join-Path $markdown.DirectoryName $destination))
        Assert-True ($resolved.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) "Link escapes repository: $destination"
        if ($WriteReadback -and $resolved -ceq $readbackPath -and -not (Test-Path -LiteralPath $resolved)) { continue }
        Assert-True (Test-Path -LiteralPath $resolved -PathType Leaf) "Broken link in $($markdown.Name): $destination"
    }
}

$combined = $surfaceText.ToString()
foreach ($pattern in @(
    '(?i)(?<![A-Z0-9_])[A-Z]:\\',
    '(?i)owner prompt|review package|detached manifest|Codex',
    '(?i)INTERNALLY_REFINED_PENDING_FINAL_OWNER_REVIEW|FINAL_OWNER_REVIEW_DEFERRED|NoApprovedRelease',
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'AKIA[0-9A-Z]{16}',
    'gh[pousr]_[A-Za-z0-9]{30,}',
    'xox[baprs]-[A-Za-z0-9-]{20,}',
    '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    '(?<!\d)\d{3}-\d{2}-\d{4}(?!\d)'
)) {
    Assert-True (-not [regex]::IsMatch($combined, $pattern)) "Prohibited residue matched: $pattern"
}
Assert-True ($combined -notmatch '(?i)real client implementation|production implementation completed|real UAT passed|deployed to production') 'Unsupported implementation claim found'

$summaryPath = Join-Path $Root 'evidence/validation-summary.json'
$summary = Read-StrictUtf8 $summaryPath | ConvertFrom-Json
Assert-True ($summary.accepted_source_core_sha256 -ceq '63C9DD67002FF1668828DC5D1DEC7F14610D3AEA15892105192299A0C278FCA3') 'Accepted source core mismatch'
Assert-True ($summary.uat.initial_pass -eq 6 -and $summary.uat.initial_fail -eq 2 -and $summary.uat.passing_retests -eq 2 -and $summary.uat.final_pass -eq 8) 'Validation summary UAT mismatch'
Assert-True ($summary.result -ceq 'PASS_SYNTHETIC_MODEL_VALIDATION') 'Validation summary terminal mismatch'

$digest = Get-CandidateDigest $inventory
$readback = [ordered]@{
    schema_version = '1.0.0'
    record_role = 'ImplementationReadinessSupportTransitionRepositoryReadback'
    terminal = $Terminal
    repository_name = 'implementation-readiness-support-transition'
    exercise_boundary = 'SYNTHETIC_DOCUMENTATION_AND_EVIDENCE_ONLY; NO_REAL_IMPLEMENTATION_OR_OUTCOME'
    deterministic_candidate_sha256 = $digest
    accepted_source_core_sha256 = '63C9DD67002FF1668828DC5D1DEC7F14610D3AEA15892105192299A0C278FCA3'
    controlled_ids = 56
    uat = [ordered]@{ initial_pass=6; initial_fail=2; passing_retests=2; final_pass=8 }
    defects = [ordered]@{ total=2; passing_retests=2; unresolved_critical_or_high=0 }
    smoke_checks = [ordered]@{ total=6; pass=6; rollback='NOT_INVOKED' }
    support_model = [ordered]@{ simulated_business_days=3; support_cases=3; runbooks=3 }
    visuals = [ordered]@{ mermaid=2; immediate_text_alternatives=2 }
    csv_profiles = @(
        [ordered]@{ relative_path='evidence/needs-requirements-acceptance-readiness.csv'; rows=24; columns=16 },
        [ordered]@{ relative_path='evidence/raid-decisions.csv'; rows=9; columns=15 },
        [ordered]@{ relative_path='evidence/uat-cases-results.csv'; rows=8; columns=17 },
        [ordered]@{ relative_path='evidence/defect-retests.csv'; rows=2; columns=17 },
        [ordered]@{ relative_path='evidence/cutover-go-no-go-rollback-smoke-checks.csv'; rows=7; columns=18 }
    )
    validation_scope = 'Repository structure, evidence consistency, links, claims, privacy, and deterministic content identity; no workflow or platform execution.'
}

if ($WriteReadback) {
    $json = $readback | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($readbackPath, ($json + "`n"), [Text.UTF8Encoding]::new($false))
    $inventory = Get-Inventory
    Assert-True (($inventory -join '|') -ceq (($ExpectedFiles | Sort-Object) -join '|')) 'Repository topology differs after readback generation'
    $digestAfter = Get-CandidateDigest $inventory
    Assert-True ($digestAfter -ceq $digest) 'Candidate digest changed while writing excluded readback'
}

Assert-True (Test-Path -LiteralPath $readbackPath -PathType Leaf) 'Validation readback is missing; run with -WriteReadback once'
$stored = Read-StrictUtf8 $readbackPath | ConvertFrom-Json
Assert-True ($stored.terminal -ceq $Terminal) 'Stored readback terminal mismatch'
Assert-True ($stored.deterministic_candidate_sha256 -ceq $digest) 'Stored readback digest mismatch'

[pscustomobject][ordered]@{
    terminal = $Terminal
    files = 16
    controlled_ids = 56
    initial_uat = '6 PASS / 2 FAIL'
    final_uat = '8 PASS / 0 FAIL'
    passing_retests = 2
    smoke_checks = '6 PASS / 0 FAIL'
    support_cases = 3
    runbooks = 3
    deterministic_candidate_sha256 = $digest
    workflow_execution_claimed = $false
} | ConvertTo-Json -Depth 5

$Terminal
