import { LightningElement, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getMyPayments from '@salesforce/apex/PaymentPortalController.getMyPayments';

const STATUS_CLASS_MAP = {
    Received: 'status-badge status-approved',
    Pending: 'status-badge status-pending',
    Failed: 'status-badge status-rejected'
};

const STORAGE_KEY = 'preferredCurrency';

export default class MyPayments extends NavigationMixin(LightningElement) {
    rawPayments;
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

    @wire(getMyPayments, { preferredCurrency: '$preferredCurrency' })
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
            formattedAmount: this.formatCurrency(p.convertedAmount, p.displayCurrency)
        }));
    }

    get hasPayments() {
        return this.payments && this.payments.length > 0;
    }

    formatCurrency(value, currencyCode) {
        const amount = value === null || value === undefined ? 0 : value;
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: currencyCode || 'USD',
            maximumFractionDigits: 0
        }).format(amount);
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