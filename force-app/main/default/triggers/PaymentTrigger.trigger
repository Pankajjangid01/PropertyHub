trigger PaymentTrigger on Payment__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            PaymentTriggerHandler.setPortalContact(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PaymentTriggerHandler.handleAfterInsert(Trigger.new);
        } 
        else if (Trigger.isUpdate) {
            PaymentTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}