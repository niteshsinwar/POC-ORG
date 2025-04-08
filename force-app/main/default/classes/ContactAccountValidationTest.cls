@isTest
public class ContactAccountValidationTest {

    @isTest
    static void testInsertWithinLimit() {
        
          Account testAccount1 = new Account(Name = 'Test Account 1');
        insert testAccount1;

        List<Contact> testContacts1 = new List<Contact>();
        for (Integer i = 1; i <= 2; i++) { // Insert 2 contacts
            testContacts1.add(new Contact(AccountId = testAccount1.Id, LastName = 'Contact1' + i));
        } 
        insert testContacts1;
        
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
   
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 4; i++) {
            testContacts.add(new Contact(AccountId = testAccount.Id, LastName = 'Contact' + i));
        }
       Test.startTest();
       Database.SaveResult[] results = Database.insert(testContacts, false); // Use the second parameter to allow partial success
      Test.stopTest();

       // Check that no errors occurred during the insert operation
      for (Database.SaveResult result : results) {
    System.assert(result.isSuccess(), 'Contact insert failed with errors.');
         }
        // Verify that 4 contacts have been successfully inserted.
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(4, contactCount, 'Incorrect number of contacts inserted.');
    }

    @isTest
    static void testInsertExceedLimit() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 7; i++) { // Insert 7 contacts
            testContacts.add(new Contact(AccountId = testAccount.Id, LastName = 'Contact' + i));
        }
      Test.startTest();
Database.SaveResult[] results = Database.insert(testContacts, false); // Use the second parameter to allow partial success
Test.stopTest();

// Verify that only 5 contacts were inserted successfully.
Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :testAccount.Id];
System.assertEquals(5, contactCount, 'Incorrect number of contacts inserted.');
    }

    @isTest
    static void testUpdateWithinLimit() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 5; i++) {
            testContacts.add(new Contact(AccountId = testAccount.Id, LastName = 'Contact' + i));
        }
        insert testContacts;

        Contact contactToUpdate = testContacts[0];
        contactToUpdate.LastName = 'UpdatedContact';
        Test.startTest();
        update contactToUpdate;
        Test.stopTest();

        // Verify that the contact has been successfully updated.
        Contact updatedContact = [SELECT LastName FROM Contact WHERE Id = :contactToUpdate.Id];
        System.assertEquals('UpdatedContact', updatedContact.LastName, 'Contact was not updated.');
    }

    @isTest
    static void testUpdateExceedLimit() {
        Account account1 = new Account(Name = 'Account 1');
        Account account2 = new Account(Name = 'Account 2');
        insert new List<Account>{ account1, account2 };

        List<Contact> testContacts1 = new List<Contact>();
        testContacts1.add(new Contact(AccountId = account1.Id, LastName = 'Contact' + 0));
        for (Integer i = 1; i <= 5; i++) {
            testContacts1.add(new Contact(AccountId = account1.Id, LastName = 'Contact' + i));
        }
        testContacts1.add(new Contact(AccountId = account1.Id, LastName = 'Contact' + 6));
 
        insert testContacts1;

        List<Contact> testContacts2 = new List<Contact>();
        testContacts2.add(new Contact(Id=testContacts1[0].Id, AccountId = account2.Id, LastName = 'UpdatedContact' + 0));
        for (Integer i = 1; i <= 5; i++) { 
            Contact con =testContacts1[i-1];
            con.AccountId = account2.Id;
            con.LastName = 'UpdatedContact' + i;
            testContacts2.add(con);
        }
     testContacts2.add(new Contact(Id=testContacts1[6].Id, AccountId = account2.Id, LastName = 'UpdatedContact' + 6));
        
       Test.startTest();
      Database.SaveResult[] results = Database.update(testContacts2, false); // Use the second parameter to allow partial success
       Test.stopTest();


        // Verify that only 5 contacts were updated successfully.
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :account2.Id];
        System.assertEquals(5, contactCount, 'Incorrect number of contacts updated.');
        
        // Verify that the other 2 contacts were not updated.
        for (Integer i = 5; i <= 6; i++) {
            Contact contactNotUpdated = [SELECT LastName FROM Contact WHERE Id = :testContacts2[i].Id];
            System.assertNotEquals('UpdatedContact' + i, contactNotUpdated.LastName, 'Contact should not have been updated.');
        }
    }

  
}