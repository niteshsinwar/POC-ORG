trigger AccountPostmanTrigger on Account (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Iterate through the inserted Account records
        for (Account acc : Trigger.new) {
            // Call a method to send the Account data to Postman
            PostToPostman.sendAccountToNode(acc.Id, 'valid_user', 'password');
        }
    }
}