import { LightningElement, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getAvailableProperties from '@salesforce/apex/PropertyPortalController.getAvailableProperties';
import getFeaturedProjects from '@salesforce/apex/ProjectShowcaseController.getFeaturedProjects';

const STORAGE_KEY = 'preferredCurrency';

export default class PropertyListing extends NavigationMixin(LightningElement) {
    activeProjectId;
    activeProjectName;
    preferredCurrency;
    rawProperties = [];
    rawProjectOptions = [];
    error;
    isLoading = true;
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
    getStateParameters(pageRef) {
        if (pageRef) {
            const stateProjectId = pageRef.state ? (pageRef.state.projectId || pageRef.state.c__projectId) : null;
            const stateProjectName = pageRef.state ? (pageRef.state.projectName || pageRef.state.c__projectName) : null;

            if (stateProjectId) {
                this.activeProjectId = stateProjectId;
                this.activeProjectName = stateProjectName;
            } else {
                const urlParams = new URLSearchParams(window.location.search);
                this.activeProjectId = urlParams.get('projectId') || urlParams.get('c__projectId') || null;
                this.activeProjectName = urlParams.get('projectName') || urlParams.get('c__projectName') || null;
            }
        } else {
            this.activeProjectId = null;
            this.activeProjectName = null;
        }
    }

    renderedCallback() {
        const selectEl = this.template.querySelector('.custom-filter-select');
        if (selectEl) {
            const desiredValue = this.activeProjectId || '';
            if (selectEl.value !== desiredValue) {
                selectEl.value = desiredValue;
            }
        }
    }

    @wire(getFeaturedProjects, { preferredCurrency: null })
    wiredProjects({ data, error }) {
        if (data) {
            this.rawProjectOptions = data.map((p) => ({ label: p.projectName, value: p.projectId }));
        }
    }

    get projectOptions() {
        return this.rawProjectOptions.map(opt => ({
            ...opt,
            selected: opt.value === this.activeProjectId
        }));
    }

    @wire(getAvailableProperties, { projectId: '$activeProjectId', preferredCurrency: '$preferredCurrency' })
    wiredProperties({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.rawProperties = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.rawProperties = [];
        }
    }

    get properties() {
        return this.rawProperties.map((prop) => ({
            ...prop,
            priceLabel: this.formatCurrency(prop.convertedPrice, prop.displayCurrency)
        }));
    }

    get hasProperties() {
        return !this.isLoading && this.properties.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && this.properties.length === 0;
    }

    handleClearFilter() {
        this.activeProjectId = null;
        this.activeProjectName = null;
        this.updateUrlState();
    }

    handleProjectChange(event) {
        const val = event.target.value;
        this.activeProjectId = val ? val : null;
        if (val) {
            const selectedOpt = this.rawProjectOptions.find(o => o.value === val);
            this.activeProjectName = selectedOpt ? selectedOpt.label : null;
        } else {
            this.activeProjectName = null;
        }
        this.updateUrlState();
    }

    updateUrlState() {
        // We update URL so refreshing keeps the filter
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Properties__c' },
            state: { 
                projectId: this.activeProjectId || '', 
                projectName: this.activeProjectName || '' 
            }
        }, true);
    }

    handlePropertyClick(event) {
        const propertyId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Property_Detail__c' },
            state: { recordId: propertyId }
        });
    }

    formatCurrency(amount, currencyCode) {
        if (amount === null || amount === undefined) {
            return 'Price on request';
        }
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: currencyCode || 'USD',
            maximumFractionDigits: 0
        }).format(amount);
    }
}