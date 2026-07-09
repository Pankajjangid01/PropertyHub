import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

export default class PortalUserProfile extends LightningElement {
    userId = USER_ID;
    isReadOnly = true;
    isSaving = false;
    isLoading = true;

    handleLoad() {
        this.isLoading = false;
    }

    toggleEditMode() {
        this.isReadOnly = !this.isReadOnly;
    }

    handleSubmit(event) {
        event.preventDefault(); // Stop default form submit
        this.isSaving = true;
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess() {
        this.isSaving = false;
        this.isReadOnly = true;
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Profile updated successfully!',
                variant: 'success',
            })
        );
    }

    handleError(event) {
        this.isSaving = false;
        
        const errorMessage = event.detail.detail ? event.detail.detail : 'Failed to update profile. Please ensure all data is valid.';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error updating profile',
                message: errorMessage,
                variant: 'error',
            })
        );
    }
}
