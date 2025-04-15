trigger AccountTrigger on Account (before insert, after update) {
  if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAccountTrigger(
            Trigger.new, 
            Trigger.oldMaps
        );
    }
}
