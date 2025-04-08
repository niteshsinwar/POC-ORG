public class ContactProcessor {
    public void processBatchContacts() {
        // Call the batch class
        Database.executeBatch(new ContactBatchProcessor(), 200);
    }
    
    public void processQueueableContacts() {
        // Enqueue the first queueable job
        System.enqueueJob(new ContactQueueableProcessor1());
    }
    
    @future
    public static void processFutureContacts() {
        // Fetch all contacts with related account type 'Technology Partner'
        List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Account.Type = 'Technology Partner'];
        for (Contact contact : contacts) {
            contact.Description = 'Updated by Future Method';
        }
        update contacts;
    }
}