
$organization = "https://dev.azure.com/mseng"
$project = "AzureDevOps"


function UrlEncode ([string]$witQuery) {
    
    [string]$encodedUrl = [System.Web.HttpUtility]::UrlEncode($witQuery)
    # Write-Host "encoded url : $($encodedurl)"
    return $encodedUrl
}

function AppendTrackingDataEngineeringScoreCard([string]$url) {
    #{"Source":"ProAct", "Script":"Boards.ps1", "Section":"EngineeringScoreCard"}
    return $url + "&tracking_data=eyJTb3VyY2UiOiJQcm9BY3QiLCAiU2NyaXB0IjoiQm9hcmRzLnBzMSIsICJTZWN0aW9uIjoiRW5naW5lZXJpbmdTY29yZUNhcmQifQ=="
}

function GetWorkItems ([string]$org, [string]$wiqlQuery) {
    $workItems = az.cmd boards query --org $org --wiql $wiqlQuery -o json | ConvertFrom-Json
    return $workItems.Count, $workItems
}


$wiql_StaleLSIrepairWorkItems = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [IcM.Severity] >= 0 AND [IcM.Severity] <= 2 AND ( [System.Tags] CONTAINS 'LSI work' OR [System.Tags] CONTAINS 'Live Site Repair' OR [System.Tags] CONTAINS 'Incident Repair Item' OR [System.Tags] CONTAINS 'LSI Repair Item' ) AND ( [System.State] <> 'Completed' AND [System.State] <> 'Cut' AND [System.State] <> 'Closed' AND [System.State] <> '6 - Closed' ) AND (( [IcM.DeliveryType] = 'ShortTerm' AND [System.CreatedDate] <= @today - 10 ) OR ( [IcM.DeliveryType] = 'MediumTerm' AND [System.CreatedDate] <= @today - 90 ) OR ( [IcM.DeliveryType] = 'LongTerm' AND [System.CreatedDate] <= @today - 365 )) AND [System.AreaPath] UNDER '{0}'"
$wiql_StaleDTSs = "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.AssignedTo], [System.CreatedDate], [Microsoft.VSTS.Common.Priority], [System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'DTS Task' and [System.State] = '5 - PG Engaged' and [Custom.Whogottheball] = 'Product Group' and ((([Microsoft.VSTS.Common.Priority] = 0 or [Microsoft.VSTS.Common.Priority] = 1) and [System.CreatedDate] <= @Today - 3) or ([Microsoft.VSTS.Common.Priority] = 2 and [System.CreatedDate] <= @Today - 7) or ([Microsoft.VSTS.Common.Priority] = 3 and [System.CreatedDate] <= @Today - 14) or ([Microsoft.VSTS.Common.Priority] = 4 and [System.CreatedDate] <= @Today - 21)) AND  ([System.AreaPath] UNDER  '{0}')"
$wiql_ActiveP0Bugs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [Microsoft.DevDiv.IssueType] <> 'Localization' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [Microsoft.VSTS.Common.Priority] = 0 AND [System.AreaPath] UNDER '{0}'"
$wiql_StaleP1Bugs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [Microsoft.DevDiv.IssueType] <> 'Localization' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [Microsoft.VSTS.Common.Priority] = 1 AND [System.CreatedDate] <= @today - 21 AND [System.AreaPath] UNDER '{0}'"
$wiql_BugsPerEngineer = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [Microsoft.DevDiv.IssueType] <> 'Localization' AND [Microsoft.VSTS.Common.IsA11yBug] = 'No' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [System.AreaPath] UNDER '{0}'"
$wiql_StaleSecurityWorkItems = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE ( [System.WorkItemType] <> 'Live Site Incident' AND [System.WorkItemType] <> 'Live Site Knowledge Base' AND [System.WorkItemType] <> 'Live Site Problem' AND [System.WorkItemType] <> 'Live Site Change Request' ) AND ( [System.State] = 'Active' OR [System.State] = 'In Progress' OR [System.State] = 'Proposed' OR [System.State] = 'Committed' ) AND ( [Microsoft.DevDiv.TenetAffected] = 'Trustworthy and Secure' OR ( [System.Tags] CONTAINS 'Security' OR [System.Tags] CONTAINS 'VSORedBlue' OR [System.Tags] CONTAINS 'VSTSRedBlue' OR [System.Tags] CONTAINS 'PenTest' OR [System.Tags] CONTAINS 'VSOSIM' OR [System.Tags] CONTAINS 'Threat Model' )) AND [System.Tags] NOT CONTAINS '1CS' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [System.CreatedDate] <= @today - 21 AND [System.AreaPath] UNDER '{0}'"
$wiql_StaleAccessibilityBugs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND ( [Microsoft.VSTS.Common.IsA11yBug] = 'Yes' OR [System.Tags] CONTAINS 'A11yMAS' ) AND [System.Tags] NOT CONTAINS 'A11yPlan' AND [System.CreatedDate] <= @today - 42 AND [System.AreaPath] UNDER '{0}'"
$wiql_StaleReliabilityBugs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [System.Tags] CONTAINS 'CI_Reliability' AND [System.CreatedDate] <= @today - 21 AND [System.AreaPath] UNDER '{0}'"

