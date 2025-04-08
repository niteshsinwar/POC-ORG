@RestResource(urlMapping='/phonepe/callback/*')
global with sharing class PhonePeCallbackService {
    
    @HttpPost
    global static void handleCallback() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Get the request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            // Extract transaction details
            String transactionId = (String)payloadMap.get('transactionId');
            String status = (String)payloadMap.get('status');
			String amount = (String)payloadMap.get('amount');
            
            // Log the callback for debugging
            System.debug('PhonePe Callback: ' + requestBody);
            
            // Process the payment result
            // This could update a custom object to store payment status
            Payment__c payment = new Payment__c(
                Name = transactionId,
                Status__c = status,
				Amount__c = amount
                // Add other fields as needed
            );
            insert payment;
            
            // Return a success response
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"success":true}');
        } catch (Exception e) {
            // Log and return error
            System.debug('PhonePe Callback Error: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"success":false,"error":"' + e.getMessage() + '"}');
        }
    }
    
 @HttpGet
global static void handleRedirect() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    
    // Get query parameters
    String merchantTransactionId = req.params.get('merchantTransactionId');
    String status = req.params.get('status');
    
    // Redirect to a Visualforce page or Lightning page showing payment result
    String homePageUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/page/home';
    String redirectUrl = homePageUrl + '?paymentStatus=' + status + '&txnId=' + merchantTransactionId;
    
    res.statusCode = 302;
    res.headers.put('Location', redirectUrl);
}
}