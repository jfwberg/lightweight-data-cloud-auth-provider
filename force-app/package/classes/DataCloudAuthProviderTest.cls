/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        October 2023
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
        
        // Override the user config and enable per user mode to "test" the callable methods
        getAuthProviderConfig().put(DataCloudAuthProvider.ENABLE_PER_USER_MODE_FIELD_NAME, 'true');
        getAuthProviderConfig().put(DataCloudAuthProvider.ENABLE_LOGIN_LOGGING_FIELD_NAME, 'true');

        utl.Clbl.setActionResponse('getAuthUserDataFromCookieHeader',  getAuthProvider().getUserInfo(getAuthProviderConfig(),null));

        // Setup the response from the callable action
        utl.Clbl.setActionResponse('updateMappingLoginDetails', null);
        utl.Clbl.setActionResponse('checkUserMappingExists',    true);
        utl.Clbl.setActionResponse('getSubjectFromUserMapping', 'federationId');
        utl.Clbl.setActionResponse('insertLoginHistoryRecord',  null);
        

        // Setup the mock response
        utl.Mck.setResponse(200, JSON.serializePretty(new Map<String,String>{
            'access_token' => 'access_token_value',
            'token_type'   => 'Bearer',
            'expires_in'   => '1682439225'
        }));

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
        
        // Setup the callable
        utl.Clbl.setActionResponse('insertLoginHistoryRecord',  null);

        // Setup the mock response
        utl.Mck.setResponse(200, JSON.serializePretty(new Map<String,String>{
            'access_token' => 'access_token_value',
            'token_type'   => 'Bearer',
            'expires_in'   => '1682439225'
        })); 

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
        
        // Setup the callable
        utl.Clbl.setActionResponse('insertLoginHistoryRecord',  null);

        // Setup the mock response
        utl.Mck.setResponse(200, JSON.serializePretty(new Map<String,String>{
            'access_token' => 'access_token_value',
            'token_type'   => 'Bearer',
            'expires_in'   => '1682439225'
        }));

        // Test the method
        Test.startTest();
        Auth.UserData userData = getAuthProvider().getUserInfo(
            getAuthProviderConfig(),
            getTokenResponse()
        );
        Test.stopTest();

        // Assert test results
        Assert.areEqual(UserInfo.getUserEmail(),    userData.email, 'Unexpected email value');
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
     * @description Method to test the exceptions thrown in case there is no package installed
     */
    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testHandleException(){
        
        // Run once so it is initialized
        getAuthProviderConfig();

        // Override the user config and enable error logging to "test" the callable methods
        authProviderConfig.put(DataCloudAuthProvider.ENABLE_ERROR_LOGGING_FIELD_NAME, 'true');
 
        // Setup the response from the callable action 
        utl.Clbl.setActionResponse('insertLog', null);

        try{
            DataCloudAuthProvider dcap = new DataCloudAuthProvider();
            
            // Try to handle the exception
            dcap.handleException(
                new DataCloudAuthProvider.GenericException('Message'),
                getAuthProviderConfig()
            );

            // This method will fail the test as it should not be reached
            utl.Tst.assertExceptionHasBeenThrow();

        }catch(Exception e){
            
            // Assert the exception works as expected
            utl.Tst.assertExceptionMessage(
                DataCloudAuthProvider.GENERIC_EXCEPTION_MSG,
                String.valueOf(DataCloudAuthProvider.GenericException.class),
                'Message',
                e
            ); 
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
                DataCloudAuthProvider.ENABLE_LOGIN_LOGGING_FIELD_NAME => 'false',
                DataCloudAuthProvider.ENABLE_LOGIN_HISTORY_FIELD_NAME => 'true'
            };
        }
        return authProviderConfig;
    }


    /** **************************************************************************************************** **
     **                                         PRIVATE MOCK CLASSES                                         **
     ** **************************************************************************************************** **/
   
}