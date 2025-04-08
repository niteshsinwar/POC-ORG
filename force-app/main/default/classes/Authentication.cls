public class Authentication {
    public static String generateAccessToken(String username, String password) {
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint('https://salesforce-node-s022.onrender.com/authenticate');
        authRequest.setMethod('POST');
        authRequest.setHeader('Content-Type', 'application/json');
        authRequest.setBody('{"username":"' + username + '", "password":"' + password + '"}');

        Http http = new Http();
        HttpResponse authResponse = http.send(authRequest);

        if (authResponse.getStatusCode() == 200) {
            Map<String, Object> authResponseMap = (Map<String, Object>)JSON.deserializeUntyped(authResponse.getBody());
            return (String)authResponseMap.get('accessToken');
        } else {
            return null;
        }
    }
}