public with sharing class OrgChartConfigController {
    //object to talk to the page
    public OrgChartConfig__c orgChartConfig{
        get {
            if (orgChartConfig == null) {
                List<OrgChartConfig__c> configs = [select orgHierarchyType__c, id from OrgChartConfig__c limit 1];
                if (configs.size() == 0) {
                    orgChartConfig = new OrgChartConfig__c();
                    orgChartConfig.orgHierarchyType__c = 'Users';
                } else {
                    orgChartConfig = configs[0];
                }
            }
            return orgChartConfig;
        }
        set;
    }
    
    List<SelectOption> options = new List<SelectOption>();
    public List<SelectOption> hierarchyValues {
        get {
            transient List<SelectOption> options = new List<SelectOption>();
            Schema.DescribeFieldResult fieldResult = OrgChartConfig__c.orgHierarchyType__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
            for( Schema.PicklistEntry f : ple)
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            return options;
        }
    }
    
    //submit button, runs the form validation 
    public void save(){
        upsert orgChartConfig;
    } 
}