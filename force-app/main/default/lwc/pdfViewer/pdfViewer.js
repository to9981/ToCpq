import { LightningElement, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import PDFJS from '@salesforce/resourceUrl/pdfobj'; // Reference the Static Resource 'pdfjs5p'

export default class PdfViewer extends LightningElement {
    @api recordId;
    isModalOpen = false; // Track if modal is open
    pdfUrl = 'https://uwaterloo.ca/onbase/sites/default/files/uploads/documents/sampleunsecuredpdf.pdf'; // Your PDF URL

    // Variables to store PDF.js components
    pdfLib;
    pdfDoc;
    pageNum = 1;
    canvas;

    async connectedCallback() {
        const pdfjsUrl = PDFJS + '/pdfobject.js'; // PDF.js main library URL
        console.log('pdfjsUrl:', pdfjsUrl);
        console.log('connectedCallback is called');
        try {
            // Load PDF.js from the Static Resource
            await loadScript(this, pdfjsUrl); // Load the main PDF.js script
            console.log('PDF.js loaded from Static Resource');

            // Access the PDF.js global object
            if (window['pdfjsLib']) {
                this.pdfLib = window['pdfjsLib']; // Access the PDF.js global object
                this.pdfLib.GlobalWorkerOptions.workerSrc = null; // Disable worker script
                console.log('PDF.js is available:', this.pdfLib);
            } else {
                console.error('PDF.js is not available in window object!');
            }
        } catch (error) {
            console.error('Error loading PDF.js from Static Resource:', error);
        }
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    // Additional methods to handle PDF rendering can be added here
}
