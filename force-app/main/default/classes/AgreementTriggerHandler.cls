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
    }
}