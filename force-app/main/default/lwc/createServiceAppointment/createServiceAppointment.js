import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateServiceAppointmentLWC extends LightningElement {
  @api recordId;

  handleSubmit(event) {
    const schedStartTime = this.template.querySelector("[data-id='schedStartTime']").value;
    const schedEndTime = this.template.querySelector("[data-id='schedEndTime']").value;

    if (!schedStartTime || !schedEndTime) {
      event.preventDefault();
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: 'Start Time and End Time are required',
          variant: 'error'
        })
      );
    }
  }

  handleSuccess(event) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Service Appointment created successfully',
        variant: 'success'
      })
    );

    this.dispatchEvent(new CustomEvent('closemodal'));
  }

  handleError(event) {
    console.error(event.detail.message);
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error creating record',
        message: event.detail.message,
        variant: 'error'
      })
    );
  }
}