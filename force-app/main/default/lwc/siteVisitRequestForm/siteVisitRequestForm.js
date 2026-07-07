import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import submitSiteVisitRequest from '@salesforce/apex/SiteVisitPortalController.submitSiteVisitRequest';

export default class SiteVisitRequestForm extends LightningElement {
    @api recordId; // property Id, comes from the same page as propertyDetailView
    visitDateTime;
    isSuccess = false;
    error;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    handleDateTimeChange(event) {
        this.visitDateTime = event.target.value;
    }

    handleSubmit() {
        this.error = undefined;

        if (!this.visitDateTime) {
            this.error = 'Please select a preferred date and time.';
            return;
        }

        submitSiteVisitRequest({ propertyId: this.recordId, visitDateTime: this.visitDateTime })
            .then(() => {
                this.isSuccess = true;
            })
            .catch((err) => {
                this.error = err.body ? err.body.message : 'Something went wrong';
            });
    }
}