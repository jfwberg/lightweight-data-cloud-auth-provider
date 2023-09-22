# Lightweight - Data Cloud Auth Provider
A lightweight Auth Provider to connect to the Data Cloud APIs through a Named Credential

## Blog details
Coming soon...

## Package info
| Info | Value |
|---|---|
|Name|Lightweight - Data Cloud Auth Provider|
|Version|0.1.0-2|
|Managed Installation URL| */packaging/installPackage.apexp?p0=04tP30000003w7VIAQ*
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
If you run Data Cloud on the same Org you want to call it from, there is no need to call the APIs directly. Use the [ConnectApi Apex Classes](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_connect_api.htm) to manage calls to data cloud whenever possible.
You can use the CDP methods from this class to save on API calls, JSON parsing etc.

## Org Info
To make clear what is the difference between the Orgs that we are going to connect using the Salesforce API, I've outlined the difference.

### Hub Org
- This Org is going to callout to the Data Cloud Org(s).
- This Org contains the Auth Provider Package
- This Org is where we will set up the named/external credentials
- This Org contains the private key / certificate that is used for connecting to the Data Cloud (spoke) org(s)

### Spoke Org / Data Cloud Org
- This Org has Data Cloud provisioned on it
- This Org is where we will set up a Connected App

## Pre-requisites
- The Hub Org My Domain URL
- The Spoke Org My Domain URL
- The Data Cloud Instance URL
- A certificate with public and private key that is used for signing the JWT. This should be a CA signed certificate but you can use a self signed certificate for testing purposes. This should be saved in the Salesforce certificate store
- Have the public certificate saved on your machine as a file, we need this later.
- Optionally: install the Auth Provider Util on the Hub Org, for easy error hanlding and per user management

## 00 :: Deployment and Preparation
1. Deploy the *Apex Class* and the *Custom Metadata (including layouts)* from this SFDX Project to your Org (Or install the package as described in the package info)

To be completed...
