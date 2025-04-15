import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiatePayment from '@salesforce/apex/PhonePeController.initiatePayment';
import checkPaymentStatus from '@salesforce/apex/PhonePeController.checkPaymentStatus';

export default class PaymentForm extends LightningElement {
    @track amount = 1;
    @track isProcessing = false;
    @track paymentUrls = '';
    @track merchantTransactionId = '';
    
    handleAmountChange(event) {
        this.amount = event.target.value;
    }
    
    initiatePayment() {
        this.isProcessing = true;
        
        // Generate a unique transaction ID
        this.merchantTransactionId = 'TXN_' + Date.now();
        const merchantUserId = 'USER_' + Date.now();
        
        initiatePayment({ 
            amount: this.amount, 
            merchantTransactionId: this.merchantTransactionId,
            merchantUserId: merchantUserId
        })
        .then(result => {
            console.log('PhonePe API Response:', result);
            if (result.success === true) {
                // Extract the payment URL from the response
                const data = result.data;
                if (data && data.instrumentResponse && data.instrumentResponse.redirectInfo) {
                    this.paymentUrl = data.instrumentResponse.redirectInfo.url;
                      window.location.href = this.paymentUrl;
                    // Set up a status check interval
                    this.paymentStatusCheckInterval = setInterval(() => {
                        this.checkPaymentStatus();
                    }, 5000); // Check every 5 seconds
                } else {
                    this.showToast('Error', 'Invalid response from payment gateway', 'error');
                }
            } else {
                this.showToast('Error', result.message || 'Payment initiation failed', 'error');
            }
        })
        .catch(error => {
            console.error('Error initiating payment:', error);
            this.showToast('Error', error.message || 'An error occurred', 'error');
        })
        .finally(() => {
            this.isProcessing = false;
        });
    }
    
    checkPaymentStatus() {
        if (!this.merchantTransactionId) return;
        
        checkPaymentStatus({ merchantTransactionId: this.merchantTransactionId })
        .then(result => {
            console.log('Payment Status:', result);
            if (result.success === true && result.data && result.data.paymentState === 'COMPLETED') {
                // Payment successful
                this.showToast('Success', 'Payment completed successfully!', 'success');
                clearInterval(this.paymentStatusCheckInterval);
                this.paymentUrl = ''; // Close the payment iframe
                
                // Further processing can be done here
            } else if (result.success === true && result.data && result.data.paymentState === 'FAILED') {
                // Payment failed
                this.showToast('Error', 'Payment failed: ' + (result.data.statusMessage || ''), 'error');
                clearInterval(this.paymentStatusCheckInterval);
                this.paymentUrl = ''; // Close the payment iframe
            }
            // Other states like PENDING, etc. will continue to be checked
        })
        .catch(error => {
            console.error('Error checking payment status:', error);
        });
    }
    
    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toast);
    }
    // In your phonePePayment.js
connectedCallback() {
    // Check if we're returning from a payment
    const urlParams = new URLSearchParams(window.location.search);
    const paymentStatus = urlParams.get('paymentStatus');
    const txnId = urlParams.get('txnId');
    
    if (paymentStatus && txnId) {
        // Handle the returned payment status
        if (paymentStatus === 'SUCCESS') {
            this.showToast('Success', 'Payment completed successfully!', 'success');
        } else if (paymentStatus === 'FAILURE') {
            this.showToast('Error', 'Payment failed', 'error');
        }
        
        // Remove parameters from URL to prevent showing the message again on refresh
        const newUrl = window.location.pathname;
        window.history.replaceState({}, document.title, newUrl);
    }
}
    
    disconnectedCallback() {
        // Clear any intervals when component is destroyed
        if (this.paymentStatusCheckInterval) {
            clearInterval(this.paymentStatusCheckInterval);
        }
    }
}
