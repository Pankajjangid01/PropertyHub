public with sharing class SiteVisitPortalController {

    @AuraEnabled
    public static void submitSiteVisitRequest(Id propertyId, String visitDateTime) {

        List<User> currentUserList = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
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

        // Find the Opportunity linked to this Contact via Primary Contact Role
        Id relatedOpportunityId;
        List<OpportunityContactRole> ocrList = [
            SELECT OpportunityId, Opportunity.OwnerId
            FROM OpportunityContactRole
            WHERE ContactId = :currentContactId AND IsPrimary = true
            ORDER BY Opportunity.CreatedDate DESC
            LIMIT 1
        ];

        Id assignedAgentId;
        if (!ocrList.isEmpty()) {
            relatedOpportunityId = ocrList[0].OpportunityId;
            assignedAgentId = ocrList[0].Opportunity.OwnerId; // fallback: Opportunity Owner
        }

        // Prefer Booking Owner if a Booking already exists for this contact (more specific/current agent)
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
        visit.Visit_Status__c = 'Scheduled';

        if (assignedAgentId != null) {
            visit.OwnerId = assignedAgentId;
        }
        
        insert visit;
    }
}