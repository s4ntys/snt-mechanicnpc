## snt-mechanicnpc
A FiveM script for a mechanic job with NPC interactions, designed for ESX and QBCore frameworks. Players can start a mechanic job, receive tasks via email (using jpr-phonesystem or lb-phone), interact with NPCs, inspect and repair vehicles, and collect rewards. The script supports qb-target or ox_target for interactions and multiple notification systems (ox_lib, ESX, QBCore).
Features

## Framework Support: 
Compatible with both ESX and QBCore.
NPC Interactions: Players can talk to NPCs, inspect and repair vehicles, and collect payments.
Email Notifications: Job tasks are delivered via email using jpr-phonesystem or lb-phone (configurable).
Target Systems: Supports qb-target or ox_target for interactive zones.
Configurable Notifications: Choose between ox_lib, ESX, or QBCore notification systems.
Debug Mode: Enable detailed console logs for troubleshooting.
Customizable Locations: Define job stations, repair locations, and vehicle models in the config.

## Requirements

FiveM Server with ESX or QBCore framework.
ox_lib (for progress bars, alerts, and optional notifications).
qb-target or ox_target (for interaction zones).
jpr-phonesystem or lb-phone (for email notifications, optional).
A MySQL database (if using ESX/QBCore features like player jobs).

## Installation

### Download the Script:

- Clone or download the repository to your FiveM server's resources folder.

- git clone https://github.com/yourusername/snt-mechanicnpc.git


## Install Dependencies:

- Ensure ox_lib, qb-target (or ox_target), 
-jpr-phonesystem (or lb-phone) are installed in your resources folder.
- Add them to your server.cfg:ensure ox_lib
```
ensure qb-target
ensure jpr-phonesystem
```



## Configure the Script:

- Open config.lua and adjust settings (e.g., UseJPRPhone, NotifyType, TargetSystem, job stations, repair locations).
Example configuration:
```
Config.UseJPRPhone = true
Config.NotifyType = 'ox_lib'
Config.TargetSystem = 'qb_target'
Config.DebugMode = false
```



## Add to server.cfg:

- Add the script to your server.cfg:
```
ensure snt-mechanicnpc
```



## Restart Server:

- Restart your FiveM server or use refresh followed by start snt-mechanicnpc.



## Configuration
- The config.lua file allows customization of the following:

- Phone System: Enable jpr-phonesystem (UseJPRPhone) or lb-phone (UseLBPhone) for job emails.
- Notification System: Choose ox_lib, esx, or qbcore for notifications (NotifyType).
- Target System: Use qb_target or ox_target for interaction zones (TargetSystem).
- Job Stations: Define locations where players can start the job (JobStations).
- Repair Locations: Set NPC and vehicle spawn points (RepairLocations).
- Vehicles: List of repairable vehicles (RepairableVehicles).
- NPC Models: Models for NPCs (NPCModels).
- Rewards: Configure reward range for job completion (RewardFixOnSite).

## Usage

- Starting the Job:

- Go to a configured job station (defined in Config.JobStations).
- Interact with the zone to start the mechanic job.


## Receiving Tasks:

- After a random delay (5-30 seconds), you receive an email (via jpr-phonesystem or lb-phone) with job details.
- A blip is added to your map indicating the NPC's location.


## Interacting with NPCs:

- Approach the NPC and use the interaction zone to talk.
- Inspect the vehicle, repair it, and collect the reward.


## Continuing or Cancelling:

- After completing a job, choose to continue with another task or cancel the job.



## Debugging

Enable
``` 
Config.DebugMode = true
``` 
- in config.lua to log detailed information about notifications, target zones, and NPC/vehicle spawning.
- Check the server/client console for debug messages to troubleshoot issues.

## Contributing
- Feel free to submit issues or pull requests to improve the script. Ensure your changes are compatible with both ESX and QBCore frameworks.
License
- This project is licensed under the MIT License. See the LICENSE file for details. 

## Credits

- Developed by [SanTy].
- Thanks to the FiveM community for framework and resource contributions.

