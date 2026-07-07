trigger BookingTrigger on Booking__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            BookingTriggerHandler.setPortalContact(Trigger.new);
            BookingTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            BookingTriggerHandler.setPortalContact(Trigger.new);
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            BookingTriggerHandler.handleAfterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            BookingTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}