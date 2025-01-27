export default class SignaturePad extends LightningElement {
    @track signatureData = '';

    canvas;
    ctx;
    isDrawing = false;

    connectedCallback() {
        this.canvas = this.template.querySelector('canvas');
        this.ctx = this.canvas.getContext('2d');
        this.setupCanvas();
    }

    setupCanvas() {
        this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
        this.canvas.addEventListener('mousemove', this.draw.bind(this));
        this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
        this.canvas.addEventListener('mouseout', this.stopDrawing.bind(this));
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
    }

    saveSignature() {
        this.signatureData = this.canvas.toDataURL();
        // Logic to preview the agreement can be added here
    }
}