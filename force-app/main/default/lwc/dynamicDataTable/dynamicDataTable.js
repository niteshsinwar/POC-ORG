import { LightningElement, track, wire } from 'lwc';
import getEditableObjects from '@salesforce/apex/DynamicObjectController.getEditableObjects';
import getRecords from '@salesforce/apex/DynamicObjectController.getRecords';
import upsertRecords from '@salesforce/apex/DynamicObjectController.upsertRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';

export default class DynamicDataTable extends NavigationMixin(LightningElement) {
    @track objectOptions = [];
    @track selectedObject = '';
    @track records = [];
    @track columns = [];
    @track draftValues = [];
    @track fieldMetadata = [];

    @wire(getEditableObjects)
    wiredEditableObjects({ error, data }) {
        if (data) {
            this.objectOptions = data.map(obj => ({ label: obj.name, value: obj.apiName }));
        } else if (error) {
            console.error('Error fetching objects:', error);
            this.showToast('Error', this.parseError(error), 'error');
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.records = [];
        this.columns = [];
        this.fetchRecords();
    }

    fetchRecords() {
        getRecords({ objectApiName: this.selectedObject })
            .then(result => {
                this.records = result.records || [];
                this.fieldMetadata = result.fieldMetadata || [];
                this.generateColumns();
                console.log(result.records);
            })
            .catch(error => {
                console.error('Error fetching records:', error);
                this.showToast('Error', this.parseError(error), 'error');
            });
    }

    generateColumns() {
        // Create basic field columns
        const fieldColumns = this.fieldMetadata
            .map(meta => ({
                label: meta.label,
                fieldName: meta.fieldName,
                editable: meta.isCreateable || meta.isUpdateable,
                type: this.getColumnType(meta.type),
                cellAttributes: { alignment: meta.type === 'CURRENCY' ? 'right' : 'left' }
            }));

        // Add action column with view and delete buttons
        const actions = [
            { label: 'View', name: 'view', iconName: 'utility:preview' },
            { label: 'Delete', name: 'delete', iconName: 'utility:delete' }
        ];

        const actionColumn = {
            type: 'action',
            typeAttributes: { rowActions: actions }
        };

        this.columns = [...fieldColumns, actionColumn];
    }

    getColumnType(fieldType) {
        const typeMap = {
            'DATE': 'date',
            'DATETIME': 'datetime',
            'BOOLEAN': 'boolean',
            'CURRENCY': 'currency',
            'DOUBLE': 'number',
            'INTEGER': 'number',
            'PERCENT': 'percent',
            'EMAIL': 'email',
            'PHONE': 'phone',
            'URL': 'url',
            'TEXTAREA': 'text'
        };
        return typeMap[fieldType] || 'text';
    }

    handleSave(event) {
        const draftValues = event.detail.draftValues;
        console.log(draftValues);
        // Process the draft values to ensure they have correct ID handling
        const processedData = draftValues.map(draft => {
            const record = {...draft};
            
            // If it's a temp ID (new record), remove the ID so Salesforce generates one
            if (record.Id && record.Id.startsWith('temp-')) {
                delete record.Id;
            }
            
            return record;
        });
         console.log(processedData);
        upsertRecords({ 
            objectApiName: this.selectedObject, 
            recordsData: JSON.parse(JSON.stringify(processedData)) 
        })
        .then(() => {
            this.showToast('Success', 'Records saved successfully', 'success');
            this.draftValues = [];
            this.fetchRecords(); // Refresh data
        })
        .catch(error => {
            console.error('Save error:', error);
            this.showToast('Error', this.parseError(error), 'error');
        });
    }

    handleAddRow() {
        const newRow = { Id: `temp-${Date.now() + Math.random()}` };
        this.fieldMetadata.forEach(meta => {
            if (meta.isCreateable) newRow[meta.fieldName] = null;
        });
        this.records = [...this.records, newRow];
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.navigateToRecord(row.Id);
                break;
            case 'delete':
                this.handleDeleteRow(row);
                break;
            default:
        }
    }

    navigateToRecord(recordId) {
        // Only navigate if it's a real record ID (not a temp ID)
        if (recordId && !recordId.startsWith('temp-')) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: this.selectedObject,
                    actionName: 'view'
                }
            });
        } else {
            this.showToast('Info', 'This record has not been saved yet', 'info');
        }
    }

 handleDeleteRow(row) {
    // For temporary rows (not yet saved)
    if (row.Id && row.Id.startsWith('temp-')) {
        this.records = this.records.filter(record => record.Id !== row.Id);
        this.showToast('Success', 'Row removed', 'success');
    } 
    // For existing Salesforce records
    else if (row.Id) {
        deleteRecord(row.Id)
            .then(() => {
                // IMMEDIATELY REMOVE THE ROW FROM UI
                this.records = this.records.filter(record => record.Id !== row.Id);
                this.showToast('Success', 'Record deleted successfully', 'success');
            })
            .catch(error => {
                console.error('Delete error:', error);
                this.showToast('Error', this.parseError(error), 'error');
            });
    }
}

    parseError(error) {
        return error.body?.message || error.body?.pageErrors?.[0]?.message || error.message || 'Unknown error';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}