Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.3.3 (2016-06-09)
-------------------------------------------------
- Upgraded validator and builder packages.
- Transfer complete environment by default to executed script.

Version 1.3.2 (2016-06-07)
-------------------------------------------------
- Allow env and cwd settings for execution.

Version 1.3.1 (2016-06-06)
-------------------------------------------------
- Upgraded builder package.
- Fix help for delimiter.

Version 1.3.0 (2016-06-03)
-------------------------------------------------
Allow attachments and changed handlebars syntax.

- Upgraded mail package and optimized verbose output.
- Fix daemon mode to only run if set via cli call.
- Upgraded validator, mail, config, mailparser and builder packages.
- Use formatter for ini parsing.
- Allow multiple verbose settings.
- Reenable help screen.
- Upgrade core, report and builder packages.
- Possibility to send email only on errors by configuration.
- Use alinex error handling.
- Upgraded validator to newest bugfix release for deep schema.
- Upgraded config, exec, report, util, async, debug and yargs packages.
- Upgrade to async 2.0 syntax.
- Upgrade to expand and clone to new util package methods.
- Upgraded alinex packages and yargs.
- Added v6 for travis but didn't activate, yet.
- Upgraded config, mail, util, validator, i18n, imap, yargs.
- Add '=' as separator in variable help.

Version 1.2.0 (2016-04-08)
-------------------------------------------------
- New version containing support for more mail origin options.
- Upgraded config, util and validator packages.
- Forward mail cc, bcc, subject and message id from original mail as json.

Version 1.1.3 (2016-04-06)
-------------------------------------------------
- Upgraded mail package to fixed report component.
- Translate also va4riable types.
- Better list separator explanation.

Version 1.1.2 (2016-04-05)
-------------------------------------------------
- Fix bug in help description for array delimiter.

Version 1.1.1 (2016-04-05)
-------------------------------------------------
- Added basic mail configuration.

Version 1.1.0 (2016-04-05)
-------------------------------------------------
- Upgraded yargs package.
- Add multilingual help.
- Make help multi lingual.
- Make delimiter output human readable also for regexp.
- Add help command to ask for possibilities.

Version 1.0.7 (2016-03-21)
-------------------------------------------------
- Allow array variables with custom delimiter.
- Limit jobs per round for deamon.
- Upgrade yargs, validator and config packages.

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

