# eSchool Data Exports
These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.

This project will create Download Definitions for the eSchool Database Tables.

Using the download definitions in eSchool instead of using Cognos is ridiculously slower. However, due to the file size limits in Cognos we have no choice. It also makes it where anybody can use these out of the box without having to modify reports for your own district.

This project requires the eSchoolUpload project: https://github.com/AR-k12code/eSchoolUpload

## Connect to eSchool
The eSchoolUpload project should already be configured and tested prior to using this. Lets dot source our login script so we have our session variables.
````
. ..\eSchoolUpload\eSchool-Login.ps1
````

## Import Module
````
Import-Module .\eSchool-Definitions.psm1 -Force
````

## Define Tables to Pull
First define the eSchool tables we want in an array. Tables are documented in the resources folder.
````
$tables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM')
````

## Create the Download Definition
Next we need to create the download definitions for those tables. DefinitionName MUST BE 5 CHARACTERS!
````
#Example of creating a download definition called "RGALL" with no limiting SQL and no SCHOOL_YEAR Limits.
New-ESPDownloadDefinition -DefinitionName "RGALL" -tables @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM') -DoNotLimitSchoolYear

#Example of creating a download definition called "RG12H" with a limitation of CHANGE_DATE_TIME within the last 12 hours.
New-ESPDownloadDefinition -DefinitionName "RG12H" -tables @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM') -SQL 'WHERE CONVERT(DATETIME,CHANGE_DATE_TIME,101) >= DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)'
````

## Download the Files
This will use the eSchoolUpload project. This will start the Download Definition, generate the files, and will wait until its complete or errors out.
````
.\eSchoolUpload\eSchoolDownload.ps1 -InterfaceID "RGALL"
````

To Run a Download Definition and Download a SINGLE file generated.
````
.\eSchoolUpload\eSchoolDownload.ps1 -InterfaceID RGALL -reportname "REG" -outputfile "c:\data\REG.csv"
````

To Run a Download Definition and bulk download files
````
.\eSchoolUpload\eSchoolDownload.ps1 -InterfaceID "RGALL"

@('REG','REG_CONTACT','REG_STU_CONTACT') | ForEach-Object {
    .\eSchoolUpload\eSchoolDownload.ps1 -rawfilename "$($PSItem).csv" -outputfile "c:\data\$($PSItem).csv"
}
````

## Data Integrity
Since eSchool can be stupid, you should validate your CSV files prior to importing into any system. We recommend csvclean from CSVKIT.

Each file is currently using ^ as the delimiter should have a record end of #!#.  Reason being that eSchool does not properly escape commas and extra quotes in the file generated. We need to find a character that we shouldn't find in a text record field. The record end of #!# is for line feed and carriage return replacement that breaks CSV files.

Example File:
````
ATTENDANCE_CODE^BUILDING^CHANGE_DATE_TIME^CHANGE_UID^DISTRICT^SCHOOL_YEAR^SUMMER_SCHOOL^#!#
CD^14^4/10/2013 10:57:59 AM^0407JDOE^407000^2015^N^#!#
PC^16^9/19/2014 10:30:52 AM^0407jdoe^407000^2015^N^#!#
````

### Example Cleanup:
This will leave you with a ^ delmited file but flat so you can import it properly.  Line Feed will be replaced with {{LF}} and extra Carriage Returns will be replaced with {{CR}}
````
(Get-Content -Raw "REG_NOTES.csv") -replace "`n",'{{LF}}' -replace "`r","{{CR}}" -replace "\^#!#{{{CR}}","`r" | Out-File ".\files\$($PSitem).csv" -Force
````


