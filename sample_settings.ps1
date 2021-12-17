<#

This is provided as an example. Please rename to settings.ps1

#>

$database = @{
    username = 'eschool'
    password = 'Z0pRuj51ic7sit#@pHap'
    dbname = 'eschooldb'
    hostname = 'localhost'
}

# Array of tables names you've created Download Definitions for and you want to download the file for.
$eSchooltables = @('REG','REG_ACADEMIC','REG_BUILDING','REG_BUILDING_GRADE','REG_CALENDAR','REG_CONTACT','REG_CONTACT_PHONE','REG_ENTRY_WITH','REG_ETHNICITY','REGTB_ETHNICITY','REG_NOTES','REG_PERSONAL','REG_PROGRAMS','REG_ROOM','REG_STAFF','REG_STAFF_ADDRESS','REG_STAFF_BLDGS','REG_STU_CONTACT','REG_USER','REGTB_HOUSE_TEAM')
$eSchooltables += @('SCHD_COURSE','SCHD_COURSE_BLOCK','SCHD_COURSE_GRADE','SCHD_COURSE_USER','SCHD_MS','SCHD_MS_BLOCK','SCHD_MS_MP','SCHD_MS_SESSION','SCHD_MS_STAFF','SCHD_MS_SUBJ','SCHD_PERIOD','SCHD_STU_COURSE','SCHD_STU_CRS_DATES')
