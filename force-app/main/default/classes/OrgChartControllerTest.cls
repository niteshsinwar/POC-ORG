@isTest
private class OrgChartControllerTest {
    
    static testMethod void testHierarchyValues(){
        OrgChartConfigController controller = new OrgChartConfigController();
        
        System.assertEquals(2, controller.hierarchyValues.size());
    }   
    
    static testMethod void testSave(){
        //assert there are no config objects
        List<OrgChartConfig__c> configs = [select orgHierarchyType__c, id from OrgChartConfig__c];
        System.assertEquals(0, configs.size());
        
        OrgChartConfigController controller = new OrgChartConfigController();
        
        OrgChartConfig__c config = controller.orgChartConfig;
        //assert not null
        System.assertNotEquals(null, config);
        //assert default values
        System.assertEquals('Users', config.orgHierarchyType__c);
        
        controller.orgChartConfig.orgHierarchyType__c = 'Contacts';
        controller.save();
        //assert there is 1 config
        configs = [select orgHierarchyType__c, id from OrgChartConfig__c];
        System.assertEquals(1, configs.size());
        //assert the value updated
        System.assertEquals('Contacts', configs[0].orgHierarchyType__c);
    }    
    
    static testMethod void testRetrieve(){
        OrgChartConfig__c config = new OrgChartConfig__c(orgHierarchyType__c = 'Users');
        insert config;
        
        OrgChartConfigController controller = new OrgChartConfigController();
        
        config = controller.orgChartConfig;
        //assert not null
        System.assertNotEquals(null, config);
        //assert values
        System.assertEquals('Users', config.orgHierarchyType__c);
    }
}