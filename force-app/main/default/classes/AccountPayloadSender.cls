public class AccountPayloadSender {

     @future(callout=true)
    public static void sendAccountDataAsync(Id accountId, String username, String password) {
        sendAccountData(accountId, username, password);
    }
    public static void sendAccountData(String accountId, String username, String password) {
        // Generate access token using the provided username and password
        String accessToken = Authentication.generateAccessToken(username, password);
        
        if (accessToken != null) {
            // Generate payload using the accountId and access token
            PayloadGenerator.PayloadWrapper payload = PayloadGenerator.generatePayload(accountId, accessToken);
            
            if (payload != null) {
                // Convert payload to JSON string
                String payloadJSON = JSON.serialize(payload);
                
                // Send the payload to the external system (replace the endpoint with your actual endpoint)
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://salesforce-node-s022.onrender.com/salesforce/account'); // Replace with your Node.js endpoint
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(payloadJSON);

                Http http = new Http();
                HttpResponse res = http.send(req);
                
                // Process the response if necessary
                if (res.getStatusCode() == 200) {
                    System.debug('Account payload sent successfully.');
                } else {
                    System.debug('Error sending account payload: ' + res.getStatus());
                    System.debug(res.getBody());
                }
            } else {
                System.debug('Error generating account payload.');
            }
        } else {
            System.debug('Error generating access token.');
        }
    }
}