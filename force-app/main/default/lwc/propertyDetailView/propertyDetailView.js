import { LightningElement, api, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import isGuest from '@salesforce/user/isGuest';
import CurrencyChangeChannel from '@salesforce/messageChannel/CurrencyChangeChannel__c';
import getPropertyDetail from '@salesforce/apex/PropertyPortalController.getPropertyDetail';

const STORAGE_KEY = 'preferredCurrency';

export default class PropertyDetailView extends NavigationMixin(LightningElement) {
    @api recordId;
    property;
    error;
    preferredCurrency;
    subscription;

    isGuestUser = isGuest;
    isModalOpen = false;
    selectedImageUrl;

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
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getPropertyDetail, { propertyId: '$recordId', preferredCurrency: '$preferredCurrency' })
    wiredProperty({ data, error }) {
        console.log('--- [DEBUG propertyDetailView] propertyId:', this.recordId);
        console.log('--- [DEBUG propertyDetailView] preferredCurrency:', this.preferredCurrency);
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
        if (!this.property || this.property.convertedPrice === null || this.property.convertedPrice === undefined) {
            return 'Price on request';
        }
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: this.property.displayCurrency || 'USD',
            maximumFractionDigits: 0
        }).format(this.property.convertedPrice);
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