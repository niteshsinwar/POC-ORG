public class OpportunityTriggerHandler {
    private static Boolean isExecuting = false;
    
   
    public static void handleOpportunityTrigger(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap, 
                                           Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        
        try {
            Set<Id> accountIds = new Set<Id>();
            
            // Collect account IDs that need Annual Revenue recalculation
            if (isInsert || isUpdate) {
                for (Opportunity opp : newOpps) {
                    if (opp.AccountId != null) {
                        accountIds.add(opp.AccountId);
                    }
                    
                    // If this is an update and the AccountId has changed, add the old AccountId too
                    if (isUpdate && oldOppsMap.get(opp.Id).AccountId != opp.AccountId && 
                        oldOppsMap.get(opp.Id).AccountId != null) {
                        accountIds.add(oldOppsMap.get(opp.Id).AccountId);
                    }
                }
            } else if (isDelete) {
                for (Opportunity opp : oldOppsMap.values()) {
                    if (opp.AccountId != null) {
                        accountIds.add(opp.AccountId);
                    }
                }
            }
            
            // Update account annual revenue and check for status change
            if (!accountIds.isEmpty()) {
                updateAccountAnnualRevenue(accountIds);
                updateAccountTypeForClosedWonOpps(accountIds);
            }
        } finally {
            isExecuting = false;
        }
    }
    
    private static void updateAccountAnnualRevenue(Set<Id> accountIds) {
        // Query accounts with their related opportunities
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>([
            SELECT Id, AnnualRevenue, 
                   (SELECT Id, Amount FROM Opportunities WHERE Amount != null) 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        // Calculate total amount for each account
        for (Account acc : accountsToUpdate.values()) {
            Decimal totalRevenue = 0;
            for (Opportunity opp : acc.Opportunities) {
                if (opp.Amount != null) {
                    totalRevenue += opp.Amount;
                }
            }
            acc.AnnualRevenue = totalRevenue;
        }
        
        // Update accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
        }
    }
    
    private static void updateAccountTypeForClosedWonOpps(Set<Id> accountIds) {
        // Find accounts with closed won opportunities
        Set<Id> accountsWithClosedWonOpps = new Set<Id>();
        
        for (AggregateResult ar : [
            SELECT AccountId 
            FROM Opportunity 
            WHERE AccountId IN :accountIds 
            AND StageName = 'Closed Won' 
            GROUP BY AccountId
        ]) {
            accountsWithClosedWonOpps.add((Id)ar.get('AccountId'));
        }
        
        if (!accountsWithClosedWonOpps.isEmpty()) {
            List<Account> accountsToUpdate = [
                SELECT Id, Type
                FROM Account
                WHERE Id IN :accountsWithClosedWonOpps
                AND Type != 'Client'
            ];
            
            for (Account acc : accountsToUpdate) {
                acc.Type = 'Client';
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    }
}