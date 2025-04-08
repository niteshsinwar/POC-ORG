trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityTriggerHandler.handleOpportunityTrigger(
                Trigger.new, 
                null, 
                true,
                false,
                false
            );
        } else if (Trigger.isUpdate) {
            OpportunityTriggerHandler.handleOpportunityTrigger(
                Trigger.new, 
                Trigger.oldMap, 
                false,
                true,
                false
            );
        } else if (Trigger.isDelete) {
            OpportunityTriggerHandler.handleOpportunityTrigger(
                null, 
                Trigger.oldMap, 
                false,
                false,
                true
            );
        }
    }
}