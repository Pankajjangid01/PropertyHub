trigger LeadAssignmentTrigger on Lead_Assignment__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LeadAssignmentTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            LeadAssignmentTriggerHandler.handleBeforeUpdate(Trigger.new);
        }
    }
}