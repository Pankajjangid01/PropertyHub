import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getMyQuotations from '@salesforce/apex/QuotationPortalController.getMyQuotations';
import getQuotationFiles from '@salesforce/apex/QuotationPortalController.getQuotationFiles';

export default class QuotationDetail extends LightningElement {
    @api recordId;
    quotation;
    files;
    error;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getMyQuotations)
    wiredQuotations({ data, error }) {
        if (data && this.recordId) {
            const found = data.find((q) => q.quotationId === this.recordId);
            if (found) {
                this.quotation = {
                    ...found,
                    formattedTotal: found.totalAmount ? `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(found.totalAmount)}` : 'N/A'
                };
            }
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
        }
    }

    @wire(getQuotationFiles, { quotationId: '$recordId' })
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