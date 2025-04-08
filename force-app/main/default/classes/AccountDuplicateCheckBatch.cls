public class AccountDuplicateCheckBatch implements Database.Batchable<sObject> {
public List<Account> accountsToProcess;
    public AccountDuplicateCheckBatch(List<Account> accountsToProcess) {
        this.accountsToProcess = accountsToProcess;
    }

  public Database.QueryLocator start(Database.BatchableContext context) {
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        Set<Id> excludedAccIds=new Set<Id>();
        for (Account acc : accountsToProcess) {
            emails.add(acc.Email__c);
            phones.add(acc.Phone);
            if(acc.Id!=null)
            excludedAccIds.add(acc.Id);
        }


        return Database.getQueryLocator([
            SELECT Id, Email__c, Phone
            FROM Account
            WHERE (Email__c IN :emails And Phone IN :phones) And Id Not IN :excludedAccIds
        ]);
    }

   public void execute(Database.BatchableContext context, List<Account> scope) {
        Set<String> emailPhoneCombinations = new Set<String>();

        for (Account acc : scope) {
           if(acc.Email__c != null && acc.Phone != null)
        {
        String key = (acc.Email__c  +  acc.Phone);
            emailPhoneCombinations.add(key);
        }
        }
               
        for (Account acc : accountsToProcess) {
              String key='';
              if(acc.Email__c != null && acc.Phone != null)
               key = (acc.Email__c  +  acc.Phone);

            if (emailPhoneCombinations.contains(key)) {
                acc.addError('An account with the same email and phone number combination already exists in the database.');
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        // Perform any post-processing logic here if needed
    }
}