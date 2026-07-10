import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import submitEnquiry from '@salesforce/apex/GuestLeadCaptureController.submitEnquiry';
import getAvailableCountries from '@salesforce/apex/GuestLeadCaptureController.getAvailableCountries';

export default class GuestLeadCaptureForm extends LightningElement {

    @api propertyId;

    salutation = '';
    firstName = '';
    lastName = '';
    phone = '';
    email = '';
    country = '';
    message = '';

    isSuccess = false;
    error;
    rawCountries;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.propertyId = pageRef.state.recordId;
        }
    }

    @wire(getAvailableCountries)
    wiredCountries({ data, error }) {
        if (data) {
            this.rawCountries = data;
        } else if (error) {
            this.rawCountries = [];
        }
    }

    get salutationOptions() {
        return [
            { label: 'Mr.', value: 'Mr.' },
            { label: 'Mrs.', value: 'Mrs.' },
            { label: 'Ms.', value: 'Ms.' },
            { label: 'Dr.', value: 'Dr.' }
        ];
    }

    get countryOptions() {
        if (!this.rawCountries) {
            return [];
        }
        return this.rawCountries.map((c) => ({ label: c, value: c }));
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

    handleCountryChange(event) {
        this.country = event.detail.value;
    }

    handleMessageChange(event) {
        this.message = event.detail.value;
    }

    handleSubmit() {
        this.error = '';

        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
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
            country: this.country,
            message: this.message,
            propertyId: this.propertyId
        })
        .then(() => {
            this.isSuccess = true;
        })
        .catch(error => {
            this.error = error.body ? error.body.message : 'Something went wrong.';
        });
    }
}