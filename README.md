Package: alinex-mailman
=================================================

[![Build Status](https://travis-ci.org/alinex/node-mailman.svg?branch=master)](https://travis-ci.org/alinex/node-mailman)
[![Coverage Status](https://coveralls.io/repos/alinex/node-mailman/badge.png?branch=master)](https://coveralls.io/r/alinex/node-mailman?branch=master)
[![Dependency Status](https://gemnasium.com/alinex/node-mailman.png)](https://gemnasium.com/alinex/node-mailman)

Email based interface to control processes. This enables an user to send commands
through email. The incoming mails will be scanned automatically, checked and if
valid the command will be processed sending back a reply with the command's log.

- imap mail support
- filter emails to access
- authentication possible
- remote control
- complete logging

> It is one of the modules of the [Alinex Namespace](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/develop).


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-mailman.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-mailman.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-mailman)

Install the package globally using npm on a central server. From there all your
machines may be checked:

``` sh
sudo npm install -g alinex-mailman --production
```

After global installation you may directly call `mailman` from anywhere.

``` sh
mailman --help
```

Because this application works agentless, you don't have to do something special
on your clients but often some simple changes can make the reports more powerful.
If so you will get a hint in the report.

Always have a look at the latest [changes](Changelog.md).


Usage
-------------------------------------------------
After the mailman is configured you can start it once using:

    > mailman

This will run the manager one time, check the emails run all required commands,
send the replies like configured and finish.

The service may run with multiple verbose levels:

- '-v' - to only show each run and numer of calls per job
- '-vv' - to display if email is send
- '-vvv' - to display what is called (with variables)

If the service is running you may also request the online help by sending
`subject: help me` to it's email address.


### Run as a service

To run the controller continuously use the `daemon` option and start it in the
background.

    > mailman -d -C > /var/log/mailman.log 2>&1 &

This will run the process continuously in daemon mode checking every few minutes
for mails to be processed.

> For production use you may start it using [pm2](http://pm2.keymetrics.io/).
> `pm2 start mailman -- --daemon`


### Try mode

Mostly for testing you may use the try mode:

    > mailman -t

That will run mailman normally but won't change the email so it can be used over
and over again. Alternatively you may mark the email as 'unread' to reenable it.


Configuration
-------------------------------------------------

The base configuration for `/mailman` looks like:

``` yaml
# Configuration for mailman
# =================================================================

# IMAP Server to check for mails
mailcheck:
  # Username for login
  user: alexander.schilling@mycompany.de
  # Password for login
  password: mypass
  # Host or IP address to connect to
  host: mail.mycompany.de
  # Connection port
  port: 143
  # Secure login, set to true to login through TLS
  tls: false
  # TLS Upgrade decides when to upgrade to a secure session:
  # one of 'always', 'required', 'never'
  autotls: never
  # Connection timeout in milliseconds to wait to establish connection"
  connTimeout: 10s
  # Authentication timeout in milliseconds to wait to authenticate user"
  authTimeout: 5s

# Check interval to recheck for new emails in daemon mode
interval: 5m
```

And then the commands under `/mailman/comand/` will look like:

``` yaml
# Commands
# -------------------------------------------------------------------
command:
  # Object of possible commands to use
  date:
    # Title and description used for the mail response
    title: "Get the Date"
    description: "Get the date from the server."
    # Filter rules which define the emails to react on
    filter:
      # case-insensitive part of the subject
      subject: 'what time is it'
      # address or list of addresses, also as case-insensitive parts
      from: '@mycompany.de'
    # Variables to support from body
    variables:      
      format:
        type: 'string'
    # Command to execute
    exec:
      # executional on command line
      cmd: 'date'
      # list of arguments
      args: []
    # response mail settings
    email:
      # use the template
      base: default
    # send an email only on error
    emailOnlyOnError: true
```

Within the `args` you may use specific parameters given in mail body (but use them
all in lowercase). Also the following general variables are present:

- `_mail` - the mail object
  - `header` - some mail header fields like `from`, `cc`, `bcc`, `subject`, `messageId`
  - `body` - text and html body if available
- `_json` - complete parameters

So you may use the email address of the sender as `_mail.header.from` to give it
to your command.

The email templates are stored under `/email` will look like:

``` yaml
# Email Templates
# -------------------------------------------------------------------
default:
  # specify how to connect to the server
  transport: smtp://alexander.schilling%40mycompany.de:<<<env://PW_ALEX_COM>>>@mail.mycompany.de
  # sender address
  from: alexander.schilling@mycompany.de
  replyTo: alexander.schilling@mycompany.de

  # content
  locale: de
  subject: >
    Re: {{conf.title}}
  body: |+
  {{conf.title}}
  ==========================================================================

  {{conf.description}}

  Started on {{dateFormat date "LL"}} from {{dateFormat process.start "LTS"}} to {{dateFormat process.end "LTS"}}

  PID {{process.host}}#{{process.pid}}

  {{#if result.code}}
  ::: alert
  **{{{result.error}}}** (Code {{result.code}})
  :::
  {{/if}}

  {{#if result.stdout}}
  Output of command was:

  `` ` text
  {{{result.stdout}}}
  `` `
  {{/if}}

  {{#if result.stderr}}
  Error output from command was:

  `` ` text
  {{{result.stderr}}}
  `` `
  {{/if}}
```


License
-------------------------------------------------

(C) Copyright 2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
