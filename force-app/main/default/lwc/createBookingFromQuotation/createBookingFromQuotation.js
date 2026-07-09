import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getQuotationPrefillData from '@salesforce/apex/BookingPrefillController.getQuotationPrefillData';

export default class CreateBookingFromQuotation extends NavigationMixin(LightningElement) {
    @api recordId;
    prefillData;

    @wire(getQuotationPrefillData, { quotationId: '$recordId' })
    wiredPrefillData({ data }) {
        if (data) {
            this.prefillData = data;
        }
    }

    get showButton() {
        return this.prefillData && this.prefillData.quotationStatus === 'Accepted' && !this.prefillData.hasBooking;
    }

    get showIneligibleMessage() {
        return this.prefillData && this.prefillData.quotationStatus !== 'Accepted';
    }

    get showBookingCreatedMessage() {
        return this.prefillData && this.prefillData.hasBooking;
    }

    get bookingName() {
        return this.prefillData ? this.prefillData.bookingName : '';
    }

    get bookingUrl() {
        return this.prefillData ? `/${this.prefillData.bookingId}` : '#';
    }

    handleCreateBooking() {
        const today = new Date().toISOString().split('T')[0];

        const defaultValues = encodeDefaultFieldValues({
            Opportunity__c: this.prefillData.opportunityId,
            Property__c: this.prefillData.propertyId,
            Quotation__c: this.recordId,
            Booking_Date__c: today
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Booking__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }
}