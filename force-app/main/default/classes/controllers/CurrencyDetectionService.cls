public with sharing class CurrencyDetectionService {

    private static final String DEFAULT_CURRENCY = 'USD';

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserCurrency() {

        User currentUser = [SELECT Country FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        if (String.isBlank(currentUser.Country)) {
            return DEFAULT_CURRENCY;
        }

        List<Country_Currency_Mapping__mdt> mappings = [
            SELECT Currency_Code__c
            FROM Country_Currency_Mapping__mdt
            WHERE Country_Name__c = :currentUser.Country
            LIMIT 1
        ];

        if (mappings.isEmpty()) {
            return DEFAULT_CURRENCY;
        }

        return mappings[0].Currency_Code__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableCurrencies() {
        Set<String> currencies = new Set<String>();
        for (Country_Currency_Mapping__mdt mapping : [
            SELECT Currency_Code__c FROM Country_Currency_Mapping__mdt
        ]) {
            currencies.add(mapping.Currency_Code__c);
        }
        List<String> result = new List<String>(currencies);
        result.sort();
        return result;
    }
}