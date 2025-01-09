import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchUrgentOpportunities from '@salesforce/apex/UrgentOpportunitiesController.fetchUrgentOpportunities';
import fetchTotalRecordCount from '@salesforce/apex/UrgentOpportunitiesController.fetchTotalRecordCount';
import saveNewOpportunity from '@salesforce/apex/UrgentOpportunitiesController.saveNewOpportunity';

export default class UrgentOpportunitiesTable extends LightningElement {
    @api recordId;
    @track opportunities = [];
    @track totalRecords = 0;
    @track isDataReadyForPagination = false;
    searchKey = '';
    offset = 0;
    limitValue = 5;

    columns = [
        { label: 'Opportunity Name', fieldName: 'Name', type: 'text' },
        { label: 'Stage', fieldName: 'StageName', type: 'text' },
        { label: 'Amount', fieldName: 'Amount', type: 'currency' },
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date' },
    ];

    showDebugToast(message) {
        const evt = new ShowToastEvent({
            title: 'Debug',
            message: message,
            variant: 'info'
        });
        this.dispatchEvent(evt);
    }    

    connectedCallback() {
        this.loadOpportunities();
    }    

    loadOpportunities() {
        if(!this.recordId) {
            console.error('Record ID is undefined.');
            this.showToast('Error', 'Record ID is undefined. Please refresh the page.', 'error');
            return;
        }

        fetchUrgentOpportunities({ searchKey: this.searchKey, accountId: this.recordId, offset: this.offset, 
                                    limitValue: this.limitValue })
            .then(result => {
                this.opportunities = result;
            })
            .catch(error => {
                let errorMessage = 'Failed to fetch urgent opportunities.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                console.error('Error fetching urgent opportunities:', errorMessage);
                this.showToast('Error', errorMessage, 'error');
                this.opportunities = [];
            });

        fetchTotalRecordCount({ searchKey: this.searchKey, accountId: this.recordId })
            .then(result => {
                this.totalRecords = result;
                this.isDataReadyForPagination = true;
            })
            .catch(error => {
                let errorMessage = 'Failed to fetch the total record count.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                console.error('Error fetching total record count:', errorMessage);
                this.showToast('Error', errorMessage, 'error');
                this.totalRecords = 0;
                this.isDataReadyForPagination = true;
            });
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.offset = 0;
        this.loadOpportunities();
    }

    // Pagination
    get pageClassMap() {
        if (!this.totalRecords || this.totalRecords <= 0 || !this.limitValue) {
            console.log('pageClassMap returning empty due to missing totalRecords or limitValue');
            return [];
        }
    
        const totalPages = Math.ceil(this.totalRecords / this.limitValue);
        const currentPage = this.currentPage;

        return Array.from({ length: totalPages }, (_, i) => {
            const pageNumber = i + 1;
            return {
                number: pageNumber,
                class: pageNumber === currentPage ? 'active-page' : ''
            };
        });
    } 

    get currentPage() {
        const currentPage = Math.floor(this.offset / this.limitValue) + 1;
        return currentPage;
    }       

    handlePrevious() {
        this.offset = Math.max(this.offset - this.limitValue, 0);
        this.loadOpportunities();
    }

    handleNext() {
        if (this.offset + this.limitValue < this.totalRecords) {
            this.offset += this.limitValue;
            this.loadOpportunities();
        }
    }

    get disablePrevious() {
        return this.offset === 0;
    }

    get disableNext() {
        return this.offset + this.limitValue >= this.totalRecords;
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10); 
        if (isNaN(selectedPage)) return;
    
        this.offset = (selectedPage - 1) * this.limitValue; 
        this.loadOpportunities(); 
    }    

    //for Custom Modal
    @track isModalOpen = false;

    handleNewOpportunity() {
        this.isModalOpen = true;
    }

    handleModalCancel() {
        this.isModalOpen = false;
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // Possible values: 'success', 'error', 'warning', 'info'
        });
        this.dispatchEvent(toastEvent);
    }

    handleModalSave(event) {
        const newOpportunity = event.detail;
        console.log('Received opportunity data from modal:', event.detail);
        newOpportunity.AccountId = this.recordId;
        newOpportunity.Urgent__c = true;

        if (!newOpportunity.Name || !newOpportunity.StageName || !newOpportunity.Amount || !newOpportunity.CloseDate) {
            console.error('Opportunity is missing required fields:', newOpportunity);
            this.showToast('Error', 'Missing required fields for the opportunity.', 'error');
            return;
        }

        saveNewOpportunity({ opportunity: newOpportunity })
            .then((result) => {
                this.isModalOpen = false;
                this.loadOpportunities();
                if(result) {
                    this.showToast('Success', 'New urgent opportunity created!', 'success');
                } else {
                    this.showToast('False', 'Problem in creating urgent opportunity', 'error');
                }
            })
            .catch(function (error) {
                let errorMessage = 'An unexpected error occurred.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message; // Fetch custom message from Apex
                }
                console.error('Error saving opportunity:', errorMessage);
                this.showToast('Error', errorMessage, 'error');
            }.bind(this));                  
        
        this.isModalOpen = false;
    }    

}