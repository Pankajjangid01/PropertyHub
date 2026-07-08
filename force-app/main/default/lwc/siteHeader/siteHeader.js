import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';

export default class SiteHeader extends NavigationMixin(LightningElement) {
    @api homePageName = 'Home';
    @api propertiesPageName = 'Properties__c';
    @api loginPageName = 'Login';
    @api myBookingsPageName = 'My_Bookings__c';
    @api myPaymentsPageName = 'My_Payments__c';
    @api myDocumentsPageName = 'My_Documents__c';
    @api myAgreementsPageName = 'My_Agreements__c';
    @api myQuotationsPageName = 'My_Quotations__c';
    @api siteVisitPageName = 'Site_Visit__c';

    isGuestUser = isGuest;

    get navigationItems() {
        const items = [
            { id: 'home', label: 'Home', pageName: this.homePageName },
            { id: 'properties', label: 'Properties', pageName: this.propertiesPageName }
        ];

        if (this.isGuestUser) {
            items.push({ id: 'contact', label: 'Contact Us', pageName: 'contact-us-trigger' });
        } else {
            [
                { id: 'bookings', label: 'Bookings', pageName: this.myBookingsPageName },
                { id: 'quotations', label: 'Quotations', pageName: this.myQuotationsPageName },
                { id: 'payments', label: 'Payments', pageName: this.myPaymentsPageName },
                { id: 'agreements', label: 'Agreements', pageName: this.myAgreementsPageName },
                // { id: 'documents', label: 'Documents', pageName: this.myDocumentsPageName },
                { id: 'site-visit', label: 'Site Visit', pageName: this.siteVisitPageName }
            ].forEach((item) => {
                if (item.pageName) {
                    items.push(item);
                }
            });
        }

        return items;
    }

    handleNavClick(event) {
        const pageName = event.currentTarget.dataset.page;
        if (pageName === 'contact-us-trigger') {
            this.handleContactClick();
        } else {
            this.navigateToPage(pageName);
        }
    }

    handleContactClick() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Contact_Us__c'
            }
        });
    }

    handleLoginClick() {
        this.navigateToPage(this.loginPageName);
    }

    navigateToPage(pageName) {
        if (!pageName) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName
            }
        });
    }
}
