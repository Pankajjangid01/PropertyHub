import { LightningElement, wire } from 'lwc';
import getMyBookings from '@salesforce/apex/BookingPortalController.getMyBookings';

const STATUS_CLASS_MAP = {
    'Pending Approval': 'status-badge status-pending',
    'Approved': 'status-badge status-approved',
    'Rejected': 'status-badge status-rejected',
    'Cancelled': 'status-badge status-cancelled'
};

export default class MyBookings extends LightningElement {
    rawBookings;
    error;

    @wire(getMyBookings)
    wiredBookings({ data, error }) {
        if (data) {
            this.rawBookings = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.rawBookings = undefined;
        }
    }

    get bookings() {
        if (!this.rawBookings) {
            return [];
        }
        return this.rawBookings.map((b) => {
            return {
                ...b,
                statusClass: STATUS_CLASS_MAP[b.bookingStatus] || 'status-badge status-default',
                formattedTotal: this.formatCurrency(b.totalAmount),
                formattedPaid: this.formatCurrency(b.amountPaid),
                formattedBalance: this.formatCurrency(b.balanceDue),
                progressStyle: `width: ${b.paidPercentage}%`
            };
        });
    }

    get hasBookings() {
        return this.bookings && this.bookings.length > 0;
    }

    formatCurrency(value) {
        if (value === null || value === undefined) {
            return 'Rs. 0';
        }
        return `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(value)}`;
    }
}