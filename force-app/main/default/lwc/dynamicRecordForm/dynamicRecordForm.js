import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class DynamicRecordForm extends NavigationMixin(LightningElement) {
    @api objectApiName;  // e.g. Account, Contact, etc.
    @api recordId;       // record Id (if updating; will be null for create)
    @api formMode = 'edit'; // mode: 'edit' to allow saving/updating

    // When record operation is successful, show a toast and navigate to the record detail page.
    handleSuccess(event) {
        const recId = event.detail.id;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully',
                variant: 'success'
            })
        );
        // Navigate to the record's detail page.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }

    // Handle error events.
    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: event.detail.message,
                variant: 'error'
            })
        );
    }
}