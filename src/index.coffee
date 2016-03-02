# Main controlling class
# =================================================
# This is the real main class which can be called using it's API. Other modules
# like the cli may be used as bridges to this.


# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('mailman')
chalk = require 'chalk'
util = require 'util'
Imap = require 'imap'
# include alinex modules
config = require 'alinex-config'
#Exec = require 'alinex-exec'
#Report = require 'alinex-report'
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
  imap.once 'ready', -> openBox (err, box) ->
    return cb err if err
    processMails box, ->
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
  imap.openBox 'INBOX', mode.try, cb

processMails = (box, cb) ->
  commands = config.get '/mailman/command'
  async.eachOf commands, (setup, command, cb) ->
    debug "#{chalk.grey command} search mails for..."
    criteria = ['UNSEEN']
    if setup.filter?.subject
      criteria.push ['SUBJECT', setup.filter.subject]
    console.log criteria
    error = null
    imap.search criteria, (err, results) ->
      return cb err if err
      count = results.length
      debug "#{chalk.grey command} found #{count} messages"
      return cb() unless count
      f = imap.fetch results,
        bodies: ['HEADER.FIELDS (FROM SUBJECT)', 'TEXT']
      f.on 'message', (msg, seqno) ->
        debug "#{chalk.grey command} read message ##{seqno}"
        header = ''
        buffer = ''
        msg.on 'body', (stream, info) ->
          stream.on 'data', (chunk) ->
            if info.which is 'TEXT'
              buffer += chunk.toString 'utf8'
            else
              header += chunk.toString 'utf8'
#        msg.once 'attributes', (attrs) ->
#          debug "#{chalk.grey command + ' #' + seqno} attributes: #{util.inspect attrs}"
        msg.once 'end', ->
          debug "end #{seqno}"
          execute
            header: Imap.parseHeader header
            body: buffer
          , command, setup, (err) ->
            return cb err if err
            count--
      f.once 'error', ->
        error = new Error "IMAP Fetch error: #{err.message}"
      f.once 'end', ->
        debug "#{chalk.grey command} no more messages"
        return cb error if error
        # wait for finishing execution
        done = ->
          return cb() unless count
          setTimeout done, 1000
        done()
  , cb

execute = (mail, command, setup, cb) ->
  console.log "EXECUTE #{command}"
  console.log mail.header
  console.log Imap
  cb()
