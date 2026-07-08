public with sharing class OpportunityStageService {

    private static final Map<String, Integer> STAGE_ORDER = new Map<String, Integer>{
        'Prospecting' => 1,
        'Qualification' => 2,
        'Site Visit Scheduled' => 3,
        'Site Visit Completed' => 4,
        'Quotation Sent' => 5,
        'Negotiation/Review' => 6,
        'Quotation Accepted' => 7,
        'Booking Confirmed' => 8,
        'Closed Won' => 9
    };

    public static void advanceStage(Id opportunityId, String newStage) {
        if (opportunityId == null || newStage == null) {
            return;
        }
        advanceStages(new Map<Id, String>{ opportunityId => newStage });
    }

    public static void advanceStages(Map<Id, String> oppIdToNewStage) {
        if (oppIdToNewStage.isEmpty()) {
            return;
        }

        List<Opportunity> currentOpps = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id IN :oppIdToNewStage.keySet()
        ];

        List<Opportunity> toUpdate = new List<Opportunity>();

        for (Opportunity opp : currentOpps) {
            // Never touch a deal that's already closed
            if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
                continue;
            }

            String newStage = oppIdToNewStage.get(opp.Id);
            Integer newOrder = STAGE_ORDER.get(newStage);
            Integer currentOrder = STAGE_ORDER.get(opp.StageName);

            if (newOrder == null) {
                continue; // unrecognized stage name, skip safely
            }

            if (currentOrder == null || newOrder > currentOrder) {
                toUpdate.add(new Opportunity(Id = opp.Id, StageName = newStage));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}