# Lightweight - Data Cloud Auth Provider
A lightweight Auth Provider to connect to the Data Cloud APIs through a Named Credential

## Blog details
For all setup details see the blog here:
https://medium.com/@justusvandenberg/connect-to-the-native-salesforce-data-cloud-api-through-named-credentials-using-a-custom-auth-9b900d0fabcf

## Package info
| Info | Value |
|---|---|
|Name|Lightweight - Data Cloud Auth Provider|
|Version|0.1.0-2|
|Managed Installation URL|  */packaging/installPackage.apexp?p0=04tP30000003w7VIAQ*
|Unlocked Installation URL| */packaging/installPackage.apexp?p0=04tP30000003wInIAI*

## Optional Dependencies
This package has an extension that adds a basic (error) logging functionality and a user mapping utility that allows the Auth Provider to work in a user context using "Per User" instead of "Named Principal". 

| Installation Order | Package Name | Package Version | Installation URL | GIT Url |
|---|---|---|---|---|
| 1 | Lightweight - Auth Provider Util v2 | 0.3.0.LATEST | /packaging/installPackage.apexp?p0=04t4K000002Jv1tQAC | https://github.com/jfwberg/auth-provider-util.git |
 

## Important
- Security is no easy subject: Before implementing this (or any) solution, always validate what you're doing with a certified sercurity expert and your certified implementation partner
- At the time of writing I work for Salesforce. The views / solutions presented here are strictly MY OWN and NOT per definition the views or solutions Salesforce as a company would recommend. Again; always consult with your certified implementation partner before implementing anything you've found on the internet.

## Important note on approach
This is an exploratory, "art of the possible" type approach. Common implementations use the [Salesforce Connect API](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_customer_360_audiences_resources.htm).

For connection from Apex to the same org use the [ConnectApi Apex Classes](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_connect_api.htm) to manage calls to data cloud whenever possible. You can use the CDP methods from this class to save on API calls, JSON parsing etc.

More details to follow soon, for now please see the Medium Blog Post as mentioned at the top.