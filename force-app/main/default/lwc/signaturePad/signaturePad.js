import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSignature from '@salesforce/apex/SignaturePadController.saveSignature';
import generateAndSavePDF from '@salesforce/apex/SignaturePadController.generateAndSavePDF';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

export default class SignaturePad extends NavigationMixin(LightningElement) {
    @api recordId;
    @track account;
    @track signatureData;
    @track attachmentId;
    @track showSaveAgreementButton = true;

    canvas;
    ctx;
    isDrawing = false;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data.fields;
        } else if (error) {
            console.error('Error loading account', error);
        }
    }

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector('canvas');
            this.ctx = this.canvas.getContext('2d');
            this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
            this.canvas.addEventListener('mousemove', this.draw.bind(this));
            this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
            this.canvas.addEventListener('mouseout', this.stopDrawing.bind(this));
        }
    }

    startDrawing(event) {
        this.isDrawing = true;
        this.ctx.beginPath();
        this.ctx.moveTo(event.offsetX, event.offsetY);
    }

    draw(event) {
        if (!this.isDrawing) return;
        this.ctx.lineTo(event.offsetX, event.offsetY);
        this.ctx.stroke();
    }

    stopDrawing() {
        this.isDrawing = false;
        this.ctx.closePath();
    }

    clearCanvas() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.signatureData = null;
    }

    async saveSignature() {
        this.signatureData = this.canvas.toDataURL(); // Keep the full data URL
        console.log('this.signatureData from saveSignature', this.signatureData);
        try {
            this.attachmentId = await saveSignature({ signatureBody: this.signatureData.split(',')[1], parentId: this.recordId }); // Remove the data URL prefix for saving
            console.log('Attachment ID:', this.attachmentId);
        } catch (error) {
            console.error('Error saving signature:', error);
        }
    }

    async saveAgreement() {
        console.log('this.signatureData from saveAgreement', this.signatureData);
        try {
            const pdfAttachmentId = await generateAndSavePDF({ accountId: this.recordId, attachmentId: this.attachmentId });
            console.log('PDF Attachment ID:', pdfAttachmentId);
            this.showSaveAgreementButton = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Agreement saved successfully!',
                    variant: 'success',
                })
            );
        } catch (error) {
            console.error('Error generating and saving PDF:', error);
        }
    }

    get noSignatureData() {
        console.log('this.signatureData from get noSignatureData', this.signatureData);
        return !this.signatureData;
    }
}