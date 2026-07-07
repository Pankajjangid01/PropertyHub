trigger AgreementTrigger on Agreement__c (before insert, before update, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AgreementTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AgreementTriggerHandler.handleBeforeUpdate(Trigger.new);
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AgreementTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}