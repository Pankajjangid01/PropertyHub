import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getAvailableProperties from '@salesforce/apex/PropertyPortalController.getAvailableProperties';

export default class PropertyListing extends NavigationMixin(LightningElement) {
    activeProjectId;
    activeProjectName;
    rawProperties = [];
    error;
    isLoading = true;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        console.log('--- getStateParameters pageRef.state:', pageRef ? JSON.stringify(pageRef.state) : 'null');
        console.log('--- window.location.search:', window.location.search);
        
        if (pageRef) {
            const stateProjectId = pageRef.state ? (pageRef.state.projectId || pageRef.state.c__projectId) : null;
            const stateProjectName = pageRef.state ? (pageRef.state.projectName || pageRef.state.c__projectName) : null;
            
            if (stateProjectId) {
                this.activeProjectId = stateProjectId;
                this.activeProjectName = stateProjectName;
            } else {
                // Fallback to URL search parameters parsing if state keys are not populated
                const urlParams = new URLSearchParams(window.location.search);
                this.activeProjectId = urlParams.get('projectId') || urlParams.get('c__projectId') || null;
                this.activeProjectName = urlParams.get('projectName') || urlParams.get('c__projectName') || null;
            }
        } else {
            this.activeProjectId = null;
            this.activeProjectName = null;
        }
        
        console.log('--- Resolved activeProjectId:', this.activeProjectId);
        console.log('--- Resolved activeProjectName:', this.activeProjectName);
    }

    @wire(getAvailableProperties, { projectId: '$activeProjectId' })
    wiredProperties({ data, error }) {
        console.log('--- wiredProperties called with activeProjectId:', this.activeProjectId);
        console.log('--- wiredProperties data retrieved:', data ? JSON.stringify(data) : 'null', 'error:', error);
        
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
            priceLabel: this.formatCurrency(prop.price)
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
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Properties__c'
            }
        });
    }

    handlePropertyClick(event) {
        const propertyId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Property_Detail__c'
            },
            state: {
                recordId: propertyId
            }
        });
    }

    formatCurrency(amount) {
        if (amount === null || amount === undefined) {
            return 'Price on request';
        }
        return `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(amount)}`;
    }
}