public without sharing class SiteVisitPortalController {

    public class SiteVisitWrapper {
        @AuraEnabled public Id visitId;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String visitDate;
        @AuraEnabled public String visitStatus;
    }

    @AuraEnabled(cacheable=true)
    public static List<SiteVisitWrapper> getMySiteVisits() {

        Id currentContactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<SiteVisitWrapper> result = new List<SiteVisitWrapper>();
        if (currentContactId == null) {
            return result;
        }

        List<Site_Visit__c> visits = [
            SELECT Id, Visit_Date__c, Visit_Status__c, Property__r.Name
            FROM Site_Visit__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY Visit_Date__c DESC
        ];

        for (Site_Visit__c v : visits) {
            SiteVisitWrapper sw = new SiteVisitWrapper();
            sw.visitId = v.Id;
            sw.propertyName = v.Property__r != null ? v.Property__r.Name : null;
            sw.visitDate = v.Visit_Date__c != null ? v.Visit_Date__c.format() : null;
            sw.visitStatus = v.Visit_Status__c;
            result.add(sw);
        }

        return result;
    }

    @AuraEnabled
    public static void submitSiteVisitRequest(Id propertyId, String visitDateTime) {

        List<User> currentUserList = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        if (currentUserList.isEmpty() || currentUserList[0].ContactId == null) {
            throw new AuraHandledException('Unable to identify the logged-in customer.');
        }

        Id currentContactId = currentUserList[0].ContactId;
        DateTime parsedVisitDateTime;
        try {
            String normalized = visitDateTime.replace('T', ' ');
            if (normalized.length() == 16) {
                normalized += ':00';
            }
            parsedVisitDateTime = DateTime.valueOf(normalized);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date/time format: ' + visitDateTime);
        }

        Id relatedOpportunityId;
        Id assignedAgentId;
        List<OpportunityContactRole> ocrList = [
            SELECT OpportunityId, Opportunity.OwnerId
            FROM OpportunityContactRole
            WHERE ContactId = :currentContactId AND IsPrimary = true
            ORDER BY Opportunity.CreatedDate DESC
            LIMIT 1
        ];

        if (!ocrList.isEmpty()) {
            relatedOpportunityId = ocrList[0].OpportunityId;
            assignedAgentId = ocrList[0].Opportunity.OwnerId;
        }

        List<Booking__c> existingBookings = [
            SELECT OwnerId
            FROM Booking__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!existingBookings.isEmpty()) {
            assignedAgentId = existingBookings[0].OwnerId;
        }

        Site_Visit__c visit = new Site_Visit__c();
        visit.Property__c = propertyId;
        visit.Portal_Contact__c = currentContactId;
        visit.Opportunity__c = relatedOpportunityId;
        visit.Visit_Date__c = parsedVisitDateTime;
        visit.Visit_Status__c = 'Requested';

        if (assignedAgentId != null) {
            visit.OwnerId = assignedAgentId;
        }

        insert visit;
    }
}
