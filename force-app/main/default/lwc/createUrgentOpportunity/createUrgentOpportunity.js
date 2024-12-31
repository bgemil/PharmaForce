import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class CreateUrgentOpportunity extends LightningElement {
    @track opportunityName = '';
    @track stageName = '';
    @track amount = null;
    @track closeDate = null;

    @track stageOptions = []; // Dynamically loaded stage options
    @track error; // To capture errors

    // Fetch metadata about the Opportunity object
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityInfo;

    // Fetch picklist values for the StageName field
    @wire(getPicklistValues, { recordTypeId: '$opportunityInfo.data.defaultRecordTypeId', fieldApiName: STAGE_FIELD })
    wiredStageOptions({ error, data }) {
        if (data) {
            this.stageOptions = data.values; // Populate stageOptions with picklist values
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.error('Error fetching picklist values:', error);
        }
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        console.log(`Field changed: ${field}, Value: ${event.target.value}`);
        this[field] = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSave() {
        // Check for null or undefined values
        // if (!this.opportunityName) {
        //     console.error('Missing opportunityName.');
        //     return;
        // } else if (!this.stageName) {
        //     console.error('Missing stageName.');
        //     return;
        // } else if (!this.amount) {
        //     console.error('Missing amount.');
        //     return;
        // } else if (!this.closeDate) {
        //     console.error('Missing closeDate.');
        //     return;
        // }

        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        let firstInvalidField = null;

        inputs.forEach((input) => {
            // Check if the input is required and empty
            if (!input.value) {
                isValid = false;

                // Show error message for invalid fields
                input.setCustomValidity('This field is required');
                input.reportValidity();

                // Focus on the first invalid field
                if (!firstInvalidField) {
                    firstInvalidField = input;
                }
            } else {
                // Clear any previous error messages
                input.setCustomValidity('');
            }
        });

        // Focus on the first invalid field
        if (!isValid) {
            firstInvalidField.focus();
            return;
        }
    
        const opportunity = {
            Name: this.opportunityName,
            StageName: this.stageName,
            Amount: this.amount,
            CloseDate: this.closeDate,
        };
    
        console.log('Dispatching save event with opportunity:', opportunity);
        this.dispatchEvent(new CustomEvent('save', { detail: opportunity, bubbles: true, composed: true }));
    }
    
}