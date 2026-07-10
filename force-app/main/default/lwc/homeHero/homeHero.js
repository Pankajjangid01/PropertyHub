import { api, LightningElement, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getFeaturedProjects from '@salesforce/apex/ProjectShowcaseController.getFeaturedProjects';

const STORAGE_KEY = 'preferredCurrency';
const FILTERS = ['All', 'Planning', 'Under Construction', 'Ready to Move', 'Completed'];

export default class HomeHero extends NavigationMixin(LightningElement) {
    @api homePageName = 'Home';
    @api propertiesPageName = 'Properties__c';
    @api loginPageName = 'Login';
    @api myBookingsPageName;
    @api myPaymentsPageName;
    @api myDocumentsPageName;
    @api siteVisitPageName;

    projects = [];
    error;
    preferredCurrency;
    subscription;
    activeFilter = 'All';

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

    @wire(getFeaturedProjects, { preferredCurrency: '$preferredCurrency' })
    wiredProjects({ data, error }) {
        console.log('--- [DEBUG homeHero] Data payload:', data ? JSON.parse(JSON.stringify(data)) : 'null');
        console.log('--- [DEBUG homeHero] Error payload:', error ? JSON.parse(JSON.stringify(error)) : 'null');

        if (data) {
            this.projects = data.map((project) => ({
                ...project,
                propertyCountLabel: `${project.propertyCount || 0} available properties`,
                priceLabel: this.formatPriceRange(project.minPrice, project.maxPrice, project.displayCurrency),
                statusLabel: project.projectStatus || 'Open',
                locationLabel: project.location || 'Location to be updated',
                builderLabel: project.builderName || 'Builder information coming soon'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.projects = [];
        }
    }

    get hasProjects() {
        return this.projects && this.projects.length > 0;
    }

    get filterOptions() {
        return FILTERS.map((f) => ({
            label: f,
            value: f,
            class: f === this.activeFilter ? 'active' : ''
        }));
    }

    get featuredProjects() {
        if (!this.projects) return [];
        if (this.activeFilter === 'All') {
            return this.projects;
        }
        return this.projects.filter(p => p.projectStatus === this.activeFilter);
    }

    get showProjectEmptyState() {
        return !this.error && this.featuredProjects.length === 0;
    }

    handleFilterClick(event) {
        this.activeFilter = event.currentTarget.dataset.value;
    }

    handleBrowseClick() {
        this.navigateToPage(this.propertiesPageName);
    }

    handleProjectClick(event) {
        const projectId = event.currentTarget.dataset.id;
        const project = this.projects.find((p) => p.projectId === projectId);
        const projectName = project ? project.projectName : '';
        this.navigateToPage(this.propertiesPageName, { projectId, projectName });
    }

    navigateToPage(pageName, state = {}) {
        if (!pageName) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName
            },
            state
        });
    }

    formatPriceRange(minPrice, maxPrice, currencyCode) {
        if (minPrice === null || minPrice === undefined) {
            return 'Price on request';
        }

        if (maxPrice === null || maxPrice === undefined || minPrice === maxPrice) {
            return `Starting at ${this.formatCurrency(minPrice, currencyCode)}`;
        }

        return `${this.formatCurrency(minPrice, currencyCode)} - ${this.formatCurrency(maxPrice, currencyCode)}`;
    }

    formatCurrency(amount, currencyCode) {
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: currencyCode || 'USD',
            maximumFractionDigits: 0
        }).format(amount);
    }
}