import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyAgreements from '@salesforce/apex/AgreementPortalController.getMyAgreements';

export default class MyAgreements extends NavigationMixin(LightningElement) {
    agreements;
    error;

    @wire(getMyAgreements)
    wiredAgreements({ data, error }) {
        if (data) {
            this.agreements = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.agreements = undefined;
        }
    }

    get hasAgreements() {
        return this.agreements && this.agreements.length > 0;
    }

    handleRowClick(event) {
        const agreementId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Agreement_Detail__c'
            },
            state: {
                recordId: agreementId
            }
        });
    }
}