# Lightweight - Data Cloud Auth Provider
A lightweight Auth Provider to connect to the Data Cloud APIs through a Named Credential

## Blog details
For all setup details see the blog here:
https://medium.com/@justusvandenberg/connect-to-the-native-salesforce-data-cloud-api-through-named-credentials-using-a-custom-auth-9b900d0fabcf

## Dependency - Package Info
The following package need to be installed first before installing this package. (In this order)
If you use the *managed package* you need to installed the managed package dependency and if you use the *unlocked version* you need to use the unlocked dependency.
| Info | Value |
|---|---|
|Name|Lightweight - Apex Unit Test Util v2|
|Version|2.4.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP3000000M6OXIA0* |
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP3000000M6Q9IAK* |
|Github URL | https://github.com/jfwberg/lightweight-apex-unit-test-util-v2         |
| | |
|Name|Lightweight - Apex REST Util|
|Version|0.11.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP3000000M6gHIAS* |
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP3000000M6htIAC* | 
|Github URL | https://github.com/jfwberg/lightweight-apex-rest-util                 |


## Optional Dependencies
This package has an extension that adds a basic (error) logging functionality and a user mapping utility that allows the Auth Provider to work in a user context using "Per User" instead of "Named Principal".

| Info | Value |
|---|---|
|Name|Lightweight - Auth Provider Util v2|
|Version|0.12.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP3000000MVUzIAO*   |
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP3000000MW1FIAW*   |
|GIT URL                  | https://github.com/jfwberg/lightweight-auth-provider-util |

## Package info
| Info | Value |
|---|---|
|Name|Lightweight - Data Cloud Auth Provider|
|Version|0.5.0-1|
|Managed Installation URL | */packaging/installPackage.apexp?p0=04tP3000000M6y1IAC* |
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP3000000M6zdIAC* |

## Important
- Security is no easy subject: Before implementing this (or any) solution, always validate what you're doing with a certified sercurity expert and your certified implementation partner
- At the time of writing I work for Salesforce. The views / solutions presented here are strictly MY OWN and NOT per definition the views or solutions Salesforce as a company would recommend. Again; always consult with your certified implementation partner before implementing anything you've found on the internet.

## Assign permissions to Automated Process User
Since the Spring 24 release platform events started running as the Automated Process User. Making the logging fail due to access issue. Only run this if you are planning on using the "Lightweight - Auth Provider" Util Package
To fix this I created a specific permission set for this user that can be assigned using the code below.
```java
insert new PermissionSetAssignment(
    AssigneeId      = [SELECT Id FROM User          WHERE alias = 'autoproc']?.Id,
    PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name  = 'Lightweight_Auth_Provider_Util_AutoProc']?.Id
);
```

## Important note on approach
This is an exploratory, "art of the possible" type approach. Common implementations use the [Salesforce Connect API](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_customer_360_audiences_resources.htm).

For connection from Apex to the same org use the [ConnectApi Apex Classes](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_connect_api.htm) to manage calls to data cloud whenever possible. You can use the CDP methods from this class to save on API calls, JSON parsing etc.

The core use case is the use of the Data Cloud Ingestion API

More details to follow soon, for now please see the Medium Blog Post as mentioned at the top.