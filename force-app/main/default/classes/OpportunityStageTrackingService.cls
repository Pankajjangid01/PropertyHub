public with sharing class OpportunityStageTrackingService {

    public static void setInitialStageDate(List<Opportunity> newOpportunities) {
        List<Opportunity> toUpdate = new List<Opportunity>();

        for (Opportunity opp : newOpportunities) {
            toUpdate.add(new Opportunity(
                Id = opp.Id,
                Stage_Changed_Date__c = Date.today()
            ));
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public static void trackStageChange(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        List<Opportunity> toUpdate = new List<Opportunity>();

        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);

            if (opp.StageName != oldOpp.StageName) {
                toUpdate.add(new Opportunity(
                    Id = opp.Id,
                    Stage_Changed_Date__c = Date.today()
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}