$wiql_approachSLA_StaleLSIrepair = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [IcM.Severity] >= 0 AND [IcM.Severity] <= 2 AND ( [System.Tags] CONTAINS 'LSI work' OR [System.Tags] CONTAINS 'Live Site Repair' OR [System.Tags] CONTAINS 'Incident Repair Item' OR [System.Tags] CONTAINS 'LSI Repair Item' ) AND ( [System.State] <> 'Completed' AND [System.State] <> 'Cut' AND [System.State] <> 'Closed' AND [System.State] <> '6 - Closed' ) AND (( [IcM.DeliveryType] = 'ShortTerm' AND [System.CreatedDate] <= @today - 0 ) OR ( [IcM.DeliveryType] = 'MediumTerm' AND [System.CreatedDate] <= @today - 78 ) OR ( [IcM.DeliveryType] = 'LongTerm' AND [System.CreatedDate] <= @today - 353 )) AND [System.AreaPath] UNDER '{0}'"
$wiql_approachSLA_StaleDTSs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'DTS Task' AND [System.State] = '5 - PG Engaged' AND [Microsoft.DevDiv.SubStatus] = 'Product Group' AND ((( [Microsoft.VSTS.Common.Priority] = 0 OR [Microsoft.VSTS.Common.Priority] = 1 ) AND [System.CreatedDate] <= @today - 0 ) OR ( [Microsoft.VSTS.Common.Priority] = 2 AND [System.CreatedDate] <= @today - 0 ) OR ( [Microsoft.VSTS.Common.Priority] = 3 AND [System.CreatedDate] <= @today - 2 ) OR ( [Microsoft.VSTS.Common.Priority] = 4 AND [System.CreatedDate] <= @today - 9 )) AND [System.AreaPath] UNDER '{0}'"
$wiql_approachSLA_StaleP1Bugs = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [Microsoft.DevDiv.IssueType] <> 'Localization' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [Microsoft.VSTS.Common.Priority] = 1 AND [System.CreatedDate] <= @today - 9 AND [System.AreaPath] UNDER '{0}'"
$wiql_approachSLA_StaleSecurity = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE ( [System.WorkItemType] <> 'Live Site Incident' AND [System.WorkItemType] <> 'Live Site Knowledge Base' AND [System.WorkItemType] <> 'Live Site Problem' AND [System.WorkItemType] <> 'Live Site Change Request' ) AND ( [System.State] = 'Active' OR [System.State] = 'In Progress' OR [System.State] = 'Proposed' OR [System.State] = 'Committed' ) AND ( [Microsoft.DevDiv.TenetAffected] = 'Trustworthy and Secure' OR ( [System.Tags] CONTAINS 'Security' OR [System.Tags] CONTAINS 'VSORedBlue' OR [System.Tags] CONTAINS 'VSTSRedBlue' OR [System.Tags] CONTAINS 'PenTest' OR [System.Tags] CONTAINS 'VSOSIM' OR [System.Tags] CONTAINS 'Threat Model' )) AND [System.Tags] NOT CONTAINS '1CS' AND [Microsoft.DevDiv.IssueType] <> 'tracking' AND [System.CreatedDate] <= @today - 9 AND [System.AreaPath] UNDER '{0}'"

