## Enums (6)
- Severity: critical, high, medium, low
- ActionStatus: open, in_progress, resolved, closed
- RiskLevel: critical, high, medium, low
- ComplianceStatus: compliant, non_compliant, pending_review, exempt
- ProjectPhase: initiation, planning, design, execution, launch, closeout
- PricingTier: basic_project, project, program, portfolio

## Data Structs (9)
- DistributionRow: category (String), openItems (Integer), critical (Integer), high (Integer), medium (Integer), low (Integer), closed (Integer), owner (String), status (String), lastUpdated (String)
- ActionVelocityRow: workstream (String), openItems (Integer), closedThisSprint (Integer), velocity (Double), throughput (Double), delta (String), avgCycleTime (String), period (String), owner (String), status (String)
- CapacityHealthRow: team (String), plannedFte (Double), allocatedFte (Double), availableFte (Double), utilization (Double), overallocated (Integer), fteVariance (Double), burnRate (String), productivityIndex (Double), overtimeHrs (Double), absenteeismRate (Double), skillGap (String), backlogWeeks (Double), costVariance (Double), riskLevel (String), owner (String), status (String), lastUpdated (String)
- ShiftCoverageRow: shift (String), requiredHeadcount (Integer), actualHeadcount (Integer), coveragePercent (Double), gap (Integer), shiftPattern (String), overtimeHrs (Double), contractorFill (Integer), agencyStaff (Integer), absenceCount (Integer), complianceStatus (String), nextRotation (String), supervisor (String), riskFlag (String), status (String), lastUpdated (String)
- ComplianceRegRow: regId (String), regulationName (String), category (String), complianceStatus (String), responsibleParty (String), dueDate (String), riskLevel (String), auditStatus (String), lastUpdated (String)
- PunchlistInsight: title (String), owner (String), dueIn (String), severity (String), status (String)
- ProjectData: id (String), name (String), phase (String), sprint (String), program (String), portfolio (String), completionPercent (Double), status (String)
- RiskItem: id (String), description (String), probability (String), impact (String), mitigation (String), owner (String), status (String)
- MilestoneItem: name (String), dueDate (String), status (String), owner (String), percentComplete (Double)

