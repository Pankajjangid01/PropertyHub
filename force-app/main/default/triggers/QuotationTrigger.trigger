trigger QuotationTrigger on Quotation__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            QuotationTriggerHandler.handleBeforeSave(Trigger.new);
        }
    }
}