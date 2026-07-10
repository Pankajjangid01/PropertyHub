import { LightningElement, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getMyBookings from '@salesforce/apex/BookingPortalController.getMyBookings';

const STATUS_CLASS_MAP = {
    'Pending Approval': 'status-badge status-pending',
    'Approved': 'status-badge status-approved',
    'Rejected': 'status-badge status-rejected',
    'Cancelled': 'status-badge status-cancelled'
};

const STORAGE_KEY = 'preferredCurrency';

export default class MyBookings extends LightningElement {
    rawBookings;
    error;
    preferredCurrency;
    subscription;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.preferredCurrency = window.localStorage.getItem(STORAGE_KEY) || null;
        this.subscribeToCurrencyChange();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    subscribeToCurrencyChange() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            CurrencyChangeChannel,
            (message) => {
                this.preferredCurrency = message.currencyCode;
            }
        );
    }

    @wire(getMyBookings, { preferredCurrency: '$preferredCurrency' })
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
                formattedTotal: this.formatCurrency(b.convertedTotal, b.displayCurrency),
                formattedPaid: this.formatCurrency(b.convertedPaid, b.displayCurrency),
                formattedBalance: this.formatCurrency(b.convertedBalance, b.displayCurrency),
                progressStyle: `width: ${b.paidPercentage}%`
            };
        });
    }

    get hasBookings() {
        return this.bookings && this.bookings.length > 0;
    }

    formatCurrency(value, currencyCode) {
        const amount = value === null || value === undefined ? 0 : value;
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: currencyCode || 'USD',
            maximumFractionDigits: 0
        }).format(amount);
    }
}