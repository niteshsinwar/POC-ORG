import { LightningElement, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/ObjectSelectorController.getRecords';
import getAllObjectNames from '@salesforce/apex/ObjectSelectorController.getAllObjectNames';

export default class ObjectSelector extends LightningElement {
    // Track the current step: 1 (object selection), 2 (record selection for update), 3 (record form)
    @track currentStep = 1;
    @track isCreate = true; // True: create; false: update
    @track selectedRecordId = '';
    @track recordOptions = [];
    @track objectOptions = [];
    @track selectedObject = '';
    
    // Compute access type for fetching objects based on checkbox selection
    get accessType() {
        return this.isCreate ? 'create' : 'update';
    }
    
    // Wire to fetch object names filtered by access (create or update)
    @wire(getAllObjectNames, { accessType: '$accessType' })
    wiredObjects({ error, data }) {
        if (data) {
            this.objectOptions = data.map(objName => ({
                label: objName,
                value: objName
            }));
        } else if (error) {
            console.error('Error fetching object names:', error);
        }
    }
    
    // Step check getters for clarity in the template
    get isStep1() {
        return this.currentStep === 1;
    }
    get isStep2() {
        return this.currentStep === 2;
    }
    get isStep3() {
        return this.currentStep === 3;
    }
    
    // Disable Next button on Step 1 until an object is selected
    get isStep1NextDisabled() {
        return this.selectedObject === '';
    }
    
    // Disable Next button on Step 2 until a record is selected
    get isStep2NextDisabled() {
        return this.selectedRecordId === '';
    }
    
    // Handle change for object picklist
    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        // If update mode, fetch records for the newly selected object.
        if (!this.isCreate) {
            this.fetchRecords();
        }
    }
    
    // Handle change for Create Record? checkbox.
    handleCreateChange(event) {
        this.isCreate = event.target.checked;
        // When switching to update mode and if an object is selected, fetch its records.
        if (!this.isCreate && this.selectedObject) {
            this.fetchRecords();
        }
    }
    
    // Handle record selection change
    handleRecordChange(event) {
        this.selectedRecordId = event.detail.value;
    }
    
    // Fetch records for the selected object.
    fetchRecords() {
        getRecords({ objectApiName: this.selectedObject })
            .then(data => {
                this.recordOptions = data.map(record => ({
                    label: record.Name, // Adjust if your object uses a different field as the label.
                    value: record.Id
                }));
            })
            .catch(error => {
                console.error('Error fetching records:', error);
            });
    }
    
    // Next button handler to navigate between steps.
    handleNext() {
        if (this.currentStep === 1) {
            // Step 1: After object selection and checkbox
            if (this.selectedObject) {
                if (this.isCreate) {
                    // If creating, skip record selection and go directly to Step 3.
                    this.currentStep = 3;
                } else {
                    // For update, move to Step 2 (record selection).
                    this.currentStep = 2;
                }
            }
        } else if (this.currentStep === 2) {
            // Step 2: Validate record selection then move to Step 3.
            if (this.selectedRecordId) {
                this.currentStep = 3;
            }
        }
    }
}