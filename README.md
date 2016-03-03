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

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/node-alinex).


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




### Run as a service

To run the controller continuously use the `daemon` option and start it in the
background.

    > mailman -d -C > /var/log/mailman.log 2>&1 &

This will run the process continuously in daemon mode checking every few minutes
for mails to be processed.

> For production use you may start it using [pm2](http://pm2.keymetrics.io/).



License
-------------------------------------------------

Copyright 2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
