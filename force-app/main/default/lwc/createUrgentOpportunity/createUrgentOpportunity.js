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

    @track stageOptions = []; 
    @track error; 

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
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        let firstInvalidField = null;

        inputs.forEach((input) => {
            if (!input.value) {
                isValid = false;

                input.setCustomValidity('This field is required');
                input.reportValidity();

                if (!firstInvalidField) {
                    firstInvalidField = input;
                }
            } else {
                if (field === 'amount' && isNaN(input.value)) {
                    isValid = false;
                    input.setCustomValidity('Amount must be a number');
                } else if (field === 'amount' && input.value <= 0) {
                    isValid = false;
                    input.setCustomValidity('Amount must be greater than zero');
                } else if (field === 'closeDate' && new Date(input.value) < new Date()) {
                    isValid = false;
                    input.setCustomValidity('Close Date cannot be in the past');
                } else {
                    input.setCustomValidity(''); // Clear any previous errors
                }
            }

            input.reportValidity(); // Display error message

            if (!isValid && !firstInvalidField) {
                firstInvalidField = input; // Capture the first invalid field
            }
        });

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