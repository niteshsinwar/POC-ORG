public class AccountTriggerHandler {
    private static Boolean isExecuting = false;
 
    public static void handleAccountTrigger(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        
        try {
                updateOpportunitiesOnAccountTypeChange(newAccounts, oldAccountsMap);
        } finally {
            isExecuting = false;
        }
    }
    
    private static void updateOpportunitiesOnAccountTypeChange(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<Id> accountsWithTypeChangeToClient = new Set<Id>();
        
        for (Account acc : newAccounts) {
            if (acc.Type == 'Client' && oldAccountsMap.get(acc.Id).Type != 'Client') {
                accountsWithTypeChangeToClient.add(acc.Id);
            }
        }
        
        // Update related opportunities
        if (!accountsWithTypeChangeToClient.isEmpty()) {
            List<Opportunity> oppsToUpdate = [
                SELECT Id, Account_Type__c 
                FROM Opportunity 
                WHERE AccountId IN :accountsWithTypeChangeToClient
                AND Account_Type__c != 'Client'
            ];
            
            for (Opportunity opp : oppsToUpdate) {
                opp.Account_Type__c = 'Client';
            }
            
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        }
    }
}