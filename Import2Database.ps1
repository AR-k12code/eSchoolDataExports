Param(
    [parameter(Mandatory=$false)][switch]$SkipRunningDefinition, #This generates the files.
    [parameter(Mandatory=$false)][switch]$SkipDownloadingFiles, #This downloads the individual files.
    [parameter(Mandatory=$false)][switch]$SkipDatabaseImport, #This downloads the individual files.
    [parameter(Mandatory=$false)][switch]$Full,
    [parameter(Mandatory=$true)][string]$DownloadDefition="RGALL" #This can be a comma separated string to run multiple Download Defitions.
)

try {
    Import-Module SimplySQL
} catch {
    $PSitem
    exit(1)
}

if (-Not(Test-Path .\settings.ps1)) {
    Write-Host "Error: You're missing the settings.ps1 file." -ForegroundColor Red
    exit(1)
} else {
    #Pull in database and eSchooltable names we want to import.
    . .\settings.ps1
}

try {
    $dbcredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $database['username'],(ConvertTo-SecureString -AsPlainText "$($database['password'])" -Force)
    Open-MySqlConnection -Server $database.hostname -Database $database.dbname -Credential $dbcredentials
} catch {
    Write-Host "Error: $PSitem"
}

#Login First.
if (-Not($eSchoolSession)) {
    . $PSScriptRoot\..\eSchoolUpload\eSchool-Login.ps1 -username $username
}

#This runs the Download Definition(s)
if (-Not($SkipRunningDefinition)) {
    ($DownloadDefition).Split(',') | ForEach-Object {
        . $PSScriptRoot\..\eSchoolUpload\eSchoolDownload.ps1 -InterfaceID $PSItem
    }
}

$eSchooltables | ForEach-Object {
    Write-Host "Info: Downloading $PSitem and saving to $("$PSScriptRoot\data\downloads\$($PSitem).csv")" -ForegroundColor Yellow
    try {

        $tableName = $PSItem

        $reportname = $tableName -replace '_',' '
        if (-Not($SkipDownloadingFiles)) {
            . $PSScriptRoot\..\eSchoolUpload\eSchoolDownload.ps1 -reportname "$reportname" -outputfile "$PSScriptRoot\data\downloads\$($tableName).csv"
        }

        if (-Not(Test-Path "$PSScriptRoot\data\downloads\$($tableName).csv")) {
            Write-Host "Error: Can not find file ""$PSScriptRoot\data\downloads\$($tableName).csv"""
            return
        }

        Write-Host "Info: Importing $($tableName).csv to ``$($tableName.ToLower())``" -ForegroundColor Yellow
        
        #Pull in to examine file contents. WE NEED THIS NOT TO BE RAW.
        $filecontents = Get-Content "$PSScriptRoot\data\downloads\$($tableName).csv"

        #Open a few lines of the file and count to make sure we have work to do.
        if (($filecontents | Measure-Object).Count -gt 1) {

            #Count the number of | characters.
            $columncount = (($filecontents | Select-Object -First 1).split('|')).count

            $newfilecontents = ''

            #find lines that match exactly to the number of columns.
            #This should be working as long as we don't use the RAW command.
            $regex = [regex]('^([^|\n]*(?:\|[^|\n]*){' + ($columncount -1) + ',' + ($columncount -1) + '})$')
            $goodlines = $filecontents | Select-String -AllMatches $regex -List
            $goodlines.Matches | ForEach-Object {
                        
                        # Dear future Craig, quit trying to fix this. Its never going to happen. Sincerly, Past Craig.
                        # This whole process breaks if you have multiple columns with different dates.
                        # $line = $_.value

                        # #Fix dates to match MySQL Format
                        # switch -regex ($line) {
                        #     #Convert Date Time
                        #     '\b(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2,4}) (?<hour>\d{1,2}):(?<minute>\d{2}):(?<seconds>\d{2}) (?<AMPM>\w{2})\b' {
                        #         [datetime]$datetime = $line | Select-String -Pattern "\b(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2,4}) (?<hour>\d{1,2}):(?<minute>\d{2}):(?<seconds>\d{2}) (?<AMPM>\w{2})\b" | Select-Object -First 1 -ExpandProperty Matches | Select-Object -ExpandProperty Value
                        #         $line = $line -replace '\b(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2,4}) (?<hour>\d{1,2}):(?<minute>\d{2}):(?<seconds>\d{2}) (?<AMPM>\w{2})\b',(Get-Date $datetime -Format "yyyy-MM-dd HH:mm:ss")
                        #     }
                        #     #Convert Date
                        #     '\b(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2,4})\b' {
                        #         $line = $line -replace '\b(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2,4})\b','${year}-${month}-${day}'
                        #     }
                        # }

                        # $newfilecontents += "$line`n"
                $newfilecontents += "$($_.value)`n"
            }
            # $newfilecontents | Out-File "$PSScriptRoot\data\$($tableName).csv" -NoNewline -Force
            
            #Now we need to find the field numbers so we can build our regex. There appears to only be one column in each table that has the potential of having carraige returns or line feeds.
            #nongoodlines is just to indicate if there are any lines that didn't match the exact number of columns. Then we need to find those and fix them.
            $nongoodlines = $filecontents | Select-String -NotMatch $regex | Select-Object -First 1
            if ($nongoodlines) {
                Write-Host "Info: $tableName contains lines that do not match the format. Attempting to fix." -ForegroundColor Cyan
                $brokencolumnnumber = (($nongoodlines | Out-String).Split('|')).Count - 1
                           
                #find lines that do not match the number of columns then remove all LF.
                $regex = [regex]('(?m)^([^|]*(?:\|[^|]*){' + ($brokencolumnnumber - 1) + '}\|[^|]*)\n([^|]*(?:\|[^|]*){' + (($columncount - $brokencolumnnumber) - 1) + '}$)')
                $brokenlines = (($filecontents | Out-String) -replace "`r") | Select-String -AllMatches $regex -List
                $brokenlines.Matches | ForEach-Object { $newfilecontents += ($_.value -replace "`n",' ') + "`n" }

            }

            $newfilecontents | Out-File "$PSScriptRoot\data\$($tableName).csv" -NoNewline -Force
            #MySQL requires double slashes on the path to the actual file.
            $file = (Get-ChildItem -Path "data\$($tableName).csv" | Select-Object -ExpandProperty FullName) -replace '\\','/' # -replace '\\','\\') + '.csv'

            #Cleaned files can be imported immediately.
            if (-Not($SkipDatabaseImport)) {
                
                "LOAD DATA LOCAL INFILE '$file' INTO TABLE ``$($tableName.ToLower())`` FIELDS TERMINATED BY '`|' ESCAPED BY '\\' IGNORE 1 LINES"
                Invoke-SqlUpdate -Query "LOAD DATA LOCAL INFILE '$file' INTO TABLE ``$($tableName.ToLower())`` FIELDS TERMINATED BY '`|' ESCAPED BY '\\' IGNORE 1 LINES"
                # Invoke-SqlUpdate -Query "LOAD DATA LOCAL INFILE '$file' INTO TABLE ``$($tableName.ToLower())`` FIELDS TERMINATED BY '`|' ENCLOSED BY '`"' ESCAPED BY '\\' IGNORE 1 LINES"
            }
        }
    } catch {
        $PSitem
    }
    
}
