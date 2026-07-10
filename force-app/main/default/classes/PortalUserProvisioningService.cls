public without sharing class PortalUserProvisioningService {

    private static final String PORTAL_PROFILE_NAME = 'PropertyHub Customer Portal User';

    public static void createPortalUsersForApprovedBookings(List<Booking__c> approvedBookings) {

        Set<Id> contactIds = new Set<Id>();
        for (Booking__c booking : approvedBookings) {
            if (booking.Portal_Contact__c != null) {
                contactIds.add(booking.Portal_Contact__c);
            }
        }

        if (contactIds.isEmpty()) {
            return;
        }

        Set<Id> contactsWithExistingUser = new Set<Id>();
        for (User u : [SELECT ContactId FROM User WHERE ContactId IN :contactIds]) {
            contactsWithExistingUser.add(u.ContactId);
        }

        Set<Id> contactsNeedingUser = new Set<Id>();
        for (Id contactId : contactIds) {
            if (!contactsWithExistingUser.contains(contactId)) {
                contactsNeedingUser.add(contactId);
            }
        }

        if (contactsNeedingUser.isEmpty()) {
            return;
        }

        Id portalProfileId = getPortalProfileId();
        if (portalProfileId == null) {
            return;
        }

        // Added MailingCountry (Contact's own address) so we can copy it onto the new User
        Map<Id, Contact> contactsToProvision = new Map<Id, Contact>(
            [SELECT Id, FirstName, LastName, Email, MailingCountry, Account.BillingCountry
             FROM Contact
             WHERE Id IN :contactsNeedingUser AND Email != null]
        );

        List<User> usersToInsert = new List<User>();

        for (Contact con : contactsToProvision.values()) {
            User newUser = new User();
            newUser.ContactId = con.Id;
            newUser.ProfileId = portalProfileId;
            newUser.FirstName = con.FirstName;
            newUser.LastName = con.LastName;
            newUser.Email = con.Email;
            newUser.Username = con.Email + '.propertyhub';
            newUser.Alias = generateAlias(con.FirstName, con.LastName);
            newUser.CommunityNickname = con.Id;
            newUser.TimeZoneSidKey = 'Asia/Kolkata';
            newUser.LocaleSidKey = 'en_IN';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';
            newUser.IsActive = true;

            // Prefer the Contact's own Country; fall back to the Account's Country if Contact's is blank
            newUser.Country = String.isNotBlank(con.MailingCountry)
                ? con.MailingCountry
                : con.Account.BillingCountry;

            usersToInsert.add(newUser);
        }

        if (!usersToInsert.isEmpty()) {
            insert usersToInsert;
        }
    }

    private static Id getPortalProfileId() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :PORTAL_PROFILE_NAME LIMIT 1];
        return profiles.isEmpty() ? null : profiles[0].Id;
    }

    private static String generateAlias(String firstName, String lastName) {
        String rawAlias = (firstName != null ? firstName : '') + (lastName != null ? lastName : '');
        return rawAlias.length() > 8 ? rawAlias.substring(0, 8) : rawAlias;
    }
}