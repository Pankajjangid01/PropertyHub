trigger SiteVisitTrigger on Site_Visit__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SiteVisitTriggerHandler.setPortalContact(Trigger.new);
            SiteVisitTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            SiteVisitTriggerHandler.setPortalContact(Trigger.new);
            SiteVisitTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            SiteVisitTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            SiteVisitTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}