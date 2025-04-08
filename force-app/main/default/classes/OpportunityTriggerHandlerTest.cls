@isTest
private class OpportunityTriggerHandlerTest {
    
    /**
     * @description Set up test data
     */
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Prospect'
            ));
        }
        insert testAccounts;
    }
    
    /**
     * @description Test annual revenue calculation on opportunity insert
     */
    @isTest
    static void testAnnualRevenueCalculationOnInsert() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        
        // Create opportunities
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(
            Name = 'Test Opp 1',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today().addDays(30)
        ));
        opps.add(new Opportunity(
            Name = 'Test Opp 2',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 2000,
            CloseDate = Date.today().addDays(30)
        ));
        
        // Insert opportunities
        Test.startTest();
        insert opps;
        Test.stopTest();
        
        // Verify annual revenue calculation
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(3000, updatedAccount.AnnualRevenue, 'Annual revenue should be the sum of opportunity amounts');
    }
    
    /**
     * @description Test annual revenue calculation on opportunity update
     */
    @isTest
    static void testAnnualRevenueCalculationOnUpdate() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        
        // Create and insert opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // Update opportunity amount
        Test.startTest();
        opp.Amount = 2500;
        update opp;
        Test.stopTest();
        
        // Verify annual revenue calculation
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(2500, updatedAccount.AnnualRevenue, 'Annual revenue should be updated when opportunity amount changes');
    }
    
    /**
     * @description Test annual revenue calculation on opportunity delete
     */
    @isTest
    static void testAnnualRevenueCalculationOnDelete() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        
        // Create and insert opportunities
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(
            Name = 'Test Opp 1',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today().addDays(30)
        ));
        opps.add(new Opportunity(
            Name = 'Test Opp 2',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 2000,
            CloseDate = Date.today().addDays(30)
        ));
        insert opps;
        
        // Delete one opportunity
        Test.startTest();
        delete opps[0];
        Test.stopTest();
        
        // Verify annual revenue calculation
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(2000, updatedAccount.AnnualRevenue, 'Annual revenue should be updated when an opportunity is deleted');
    }
    
    /**
     * @description Test annual revenue calculation on opportunity reassignment
     */
    @isTest
    static void testAnnualRevenueCalculationOnReassignment() {
        // Get test accounts
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name LIKE 'Test Account %' ORDER BY Name LIMIT 2];
        Account account1 = testAccounts[0];
        Account account2 = testAccounts[1];
        
        // Create and insert opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = account1.Id,
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // Reassign opportunity to another account
        Test.startTest();
        opp.AccountId = account2.Id;
        update opp;
        Test.stopTest();
        
        // Verify annual revenue calculation for both accounts
        Account updatedAccount1 = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :account1.Id];
        Account updatedAccount2 = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :account2.Id];
        
        System.assertEquals(0, updatedAccount1.AnnualRevenue, 'Original account should have 0 annual revenue');
        System.assertEquals(1000, updatedAccount2.AnnualRevenue, 'New account should have annual revenue from the opportunity');
    }
    
    /**
     * @description Test account type change to Client when opportunity is Closed Won
     */
    @isTest
    static void testAccountTypeChangeOnClosedWon() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        
        // Create and insert opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today().addDays(30),
            Account_Type__c = 'Prospect'
        );
        insert opp;
        
        // Update opportunity to Closed Won
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();
        
        // Verify account type change
        Account updatedAccount = [SELECT Id, Type FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Client', updatedAccount.Type, 'Account type should be changed to Client');
    }
    
}