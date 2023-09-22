/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        April 2023
 * @copyright   (c) 2023 Justus van den Berg
 * @license     MIT (See LICENSE file in the project root)
 * @description Class for testing the DataCloudAuthProvider Methods
 */
@IsTest
private with sharing class DataCloudAuthProviderTest {
    
    /** **************************************************************************************************** **
     **                                      PRIVATE TEST DATA VARIABLE                                      **
     ** **************************************************************************************************** **/
    // Variables for holding test data
    private static DataCloudAuthProvider authProvider;
    private static Map<String,String> authProviderConfig; 


    /** **************************************************************************************************** **
     **                                             TEST METHODS                                             **
     ** **************************************************************************************************** **/
    /**
     * @description Method to test the initiate function
     */
    @IsTest
    static void testInitiate(){
        
        // Test the method
        Test.startTest();
        PageReference pageReference = getAuthProvider().initiate(getAuthProviderConfig(),'TestState');
        Test.stopTest();
        
        // Assert test results
        Assert.areEqual(
            pageReference.getUrl(),
            URL.getOrgDomainUrl().toExternalForm() + '/services/authcallback/TestAuthProvider?state=TestState',
            'Unexpected callback URL'
        );
    }


    /**
     * @description Method to test the handleCallback() function
     */
    @IsTest
    static void testHandleCallback(){
        
        // Set a mock resonse for the token
        Test.setMock(HttpCalloutMock.class, new MockTokenResponse()); 

        // Test the method
        Test.startTest();
        Auth.AuthProviderTokenResponse tokenResponse = getTokenResponse();
        Test.stopTest();

        // Assert test results
        Assert.areEqual('access_token_value', tokenResponse.oauthToken, 'Unexpected oauthToken value');
        Assert.areEqual('TestState',          tokenResponse.state     , 'Unexpected state value');
    }


    /**
     * @description Method to test the refresh() function
     */
    @IsTest
    static void testRefresh(){
        
        // Set a mock resonse for the token
        Test.setMock(HttpCalloutMock.class, new MockTokenResponse()); 

        // Test the method
        Test.startTest();
        Auth.OAuthRefreshResult refreshResult = getAuthProvider().refresh(getAuthProviderConfig(),'[REFRESH_TOKEN]');
        Test.stopTest();

        // Assert test results
        Assert.areEqual('access_token_value',    refreshResult.accessToken, 'Unexpected accessToken value');
    }


    /**
     * @description Method to test the getUserInfo() function
     */
    @IsTest
    static void testGetUserInfo(){
        
        // Set a mock resonse for the token
        Test.setMock(HttpCalloutMock.class, new MockTokenResponse());

        // Test the method
        Test.startTest();
        Auth.UserData userData = getAuthProvider().getUserInfo(
            getAuthProviderConfig(),
            getTokenResponse()
        );
        Test.stopTest();

        // Assert test results
        Assert.areEqual('integration.user@example.com.invalid',    userData.email, 'Unexpected email value');
    }


    /**
     * @description Method to test the getCustomMetadataType() function
     */
    @IsTest
    static void testGetCustomMetadataType(){
        // Assert test results
        Assert.areEqual(
            String.valueOf(DataCloudAuthProvider__mdt.getSObjectType()),
            getAuthProvider().getCustomMetadataType(),
            'Unexpected custom metadata value'
        );
    }


    /**
     * @description Method to test the generateHttpRequest() function
     */
    @IsTest
    static void testGenerateHttpRequest(){
        
        // Test the http request is generated correcty
        Test.startTest();
        HttpRequest httpRequest = getAuthProvider().generateHttpRequest('/api/v1',getAuthProviderConfig(),'test=body');
        Test.stopTest();

        // Validate
        Assert.areEqual('test=body', httpRequest.getBody(), 'Unexpected request body');
        
        // assert result for the endpoint
        Assert.areEqual(
            getAuthProviderConfig().get(DataCloudAuthProvider.MY_DOMAIN_FIELD_NAME) + '/api/v1',
            httpRequest.getEndpoint(),
            'Unexpected endpoint'
        );
    }


    /**
     * @description Method to test the exceptions thrown in case there is no package installed
     */
    @IsTest
    static void testGetAuthProviderUtil(){
        try{
            DataCloudAuthProvider.getAuthProviderUtil();
        }catch(Exception e){
            try{
                DataCloudAuthProvider.handleException(e,getAuthProviderConfig());
            }catch(Exception se){
                Assert.areEqual(
                    String.format(
                        DataCloudAuthProvider.GENERIC_EXCEPTION_MSG, 
                        new String[]{e.getTypeName(), e.getMessage()}
                    ),
                    se.getMessage(),
                    'Unexpected exception message'
                );
            }
        }
    }
    

    /** **************************************************************************************************** **
     **                                      PRIVATE TEST DATA METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method that return a mock token response
     * @return      Mock token reponse
     */
    private static Auth.AuthProviderTokenResponse getTokenResponse(){
        return getAuthProvider().handleCallback(
            getAuthProviderConfig(),
            new Auth.AuthProviderCallbackState(
                null,
                null,
                new Map<String,String>{
                    'code' => 'NoCodeRequiredButMandatory',
                    'state'=> 'TestState'
                }
            )
        );
    }


    /**
     * @description Method to create a Auth Provider (DataCloudAuthProvider) class instance that is
     *              used for testing
     * @return      Class representing the Auth Provider
     */
    private static DataCloudAuthProvider getAuthProvider(){
        if(authProvider == null){
            authProvider = new DataCloudAuthProvider();
        }
        return authProvider;
    }


    /**
     * @description Method to generate the Auth Provider Config data that is used for testing
     * @return      The auth provider configuration data map
     */
    private static Map<String,String> getAuthProviderConfig(){
        if(authProviderConfig == null){
            authProviderConfig=  new Map<String,String>{
                DataCloudAuthProvider.MY_DOMAIN_FIELD_NAME            => 'https://localhost/oauth/token',
                DataCloudAuthProvider.IS_SANDBOX_FIELD_NAME           => 'true',
                DataCloudAuthProvider.INTEG_USERNAME_FIELD_NAME       => '[SUBJECT]',
                DataCloudAuthProvider.CONNECTED_APP_ID_FIELD_NAME     => '[ISSUER]',
                DataCloudAuthProvider.AUTH_PROVIDER_NAME_FIELD_NAME   => 'TestAuthProvider',
                DataCloudAuthProvider.JWS_SIGNING_CERT_FIELD_NAME     => 'certName',
                DataCloudAuthProvider.ENABLE_PER_USER_MODE_FIELD_NAME => 'false',
                DataCloudAuthProvider.ENABLE_ERROR_LOGGING_FIELD_NAME => 'false',
                DataCloudAuthProvider.ENABLE_LOGIN_LOGGING_FIELD_NAME => 'false'
            };
        }
        return authProviderConfig;
    }


    /** **************************************************************************************************** **
     **                                         PRIVATE MOCK CLASSES                                         **
     ** **************************************************************************************************** **/
    /**
     * @description Class for testing the OAuthJwtClientAuthentication Methods
     */
     private class MockTokenResponse implements HttpCalloutMock { 
        
        /**
         * @description Method to generate the mock token response
         * @param       httpRequest The HttpRequest object to add the header values to
         * @return      The mocked HttpResponse (Token)
         */
        public HttpResponse respond(HttpRequest httpRequest) { 
            
            DataCloudAuthProvider.TokenResponse tokenResponse = new DataCloudAuthProvider.TokenResponse();
            tokenResponse.access_token  = 'access_token_value';
            tokenResponse.token_type    = 'Bearer';
            tokenResponse.expires_in    = '1682439225';

            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setStatusCode(200);
            httpResponse.setBody(JSON.serializePretty(tokenResponse));

            return httpResponse;
        }
    }
}