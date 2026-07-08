import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyQuotations from '@salesforce/apex/QuotationPortalController.getMyQuotations';

export default class MyQuotations extends NavigationMixin(LightningElement) {
    quotations;
    error;

    @wire(getMyQuotations)
    wiredQuotations({ data, error }) {
        if (data) {
            this.quotations = data.map((q) => ({
                ...q,
                formattedTotal: q.totalAmount ? `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(q.totalAmount)}` : 'N/A'
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