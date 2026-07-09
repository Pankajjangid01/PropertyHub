public with sharing class SiteVisitTriggerHandler {

    public static void handleBeforeInsert(List<Site_Visit__c> newVisits) {
        for (Site_Visit__c visit : newVisits) {
            if (visit.Visit_Outcome__c == 'Not Interested' || visit.Visit_Outcome__c == 'Not Intrested') {
                visit.Visit_Status__c = 'Completed';
            }
        }
    }

    public static void handleBeforeUpdate(List<Site_Visit__c> newVisits, Map<Id, Site_Visit__c> oldMap) {
        for (Site_Visit__c visit : newVisits) {
            Site_Visit__c oldVisit = oldMap.get(visit.Id);
            if ((visit.Visit_Outcome__c == 'Not Interested' || visit.Visit_Outcome__c == 'Not Intrested') && oldVisit.Visit_Outcome__c != visit.Visit_Outcome__c) {
                visit.Visit_Status__c = 'Completed';
            }
        }
    }

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
                if (visit.Visit_Outcome__c == 'Not Interested' || visit.Visit_Outcome__c == 'Not Intrested') {
                    oppStageMap.put(visit.Opportunity__c, 'Closed Lost');
                } else {
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
                    if (visit.Visit_Outcome__c == 'Not Interested' || visit.Visit_Outcome__c == 'Not Intrested') {
                        oppStageMap.put(visit.Opportunity__c, 'Closed Lost');
                    } else {
                        oppStageMap.put(visit.Opportunity__c, 'Site Visit Completed');
                    }
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

    public static void setPortalContact(List<Site_Visit__c> visits) {
        Set<Id> oppIds = new Set<Id>();
        for (Site_Visit__c v : visits) {
            if (v.Portal_Contact__c == null && v.Opportunity__c != null) {
                oppIds.add(v.Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) return;

        Map<Id, Id> oppToContactMap = new Map<Id, Id>();

        List<OpportunityContactRole> ocrList = [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds AND IsPrimary = true
        ];

        for (OpportunityContactRole ocr : ocrList) {
            oppToContactMap.put(ocr.OpportunityId, ocr.ContactId);
        }

        for (Site_Visit__c v : visits) {
            if (v.Portal_Contact__c == null && v.Opportunity__c != null && oppToContactMap.containsKey(v.Opportunity__c)) {
                v.Portal_Contact__c = oppToContactMap.get(v.Opportunity__c);
            }
        }
    }
}