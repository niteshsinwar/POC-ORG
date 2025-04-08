public with sharing class ObjectSelectorController {
    
    // Returns records for the given object – only records the user can see/update will be returned by SOQL.
    @AuraEnabled(cacheable=true)
    public static List<sObject> getRecords(String objectApiName) {
        String query = 'SELECT Id, Name FROM ' + objectApiName + ' LIMIT 200';
        return Database.query(query);
    }
    
    // Returns object API names filtered by access type.
    @AuraEnabled(cacheable=true)
    public static List<String> getAllObjectNames(String accessType) {
        List<String> objectNames = new List<String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        for (String key : schemaMap.keySet()) {
            Schema.DescribeSObjectResult dsr = schemaMap.get(key).getDescribe();
            if(accessType == 'create') {
                if(dsr.isCreateable()) {
                    objectNames.add(dsr.getName());
                }
            } else if(accessType == 'update') {
                if(dsr.isUpdateable()) {
                    objectNames.add(dsr.getName());
                }
            }
        }
        return objectNames;
    }
}