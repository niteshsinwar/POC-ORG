public with sharing class DynamicObjectController {

    // Wrapper class to hold SObject info and implement sorting.
    public class SObjectInfoWrapper implements Comparable {
        public String apiName;
        public String label;

        public SObjectInfoWrapper(String apiName, String label) {
            this.apiName = apiName;
            this.label = label;
        }

        // Sorting by label (alphabetically)
        public Integer compareTo(Object other) {
            SObjectInfoWrapper otherWrapper = (SObjectInfoWrapper) other;
            return this.label.compareTo(otherWrapper.label);
        }
    }

    // Class to encapsulate field metadata.
    public class FieldMetadata {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isCreateable;
    }

    // Wrapper for returning records and metadata.
    public class GetRecordsResult {
        @AuraEnabled public List<Map<String, Object>> records;
        @AuraEnabled public List<FieldMetadata> fieldMetadata;
    }

    // Returns a list of editable objects (with create/update access), sorted by label.
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getEditableObjects() {
        try {
            List<SObjectInfoWrapper> objectWrappers = new List<SObjectInfoWrapper>();
            for (Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
                Schema.DescribeSObjectResult dsr = objType.getDescribe();
                if (dsr.isCreateable() && dsr.isUpdateable() && dsr.isAccessible()) {
                    objectWrappers.add(new SObjectInfoWrapper(dsr.getName(), dsr.getLabel()));
                }
            }

            // Sort the list based on the object's label.
            objectWrappers.sort();

            // Convert the sorted wrappers to a list of maps.
            List<Map<String, String>> objects = new List<Map<String, String>>();
            for (SObjectInfoWrapper wrapper : objectWrappers) {
                objects.add(new Map<String, String>{
                    'apiName' => wrapper.apiName,
                    'name' => wrapper.label
                });
            }
            return objects;
        } catch (Exception e) {
            throw new AuraHandledException('Object fetch error: ' + e.getMessage());
        }
    }

    // Retrieves records and field metadata for the given object.
    @AuraEnabled
    public static GetRecordsResult getRecords(String objectApiName) {
        try {
            GetRecordsResult result = new GetRecordsResult();
            result.records = new List<Map<String, Object>>();
            result.fieldMetadata = new List<FieldMetadata>();

            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) throw new AuraHandledException('Invalid object');
            
            Schema.DescribeSObjectResult objDesc = objType.getDescribe();
            if (!objDesc.isAccessible()) throw new AuraHandledException('No object access');

            // Collect field metadata and build list of query fields.
            Map<String, Schema.SObjectField> fieldMap = objDesc.fields.getMap();
            List<String> queryFields = new List<String>();
            
            // Always include Id field first
            queryFields.add('Id');
            
            // Add Id field metadata
            Schema.DescribeFieldResult idFieldDesc = fieldMap.get('Id').getDescribe();
            FieldMetadata idFieldMeta = new FieldMetadata();
            idFieldMeta.fieldName = 'Id';
            idFieldMeta.label = idFieldDesc.getLabel();
            idFieldMeta.type = String.valueOf(idFieldDesc.getType());
            idFieldMeta.isUpdateable = false;
            idFieldMeta.isCreateable = false;
            result.fieldMetadata.add(idFieldMeta);
            
            // Add other fields
            for (String fieldName : fieldMap.keySet()) {
                if (fieldName == 'Id') continue; // Skip Id as we've already added it
                
                Schema.DescribeFieldResult fDesc = fieldMap.get(fieldName).getDescribe();
                if (fDesc.isAccessible()) {
                    FieldMetadata fm = new FieldMetadata();
                    fm.fieldName = fDesc.getName();
                    fm.label = fDesc.getLabel();
                    fm.type = String.valueOf(fDesc.getType());
                    fm.isUpdateable = fDesc.isUpdateable();
                    fm.isCreateable = fDesc.isCreateable();
                    result.fieldMetadata.add(fm);
                    queryFields.add(fDesc.getName());
                }
            }

            // Query records if there are any accessible fields.
            if (!queryFields.isEmpty()) {
                String query = 'SELECT ' + String.join(queryFields, ', ') + 
                             ' FROM ' + objectApiName + ' ORDER BY LastModifiedDate DESC LIMIT 200';
                for (SObject rec : Database.query(query)) {
                    // Convert SObject to Map, remove attributes
                    Map<String, Object> recMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rec));
                    recMap.remove('attributes');
                    result.records.add(recMap);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Record fetch error: ' + e.getMessage());
        }
    }

    // Upserts records (creates new or updates existing ones) for the given object.
    @AuraEnabled
    public static void upsertRecords1(String objectApiName, List<Map<String, Object>> recordsData) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) throw new AuraHandledException('Invalid object');

            List<SObject> records = new List<SObject>();
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
              System.debug(fieldMap);
            for (Map<String, Object> recData : recordsData) {
                SObject record = objType.newSObject();
                Boolean isNew = !recData.containsKey('Id') || recData.get('Id') == null;

                for (String fieldName : recData.keySet()) {
                    // Skip null values for non-Id fields to prevent setting fields to null unintentionally
                    if (fieldName != 'Id' && recData.get(fieldName) == null) continue;
                    
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    if (field == null) continue;

                    Schema.DescribeFieldResult fDesc = field.getDescribe();
                    if ((isNew && fDesc.isCreateable()) || (!isNew && fDesc.isUpdateable())) {
                        record.put(fieldName, recData.get(fieldName));
                    }
                }
                records.add(record);
            }

            if (!records.isEmpty()) {
                upsert records;
            }
        } catch (DMLException e) {
            throw new AuraHandledException('DML Error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Operation failed: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void upsertRecords(String objectApiName, List<Map<String, Object>> recordsData) {
    try {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) throw new AuraHandledException('Invalid object');

        List<SObject> records = new List<SObject>();
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        for (Map<String, Object> recData : recordsData) {
            SObject record = objType.newSObject();
            Boolean isNew = !recData.containsKey('Id') || recData.get('Id') == null;

            // Set the Id for existing records
            if (!isNew) {
                record.put('Id', recData.get('Id'));
            }

            for (String fieldName : recData.keySet()) {
                // Skip Id field here since it's already handled above
                if (fieldName == 'Id') continue;

                Schema.SObjectField field = fieldMap.get(fieldName);
                if (field == null) continue;

                Schema.DescribeFieldResult fDesc = field.getDescribe();
                if ((isNew && fDesc.isCreateable()) || (!isNew && fDesc.isUpdateable())) {
                    // Allow setting fields to null if explicitly provided
                    record.put(fieldName, recData.get(fieldName));
                }
            }
            records.add(record);
        }

        if (!records.isEmpty()) {
            system.debug(records);
            upsert records;
        }
    } catch (DMLException e) {
        throw new AuraHandledException('DML Error: ' + e.getDmlMessage(0));
    } catch (Exception e) {
        throw new AuraHandledException('Operation failed: ' + e.getMessage());
    }
}
    
    // Validates if the user has delete access to the object
    @AuraEnabled
    public static Boolean canDeleteObject(String objectApiName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) return false;
            
            return objType.getDescribe().isDeletable();
        } catch (Exception e) {
            return false;
        }
    }
}