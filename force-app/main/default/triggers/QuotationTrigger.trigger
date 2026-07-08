trigger QuotationTrigger on Quotation__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            QuotationTriggerHandler.handleBeforeSave(Trigger.new);
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            QuotationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}