$wiql_approachSLA_StaleReliability = "SELECT [System.Id],[System.WorkItemType],[System.Title],[System.State],[System.AssignedTo],[System.CreatedDate],[Microsoft.VSTS.Common.Priority],[System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active' AND [System.Tags] CONTAINS 'CI_Reliability' AND [System.CreatedDate] <= @today - 9 AND [System.AreaPath] UNDER '{0}'"
# [ScoreCardQuery]$surface = [ScoreCardQuery]::new($wiql_StaleDTSs, 0)


$wiql_EngineeringScoreCard = [ordered]@{
    # 'Stale LSI repair items' = [ScoreCardQuery]::new($wiql_StaleLSIrepairWorkItems, $wiql_approachSLA_StaleLSIrepair, 0)
    'Stale DTSs'               = [ScoreCardQuery]::new($wiql_StaleDTSs, $wiql_approachSLA_StaleDTSs, 0)  
    # 'Active P0 bugs'         = [ScoreCardQuery]::new($wiql_ActiveP0Bugs, $null, 0)
    # 'Stale P1 Bugs'            = [ScoreCardQuery]::new($wiql_StaleP1Bugs, $wiql_approachSLA_StaleP1Bugs, 0)
    # 'Bugs Per Engineer'      = [ScoreCardQuery]::new($wiql_BugsPerEngineer, $null, 5)
    # 'Stale security items'     = [ScoreCardQuery]::new($wiql_StaleSecurityWorkItems, $wiql_approachSLA_StaleSecurity, 5)
    'Stale accessibility bugs' = [ScoreCardQuery]::new($wiql_StaleAccessibilityBugs, $null, 0)
    # 'Stale reliability items'  = [ScoreCardQuery]::new($wiql_StaleReliabilityBugs, $wiql_approachSLA_StaleReliability, 0)  
}


# team headcount reference  https://dev.azure.com/mseng/_git/AzureDevOps?path=%2FTools%2FExtensions%2FEngineeringScorecard%2Fscripts%2FImplementation%2FTeamsProvider.ts&version=GBmaster
$teams = [ordered]@{
    #'Search Core' = [TeamDetails]::new("Search core", 15, "AzureDevOps\VSTS\RM and Deployment\RM-Service")
    # 'Search Core' = [TeamDetails]::new("Search core", 15, "AzureDevOps\VSTS\Modern Interactions and Search\Search Core")
    # 'ProTocol' = [TeamDetails]::new("ProToCol", 12, "AzureDevOps\VSTS\Modern Interactions\ProToCol")  
    # 'Boards' = [TeamDetails]::new("Boards", 6, "AzureDevOps\VSTS\Apps\Boards")  
    'Pipelines Application and Web Platform' = [TeamDetails]::new("Boards", 6, "AzureDevOps\VSTS\Apps\Pipelines Application and Web Platform")  
    
}

$areapath_engScoreCard = New-Object 'system.collections.generic.dictionary[[string],[TeamScoreCardOutput]]'

