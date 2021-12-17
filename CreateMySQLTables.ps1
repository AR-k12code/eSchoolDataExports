<#

$tables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM')
.\CreateMySQLTables.ps1

#>

if (-Not(Test-Path .\settings.ps1)) {
    Write-Host "Error: You're missing the settings.ps1 file." -ForegroundColor Red
    exit(1)
} else {
    . .\settings.ps1
}

try {
    Import-Module SimplySQL
} catch {
    $PSitem
    exit(1)
}

if (-Not($tables)) {
    Write-Host "Info: You didn't specify tables to use. This script will do 'REG','REG_STU_CONTACT','REG_CONTACT','REG_CONTACT_PHONE' by default." -ForegroundColor Red
    $tables = @('REG','REG_STU_CONTACT','REG_CONTACT','REG_CONTACT_PHONE')
}

try {
    $dbcredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $database['username'],(ConvertTo-SecureString -AsPlainText "$($database['password'])" -Force)
    Open-MySqlConnection -Server $database.hostname -Database $database.dbname -Credential $dbcredentials
} catch {
    Write-Host "Error: $PSitem"
}

$TypeID = @{
    '34' = 'varchar' #Not sure
    '35' = 'varchar' #Not sure
    '36' = 'varchar' #Not sure
    '40' = 'varchar' #Not sure
    '42' = 'varchar' #Not sure
    '52' = 'varchar' #Not sure. This is 3 characters
    '56' = 'varchar' #was int
    '58' = 'varchar' #Not sure
    #'61' = 'date' #This is not compatible.
    '61' = 'varchar' #instead on queries convert this. select STR_TO_DATE(CHANGE_DATE_TIME,'%m/%d/%Y %h:%i:%s %p') from reg
    '99' = 'varchar' #Not sure
    '104' = 'varchar' #Not sure
    '106' = 'varchar' #Not Sure but it is set to 5 characters
    '108' = 'varchar' #Not sure
    '127' = 'varchar' #Not sure but it is set to 8 characters
    '165' = 'varchar' #Not sure
    '167' = 'varchar'
    '175' = 'char'
    '231' = 'text'
}

$eschooltables = Import-Csv .\info\eSchoolDatabase.csv
$sql_create_tables = @{}

$eschooltables | Group-Object -Property tblName | ForEach-Object {

    $sql = "CREATE TABLE IF NOT EXISTS ``$($PSItem.Name)`` ("

    $tblColumns = $PSItem.group
    
    $columnCount = 0
    $tblColumns | ForEach-Object {

        $columnCount++

        $colName = $PSItem.colName
        $colDataType = $TypeID.($PSItem.colUserTypeId)

        #This leaves so many things broken.
        # $colLength = [int]$PSItem.colMaxLength
        # if ($colLength -lt 253) {
        #     $colLength = $colLength + 2
        # }
        $colLength = 255

        $sql += '`' + $colName + '` ' + $colDataType

        if (@('int','date') -notcontains $colDataType) {
            switch ($PSItem.colIsNullable) {
                0 { $sql += "($colLength) NOT NULL"}
                1 { $sql += "($colLength) NULL" }
            }
        }

        if ($columnCount -lt $tblColumns.Count) {
            $sql += ','
        }

    }

    $primaryKey = $tblColumns | Where-Object { $PSItem.colIsIdentity -eq 1 } | Select-Object -First 1 -ExpandProperty colName
    if ($primaryKey) {
        $sql += ",PRIMARY KEY (``$primaryKey``)"
    }

    $sql += ')'

    $sql_create_tables.($PSItem.Name) = $sql

}

$errors = @()
$tables | ForEach-Object {

    $tblName = $PSItem

    if ($sql_create_tables.$tblName) {
        Write-Host "Info: Creating table $tblName" -ForegroundColor Yellow
        try {
            Invoke-SqlUpdate -Query $sql_create_tables.$tblName | Out-Null
        } catch {
            Write-Host "Error: Failed to create table $tblName $PSitem" -ForegroundColor Red
            $errors += $tblName
        }
    } else {
        Write-Host "Error: Table $tblName not found."
    }
}

$errors