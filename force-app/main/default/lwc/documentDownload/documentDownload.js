import { LightningElement, wire } from 'lwc';
import getMyDocuments from '@salesforce/apex/DocumentPortalController.getMyDocuments';

export default class DocumentDownload extends LightningElement {
    documents;
    error;

    @wire(getMyDocuments)
    wiredDocuments({ data, error }) {
        if (data) {
            this.documents = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.documents = undefined;
        }
    }
}