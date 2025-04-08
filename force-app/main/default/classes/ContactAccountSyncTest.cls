@isTest
public class ContactAccountSyncTest {

    @isTest
    static void testContactInsert() {
        // Create test data: Accounts and Contacts
        Account testAccount = new Account(Name = 'Test Account', Relationship_status__c = 'New');
        Contact testContact1 = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = testAccount.Id, primary_contact_field__c = false, Relationship_status__c = 'Discovery');
        Contact testContact2 = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id, primary_contact_field__c = true, Relationship_status__c = 'Confirmed');
        Contact testContact3 = new Contact(FirstName = 'qwe', LastName = 'ert', AccountId = testAccount.Id, primary_contact_field__c = true, Relationship_status__c = 'Discovery');
        List<Contact> contactsToInsert = new List<Contact>{testContact1, testContact2, testContact3};
        
        // Insert the test data
        insert testAccount;
        Test.startTest();
        insert contactsToInsert;
        Test.stopTest();
        
        // Verify the trigger's behavior
        testContact3 = [SELECT primary_contact_field__c FROM Contact WHERE Id = :testContact3.Id];
        System.assertEquals(null, testContact3);
        
        testAccount = [SELECT Relationship_status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Confirmed', testAccount.Relationship_status__c);
    }

    @isTest
    static void testContactUpdate() {
        // Create test data: Account and Contacts
        Account testAccount = new Account(Name = 'Test Account', Relationship_status__c = 'New');
        Contact testContact1 = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = testAccount.Id, primary_contact_field__c = true, Relationship_status__c = 'Discovery');
        Contact testContact2 = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id, primary_contact_field__c = false, Relationship_status__c = 'Confirmed');
        Contact testContact3 = new Contact(FirstName = 'qwe', LastName = 'ert', AccountId = testAccount.Id, primary_contact_field__c = false, Relationship_status__c = 'Discovery');
        List<Contact> contactsToInsert = new List<Contact>{testContact1, testContact2, testContact3};
        
        insert testAccount;
        insert contactsToInsert;
 
        List<Contact> contactsToUpdate = new List<Contact>();
        contactsToUpdate.add(new Contact(Id = testContact2.Id, primary_contact_field__c = true, Relationship_status__c = 'Confirmed'));
        contactsToUpdate.add(new Contact(Id = testContact1.Id, primary_contact_field__c = true, Relationship_status__c = 'Discovery'));
        
        Test.startTest();
        update contactsToUpdate;
        Test.stopTest();
        
        // Verify the trigger's behavior
        testContact2 = [SELECT primary_contact_field__c FROM Contact WHERE Id = :testContact2.Id];
        System.assertEquals(false, testContact2.primary_contact_field__c);
        
        // Verify the trigger's behavior
        testAccount = [SELECT Relationship_status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Discovery', testAccount.Relationship_status__c);
    }

   

}