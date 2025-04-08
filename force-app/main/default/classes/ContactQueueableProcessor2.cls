public class ContactQueueableProcessor2 implements Queueable {
    public void execute(QueueableContext context) {
        // Fetch all contacts with updated description by the first queueable job
         List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Account.Type = 'Prospect'];
        for (Contact contact : contacts) {
            contact.Description = 'Updated by Queueable Process 2';
        }
        update contacts;
        // Chain the next job
        System.enqueueJob(new ContactQueueableProcessor3());
    }
}