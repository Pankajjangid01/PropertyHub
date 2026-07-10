public without sharing class GuestLeadCaptureController {

    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableCountries() {
        List<String> countries = new List<String>();
        for (Country_Currency_Mapping__mdt mapping : [
            SELECT Country_Name__c FROM Country_Currency_Mapping__mdt ORDER BY Country_Name__c ASC
        ]) {
            countries.add(mapping.Country_Name__c);
        }
        return countries;
    }

    @AuraEnabled
    public static void submitEnquiry(
        String salutation,
        String firstName,
        String lastName,
        String phone,
        String email,
        String country,
        String message,
        Id propertyId
    ) {

        if (String.isBlank(lastName) || String.isBlank(phone)) {
            throw new AuraHandledException('Last Name and Phone are required.');
        }

        Lead newLead = new Lead();

        newLead.Salutation = salutation;
        newLead.FirstName = firstName;
        newLead.LastName = lastName;
        newLead.Phone = phone;
        newLead.Email = email;
        newLead.Country = country;
        newLead.Company = 'Individual';
        newLead.LeadSource = 'Web';
        newLead.Description = message;

        if (propertyId != null) {
            newLead.Property_Interest__c = propertyId;
        }

        insert newLead;
    }
}