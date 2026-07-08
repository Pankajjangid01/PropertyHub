public with sharing class QuotationTriggerHandler {
    public static void handleBeforeSave(List<Quotation__c> quotations) {
        DiscountApprovalService.evaluateDiscountApproval(quotations);
        QuotationPortalContactService.setPortalContact(quotations);
        setDefaultExpiryDate(quotations);
    }

    private static void setDefaultExpiryDate(List<Quotation__c> quotations) {
        for (Quotation__c q : quotations) {
            if (q.Expiry_Date__c == null) {
                q.Expiry_Date__c = Date.today().addDays(15);
            }
        }
    }

    public static void handleAfterUpdate(List<Quotation__c> newQuotations, Map<Id, Quotation__c> oldMap) {
        Map<Id, String> oppStageMap = new Map<Id, String>();

        for (Quotation__c q : newQuotations) {
            Quotation__c oldQ = oldMap.get(q.Id);
            if (q.Quotation_Status__c == 'Accepted' &&
                oldQ.Quotation_Status__c != 'Accepted' &&
                q.Opportunity__c != null) {
                oppStageMap.put(q.Opportunity__c, 'Quotation Accepted');
            }
        }

        OpportunityStageService.advanceStages(oppStageMap);
    }
}