trigger OpportunityContactRoleTrigger on OpportunityContactRole (after insert, after update) {
    OpportunityContactRoleTriggerHandler.handleAfterInsertUpdate(Trigger.new);
}