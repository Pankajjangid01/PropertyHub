public with sharing class DiscountApprovalService {

    public static void evaluateDiscountApproval(List<Quotation__c> quotations) {

        Decimal thresholdPercentage = getDiscountThreshold();
        if (thresholdPercentage == null) {
            return; // no threshold configured — skip evaluation, avoid bad data
        }

        for (Quotation__c quotation : quotations) {
            if (quotation.Base_Price__c == null || quotation.Base_Price__c == 0) {
                quotation.Requires_Discount_Approval__c = false;
                continue;
            }

            Decimal discountAmount = (quotation.Discount__c != null) ? quotation.Discount__c : 0;
            Decimal discountPercentage = (discountAmount / quotation.Base_Price__c) * 100;

            quotation.Requires_Discount_Approval__c = (discountPercentage > thresholdPercentage);
        }
    }

    private static Decimal getDiscountThreshold() {
        List<Commission_Setting__mdt> settings = [
            SELECT Discount_Threshold_Percentage__c
            FROM Commission_Setting__mdt
            LIMIT 1
        ];
        if (settings.isEmpty()) {
            return null;
        }
        return settings[0].Discount_Threshold_Percentage__c;
    }
}