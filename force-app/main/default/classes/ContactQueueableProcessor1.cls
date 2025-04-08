public class ContactQueueableProcessor1 implements Queueable {
    public void execute(QueueableContext context) {
        // Fetch all contacts with account type 'Prospect'
        List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Account.Type = 'Prospect'];
        for (Contact contact : contacts) {
            contact.Description = 'Updated by Queueable Process 1';
        }
        update contacts;
        // Chain the next job
        System.enqueueJob(new ContactQueueableProcessor2());
    }
}