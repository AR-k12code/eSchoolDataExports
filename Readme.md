# eSchool Data Exports
These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.

This project will create Download Definitions for the eSchool Database Tables. This script does limit the data to be the current school year only if the table has the SCHOOL_YEAR column. We have also included examples of pulling data that has been modified within the last X number of hours.

Using the download definitions in eSchool instead of using Cognos is ridiculously slower. However, it keeps the project to JUST using eSchool instead of involving Cognos as well. It also makes it where anybody can use these out of the box without having to modify reports for your own district. Another team is working on generic Cognos reports.

This project requires the eSchoolUpload project: https://github.com/AR-k12code/eSchoolUpload

## Define Tables to Pull
First define the eSchool tables we want in an array. The script will create a Download Definition with each of these tables as a Interface Header. This is run in your terminal prior to calling the .\CreateDownloadDefinitions.ps1 script. Tables are documented in the resources folder.
````
$tables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM')
````

## Create the Download Definition
Next we need to create the download definitions for those tables. DefinitionName MUST BE 5 CHARACTERS!
````
#Example of creating a download definition called "RGALL" with no limiting SQL.
.\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RGALL"

#Example of creating a download definition called "RG12H" with a limitation of CHANGE_DATE_TIME within the last 12 hours.
.\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RG12H" -SQL 'WHERE CONVERT(DATETIME,CHANGE_DATE_TIME,101) >= DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)'
````

## Download the Files

First we have to Run the Download Definition. This will start the Download Definition, generate the files, and will wait until its complete or errors out.
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
    .\eSchoolUpload\eSchoolDownload.ps1 -reportname "$($PSItem)" -outputfile "c:\data\$($PSItem).csv"
}
````

## Data Integrity
Since eSchool can be stupid, you should validate your CSV files prior to importing into any system. We recommend csvclean from CSVKIT.
