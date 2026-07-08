public without sharing class OpportunityPortalContactService {

    public static void setPortalContact(Set<Id> opportunityIds) {
        Map<Id, Id> oppToContactMap = new Map<Id, Id>();

        for (OpportunityContactRole ocr : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds AND IsPrimary = true
        ]) {
            oppToContactMap.put(ocr.OpportunityId, ocr.ContactId);
        }

        if (oppToContactMap.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Id oppId : oppToContactMap.keySet()) {
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                Portal_Contact__c = oppToContactMap.get(oppId)
            ));
        }

        update oppsToUpdate;
    }
}