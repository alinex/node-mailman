mailman
=================================================

Email based interface to control processes. This enables an user to send commands
through email. The incoming mails will be scanned automatically, checked and if
valid the command will be processed sending back a reply with the command's log.

- imap mail support
- filter emails to access
- authentication possible
- remote control
- complete logging


Usage
-------------------------------------------------
After the mailman is configured you can start it once using:

    > mailman

This will run the manager one time, check the emails run all required commands,
send the replies like configured and finish.


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

### Setup

To use mailman you have to setup the jobs using some configuration
files.


Read more
-------------------------------------------------
To get the full documentation including configuration description look into
[Mailman](http://alinex.github.io/node-mailman).


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
