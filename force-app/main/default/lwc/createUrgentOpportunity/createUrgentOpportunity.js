import { LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class CreateUrgentOpportunity extends LightningElement {
    // track de sters
    opportunityName = '';
    stageName = '';
    amount = null;
    closeDate = null;

    stageOptions = []; 
    error; 

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityInfo;

    @wire(getPicklistValues, { recordTypeId: '$opportunityInfo.data.defaultRecordTypeId', fieldApiName: STAGE_FIELD })
    wiredStageOptions({ error, data }) {
        if (data) {
            this.stageOptions = data.values; 
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
            const field = input.dataset.field;

            if (!input.value) {
                isValid = false;
                input.setCustomValidity('This field is required');

                if (!firstInvalidField) {
                    firstInvalidField = input;
                }
            } else {
                input.setCustomValidity('');
                if (field === 'amount') {
                    if (isNaN(input.value)) {
                        isValid = false;
                        input.setCustomValidity('Amount must be a number');
                    } else if (input.value <= 0) {
                        isValid = false;
                        input.setCustomValidity('Amount must be greater than zero');
                    }
                } else if (field === 'closeDate') {
                    if (new Date(input.value) < new Date()) {
                        isValid = false;
                        input.setCustomValidity('Close Date cannot be in the past');
                    }
                }
            }

            input.reportValidity();

            if (!isValid && !firstInvalidField) {
                firstInvalidField = input; 
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