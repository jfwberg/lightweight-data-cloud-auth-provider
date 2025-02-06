REM --------------------------------------------------------
REM MANGED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)  -
REM --------------------------------------------------------
rem Lightweight - Apex Unit Test Util v2@2.5.0-2
sf package install -p "04tP3000000rUmLIAU" -w 30

rem Lightweight - REST Util@0.13.0-1
sf package install -p "04tP3000000wMhhIAE" -w 30

REM ----------------- OPTIONAL BUT ADVICED -----------------
rem Lightweight - Auth Provider Util v2@0.12.0-1
sf package install -p "04tP3000000MVUzIAO" -w 30


REM --------------------------------------------------------
REM UNLOCKED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)-
REM --------------------------------------------------------
rem Lightweight - Apex Unit Test Util v2 (Unlocked)@2.5.0-2
sf package install -p "04tP3000000rUpZIAU" -w 30

rem Lightweight - REST Util (Unlocked)@0.13.0-1
sf package install -p "04tP3000000wMkvIAE" -w 30

REM ----------------- OPTIONAL BUT ADVICED -----------------
rem Lightweight - Auth Provider Util v2 (Unlocked)@0.12.0-1
sf package install -p "04tP3000000MW1FIAW" -w 30


REM --------------------------------------------------------
REM                  ASSIGN PERMISSION SETS                -
REM --------------------------------------------------------
sf org assign permset --name "Lightweight_Apex_Unit_Test_Util_v2"
sf org assign permset --name "Lightweight_REST_Util"
sf org assign permset --name "Lightweight_Auth_Provider_Util"
sf org assign permset --name "Lightweight_Data_Cloud_Auth_Provider"
