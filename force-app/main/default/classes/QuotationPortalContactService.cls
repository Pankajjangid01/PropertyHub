public with sharing class QuotationPortalContactService {

    public static void setPortalContact(List<Quotation__c> quotations) {
        Set<Id> oppIds = new Set<Id>();
        for (Quotation__c q : quotations) {
            if (q.Opportunity__c != null) {
                oppIds.add(q.Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) return;

        Map<Id, Id> oppToContactMap = new Map<Id, Id>();
        for (OpportunityContactRole ocr : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds AND IsPrimary = true
        ]) {
            oppToContactMap.put(ocr.OpportunityId, ocr.ContactId);
        }

        for (Quotation__c q : quotations) {
            if (q.Opportunity__c != null && oppToContactMap.containsKey(q.Opportunity__c)) {
                q.Portal_Contact__c = oppToContactMap.get(q.Opportunity__c);
            }
        }
    }
}