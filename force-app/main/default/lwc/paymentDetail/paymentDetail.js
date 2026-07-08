import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getMyPayments from '@salesforce/apex/PaymentPortalController.getMyPayments';
import getPaymentFiles from '@salesforce/apex/PaymentPortalController.getPaymentFiles';

export default class PaymentDetail extends LightningElement {
    @api recordId;
    payment;
    files;
    error;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getMyPayments)
    wiredPayments({ data, error }) {
        if (data && this.recordId) {
            const found = data.find((p) => p.paymentId === this.recordId);
            if (found) {
                this.payment = {
                    ...found,
                    formattedAmount: found.amount
                        ? `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(found.amount)}`
                        : 'N/A'
                };
            }
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
        }
    }

    @wire(getPaymentFiles, { paymentId: '$recordId' })
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