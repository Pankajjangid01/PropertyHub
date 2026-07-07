public with sharing class LeadAssignmentTriggerHandler {

    public static void handleBeforeInsert(List<Lead_Assignment__c> newRecords) {
        LeadAssignmentValidationService.checkUniqueSequence(newRecords);
        LeadAssignmentValidationService.checkUniqueAgent(newRecords);
    }

    public static void handleBeforeUpdate(List<Lead_Assignment__c> newRecords) {
        LeadAssignmentValidationService.checkUniqueSequence(newRecords);
        LeadAssignmentValidationService.checkUniqueAgent(newRecords);
    }
}