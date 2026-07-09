import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';
import getPropertyDetail from '@salesforce/apex/PropertyPortalController.getPropertyDetail';

export default class PropertyDetailView extends NavigationMixin(LightningElement) {
    @api recordId;
    property;
    error;

    isGuestUser = isGuest;
    isModalOpen = false;
    selectedImageUrl;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getPropertyDetail, { propertyId: '$recordId' })
    wiredProperty({ data, error }) {
        console.log('--- [DEBUG propertyDetailView] propertyId:', this.recordId);
        console.log('--- [DEBUG propertyDetailView] Data payload:', data ? JSON.parse(JSON.stringify(data)) : 'null');
        console.log('--- [DEBUG propertyDetailView] Error payload:', error ? JSON.parse(JSON.stringify(error)) : 'null');
        
        if (data) {
            this.property = data;
            this.error = undefined;
            if (data.imageUrls && data.imageUrls.length > 0) {
                this.selectedImageUrl = data.imageUrls[0];
            } else {
                this.selectedImageUrl = undefined;
            }
        } else if (error) {
            this.error = error.body ? error.body.message : 'Something went wrong';
            this.property = undefined;
            this.selectedImageUrl = undefined;
        }
    }

    get activeImageUrl() {
        return this.selectedImageUrl;
    }

    get hasMultipleImages() {
        return this.property && this.property.imageUrls && this.property.imageUrls.length > 1;
    }

    get imageUrls() {
        if (!this.property || !this.property.imageUrls) {
            return [];
        }
        return this.property.imageUrls.map((url) => {
            return {
                url,
                selectedClass: url === this.selectedImageUrl ? 'thumbnail-item active' : 'thumbnail-item'
            };
        });
    }

    get priceLabel() {
        if (!this.property || this.property.price === null || this.property.price === undefined) {
            return 'Price on request';
        }
        return `Rs. ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(this.property.price)}`;
    }

    handleThumbnailClick(event) {
        this.selectedImageUrl = event.currentTarget.dataset.url;
    }

    handleOpenModal() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    handleEnquireNow() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Contact_Us__c'
            },
            state: {
                recordId: this.recordId
            }
        });
    }
}