import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateFileVisibility from '@salesforce/apex/PropertyPortalController.updateFileVisibility';

export default class PropertyThumbnailUploader extends LightningElement {
    @api recordId;
    isUploading = false;

    get acceptedFormats() {
        return ['.jpg', '.jpeg', '.png'];
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (!uploadedFiles || uploadedFiles.length === 0) {
            return;
        }

        const documentIds = uploadedFiles.map(file => file.documentId);
        this.isUploading = true;

        updateFileVisibility({ documentIds: documentIds, recordId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Thumbnail uploaded and made public successfully!',
                        variant: 'success'
                    })
                );
                // Dispatch event to close the quick action modal
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error setting visibility',
                        message: error.body ? error.body.message : 'Unknown error',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isUploading = false;
            });
    }
}
