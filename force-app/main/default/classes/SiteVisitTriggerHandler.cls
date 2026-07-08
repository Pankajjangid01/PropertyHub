public with sharing class SiteVisitTriggerHandler {

    public static void handleAfterInsert(List<Site_Visit__c> newVisits) {
        Map<Id, String> oppStageMap = new Map<Id, String>();
        List<Site_Visit__c> scheduledVisits = new List<Site_Visit__c>();
        for (Site_Visit__c visit : newVisits) {
            if (visit.Opportunity__c == null) {
                continue;
            }
            if (visit.Visit_Status__c == 'Scheduled') {
                oppStageMap.put(visit.Opportunity__c, 'Site Visit Scheduled');
                scheduledVisits.add(visit);
            }
            else if (visit.Visit_Status__c == 'Completed') {
                oppStageMap.put(visit.Opportunity__c, 'Site Visit Completed');
            }
        }

        if (!oppStageMap.isEmpty()) {
            OpportunityStageService.advanceStages(oppStageMap);
        }
        if (!scheduledVisits.isEmpty()) {
            SiteVisitEmailService.sendVisitScheduledEmail(scheduledVisits);
        }
    }

    public static void handleAfterUpdate(List<Site_Visit__c> newVisits,Map<Id, Site_Visit__c> oldMap) {
        Map<Id, String> oppStageMap = new Map<Id, String>();
        List<Site_Visit__c> scheduledVisits = new List<Site_Visit__c>();
        for (Site_Visit__c visit : newVisits) {
            Site_Visit__c oldVisit = oldMap.get(visit.Id);
            if (visit.Opportunity__c != null &&
                visit.Visit_Status__c != oldVisit.Visit_Status__c) {
                if (visit.Visit_Status__c == 'Scheduled') {
                    oppStageMap.put(visit.Opportunity__c, 'Site Visit Scheduled');
                    scheduledVisits.add(visit);
                }
                else if (visit.Visit_Status__c == 'Completed') {
                    oppStageMap.put(visit.Opportunity__c, 'Site Visit Completed');
                }
            }
        }

        if (!oppStageMap.isEmpty()) {
            OpportunityStageService.advanceStages(oppStageMap);
        }

        if (!scheduledVisits.isEmpty()) {
            SiteVisitEmailService.sendVisitScheduledEmail(scheduledVisits);
        }
    }
}