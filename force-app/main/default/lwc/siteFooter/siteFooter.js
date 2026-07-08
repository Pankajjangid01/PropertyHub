import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';

export default class SiteFooter extends NavigationMixin(LightningElement) {
    @api showContactButton = false;
    @api brandName = 'PropertyHub';
    @api tagline = 'Your trusted partner in real estate';

    isGuestUser = isGuest;

    get shouldShowContact() {
        return this.isGuestUser;
    }

    handleContactClick() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Contact_Us__c'
            }
        });
    }
}