public class ContactBatchProcessor implements Database.Batchable<sObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Select all contacts with related account type 'Other'
        return Database.getQueryLocator([SELECT Id, Description FROM Contact WHERE Account.Type = 'Other']);
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        // Update the description of contacts in scope
        for (Contact contact : scope) {
           
             contact.Level__c = 'Primary';
        }
        update scope;
    }
    
    public void finish(Database.BatchableContext BC) {
        // Update the level of all processed contacts to 'Primary'
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Level__c = 'Primary'];
        for (Contact contact : contacts) {
            contact.Description = 'Updated by Batch Process';
        }
        update contacts;
    }
}