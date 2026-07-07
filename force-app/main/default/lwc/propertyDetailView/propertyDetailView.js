import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getPropertyDetail from '@salesforce/apex/PropertyPortalController.getPropertyDetail';

export default class PropertyDetailView extends LightningElement {
    @api recordId;
    property;
    error;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getPropertyDetail, { propertyId: '$recordId' })
    wiredProperty({ data, error }) {
        if (data) {
            this.property = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.property = undefined;
        }
    }
}