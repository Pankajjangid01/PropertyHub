import { LightningElement, api, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getMyPayments from '@salesforce/apex/PaymentPortalController.getMyPayments';
import getPaymentFiles from '@salesforce/apex/PaymentPortalController.getPaymentFiles';

const STORAGE_KEY = 'preferredCurrency';

export default class PaymentDetail extends LightningElement {
    @api recordId;
    payment;
    files;
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

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getMyPayments, { preferredCurrency: '$preferredCurrency' })
    wiredPayments({ data, error }) {
        if (data && this.recordId) {
            const found = data.find((p) => p.paymentId === this.recordId);
            if (found) {
                this.payment = {
                    ...found,
                    formattedAmount: found.convertedAmount !== null && found.convertedAmount !== undefined
                        ? new Intl.NumberFormat(LOCALE, {
                              style: 'currency',
                              currency: found.displayCurrency || 'USD',
                              maximumFractionDigits: 0
                          }).format(found.convertedAmount)
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