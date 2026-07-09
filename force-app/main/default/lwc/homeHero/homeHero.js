import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFeaturedProjects from '@salesforce/apex/ProjectShowcaseController.getFeaturedProjects';

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

    @wire(getFeaturedProjects)
    wiredProjects({ data, error }) {
        console.log('--- [DEBUG homeHero] Data payload:', data ? JSON.parse(JSON.stringify(data)) : 'null');
        console.log('--- [DEBUG homeHero] Error payload:', error ? JSON.parse(JSON.stringify(error)) : 'null');
        
        if (data) {
            this.projects = data.map((project) => ({
                ...project,
                propertyCountLabel: `${project.propertyCount || 0} available properties`,
                priceLabel: this.formatPriceRange(project.minPrice, project.maxPrice),
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

    get featuredProjects() {
        return this.projects.slice(0, 6);
    }

    get showProjectEmptyState() {
        return !this.error && !this.hasProjects;
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

    formatPriceRange(minPrice, maxPrice) {
        if (minPrice === null || minPrice === undefined) {
            return 'Price on request';
        }

        if (maxPrice === null || maxPrice === undefined || minPrice === maxPrice) {
            return `Starting at ${this.formatCurrency(minPrice)}`;
        }

        return `${this.formatCurrency(minPrice)} - ${this.formatCurrency(maxPrice)}`;
    }

    formatCurrency(amount) {
        return `Rs. ${new Intl.NumberFormat('en-IN', {
            maximumFractionDigits: 0
        }).format(amount)}`;
    }
}
