trigger AccountTrigger on Account (after update) {

    
    List<Account> updatedAccounts = new List<Account>();

    for (Account acc : Trigger.new) {
        Account oldAcc = Trigger.oldMap.get(acc.Id);
        
        // Check if the field value changed to 'Prospect'
        if (acc.Type == 'Prospect' && (oldAcc == null || oldAcc.Type != 'Prospect')) {
            updatedAccounts.add(acc);
        }
    }

    if (!updatedAccounts.isEmpty()) {
        // Call the method to send account data for each updated Account
        for (Account acc : updatedAccounts) {
            AccountPayloadSender.sendAccountDataAsync(acc.Id, 'valid_user', 'password');
        }
    }
}