# Cemu Save Switcher

Powershell script for Cemu saves management

## How to use it ?

Simply run it with your favorite Powershell binary

### First run

You will be asked to select your Cemu *mlc01* folder.

Then to input the nickname of the current owner of *mlc01/usr/save*

You can add more user to handle now, or later.

It will create an XML config file in the folder where the script resides

### Regular run

For the moment you only have two awesome options :
- Switch the save folders
- Add more users

## How does it work ?

When switching a user, the script simply renames the *save* folder to *save_<current_user_nickname>* and *save_<selected_user_nickname>* to *save*
