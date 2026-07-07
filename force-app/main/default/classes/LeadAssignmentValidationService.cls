public without sharing class LeadAssignmentValidationService {
    public static void checkUniqueSequence(List<Lead_Assignment__c> triggeredRecords) {

        // Only active records need unique sequence checking
        List<Lead_Assignment__c> activeTriggeredRecords = new List<Lead_Assignment__c>();
        for (Lead_Assignment__c rec : triggeredRecords) {
            if (rec.Active__c == true && rec.Sequence__c != null) {
                activeTriggeredRecords.add(rec);
            }
        }

        if (activeTriggeredRecords.isEmpty()) {
            return;
        }

        Set<Id> triggeredIds = new Set<Id>();
        for (Lead_Assignment__c rec : activeTriggeredRecords) {
            if (rec.Id != null) {
                triggeredIds.add(rec.Id);
            }
        }

        List<Lead_Assignment__c> existingActiveRecords = [
            SELECT Id, Sequence__c
            FROM Lead_Assignment__c
            WHERE Active__c = true AND Id NOT IN :triggeredIds
        ];

        Map<Decimal, Integer> sequenceCountMap = new Map<Decimal, Integer>();
        for (Lead_Assignment__c rec : existingActiveRecords) {
            if (rec.Sequence__c != null) {
                Integer count = sequenceCountMap.containsKey(rec.Sequence__c) ? sequenceCountMap.get(rec.Sequence__c) : 0;
                sequenceCountMap.put(rec.Sequence__c, count + 1);
            }
        }

        Map<Decimal, Integer> batchSequenceCountMap = new Map<Decimal, Integer>();
        for (Lead_Assignment__c rec : activeTriggeredRecords) {
            Integer count = batchSequenceCountMap.containsKey(rec.Sequence__c) ? batchSequenceCountMap.get(rec.Sequence__c) : 0;
            batchSequenceCountMap.put(rec.Sequence__c, count + 1);
        }

        for (Lead_Assignment__c rec : activeTriggeredRecords) {
            Boolean clashesWithExisting = sequenceCountMap.containsKey(rec.Sequence__c);
            Boolean clashesWithinBatch = batchSequenceCountMap.get(rec.Sequence__c) > 1;

            if (clashesWithExisting || clashesWithinBatch) {
                rec.addError('An active agent with Sequence ' + rec.Sequence__c + ' already exists. Each active agent must have a unique sequence number.');
            }
        }
    }

    public static void checkUniqueAgent(List<Lead_Assignment__c> triggeredRecords) {
        List<Lead_Assignment__c> recordsWithAgent = new List<Lead_Assignment__c>();
        for (Lead_Assignment__c rec : triggeredRecords) {
            if (rec.Agent__c != null) {
                recordsWithAgent.add(rec);
            }
        }

        if (recordsWithAgent.isEmpty()) {
            return;
        }

        Set<Id> triggeredIds = new Set<Id>();
        for (Lead_Assignment__c rec : recordsWithAgent) {
            if (rec.Id != null) {
                triggeredIds.add(rec.Id);
            }
        }

        Set<Id> agentIds = new Set<Id>();
        for (Lead_Assignment__c rec : recordsWithAgent) {
            agentIds.add(rec.Agent__c);
        }

        List<Lead_Assignment__c> existingRecords = [
            SELECT Id, Agent__c
            FROM Lead_Assignment__c
            WHERE Agent__c IN :agentIds AND Id NOT IN :triggeredIds
        ];

        Set<Id> existingAgentIds = new Set<Id>();
        for (Lead_Assignment__c rec : existingRecords) {
            existingAgentIds.add(rec.Agent__c);
        }

        Map<Id, Integer> batchAgentCountMap = new Map<Id, Integer>();
        for (Lead_Assignment__c rec : recordsWithAgent) {
            Integer count = batchAgentCountMap.containsKey(rec.Agent__c) ? batchAgentCountMap.get(rec.Agent__c) : 0;
            batchAgentCountMap.put(rec.Agent__c, count + 1);
        }

        for (Lead_Assignment__c rec : recordsWithAgent) {
            Boolean clashesWithExisting = existingAgentIds.contains(rec.Agent__c);
            Boolean clashesWithinBatch = batchAgentCountMap.get(rec.Agent__c) > 1;

            if (clashesWithExisting || clashesWithinBatch) {
                rec.addError('This Agent already has a Lead Assignment record. Each agent can only have one entry.');
            }
        }
    }
}