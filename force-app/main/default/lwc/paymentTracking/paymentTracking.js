import { LightningElement, wire } from 'lwc';
import getMyPayments from '@salesforce/apex/PaymentPortalController.getMyPayments';

export default class PaymentTracking extends LightningElement {
    payments;
    error;

    @wire(getMyPayments)
    wiredPayments({ data, error }) {
        if (data) {
            this.payments = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.payments = undefined;
        }
    }
}