import { LightningElement, api } from 'lwc';
import submitEnquiry from '@salesforce/apex/GuestLeadCaptureController.submitEnquiry';

export default class GuestLeadCaptureForm extends LightningElement {

    @api propertyId;

    salutation = '';
    firstName = '';
    lastName = '';
    phone = '';
    email = '';
    message = '';

    isSuccess = false;
    error;

    get salutationOptions() {
        return [
            { label: 'Mr.', value: 'Mr.' },
            { label: 'Mrs.', value: 'Mrs.' },
            { label: 'Ms.', value: 'Ms.' },
            { label: 'Dr.', value: 'Dr.' }
        ];
    }

    handleSalutationChange(event) {
        this.salutation = event.detail.value;
    }

    handleFirstNameChange(event) {
        this.firstName = event.detail.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.detail.value;
    }

    handlePhoneChange(event) {
        this.phone = event.detail.value;
    }

    handleEmailChange(event) {
        this.email = event.detail.value;
    }

    handleMessageChange(event) {
        this.message = event.detail.value;
    }

    handleSubmit() {

        this.error = '';

        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            return;
        }

        submitEnquiry({
            salutation: this.salutation,
            firstName: this.firstName,
            lastName: this.lastName,
            phone: this.phone,
            email: this.email,
            message: this.message
        })
        .then(() => {
            this.isSuccess = true;
        })
        .catch(error => {
            this.error = error.body ? error.body.message : 'Something went wrong.';
        });
    }
}