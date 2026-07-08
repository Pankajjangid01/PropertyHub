public with sharing class OpportunityContactRoleTriggerHandler {

    public static void handleAfterInsertUpdate(List<OpportunityContactRole> newRecords) {
        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityContactRole ocr : newRecords) {
            if (ocr.IsPrimary == true && ocr.OpportunityId != null) {
                opportunityIds.add(ocr.OpportunityId);
            }
        }

        if (opportunityIds.isEmpty()) {
            return;
        }

        OpportunityPortalContactService.setPortalContact(opportunityIds);
    }
}