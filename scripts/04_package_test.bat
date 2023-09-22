REM *****************************
REM      INSTALL ON TEST ORG   
REM *****************************

REM Config
SET testOrg=orgAlias
SET packageVersionId=04tP30000003w7VIAQ

REM Install the package
sf package:install -p %packageVersionId% --target-org %testOrg% --wait 30

REM Uninstall the package
sf package uninstall --package %packageVersionId% --target-org %testOrg% --wait 30

REM Uninstall the dependencies
sf package uninstall --package %packageVersionId% --target-org %testOrg% --wait 30
