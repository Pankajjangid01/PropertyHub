import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyPayments from '@salesforce/apex/PaymentPortalController.getMyPayments';

const STATUS_CLASS_MAP = {
    Received: 'status-badge status-approved',
    Pending: 'status-badge status-pending',
    Failed: 'status-badge status-rejected'
};

export default class MyPayments extends NavigationMixin(LightningElement) {
    rawPayments;
    error;

    @wire(getMyPayments)
    wiredPayments({ data, error }) {
        if (data) {
            this.rawPayments = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.rawPayments = undefined;
        }
    }

    get payments() {
        if (!this.rawPayments) {
            return [];
        }
        return this.rawPayments.map((p) => ({
            ...p,
            statusClass: STATUS_CLASS_MAP[p.paymentStatus] || 'status-badge status-default',
            formattedAmount: this.formatCurrency(p.amount)
        }));
    }

    get hasPayments() {
        return this.payments && this.payments.length > 0;
    }

    formatCurrency(value) {
        if (value === null || value === undefined) {
            return 'Rs. 0';
        }
        return `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(value)}`;
    }

    handleRowClick(event) {
        const paymentId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Payment_Detail__c'
            },
            state: {
                recordId: paymentId
            }
        });
    }
}
