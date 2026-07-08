import { LightningElement, wire } from 'lwc';
import getMySiteVisits from '@salesforce/apex/SiteVisitPortalController.getMySiteVisits';

const STATUS_CLASS_MAP = {
    Requested: 'status-badge status-pending',
    Scheduled: 'status-badge status-approved',
    Completed: 'status-badge status-approved',
    Cancelled: 'status-badge status-rejected',
    'No Show': 'status-badge status-rejected'
};

const FILTERS = ['All', 'Requested', 'Scheduled', 'Completed', 'Cancelled'];

export default class MySiteVisits extends LightningElement {
    rawVisits;
    error;
    activeFilter = 'All';

    @wire(getMySiteVisits)
    wiredVisits({ data, error }) {
        if (data) {
            this.rawVisits = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.rawVisits = undefined;
        }
    }

    get filterOptions() {
        return FILTERS.map((f) => ({
            label: f,
            value: f,
            class: f === this.activeFilter ? 'filter-pill filter-pill-active' : 'filter-pill'
        }));
    }

    get allVisits() {
        if (!this.rawVisits) {
            return [];
        }
        return this.rawVisits.map((v) => ({
            ...v,
            statusClass: STATUS_CLASS_MAP[v.visitStatus] || 'status-badge status-default'
        }));
    }

    get visits() {
        if (this.activeFilter === 'All') {
            return this.allVisits;
        }
        return this.allVisits.filter((v) => v.visitStatus === this.activeFilter);
    }

    get hasVisits() {
        return this.visits && this.visits.length > 0;
    }

    handleFilterClick(event) {
        this.activeFilter = event.currentTarget.dataset.value;
    }
}