# ![PPPC Utility logo][logo] Privacy Preferences Policy Control (PPPC) Utility

[logo]: /Resources/Assets.xcassets/AppIcon.appiconset/PPPC_Logo_32%402x.png "PPPC Utility"

PPPC Utility is a macOS (10.15 and newer) application for creating configuration profiles containing the Privacy Preferences Policy Control payload for macOS. The profiles can be saved locally, signed or unsigned. Profiles can also be uploaded directly to a Jamf Pro server.

All changes to the application are tracked in [the changelog](https://github.com/jamf/PPPC-Utility/blob/master/CHANGELOG.md).

## Installation

Download the latest version from [the Releases page](https://github.com/jamf/PPPC-Utility/releases).

## Building profile

Start by adding the bundles/executables for the payload by using drag-and-drop or by selecting the add (+) button in the left corner.

![Start by adding to the **Applications** table](/Images/Building.png "Building profile")

## Saving

Profiles can be saved locally either signed or unsigned.

![Click **Save** button to save a profile](/Images/SavingUnsigned.png "Saving an unsigned  profile")

![Choose a **Signing Identity** to save a signed profile](/Images/SavingSigned.png "Saving a signed profile")

## Upload to Jamf Pro

### Jamf Pro 10.7.1 and newer

Starting in Jamf Pro 10.7.1 the Privacy Preferences Policy Control Payload can be uploaded to the API without being signed before uploading.

![In 10.7.1 or greater choosing **Signing Identity** is optional before upload](/Images/UploadUnsigned.png "Upload unsigned")

### Jamf Pro 10.7.0 and below

To upload the Privacy Preferences Policy Control Payload to Jamf Pro 10.7.0 and below, the profile will need to be signed before uploading.

![In 10.7.0 or less **Signing Identity** must be chosen before uploading](/Images/UploadSigned.png "Upload signed")

## Importing

Signed and unsigned profiles can be imported.

![Import any profile](/Images/ImportProfile.png "Import profiles")
