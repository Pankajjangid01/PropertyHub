trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityStageTrackingService.setInitialStageDate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            OpportunityStageTrackingService.trackStageChange(Trigger.new, Trigger.oldMap);
        }
    }
}