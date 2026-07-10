import { LightningElement, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getMyQuotations from '@salesforce/apex/QuotationPortalController.getMyQuotations';

const STORAGE_KEY = 'preferredCurrency';

export default class MyQuotations extends NavigationMixin(LightningElement) {
    quotations;
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

    @wire(getMyQuotations, { preferredCurrency: '$preferredCurrency' })
    wiredQuotations({ data, error }) {
        if (data) {
            this.quotations = data.map((q) => ({
                ...q,
                formattedTotal: q.convertedTotal !== null && q.convertedTotal !== undefined
                    ? new Intl.NumberFormat(LOCALE, {
                          style: 'currency',
                          currency: q.displayCurrency || 'USD',
                          maximumFractionDigits: 0
                      }).format(q.convertedTotal)
                    : 'N/A'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.quotations = undefined;
        }
    }

    get hasQuotations() {
        return this.quotations && this.quotations.length > 0;
    }

    handleRowClick(event) {
        const quotationId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Quotation_Detail__c'
            },
            state: {
                recordId: quotationId
            }
        });
    }
}