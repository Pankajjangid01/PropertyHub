public without sharing class AgentCommissionService {

    public static void createCommissionsForAgreements(List<Agreement__c> newAgreements) {
        Set<Id> bookingIds = new Set<Id>();
        for (Agreement__c agreement : newAgreements) {
            if (agreement.Booking__c != null) {
                bookingIds.add(agreement.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) {
            return;
        }

        // Booking -> Owner (Agent) + Quotation Total Amount, in one query
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, OwnerId, Quotation__c, Quotation__r.Total_Amount__c
             FROM Booking__c
             WHERE Id IN :bookingIds]
        );

        Decimal commissionPercentage = getCommissionPercentage();
        if (commissionPercentage == null) {
            return; // no metadata configured — nothing to calculate, avoid bad data
        }

        List<Agent_Commission__c> commissionsToInsert = new List<Agent_Commission__c>();

        for (Agreement__c agreement : newAgreements) {
            Booking__c booking = bookingMap.get(agreement.Booking__c);
            if (booking == null || booking.OwnerId == null || booking.Quotation__r.Total_Amount__c == null) {
                continue;
            }

            Decimal totalAmount = booking.Quotation__r.Total_Amount__c;
            Decimal commissionAmount = (totalAmount * commissionPercentage) / 100;

            commissionsToInsert.add(new Agent_Commission__c(
                Agreement__c = agreement.Id,
                Booking__c = booking.Id,
                Agent__c = booking.OwnerId,
                Commission_Amount__c = commissionAmount,
                Commission_Status__c = 'Pending'
            ));
        }

        if (!commissionsToInsert.isEmpty()) {
            insert commissionsToInsert;
        }
    }

    // Fetches the flat commission percentage from Custom Metadata
    private static Decimal getCommissionPercentage() {
        List<Commission_Setting__mdt> settings = [
            SELECT Commission_Percentage__c
            FROM Commission_Setting__mdt
            LIMIT 1
        ];
        if (settings.isEmpty()) {
            return null;
        }
        return settings[0].Commission_Percentage__c;
    }
}