/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           October 2023
 * @copyright      (c) 2023 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description   A lightweight Auth Provider to connect to the Data Cloud APIs through a Named Credential
 * @note           In order to use the (error) logging functions and to enabled "Per User" mode for
 *                 user context mappings, It is required that the "Lightweight - Auth Provider Util
 *                 v2" package is installed.
 */
@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class DataCloudAuthProvider extends Auth.AuthProviderPluginClass{

    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // The type of flow (Initial or Refresh)
     private String flowType;

    // For debugging purposes extract the callout data
    private utl.Rst sfTokenCallout;
    private utl.Rst dcTokenCallout;

    // The optional auth provider util for error logging and per user principal (requires the "Lightweight - Auth Provider Util v2" package)
    // If you dont want this depencency, disable the options "Enable Error Logging", "Enabled Per user principal" and "Enabled Per User Login Logging" in the Custom Auth Provider Setup.
    private Callable authProviderUtil;

    // The details of the logged in user
    private String        loggedInUserId   = UserInfo.getUserId();
    private Auth.UserData loggedInUserData = new Auth.UserData(
        UserInfo.getUserId(),    // User Id
        UserInfo.getFirstName(), // First Name
        UserInfo.getLastName(),  // Last Name
        UserInfo.getFirstName() + ' ' +  UserInfo.getLastName(), // Full Name (user name here)
        UserInfo.getUserEmail(), // Email Address
        null,                    // Link
        UserInfo.getUserName(),  // Username
        UserInfo.getLocale(),    // Locale
        null,                    // Provider
        null,                    // Site login
        null                     // Attribute map
    );


    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Grant details
    @TestVisible private final static String MY_DOMAIN_FIELD_NAME  = String.valueOf(DataCloudAuthProvider__mdt.My_Domain_URL__c);
    @TestVisible private final static String IS_SANDBOX_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Is_Sandbox__c);
    
    // JWT Settings
    @TestVisible private final static String INTEG_USERNAME_FIELD_NAME  = String.valueOf(DataCloudAuthProvider__mdt.Integration_Username__c);
    @TestVisible private final static String CONNECTED_APP_ID_FIELD_NAME= String.valueOf(DataCloudAuthProvider__mdt.Connected_App_Id__c);
    
    // Data Space settings
    @TestVisible private final static String DATA_SPACE_NAME_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Data_Space_Name__c);

    // Specify the name for your auth provider for the callback URL
    @TestVisible private final static String AUTH_PROVIDER_NAME_FIELD_NAME    = String.valueOf(DataCloudAuthProvider__mdt.Auth_Provider_Name__c);

    // The API name of the certificate and the algorithm used for signing the JWT
    @TestVisible private final static String JWS_SIGNING_CERT_FIELD_NAME      = String.valueOf(DataCloudAuthProvider__mdt.JWT_Signing_Certificate_Name__c);
    
    // Setup switches
    @TestVisible private final static String ENABLE_PER_USER_MODE_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Enable_Per_User_Mode__c);
    @TestVisible private final static String ENABLE_ERROR_LOGGING_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Enable_Error_Logging__c);
    @TestVisible private final static String ENABLE_LOGIN_LOGGING_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Enable_Per_User_Login_Logging__c);
    @TestVisible private final static String ENABLE_LOGIN_HISTORY_FIELD_NAME = String.valueOf(DataCloudAuthProvider__mdt.Enable_Login_History__c);

    // This will generate the GUID that is used to identify this specific transaction so it can be followed through the logs
    @TestVisible private final static String GUID = utl.Rst.guid();

    // Parameter names
    @TestVisible private final static String PARAM_NAME_STATE = 'state';

    // Test Cookie header
    @TestVisible private final static String TEST_COOKIE_HEADER = 'sid=[SESSION_ID];';

    // Any messages go here
    @TestVisible private final static String GENERIC_EXCEPTION_MSG      = 'A {0} was thrown with the message: {1}';
    @TestVisible private final static String NO_USER_MAPPING_MSG        = 'Nu User Mapping Record was found for Auth Proivder "{0}" with user "{1}"';    
    @TestVisible private final static String MISSING_UTIL_PACKAGE_MSG   = 'Issue whilst instantiating the AuthProviderUtil class. Make sure the "Lightweight - Auth Provider Util v2" package is installed. Alternatively, DISABLE the options "Enable Error Logging", "Enable Per user principal" and "Enable Per User Login Logging" in the Custom Auth Provider Setup.';
    @TestVisible private final static String INVALID_TOKEN_RESPONSE_MSG = 'Unexpected response when calling the token endpoint: {0}';
    

    /** **************************************************************************************************** **
     **                                       PUBLIC INTERFACE METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description     Returns the URL where the user is redirected for authentication.
     * @param           authProviderConfiguration The configuration items for the custom authentication
     *                                            provider that have been configured in the custom
     *                                            metadata type.
     * @param           stateToPropagate          The state passed in to initiate the authentication
     *                                            request for the user
     * @return          The URL of the page where the user is redirected for authentication.
     * @false-positives The URL is generated at a known source and no danger. It's not user updateable.
     *                  Also the remote site settings will prevent any unauthorised endpoint call-outs
     */
    @SuppressWarnings('PMD.ApexOpenRedirect')
    public PageReference initiate(Map<String,String> authProviderConfiguration, String stateToPropagate){ 

        // Get the standard auth provider endpoint url
        PageReference pageReference = this.getSfdcCallbackURL(authProviderConfiguration);
        
        // Add the state parameter
        pageReference.getParameters().put(PARAM_NAME_STATE, stateToPropagate);

        // Return the pageReference
        return pageReference;
    }


    /**
     * @description Uses the authentication provider’s supported authentication protocol to return an
     *              OAuth access token, OAuth secret or refresh token, and the state passed in when the
     *              request for the current user was initiated.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @param       callbackState             The class that contains the HTTP headers, body, and
     *                                        queryParams of the authentication request.
     * @return      Creates an instance of the AuthProviderTokenResponse class
     * @note        There is no refresh token in the OAUth 2.0 JWT Client Authentication flow so we
     *              just ignore this value or put in a random, invalid value.
     */
    public Auth.AuthProviderTokenResponse handleCallback(Map<String,String> authProviderConfiguration, Auth.AuthProviderCallbackState callbackState){
        try{
            // Set the flow type
            this.flowType = 'Initial';

            // Check if the "per user" principal is enabled and if so set the logged in user Id
            if(Boolean.valueOf(authProviderConfiguration.get(ENABLE_PER_USER_MODE_FIELD_NAME))){
                this.setLoggedInUserDetails(callbackState);
            }

            // Retrieve a new token from the token endpoint
            TokenResponse sfTokenResponse = this.retrieveSalesforceToken(authProviderConfiguration);

            // Manage the login history
            this.handleInsertHistoryRecord(
                authProviderConfiguration,
                'Initial',
                String.isNotBlank(sfTokenResponse.access_token),
                'Salesforce',
                this.sfTokenCallout
            );

            // Error with the token, purposely thrown here to manage proper error logging
            if(String.isBlank(sfTokenResponse.access_token)){
                throw new TokenException(String.format(INVALID_TOKEN_RESPONSE_MSG, new String[]{sfTokenCallout.getResponse().getBody()}));
            }

            // Retrieve the access token from the data cloud API call
            TokenResponse dcTokenResponse = this.retrieveDataCloudToken(authProviderConfiguration, sfTokenResponse.access_token);

            // Manage the login history
            this.handleInsertHistoryRecord(
                authProviderConfiguration,
                'Initial',
                String.isNotBlank(dcTokenResponse.access_token),
                'Data Cloud',
                this.dcTokenCallout
            );

            // Check if the per user principal is enabled, if so update the log entry for that user mapping
            if( Boolean.valueOf(authProviderConfiguration.get(ENABLE_PER_USER_MODE_FIELD_NAME)) &&
                Boolean.valueOf(authProviderConfiguration.get(ENABLE_LOGIN_LOGGING_FIELD_NAME))){
                
                // Update the mapping record    
                getAuthProviderUtil().call('updateMappingLoginDetails', new Map<String, Object> { 
                    'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                    'userId'           => loggedInUserId
                });
            }

            // Error with the token, purposely thrown here to manage proper error logging
            if(String.isBlank(dcTokenResponse.access_token)){
                throw new TokenException(String.format(INVALID_TOKEN_RESPONSE_MSG, new String[]{dcTokenCallout.getResponse().getBody()}));
            }

            // Return the the token response, there is no refresh token so we just set a random value
            return new Auth.AuthProviderTokenResponse(
                authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                dcTokenResponse.access_token,
                loggedInUserId, // The logged in user is used for the refresh flow to know what user to login (if per user enabled else ignored)
                callbackState.queryParameters.get(PARAM_NAME_STATE)
            ); 
        }catch(Exception e){
            handleException(e, authProviderConfiguration);
        }

        // Unreachable statement to please the apex compiler
        return null;
    }


    /**
     * @description Returns a new access token, which is used to update an expired access token.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @param       refreshToken              The refresh token for the user who is logged in.
     * @return      Returns the new access token, or an error message if an error occurs.
     * @note        There is no refresh token in the OAUth 2.0 JWT Client Authentication flow so we
     *              just ignore this value or put in a random, invalid value.
     */
    public override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken){
        try{
            // Check if the "per user" principal is enabled and if so set the logged in user Id
            // This way the correct user is
            if(Boolean.valueOf(authProviderConfiguration.get(ENABLE_PER_USER_MODE_FIELD_NAME))){
                loggedInUserId = refreshToken;
            }

            // Retrieve a new token from the token endpoint
            TokenResponse sfTokenResponse = this.retrieveSalesforceToken(authProviderConfiguration);

            // Manage the login history
            this.handleInsertHistoryRecord(
                authProviderConfiguration,
                'Refresh',
                String.isNotBlank(sfTokenResponse.access_token),
                'Salesforce',
                this.sfTokenCallout
            );

            // Error with the token, purposely thrown here to manage proper error logging
            if(String.isBlank(sfTokenResponse.access_token)){
                throw new TokenException(String.format(INVALID_TOKEN_RESPONSE_MSG, new String[]{sfTokenCallout.getResponse().getBody()}));
            }

            // Retrieve the access token from the data cloud API call
            TokenResponse dcTokenResponse = this.retrieveDataCloudToken(authProviderConfiguration, sfTokenResponse.access_token);

            // Manage the login history
            this.handleInsertHistoryRecord(
                authProviderConfiguration,
                'Refresh',
                String.isNotBlank(dcTokenResponse.access_token),
                'Data Cloud',
                this.dcTokenCallout
            );

            // Check if the per user principal is enabled, if so update the log entry for that user mapping
            if( Boolean.valueOf(authProviderConfiguration.get(ENABLE_PER_USER_MODE_FIELD_NAME)) &&
                Boolean.valueOf(authProviderConfiguration.get(ENABLE_LOGIN_LOGGING_FIELD_NAME))){
                
                // Update the mapping record    
                getAuthProviderUtil().call('updateMappingLoginDetails', new Map<String, Object> { 
                    'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                    'userId'           => loggedInUserId
                });
            }

            // Error with the token, purposely thrown here to manage proper error logging
            if(String.isBlank(dcTokenResponse.access_token)){
                throw new TokenException(String.format(INVALID_TOKEN_RESPONSE_MSG, new String[]{dcTokenCallout.getResponse().getBody()}));
            }

            // Return the (refresh) token response
            return new Auth.OAuthRefreshResult(
                dcTokenResponse.access_token,
                refreshToken
            );
        }catch(Exception e){
            handleException(e, authProviderConfiguration);
        }

        // Unreachable statement to please the apex compiler
        return null;
    }


    /**
     * @description Returns information from the custom authentication provider about the current user.
     *              This information is used by the registration handler and in other authentication
     *              provider flows.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @param       response                  The OAuth access token, OAuth secret or refresh token,
     *                                        and state provided by the authentication provider to
     *                                        authenticate the current user.
     * @return      Creates a new instance of the Auth.UserData class.
     * @note        User data is not being used in the OAUth 2.0 JWT Client Authentication flow as it
     *              is a system to system integration. As some basic required info I put in an
     *              integration user.
     */
    public Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        return loggedInUserData;
    }


    /**
     * @description Returns the custom metadata type API name for a custom OAuth-based authentication
     *              provider for single sign-on to Salesforce.
     * @return      The custom metadata type API name for the authentication provider.
     */
    public String getCustomMetadataType() {
        return String.valueOf(DataCloudAuthProvider__mdt.getSObjectType());
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description     Method to Generate the standard Salesforce Auth Provider callback URL for the
     *                  specific Auth Provider Name.
     * @param           authProviderConfiguration The configuration items for the custom authentication
     *                                            provider that have been configured in the custom
     *                                            metadata type.
     * @return          The Auth Provider's callback URL
     * @false-positives The URL is generated at a known source and no danger. It's not user updateable.
     *                  Also the remote site settings will prevent any unauthorised endpoint call-outs
     */
    @SuppressWarnings('PMD.ApexOpenRedirect')
    private PageReference getSfdcCallbackURL(Map<String,String> authProviderConfiguration){
        
        // By default generate the Standard Salesforce Callback URL for the Auth Provider
        return new PageReference(
            URL.getOrgDomainUrl().toExternalForm() + '/services/authcallback/' + authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim()
        );
    }


    /**
     * @description Method to parse the token response JSON into a TokenResponse Object
     * @param       tokenResponseJSON The JSON response returned from the Authorisation Server
     * @return      A TokenResponse Object
     */
    private TokenResponse parseTokenResponse(String tokenResponseJSON){
        return (TokenResponse) JSON.deserialize(tokenResponseJSON, TokenResponse.class);
    }


    /**
     * @description Method that generates the JWT, JWS and HTTP Request to retrieve an access token
     *              from the configured token endpoint.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @return      A TokenResponse with the access token
     * @throws      TokenException            There is an error in parsing the token response
     */
    private TokenResponse retrieveSalesforceToken(Map<String,String> authProviderConfiguration){
        
        // Call SF token endpoint, extract for error handling
        this.sfTokenCallout = new utl.Rst()
            .setEndpoint(authProviderConfiguration.get(MY_DOMAIN_FIELD_NAME) + '/services/oauth2/token')
            .setContentTypeHeaderToFormUrlEncoded(
                new Map<String,String>{
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion'  => this.generateJWS(authProviderConfiguration)
                }
            )
            .call();
            
        // Parse the response into a token response
        return this.parseTokenResponse(this.sfTokenCallout.getResponse().getBody());
    }


    /**
     * @description Method that generates the JWT, JWS and HTTP Request to retrieve an access token
     *              from the configured token endpoint.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @param       sessionId                 The Salesforce Session Id from The salesforce token response
     * @return      A TokenResponse with the access token
     * @throws      TokenException            There is an error in parsing the token response
     */
    private TokenResponse retrieveDataCloudToken(Map<String,String> authProviderConfiguration, String sessionId){
        
        // Map holding the body parameters for the
        Map<String,String> bodyParams = new Map<String,String>{
            'grant_type'        => 'urn:salesforce:grant-type:external:cdp',
            'subject_token'     => sessionId,
            'subject_token_type'=> 'urn:ietf:params:oauth:token-type:access_token'
        };

        // If a data space is provider, populate the data space parameter
        if(!String.isBlank(String.valueOf(authProviderConfiguration.get(DATA_SPACE_NAME_FIELD_NAME)))){
            bodyParams.put('dataspace',String.valueOf(authProviderConfiguration.get(DATA_SPACE_NAME_FIELD_NAME)));
        }

        // Call DC token endpoint, extract for error handling
        this.dcTokenCallout = new utl.Rst()
            .setEndpoint(authProviderConfiguration.get(MY_DOMAIN_FIELD_NAME) + '/services/a360/token')
            .setContentTypeHeaderToFormUrlEncoded(bodyParams)
            .call();
        
        // Parse the response into a token response
        return this.parseTokenResponse(this.dcTokenCallout.getResponse().getBody());
    }


    /**
     * @description Method to generate a JWT and JWS Compact Serialization
     *              This is in a custom method because the Salesforce Auth.JWS Class does not allow you
     *              to change to any other algorithms than SHA256 (unless I missed something
     *              somewhere...)
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @return      JWS Compact Serialized, generated from the configuration
     */
    private String generateJWS(Map<String,String> authProviderConfiguration){
        
        // Create the JWK header
        String header = JSON.serialize(new Map<String,String>{
            'alg' => 'RS256',
            'typ' => 'JWT'
        });

        // Create the JWT payload
        String payload = JSON.serialize(new Map<String,Object>{
            'iss' => authProviderConfiguration.get(CONNECTED_APP_ID_FIELD_NAME)?.trim(),
            'aud' => getAudience(authProviderConfiguration),
            'sub' => getSubject(authProviderConfiguration),
            'exp' => (DateTime.now().addSeconds(300).getTime() / 1000),
            'jti' => GUID
        });        
        
        // Encode and combine the header and body for signing
        String b64UrlEncodedHeaderAndPayload = String.format('{0}.{1}',
            new String[]{
                utl.Rst.base64UrlEncode(Blob.valueOf(header )),
                utl.Rst.base64UrlEncode(Blob.valueOf(payload))
            }
        );

        // Generate the signature
        String b64UrlEncodedSignature = (!Test.isRunningTest()) ? utl.Rst.base64UrlEncode(
            Crypto.signWithCertificate(
                'RSA-SHA256',
                Blob.valueOf(b64UrlEncodedHeaderAndPayload),
                authProviderConfiguration.get(JWS_SIGNING_CERT_FIELD_NAME)?.trim()
            )
        ) : '[TEST_CLASS_VALUE_BECAUSE_THERE_IS_NO_MOCK_CERT_OPTION]';

        // Create and return the JWT in a signed and compact serialization
        return String.format('{0}.{1}', new String[]{
            b64UrlEncodedHeaderAndPayload,
            b64UrlEncodedSignature
        });
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE UTILITY METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Method to define the Audience URL for the Sandbox
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @return      The audience URL for either the Sandbox or for Production
     */
    private String getAudience(Map<String,String> authProviderConfiguration){
        return (
            (Boolean.valueOf(authProviderConfiguration.get(IS_SANDBOX_FIELD_NAME))) ?
                'https://test.salesforce.com' :    
                'https://login.salesforce.com'
        );
    }


    /**
     * @description Method that logs an exception and transforms any exception type into a
     *              GenericException
     * @param       e                         The exception that is thrown and needs to be handled
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @throws      GenericException          Always
     */
    @TestVisible
    private void handleException(Exception e, Map<String,String> authProviderConfiguration){
        
        // Generate a generic exception message for the error handling and to be thrown to the user
        String exceptionMessage = String.format(GENERIC_EXCEPTION_MSG, new String[]{e.getTypeName(), e.getMessage()});
        
        // If logging is enabled use the "Lightweight - Auth Provider Util v2" method to insert an error log
        // This does mean a dependency with a different package, simply remove this code if you don't
        // want to install the dependency      
        if(Boolean.valueOf(authProviderConfiguration.get(ENABLE_ERROR_LOGGING_FIELD_NAME))){
            
            getAuthProviderUtil().call('insertLog', new Map<String, Object> { 
                'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                'userId'           => loggedInUserId,
                'logId'            => GUID,
                'message'          => exceptionMessage
            });
        }
        
        // Throw the new generic exception to the user#
        throw new GenericException(exceptionMessage);
    }


    /**
     * @description Method to Switch the mapped subject between per user principal and Named Principal Mode
     *              as a Identity Type
     *              If per user principal is enabled use the "Lightweight - Auth Provider Util v2" method
     *              and populate the mapping fields for each user  that is allowed to get a token.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @return      The subject that will be part of the JWT sub parameter
     */
    private String getSubject(Map<String,String> authProviderConfiguration){
        
        // Check if the per user principal is enabled
        if(Boolean.valueOf(authProviderConfiguration.get(ENABLE_PER_USER_MODE_FIELD_NAME))){
            
            // If no user mapping exists throw an error
            if(! (Boolean) getAuthProviderUtil().call('checkUserMappingExists', new Map<String, Object> { 
                'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                'userId'           => loggedInUserId
            })){
                throw new SubjectException(
                    String.format(
                        NO_USER_MAPPING_MSG,
                        new String[]{authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME) , loggedInUserId}
                    )
                );
            }

            // Return the subject from the user mapping record related to this user and auth provider
            return (String) getAuthProviderUtil().call('getSubjectFromUserMapping', new Map<String, Object> { 
                'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                'userId'           => loggedInUserId
            });
        }
        
        // By default return the NamedPrincipal
        return authProviderConfiguration.get(INTEG_USERNAME_FIELD_NAME)?.trim();
    }


    /**
     * @description Method to set the user id for the logged in user
     * @param  callbackState The callback state containing the the cookie headers
     */
    @TestVisible
    private void setLoggedInUserDetails(Auth.AuthProviderCallbackState callbackState){
     
        // Get the data for the  logged in user based on the cookie header
        loggedInUserData = (Auth.UserData) getAuthProviderUtil().call('getAuthUserDataFromCookieHeader', new Map<String, Object> { 
            'cookieHeader' => (!Test.IsRunningTest()) ? callbackState.headers.get('Cookie') : TEST_COOKIE_HEADER
        });

        // Extract the user Id for ease of use later
        loggedInUserId = loggedInUserData.identifier;
    }

    
    /**
     * @description Method to get an instance of the AuthProviderUtil class.
     *              This option requires the "Lightweight - Auth Provider Util v2" (04t4K000002Jv1tQAC)
     *              package to be installed
     * @return      Instance of the AuthProviderUtil class
     * @throws      GenericException The lwt.AuthProviderUtil class does not exist.
     */
    @TestVisible
    private Callable getAuthProviderUtil(){
        if(this.authProviderUtil == null){
            
            // Allow for testing a callable method
            if(Test.isRunningTest()){return (Callable) utl.Clbl.getInstance();}
            
            // Dymaically instatiate class 
            this.authProviderUtil = (Callable) Type.forName('lwt.AuthProviderUtil')?.newInstance();
            
            // Throw an error if the package is not installed
            // Add Test check here so the test does not fail in case the package is installed
            if(this.authProviderUtil == null){
                throw new GenericException(MISSING_UTIL_PACKAGE_MSG);
            }
        }
        return this.authProviderUtil;
    }


    /**
     * @description Method that generates the JWT, JWS and HTTP Request to retrieve an access token
     *              from the configured token endpoint.
     * @param       authProviderConfiguration The configuration items for the custom authentication
     *                                        provider that have been configured in the custom metadata
     *                                        type.
     * @param       flowType                  The type of login flow (Initial or Refresh)
     * @param       success                   Inidcator if the login was successful or not
     * @param       providerType              Optional description of the provider. This is handy when you
     *                                        have chained callouts.
     * @param       callout                   The callout details for error logging
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void handleInsertHistoryRecord(Map<String,String> authProviderConfiguration, String flowType, Boolean success, String providerType, utl.Rst callout){
        // If login history is enabled, create a login history entry
        if(Boolean.valueOf(authProviderConfiguration.get(ENABLE_LOGIN_HISTORY_FIELD_NAME))){
            getAuthProviderUtil().call('insertLoginHistoryRecord', new Map<String, Object> { 
                'authProviderName' => authProviderConfiguration.get(AUTH_PROVIDER_NAME_FIELD_NAME)?.trim(),
                'userId'           => loggedInUserId,
                'flowType'         => flowType,
                'timestamp'        => Datetime.now(),
                'success'          => success,
                'providerType'     => providerType,
                'loginInfo'        => success ? null : callout?.getResponse()?.getBody()
            });
        }
    }


    /** **************************************************************************************************** **
     **                                      PRIVATE EXCEPTION CLASSES                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Custom Exception thrown when there is an issue generating the JWS.
     */
    @TestVisible
    private class JwsException    extends Exception{}


    /**
     * @description Custom Exception thrown when there is an issue generating the token.
     */
    @TestVisible
    private class TokenException  extends Exception{}


    /**
     * @description Custom Exception thrown when there is an issue related the subject
     */
    @TestVisible
    private class SubjectException extends Exception{}


    /**
     * @description Custom Exception thrown when there is an issue generating the token.
     */
    @TestVisible
    private class GenericException extends Exception{}


    /** **************************************************************************************************** **
     **                                    PRIVATE DATA STRUCTURE CLASSES                                    **
     ** **************************************************************************************************** **/
    /**
     * @description     Class representing the data strcuture of an OAuth Token Response as described in standard:
     *                  https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.2
     * @false-positives Namings conventions have to match the JSON response format in order to properly
     *                  deserialize.  In this case the naming conventions will not follow standard
     *                  conventions to accomodate this
     */
    @SuppressWarnings('PMD.VariableNamingConventions, PMD.FieldNamingConventions')
    @TestVisible
    private class TokenResponse{
        
        // Required
        public String access_token;
        public String token_type;

        // Optional
        public String expires_in;
        public String scope;
        public String state;

        // Data cloud response only
        public String instance_url;
        public String issued_token_type;
    }


}