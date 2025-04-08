trigger ContactTrigger on Contact (before insert, before update) {
    if (Trigger.isInsert && Trigger.isBefore) {
        handleSync(Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isBefore) {
        handleSync(Trigger.new);
    }

    public static void handleSync(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contact : contacts) {
            accountIds.add(contact.AccountId);
        }
    
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id IN :accountIds]);
    
        for (Contact contact : contacts) {
            if (contact.AccountId != null) {
                Account relatedAccount = accountMap.get(contact.AccountId);
    
                // Check if the contact's mailing address fields are not already the same as the account's billing address fields.
                if (contact.MailingStreet != relatedAccount.BillingStreet ||
                    contact.MailingCity != relatedAccount.BillingCity ||
                    contact.MailingState != relatedAccount.BillingState ||
                    contact.MailingPostalCode != relatedAccount.BillingPostalCode ||
                    contact.MailingCountry != relatedAccount.BillingCountry) {
                    
                    contact.MailingStreet = relatedAccount.BillingStreet;
                    contact.MailingCity = relatedAccount.BillingCity;
                    contact.MailingState = relatedAccount.BillingState;
                    contact.MailingPostalCode = relatedAccount.BillingPostalCode;
                    contact.MailingCountry = relatedAccount.BillingCountry;
                }
            } else {
                // If no account is associated, set the mailing address fields to null.
                contact.MailingStreet = null;
                contact.MailingCity = null;
                contact.MailingState = null;
                contact.MailingPostalCode = null;
                contact.MailingCountry = null;
            }
        }
    }
    
}