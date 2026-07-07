public without sharing class RoundRobinAssignmentService {

    public static void assignAgentsRoundRobin(List<Lead> newLeads) {

        // Only apply round-robin to auto-generated leads; manually-created leads
        // (Phone Inquiry, Partner Referral) stay with the agent who created them.
        Set<String> roundRobinEligibleSources = new Set<String>{ 'Web', 'Purchased List' };

        List<Lead> leadsForRoundRobin = new List<Lead>();
        for (Lead newLead : newLeads) {
            if (roundRobinEligibleSources.contains(newLead.LeadSource)) {
                leadsForRoundRobin.add(newLead);
            }
            // else: leave OwnerId untouched — defaults to the running user (whoever created it)
        }

        if (leadsForRoundRobin.isEmpty()) {
            return;
        }

        // ---- rest of the method same rahega, bas 'newLeads' ki jagah 'leadsForRoundRobin' use hoga ----

        List<Lead_Assignment__c> activeAgents = [
            SELECT Agent__c, Sequence__c
            FROM Lead_Assignment__c
            WHERE Active__c = true
            ORDER BY Sequence__c ASC
        ];

        if (activeAgents.isEmpty()) {
            return;
        }

        List<Round_Robin_Tracker__c> trackers = [
            SELECT Id, Last_Assigned_Index__c
            FROM Round_Robin_Tracker__c
            LIMIT 1
        ];

        if (trackers.isEmpty()) {
            return;
        }

        Round_Robin_Tracker__c tracker = trackers[0];
        Integer currentIndex = (tracker.Last_Assigned_Index__c != null)
            ? (Integer) tracker.Last_Assigned_Index__c
            : -1;

        Integer totalAgents = activeAgents.size();

        for (Lead newLead : leadsForRoundRobin) {
            currentIndex = Math.mod(currentIndex + 1, totalAgents);
            Lead_Assignment__c assignedAgent = activeAgents[currentIndex];
            newLead.OwnerId = assignedAgent.Agent__c;
        }

        tracker.Last_Assigned_Index__c = currentIndex;
        update tracker;
    }
}