import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getMyAgreements from '@salesforce/apex/AgreementPortalController.getMyAgreements';
import getAgreementFiles from '@salesforce/apex/AgreementPortalController.getAgreementFiles';

export default class AgreementDetail extends LightningElement {
    @api recordId;
    agreement;
    files;
    error;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getMyAgreements)
    wiredAgreements({ data, error }) {
        if (data && this.recordId) {
            this.agreement = data.find((a) => a.agreementId === this.recordId);
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
        }
    }

    @wire(getAgreementFiles, { agreementId: '$recordId' })
    wiredFiles({ data, error }) {
        if (data) {
            this.files = data;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
        }
    }

    get hasFiles() {
        return this.files && this.files.length > 0;
    }
}