trigger SiteVisitTrigger on Site_Visit__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            SiteVisitTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            SiteVisitTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}