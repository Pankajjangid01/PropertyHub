import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAvailableProperties from '@salesforce/apex/PropertyPortalController.getAvailableProperties';

export default class PropertyCatalog extends NavigationMixin(LightningElement) {
    properties;
    error;

    @wire(getAvailableProperties)
    wiredProperties({ data, error }) {
        if (data) {
            this.properties = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.properties = undefined;
        }
    }

    handlePropertyClick(event) {
        const propertyId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Property_Detail__c'
            },
            state: {
                recordId: propertyId
            }
        });
    }
}