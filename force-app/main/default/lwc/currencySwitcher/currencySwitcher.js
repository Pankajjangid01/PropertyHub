import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getAvailableCurrencies from '@salesforce/apex/CurrencyDetectionService.getAvailableCurrencies';
import { CurrentPageReference } from 'lightning/navigation';

const STORAGE_KEY = 'preferredCurrency';

export default class CurrencySwitcher extends LightningElement {
    currencies = [];
    selectedCurrency;
    showSwitcher = true;

    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef && pageRef.attributes && pageRef.attributes.name) {
            const pageName = pageRef.attributes.name;
            this.showSwitcher = pageName !== 'Contact_Us__c' && pageName !== 'Login';
        }
    }

    @wire(getAvailableCurrencies)
    wiredCurrencies({ data, error }) {
        if (data) {
            const stored = window.localStorage.getItem(STORAGE_KEY);
            let initialSelected = data.length > 0 ? data[0] : null;
            if (stored && data.includes(stored)) {
                initialSelected = stored;
            }
            this.selectedCurrency = initialSelected;
            this.currencies = data.map((code) => ({
                label: code,
                value: code,
                selected: code === initialSelected
            }));
        } else if (error) {
            console.error('--- [DEBUG currencySwitcher] getAvailableCurrencies error:', JSON.stringify(error));
        }
    }

    handleChange(event) {
        const newCurrency = event.target ? event.target.value : event.detail.value;
        this.selectedCurrency = newCurrency;
        window.localStorage.setItem(STORAGE_KEY, newCurrency);

        publish(this.messageContext, CurrencyChangeChannel, {
            currencyCode: newCurrency
        });
    }
}