import { LightningElement, wire } from 'lwc';
import getAvailableProperties from '@salesforce/apex/PropertyPortalController.getAvailableProperties';

export default class GuestPropertyBrowse extends LightningElement {
    properties;
    error;
    selectedPropertyId;

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

    handleSelectProperty(event) {
        this.selectedPropertyId = event.currentTarget.dataset.id;
    }
}