foreach ($teamName in $teams.Keys) {
    $team = $teams[$teamName]
    $areapath = $team.areapath
    Write-Host "team $($areapath)     Head Count $($team.headCount)"
    [TeamScoreCardOutput]$teamScoreOutput = [TeamScoreCardOutput]::new($teamName, $team)

    foreach ($scoreCardAttributes in $wiql_EngineeringScoreCard.Keys) { 
        $scoreCardAttr = $wiql_EngineeringScoreCard[$scoreCardAttributes]
        $finalQuery = [string]::Format($scoreCardAttr.wiqlQuery, $areapath)
        $witCount, $wits = GetWorkItems $organization $finalQuery
        # Write-Host "output $($scoreCardAttributes)   $($witCount)       $($scoreCardAttr.threshold)"

        if ($scoreCardAttr.wiqlQueryApproachSLA -ne "") {
            $approachSLA_finalQuery = [string]::Format($scoreCardAttr.wiqlQueryApproachSLA, $areapath)
            $approachSLA_witCount, $approachSLA_wits = GetWorkItems $organization $approachSLA_finalQuery
        }
        else {
            $approachSLA_finalQuery = ""
            $approachSLA_witCount = 0
            $approachSLA_wits = $null
        }
        [ScoreCardQueryOutput]$queryOutput = [ScoreCardQueryOutput]::new($finalQuery, $approachSLA_finalQuery, $scoreCardAttr.threshold, $witCount, $($approachSLA_witCount - $witCount))
        $teamScoreOutput.AddScoreCardQueryOutput($scoreCardAttributes, $queryOutput)
    }
    $areapath_engScoreCard.Add($teamName, $teamScoreOutput)
}


    
foreach ($teamName in $areapath_engScoreCard.keys) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine( "<html><head><style>table { border-collapse: collapse; } table, th, td {border: 1px solid black; font-family:verdana;font-size:12;}</style></head><body  style=`"font-family:verdana;font-size:11`">" )
    
    [void]$sb.AppendLine( "<table><tr><th align='left' colspan='4'>$teamName</th></tr>" )

    $engScoreCard = $areapath_engScoreCard[$teamName]
    $outputs = $engScoreCard.scoreCardOutputs

    foreach ($key in $outputs.keys) {
        [ScoreCardQueryOutput]$queryOutput = $outputs[$key]
        #  Write-Host "output $($key)   $($queryOutput.count)       $($queryOutput.threshold)"

        $scoreCardQueryUrl = $organization + "/" + $project + "/_queries/query?wiql=" + $(UrlEncode($queryOutput.wiqlQuery))

        $approachQueryUrl = $organization + "/" + $project + "/_queries/query?wiql=" + $(UrlEncode($queryOutput.wiqlQueryApproachSLA))

        $approachSLAText = [System.Text.StringBuilder]::new()
        if ($queryOutput.approachSLACount -gt 0) {
            [void]$approachSLAText.AppendLine( "<br>" )
            [void]$approachSLAText.AppendLine( "<a href=$approachQueryUrl>$($queryOutput.approachSLACount) more items due before sprint end</a>" )
        }

        $scoreColor = $(if ($queryOutput.count -gt $queryOutput.threshold) { 'red' } else { 'black' } )
        [void]$sb.AppendLine( "<tr><td align='center' width='25px' height='50px'><a href=$scoreCardQueryUrl>$($queryOutput.count)</a></td><td><font color=$($scoreColor)>$key</font>$($approachSLAText.ToString())</td><td></td><td></td></tr>" )
    }
    [void]$sb.AppendLine( "</table>" );
    [void]$sb.AppendLine( "</body></html>" );
    $sb.ToString()
    echo "::set-output name=scorecard::true"
}



class ScoreCardQuery {
    [string]$wiqlQuery
    [string]$wiqlQueryApproachSLA
    [int]$threshold
 
    ScoreCardQuery(
        [string]$wiqlQuery,
        [string]$wiqlQueryApproachSLA,
        [int]$threshold
    ) {
        $this.wiqlQuery = $wiqlQuery
        $this.wiqlQueryApproachSLA = $wiqlQueryApproachSLA
        $this.threshold = $threshold
    }
}

class ScoreCardQueryOutput : ScoreCardQuery {
    [int]$count
    [int]$approachSLACount
 
    ScoreCardQueryOutput([string]$wiqlQuery, [string]$wiqlQueryApproachSLA, [int]$threshold, [int]$count, [int]$approachSLACount) : base($wiqlQuery, $wiqlQueryApproachSLA, $threshold) {
        $this.count = $count
        $this.approachSLACount = $approachSLACount
    }
}

class TeamDetails {
    [string]$name
    [int]$headCount
    [string]$areaPath
    
    TeamDetails(
        [string]$name,
        [int]$headCount,
        [string]$areapath        
    ) {
        $this.name = $name
        $this.headCount = $headCount
        $this.areapath = $areapath
    }
}

class TeamScoreCardOutput {
    [string]$name
    [TeamDetails]$teamDetails
    $scoreCardOutputs = [ordered]@{ }
    #[ScoreCardQueryOutput]$scoreCardQueryOutput
    
    TeamScoreCardOutput(
        [string]$name,
        [TeamDetails]$teamDetails
    ) {
        $this.name = $name
        $this.teamDetails = $teamDetails
    }

    #GetScoreCardQueryOutput() {
    #   return $this.scoreCardOutputs
    #}

    [void] AddScoreCardQueryOutput([string]$name, [ScoreCardQueryOutput]$queryOutput) {
        ## Add argument validation logic here
        $this.scoreCardOutputs[$name] = $queryOutput
    }
}