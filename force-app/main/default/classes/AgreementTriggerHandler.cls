public with sharing class AgreementTriggerHandler {

    public static void handleBeforeInsert(List<Agreement__c> newAgreements) {
        AgreementValidationService.checkAgreementBookingStatus(newAgreements);
        AgreementPortalContactService.setPortalContact(newAgreements);
    }

    public static void handleBeforeUpdate(List<Agreement__c> updatedAgreements) {
        AgreementPortalContactService.setPortalContact(updatedAgreements);
    }

    public static void handleAfterInsert(List<Agreement__c> newAgreements) {
        AgentCommissionService.createCommissionsForAgreements(newAgreements);
        markBookingAgreementCreated(newAgreements);
        advanceOpportunityToClosedWon(newAgreements);
    }

    private static void advanceOpportunityToClosedWon(List<Agreement__c> agreements) {
        Set<Id> bookingIds = new Set<Id>();
        for (Agreement__c a : agreements) {
            if (a.Booking__c != null) {
                bookingIds.add(a.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) {
            return;
        }

        Map<Id, String> oppStageMap = new Map<Id, String>();
        for (Booking__c b : [
            SELECT Id, Opportunity__c
            FROM Booking__c
            WHERE Id IN :bookingIds AND Opportunity__c != null
        ]) {
            oppStageMap.put(b.Opportunity__c, 'Closed Won');
        }

        OpportunityStageService.advanceStages(oppStageMap);
    }

    private static void markBookingAgreementCreated(List<Agreement__c> agreements) {
        Set<Id> bookingIds = new Set<Id>();
        for (Agreement__c a : agreements) {
            if (a.Booking__c != null) {
                bookingIds.add(a.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) {
            return;
        }

        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Id bId : bookingIds) {
            bookingsToUpdate.add(new Booking__c(Id = bId, Agreement_Created__c = true));
        }

        TriggerControl.skipBookingPortalContactSync = true;
        update bookingsToUpdate;
        TriggerControl.skipBookingPortalContactSync = false;
    }
}