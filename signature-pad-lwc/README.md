# Signature Pad LWC

This project implements a Lightning Web Component (LWC) for capturing signatures on an agreement. The component allows users to view the terms of the agreement and sign it using a canvas.

## Project Structure

```
signature-pad-lwc
├── force-app
│   └── main
│       └── default
│           ├── lwc
│           │   └── signaturePad
│           │       ├── signaturePad.html
│           │       ├── signaturePad.js
│           │       └── signaturePad.js-meta.xml
│           └── classes
│               └── SignaturePadController.cls
├── sfdx-project.json
└── README.md
```

## Setup Instructions

1. **Clone the Repository**
   Clone this repository to your local machine using:
   ```
   git clone <repository-url>
   ```

2. **Install Salesforce CLI**
   Ensure you have the Salesforce CLI installed. You can download it from the [Salesforce CLI website](https://developer.salesforce.com/tools/sfdxcli).

3. **Authenticate to Your Salesforce Org**
   Run the following command to authenticate:
   ```
   sfdx auth:web:login -a <alias>
   ```

4. **Deploy the Component**
   Navigate to the project directory and deploy the component to your Salesforce org:
   ```
   sfdx force:source:push
   ```

## Usage

- Navigate to the Lightning App Builder in your Salesforce org.
- Add the `signaturePad` component to your desired Lightning page.
- Users can view the agreement and sign it directly on the canvas.

## License

This project is licensed under the MIT License. See the LICENSE file for details.