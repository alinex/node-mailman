# Main controlling class
# =================================================
# This is the real main class which can be called using it's API. Other modules
# like the cli may be used as bridges to this.


# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('mailman')
Imap = require 'imap'
# include alinex modules
config = require 'alinex-config'
Exec = require 'alinex-exec'
{string} = require 'alinex-util'
Report = require 'alinex-report'
async = require 'alinex-async'
# include classes and helpers


# Initialized Data
# -------------------------------------------------
# This will be set on init

# ### General Mode
# This is a collection of base settings which may alter the runtime of the system
# without changing anything in the general configuration. This values may also
# be changed at any time.
mode =
  try: false # work in try mode

imap = null

exports.init = (setup) ->
  mode = setup

# Run Mailman
# -------------------------------------------------
exports.run = (cb) ->
  debug "connect to mailserver..."
  setup = config.get '/mailman/mailcheck'
  imap = new Imap setup
  imap.once 'ready', -> openBox -> processMails ->
    imap.end()
    cb()
  imap.once 'error', cb
  imap.once 'end', ->
    debug 'mailserver connection ended'
  imap.connect()

# Helper Methods
# -------------------------------------------------
openBox = (cb) ->
  debug "open INBOX..."
  imap.status 'INBOX', (err, box) ->
    debug "found #{box.messages.total} messages (#{box.messages.unseen} unread)"
  console.log mode
  imap.openBox 'INBOX', mode.try, cb

processMails = (cb) ->
  commands = config.get '/mailman/commands'
  async.eachOf commands, (setup, command, cb) ->
    debug "search mails for #{command}..."


    cb()
  , cb
