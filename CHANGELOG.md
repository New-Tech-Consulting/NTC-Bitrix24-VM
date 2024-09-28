# Changelog
All significant changes, improvements, and new functionality in this project will be documented in this file.
## 1.2.0 - 01.09.2024 - New environment released
### Added
- Added the ability to add personal settings for the site in Nginx
- Added the ability to install a File Conversion Server
### Bug Fixes
- Minor bug fixes and small improvements
## 1.1.2 - 15.08.2024 - New environment released
### Added
- Ability to install Sphinx full-text search
### Bug Fixes
- Minor bug fixes and small improvements
## 1.1.1 - 01.08.2024 - New environment released
### Added
- Site deletion
- Constant BX_TEMPORARY_FILES_DIRECTORY and directories for it
- Priority of serving WEBP files if a file with such an extension exists (img.jpg and img.jpg.webp - when accessing img.jpg, img.jpg.webp will be served)
### Changed
- All symbolic links related to the site will be created from the bitrix user and group
- Passwords will contain special characters
### Bug Fixes
- Minor bug fixes and small improvements
## 1.1.0 - 22.07.2024 - New environment released
### Added
- Added the ability to configure SMTP for sites
- When setting up the environment and creating a full-fledged site, a CRON job for agents is automatically created
- Agents are automatically transferred to CRON
- Added support for serving static content with Brotli compression by default
- Added default SSL certificate
- When creating a site in any mode, a config with a standard SSL certificate is created and automatically connected to the site, simplifying the addition of a purchased SSL certificate
- Added the ability to add your own configs to Nginx directives in http (nginx.conf), server for all sites (for both HTTP/HTTPS protocols at once, or for a specific protocol separately) without editing these files
- Added server reboot
- Added server shutdown
- Added the ability to install Netdata
### Changed
- Changed the task for issuing a Let's Encrypt certificate
- PHP sorting: new versions at the top, old versions at the bottom
### Bug Fixes
- In the file .settings.php, the parameter signature_key
- PHP short tags are always enabled (they would reset when increasing/decreasing PHP version)
- Fixed system check error LocalRedirect
## 1.0.1 - 17.07.2024 - New environment released
### Added
- Composite support for sites
### Changed
- Site user (bitrix) can connect via SFTP/SSH
### Bug Fixes
- Redirect from HTTP to HTTPS for the default site
- Adding www to the domain when issuing Let's Encrypt SSL certificate
- Setting the time zone to UTC when setting up the environment (Time in DB and web server Error! Time differs by N seconds)
- Ignoring errors when creating a new full-fledged site DB
- Corrected display of IP address and network interface
- Correct display of IP address and network interface on the screen or in the hosting console
## 1.0.0 - 14.07.2024 - First stable version released
### Added
- Scripts written for installing both the entire environment and the menu separately
- Menu updates implemented using a script or command
- Site list added
- Display of the current PHP version added
- PHP version management added
- BitrixVM emulation added
- Let's Encrypt certificate issuance added
- HTTP to HTTPS redirect management added
- Site creation added, both separate and on symbolic links
- Server updates added
- Display of IP address added, both in the menu and on the system login screen