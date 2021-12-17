# eSchoolData

This project was created to work with Download Definitions of the eSchool Database Tables. The Download Definitions are created automatically for you. This includes examples of pulling differencing data from the tables with a CHANGE_DATE_TIME. For scheduling you can pull the current year only automatically as well.

Using the download definitions in eSchool instead of using Cognos is slower. However, it keeps the project to JUST using eSchool instead of involving Cognos as well. It also makes it where anybody can use these out of the box without having to modify reports for your own district. Another team is working on Cognos reports.

This project requires the eSchoolUpload project.

First define the eSchool tables we want in an array.
````
$tables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM')
````

Next we need to create the download definitions for those tables. DefinitionName MUST BE 5 CHARACTERS!
````
#Example of creating a download definition called "RGALL" with no limiting SQL.
.\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RGALL"

#Example of creating a download definition called "RG12H" with a limitation of CHANGE_DATE_TIME within the last 12 hours.
.\CreateDownloadDefinitions.ps1 -username 0403cmillsap -DefinitionName "RG12H" -SQL 'WHERE CONVERT(DATETIME,CHANGE_DATE_TIME,101) >= DateAdd(Hour, DateDiff(Hour, 0, GetDate())-12, 0)'
````

To download the files created by the download definition using the eSchoolUpload Project.
````
#This runs the Download Definition and downloads the first file when complete.
.\eSchoolUpload\eSchoolDownload.ps1 -InterfaceID RGALL -reportname "REG" -outputfile "$PSScriptRoot\data\REG.csv"

#This will just download the next file.
.\eSchoolUpload\eSchoolDownload.ps1 -reportname "REG_ACADEMIC" -outputfile "$PSScriptRoot\data\REG_ACADEMIC.csv"
````

# CSVs
All CSVs are | delimited by default because you can't wrap fields in quotes. Some fields have commas. However, you can convert them to regular CSV by specifying the -TrimCSVWhiteSpacing parameter on the eSchoolDownload.ps1 file.

# MySQL/MariaDB
Server Configuration - In my testing I needed to the following config before I could properly create tables in the lateset version of MariaDB.
````
innodb_strict_mode = 0
````


Create user, database, and set permissions. (password is in the sample as well but please change it in production.)
````
mysql.exe -u root -p

#MySQL
CREATE USER 'eschool'@'localhost' IDENTIFIED VIA mysql_native_password USING 'Z0pRuj51ic7sit#@pHap';
#MariaDB
CREATE USER 'eschool'@'localhost' IDENTIFIED BY 'Z0pRuj51ic7sit#@pHap';

#Either
GRANT FILE ON *.* TO 'eschool'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS `eschooldb`;
GRANT ALL PRIVILEGES ON `eschooldb`.* TO 'eschool'@'localhost';
````

Define the eSchool tables you want to create MySQL tables for. You can do this as many times as you need to.
````
$tables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER',,'REGTB_HOUSE_TEAM')
.\CreateMySQLTables.ps1
````

