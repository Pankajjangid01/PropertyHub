import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import sendRecordEmail from '@salesforce/apex/RecordEmailController.sendRecordEmail';

export default class RecordSendEmailButton extends LightningElement {
    @api recordId;
    @api objectApiName; // 'Quotation__c' or 'Agreement__c' — set via App Builder property panel
    isSending = false;

    get cardTitle() {
        return this.objectApiName === 'Agreement__c' ? 'Send Agreement to Customer' : 'Send Quotation to Customer';
    }

    get buttonLabel() {
        return this.objectApiName === 'Agreement__c' ? 'Send Agreement Email' : 'Send Quotation Email';
    }

    handleSendEmail() {
        this.isSending = true;

        sendRecordEmail({ recordId: this.recordId, objectType: this.objectApiName })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Email sent to customer.',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new RefreshEvent());
            })
            .catch((error) => {
                const message = error.body ? error.body.message : 'Something went wrong.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isSending = false;
            });
    }
}