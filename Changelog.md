Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.0.6 (2016-03-18)
-------------------------------------------------
- Optimize error response mails.
- Fixed man page.
- Fix hang of system if mailserver login failed.
- Move sender check from IMAP to code.
- Fixed parsing of variables.
- Read only the part till the first empty line.
- Don't parse body if not needed.

Version 1.0.5 (2016-03-17)
-------------------------------------------------
- 

Version 1.0.4 (2016-03-17)
-------------------------------------------------
- Give only selected mail header fields to executing program.
- Added checking for _mail parameter in variables.

Version 1.0.3 (2016-03-17)
-------------------------------------------------
- Allow _mail as object in variables.

Version 1.0.2 (2016-03-17)
-------------------------------------------------
- Added util package.

Version 1.0.1 (2016-03-17)
-------------------------------------------------
- Optimize documentation of configuration.
- Added validation for email body variables.
- Use all variables in lower case.

Version 1.0.0 (2016-03-16)
-------------------------------------------------
- Removed unneccessary packages.
- Added _json and _mail automatic variables.
- Allow handlebars in command arguments.
- Move mail sending into extra package.
- Merge branch 'master' of http://github.com/alinex/node-mailman
- Changed general link.
- Add config example to documentation.
- Add config example.
- Set schema check more detailed.

Version 0.1.3 (2016-03-03)
-------------------------------------------------
- Also give args to executing command.

Version 0.1.2 (2016-03-03)
-------------------------------------------------
- Fixed bug in email sending.

Version 0.1.1 (2016-03-03)
-------------------------------------------------
- Upgrade nodemailer package.
- Fix list from filter.
- Add support to filter on from address.
- Optimize console output.
- Make email optional and support onlyOnError setting.

Version 0.1.0 (2016-03-03)
-------------------------------------------------
- Upgraded chai to new version.
- Add daemon mode with interval configuration.
- Support email template for report.
- Filter mails on server.
- Remove modules, not used, yet.
- Open mailbox.
- Base structure for using config file.
- Added schema test.
- Minor changes
- Adding binary for startup.
- Initial code setup.
- Initial commit

