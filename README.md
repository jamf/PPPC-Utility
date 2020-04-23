# ![alt text][logo] Privacy Preferences Policy Control (PPPC) Utility

[logo]: /Resources/Assets.xcassets/AppIcon.appiconset/PPPC_Logo_32%402x.png "PPPC Utility"

PPPC Utility is a macOS (10.13 and newer) application for creating configuration profiles containing the 
Privacy Preferences Policy Control payload for macOS. The profiles can be saved locally signed or unsigned. 
Profiles can also be uploaded directly to a Jamf Pro server. 

## Installation

#### [Download the latest version here](https://github.com/jamf/PPPC-Utility/releases)

## Building profile
Start by adding the bundles/executables for the payload by using drag-and-drop or by selecting the add (+)
button in the left corner.
![alt text](/Images/Building.png "Building profile")

## Saving
Profiles can be saved locally either signed or unsigned.  

![alt text](/Images/SavingUnsigned.png "Building profile")


## Upload to Jamf Pro

#### Jamf Pro 10.7.1 and newer
Starting in Jamf Pro 10.7.1 the Privacy Preferences Policy Control Payload can be uploaded to the API without being signed before uploading.
![alt text](/Images/UploadUnsigned.png "Upload unsigned")

#### Jamf Pro 10.7.0 and below 
To upload the Privacy Preferences Policy Control Payload to Jamf Pro 10.7.0 and below, 
the profile will need to be signed before uploading.
![alt text](/Images/UploadSigned.png "Upload signed")

## Importing
Signed and unsigned profiles can be imported.

![alt text](/Images/ImportProfile.png "Import profiles")
