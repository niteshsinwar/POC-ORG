
@isTest
private class AccountTriggerHandlerTest {

    
    /**
     * @description Test propagation of Account Type change to related opportunities
     */
    @isTest
    static void testOpportunityTypeUpdateOnAccountTypeChange() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Type Change Test Account',
            Type = 'Prospect'
        );
        insert testAccount;
        
        // Create and insert opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            opps.add(new Opportunity(
                Name = 'Type Change Test Opp ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                Amount = 1000 * (i + 1),
                CloseDate = Date.today().addDays(30),
                Account_Type__c = 'Prospect'
            ));
        }
        insert opps;
        
        // Update account type directly
        Test.startTest();
        testAccount.Type = 'Client';
        update testAccount;
        Test.stopTest();
        
        // Verify opportunities have been updated
        List<Opportunity> updatedOpps = [SELECT Id, Account_Type__c FROM Opportunity WHERE AccountId = :testAccount.Id];
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Client', opp.Account_Type__c, 'Opportunity account type should be updated to match Account');
        }
    }
    
    
}