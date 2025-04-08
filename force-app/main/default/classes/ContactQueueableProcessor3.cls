public class ContactQueueableProcessor3 implements Queueable {
    public void execute(QueueableContext context) {
        // Fetch all contacts with updated description by the second queueable job
          List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Account.Type = 'Prospect'];
        for (Contact contact : contacts) {
            contact.Level__c = 'Secondary';
        }
        update contacts;
    }
}