public without sharing class GuestLeadCaptureController {

    @AuraEnabled
    public static void submitEnquiry(
        String salutation,
        String firstName,
        String lastName,
        String phone,
        String email,
        String message
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
        newLead.Company = 'Individual';
        newLead.LeadSource = 'Web';
        newLead.Description = message;


        insert newLead;
    }
}