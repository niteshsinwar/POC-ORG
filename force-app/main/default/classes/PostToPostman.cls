public with sharing class PostToPostman {
      @future(callout=true)
   public static void sendAccountToNode(String accountId, String username, String password) {
        // Authenticate with your Node.js project to obtain an access token.
        System.debug(username);
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint('https://salesforce-node-s022.onrender.com/authenticate');
        authRequest.setMethod('POST');
        authRequest.setHeader('Content-Type', 'application/json');
        authRequest.setBody('{"username":"' + username + '", "password":"' + password + '"}');

        Http http = new Http();
        HttpResponse authResponse = http.send(authRequest);

        if (authResponse.getStatusCode() == 200) {
             System.debug('succesful');
            // Successfully authenticated. Extract the access token.
               Map<String, Object> authResponseMap = (Map<String, Object>)JSON.deserializeUntyped(authResponse.getBody());
                String accessToken = (String)authResponseMap.get('accessToken');
           System.debug('accessToken');
            System.debug(accessToken);
            // Fetch the Account data using the accountId and construct a JSON payload.
            // You can add additional fields as needed.
            // Replace 'https://your-node-project-url/salesforce/account' with your Node.js endpoint.
            HttpRequest accountRequest = new HttpRequest();
            accountRequest.setEndpoint('https://salesforce-node-s022.onrender.com/salesforce/account');
            accountRequest.setMethod('POST');
            accountRequest.setHeader('Authorization', 'Bearer ' + accessToken);
            accountRequest.setHeader('Content-Type', 'application/json');
            accountRequest.setBody('{"account_id":"' + accountId + '", "other_data": "..." }');

            HttpResponse accountResponse = http.send(accountRequest);
             System.debug('accountResponse');
                      System.debug(accountResponse);
            // Process the response if necessary.
        }
    }
}