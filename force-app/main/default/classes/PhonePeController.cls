public with sharing class PhonePeController {
    
    private static final String PHONEPE_API_URL = 'https://api-preprod.phonepe.com/apis/pg-sandbox'; // Testing URL
    private static final String MERCHANT_ID = 'PGTESTPAYUAT86';
    private static final String SALT_KEY = '96434309-7796-489d-8924-ab56988a6076';
    private static final String SALT_INDEX = '1';

    private static String getCallbackUrl() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        return baseUrl + '/services/apexrest/phonepe/callback';
    }

    private static String getRedirectUrl() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        return baseUrl + '/services/apexrest/phonepe/callback';
    }
    
  @AuraEnabled
public static Map<String, Object> initiatePayment(Decimal amount, String merchantTransactionId, String merchantUserId) {
    try {
        System.debug('### initiatePayment method started ###');
        
        // Prepare payload
        Map<String, Object> payloadMap = new Map<String, Object>();
        Map<String, Object> merchantDetails = new Map<String, Object>();
        merchantDetails.put('merchantId', MERCHANT_ID);
        merchantDetails.put('merchantTransactionId', merchantTransactionId);
        
        Map<String, Object> amountDetails = new Map<String, Object>();
        amountDetails.put('value', Integer.valueOf(amount * 100)); // Convert to paisa as integer
        amountDetails.put('currency', 'INR');
        
        payloadMap.put('merchantId', MERCHANT_ID);
        payloadMap.put('merchantTransactionId', merchantTransactionId);
        payloadMap.put('merchantUserId', merchantUserId);
        payloadMap.put('amount', amountDetails);
        payloadMap.put('redirectUrl', getRedirectUrl());
        payloadMap.put('redirectMode', 'POST');
        payloadMap.put('callbackUrl', getCallbackUrl());
        payloadMap.put('paymentInstrument', new Map<String, String>{'type' => 'PAY_PAGE'});

        System.debug('### Constructed Payload Map: ' + JSON.serializePretty(payloadMap));

        // Convert payload to JSON string
        String payload = JSON.serialize(payloadMap);
        System.debug('### JSON Payload: ' + payload);

        // Create base64 encoded string
        String base64Payload = EncodingUtil.base64Encode(Blob.valueOf(payload));
        System.debug('### Base64 Encoded Payload: ' + base64Payload);

        // Generate checksum (SHA256 hash of the payload + "/pg/v1/pay" + salt key)
        String dataToHash = base64Payload + '/pg/v1/pay' + SALT_KEY;
        String checksum = generateSHA256Hash(dataToHash);
        System.debug('### Generated Checksum: ' + checksum);

        // Prepare request body
        Map<String, String> requestBody = new Map<String, String>();
        requestBody.put('request', base64Payload);
        System.debug('### Request Body: ' + JSON.serializePretty(requestBody));

        // Make API call
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PHONEPE_API_URL + '/pg/v1/pay');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-VERIFY', checksum + '###' + SALT_INDEX);
        req.setBody(JSON.serialize(requestBody));

        System.debug('### Final HTTP Request: ' + req);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('### HTTP Response Status Code: ' + res.getStatusCode());
        System.debug('### HTTP Response Body: ' + res.getBody());

        // Check response status
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            System.debug('### API Request Failed with Status: ' + res.getStatus());
            throw new CalloutException('API request failed with status code ' + res.getStatusCode() + ': ' + res.getStatus());
        }

        // Parse and return response
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

    } catch (Exception e) {
        System.debug('### Exception Occurred: ' + e.getMessage());
        return createErrorResponse(e.getMessage());
    }
}

    
    @AuraEnabled
    public static Map<String, Object> checkPaymentStatus(String merchantTransactionId) {
        try {
            // Generate checksum for status check
            String path = '/pg/v1/status/' + MERCHANT_ID + '/' + merchantTransactionId;
            String dataToHash = path + SALT_KEY;
            String checksum = generateSHA256Hash(dataToHash);
            
            // Make API call
            HttpRequest req = new HttpRequest();
            req.setEndpoint(PHONEPE_API_URL + path);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-VERIFY', checksum + '###' + SALT_INDEX);
            // Removed unnecessary X-MERCHANT-ID header
            
            Http http = new Http();
          
            HttpResponse res = http.send(req);
            
            // Check response status
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                throw new CalloutException('API request failed with status code ' + res.getStatusCode() + ': ' + res.getStatus());
            }
            
            // Parse and return response
            return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
        } catch (Exception e) {
            return createErrorResponse(e.getMessage());
        }
    }
    
    private static String generateSHA256Hash(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob hashOutput = Crypto.generateDigest('SHA-256', inputBlob);
        return EncodingUtil.convertToHex(hashOutput);
    }
    
    private static Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> errorResponse = new Map<String, Object>();
        errorResponse.put('success', false);
        errorResponse.put('message', message);
        return errorResponse;
    }
}