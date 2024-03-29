<#

    eSchool Data Exports
    Author: Craig Millsap

    This project is used to create download definitions for eSchool Tables automatically.

    You must specify what tables you want to create the download definition for in advance OR specify them in the settings.ps1 file.

    Table names are in the resources folder.

    Example of defining your tables:
    $tables = @('REG','REG_ACADEMIC','REG_CONTACT','REG_STU_CONTACT','REG_CONTACT_PHONE','REGTB_HOUSE_TEAM')

    No SQL Filtering
    .\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RGALL"

    #Modifications in the last 12 hours.

    .\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RG12H" -SQL 'WHERE CONVERT(DATETIME,CHANGE_DATE_TIME,101) >= DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)'

    #Modifications in the last 48 hours.
    .\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RG48H" -SQL 'WHERE CONVERT(DATETIME,CHANGE_DATE_TIME,101) >= DateAdd(Hour, DateDiff(Hour, 0, GetDate())-48, 0)'

#>

function New-ESPDownloadDefinition {
    Param(
        [parameter(Mandatory=$true)][array]$tables,
        [parameter(Mandatory=$true)][String]$DefinitionName,
        [parameter(Mandatory=$false)][String]$SQL = $null,
        [parameter(Mandatory=$false)][Switch]$DoNotLimitSchoolYear, #otherwise all queries are limited to the current school year if the table has the SCHOOL_YEAR in it.
        [parameter(Mandatory=$false)]$eSchoolSession = $eSchoolSession #incoming eschool session variable from .\eschool-login.ps1
    )

    # if (-Not($tables)) {
    #     $tables = @('REG','REG_STU_CONTACT','REG_CONTACT')
    # }

    if ($DefinitionName.Length -ne 5) {
        Write-Host "Error: Definition Name MUST BE 5 CHARACTERS LONG!" -ForegroundColor Red
        exit(1)
    }

    # if (-Not($eSchoolSession)) {
    #     Throw "you must already have logged into eschool."
    #     # . $PSScriptRoot\..\eSchoolUpload\eSchool-Login.ps1 -username $username
    # }

    # if (-Not(Get-Variable -Name eSchoolSession)) {
    #     Write-Host "Error: Failed to login to eSchool." -ForegroundColor Red
    #     exit(1)
    # }

    if ($SQL) {
        $sqlspecified = $True
    }

    $tables_with_years = Import-CSV ".\resources\eSchool Tables with SCHOOL_YEAR.csv" | Select-Object -ExpandProperty tblName

    #dd = download definition
    $ddhash = @{}

    $ddhash["IsCopyNew"] = "False"
    $ddhash["NewHeaderNames"] = @("")
    $ddhash["InterfaceHeadersToCopy"] = @("")
    $ddhash["InterfaceToCopyFrom"] = @("")
    $ddhash["CopyHeaders"] = "False"
    $ddhash["PageEditMode"] = 0
    $ddhash["UploadDownloadDefinition"] = @{}
    $ddhash["UploadDownloadDefinition"]["UploadDownload"] = "D"

    $ddhash["UploadDownloadDefinition"]["DistrictId"] = 0
    $ddhash["UploadDownloadDefinition"]["InterfaceId"] = "$DefinitionName"
    $ddhash["UploadDownloadDefinition"]["Description"] = "Export All eSchool Tables"
    $ddhash["UploadDownloadDefinition"]["UploadDownloadRaw"] = "D"
    $ddhash["UploadDownloadDefinition"]["ChangeUser"] = $null
    $ddhash["UploadDownloadDefinition"]["DeleteEntity"] = $False

    $ddhash["UploadDownloadDefinition"]["InterfaceHeaders"] = @()

    $headerorder = 0
    $tblShortNamesArray = @()
    Import-Csv ".\resources\eSchoolDatabase.csv" | Where-Object { $tables -contains $PSItem.tblName } | Group-Object -Property tblName | ForEach-Object {
        $tblName = $PSItem.Name
        $sql_table = "LEFT OUTER JOIN (SELECT '#!#' AS 'RC_RUN') AS [spi_checklist_setup_hdr] ON 1=1 " + $SQL #pull from global variable so we can modify local variable without pulling it back into the loop.

        #We need to either APPEND or USE the SCHOOL_YEAR if the table has it.
        if (-Not($DoNotLimitSchoolYear) -and ($tables_with_years -contains $tblName)) {
            if ($sqlspecified) {
                $sql_table += " AND SCHOOL_YEAR = (SELECT CASE WHEN MONTH(GetDate()) > 6 THEN YEAR(GetDate()) + 1 ELSE YEAR(GetDate()) END)"
            } else {
                $sql_table = "$($sql_table) WHERE SCHOOL_YEAR = (SELECT CASE WHEN MONTH(GetDate()) > 6 THEN YEAR(GetDate()) + 1 ELSE YEAR(GetDate()) END)"
            }
        }

        #Get the name and generate a shorter name so its somewhat identifiable when getting errors.
        if ($tblName.IndexOf('_') -ge 1) {
            $tblShortName = $tblName[0]
            $tblName | Select-String '_' -AllMatches | Select-Object -ExpandProperty Matches | ForEach-Object {
                $tblShortName += $tblName[$PSItem.Index + 1]
            }
        } else {
            $tblShortName = $tblName
        }

        if ($tblShortName.length -gt 5) {
            $tblShortName = $tblShortName.SubString(0,5)
        }

        #We need to verify we don't already have an interface ID named the same thing. Stupid eSchool and its stupid 5 character limit.
        if ($tblShortNamesArray -contains $tblShortName) {
            $number = 0
            do {
                $number++
                if ($tblShortName.length -ge 5) {
                    $tblShortName = $tblShortName.SubString(0,4) + "$number"
                } else {
                    $tblShortName = $tblShortName + "$number"
                }
            } until ($tblShortNamesArray -notcontains $tblShortName)
        }

        $tblShortNamesArray += $tblShortName

        $ifaceheader = $tblShortName
        $description = $tblName
        $filename = "$($tblName).csv"

        Write-Verbose "$($ifaceheader),$($description),$($filename)"

        $headerorder++
        $ddhash["UploadDownloadDefinition"]["InterfaceHeaders"] += @{
            "InterfaceId" = "$DefinitionName"
            "HeaderId" = "$ifaceheader"
            "HeaderOrder" = $headerorder
            "Description" = "$description"
            "FileName" = "$filename"
            "LastRunDate" = $null
            "DelimitChar" = '^'
            "UseChangeFlag" = $False
            "TableAffected" = "$($tblName.ToLower())"
            "AdditionalSql" = $sql_table
            "ColumnHeaders" = $True
            "Delete" = $False
            "CanDelete" = $True
            "ColumnHeadersRaw" = "Y"
            "InterfaceDetails" = @()
        }
    
        $columns = @()
        $columnNum = 1
        $PSItem.Group | ForEach-Object {
            $columns += @{
                "Edit" = $null
                "InterfaceId" = "$DefinitionName"
                "HeaderId" = "$ifaceheader"
                "FieldId" = "$columnNum"
                "FieldOrder" = "$columnNum"
                "TableName" = "$($tblName.ToLower())"
                "TableAlias" = $null
                "ColumnName" = $PSItem.colName
                "ScreenType" = $null
                "ScreenNumber" = $null
                "FormatString" = $null
                "StartPosition" = $null
                "EndPosition" = $null
                "FieldLength" = 255 #[int]$PSItem.colMaxLength + 2 #This fixes the dates that are cut off. #This doesn't seem to matter at all. Set to maximum length.
                "ValidationTable" = $null
                "CodeColumn" = $null
                "ValidationList" = $null
                "ErrorMessage" = $null
                "ExternalTable" = $null
                "ExternalColumnIn" = $null
                "ExternalColumnOut" = $null
                "Literal" = $null
                "ColumnOverride" = $null
                "Delete" = $False
                "CanDelete" = $True
                "NewRow" = $True
                "InterfaceTranslations" = @("")
            }
            $columnNum++
        }

        #add line delimiter
        $columns += @{
            "Edit" = $null
            "InterfaceId" = "$DefinitionName"
            "HeaderId" = "$ifaceheader"
            "FieldId" = "99"
            "FieldOrder" = "99"
            "TableName" = "spi_checklist_setup_hdr"
            "TableAlias" = $null
            "ColumnName" = "RC_RUN"
            "ScreenType" = $null
            "ScreenNumber" = $null
            "FormatString" = $null
            "StartPosition" = $null
            "EndPosition" = $null
            "FieldLength" = 3
            "ValidationTable" = $null
            "CodeColumn" = $null
            "ValidationList" = $null
            "ErrorMessage" = $null
            "ExternalTable" = $null
            "ExternalColumnIn" = $null
            "ExternalColumnOut" = $null
            "Literal" = $null
            "ColumnOverride" = '#!#'
            "Delete" = $False
            "CanDelete" = $True
            "NewRow" = $True
            "InterfaceTranslations" = @("")
        }

        $ddhash["UploadDownloadDefinition"]["InterfaceHeaders"][$headerorder - 1]["InterfaceDetails"] += $columns

    }

    $jsonpayload = $ddhash | ConvertTo-Json -depth 6

    Write-Verbose "$jsonpayload"

    # $checkIfExists = Invoke-WebRequest -Uri "https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Utility/UploadDownload?interfaceId=$($DefinitionName)" -WebSession $eSchoolSession
    
    # #Write-Verbose $checkIfExists
    
    # if (($checkIfExists.InputFields | Where-Object { $PSItem.name -eq 'UploadDownloadDefinition.InterfaceId' } | Select-Object -ExpandProperty value) -eq '') {

        #create download definition.
        $response3 = Invoke-RestMethod -Uri "https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Utility/SaveUploadDownload" `
        -WebSession $eSchoolSession `
        -Method "POST" `
        -ContentType "application/json; charset=UTF-8" `
        -Body $jsonpayload `
        -MaximumRedirection 0

        if ($response3.PageState -eq 1) {
            Write-Warning "Download Defintion failed."
            return [PSCustomObject]@{
                'Tables' = $tables -join ','
                'Status' = $False
                'Message' = $($response3.ValidationErrorMessages)
            }
        } elseif ($response3.PageState -eq 2) {
            Write-Warning "Download definition created successfully. You can review it here: https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Utility/UploadDownload?interfaceId=$($DefinitionName)"
            return [PSCustomObject]@{
                'Tables' = $tables -join ','
                'Status' = $True
                'Message' = $response3
            }
        } else {
            throw "Failed."
        }
    # } else {
    #     Write-Host "Info: Job already exists. You need to delete the $($DefinitionName) Download Definition here: https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Utility/UploadDownloadSearch" -ForegroundColor Red
    # }
    
}