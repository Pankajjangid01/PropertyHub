public with sharing class QuotationTriggerHandler {
    public static void handleBeforeSave(List<Quotation__c> quotations) {
        DiscountApprovalService.evaluateDiscountApproval(quotations);
        QuotationPortalContactService.setPortalContact(quotations);
    }
}