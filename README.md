# Cemu Save Switcher

Powershell script for Cemu saves management

## How to use it ?

Simply run it with your favorite Powershell binary

### First run

You will be asked for a couple of things

1. Select your Cemu `mlc01` folder.
2. Input the nickname of the current owner of `mlc01/usr/save`
3. Add more users (you can do it later)

It will create an XML config file storing these informations where the script resides

### Regular run

For the moment you only have two awesome options :
- Switch the save folders
- Add more users

## How does it work ?

When switching a user, the script simply renames the `save` folder to `save_<CurrentUser>` and `save_<SelectedUser>` to `save`
