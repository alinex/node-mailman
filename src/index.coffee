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
Exec = require 'alinex-exec'
{object} = require 'alinex-util'
async = require 'alinex-async'
mail = require 'alinex-mail'
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
  console.log "check for commands on mailbox"
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
    debug "#{chalk.grey command} search mails..."
    criteria = ['UNSEEN', ['!HEADER', 'INREPLYTO', '']]
    if setup.filter?.subject
      criteria.push ['SUBJECT', setup.filter.subject]
    if setup.filter?.from
      list = ['FROM', setup.filter.from[0]]
      if setup.filter.from.length > 1
        for addr in setup.filter?.from[1..]
          list = ['OR', ['FROM', addr], list]
      criteria.push list
    debug chalk.grey "#{command} use filter #{util.inspect(criteria).replace /\s+/g, ' '}"
    error = null
    imap.search criteria, (err, results) ->
      return cb err if err
      count = results.length
      debug "#{chalk.grey command} found #{count} messages"
      return cb() unless count
      f = imap.fetch results,
        bodies: ['HEADER.FIELDS (FROM SUBJECT MESSAGE-ID)', 'TEXT']
        markSeen: true
      f.on 'message', (msg, seqno) ->
        debug "#{chalk.grey command} read message ##{seqno}"
        header = ''
        buffer = ''
#        attrs = null
        msg.on 'body', (stream, info) ->
          stream.on 'data', (chunk) ->
            if info.which is 'TEXT'
              buffer += chunk.toString 'utf8'
            else
              header += chunk.toString 'utf8'
#        msg.once 'attributes', (data) ->
#          attrs = data
#          debug "#{chalk.grey command + ' #' + seqno} attributes: #{util.inspect attrs}"
        msg.once 'end', ->
          debug "#{chalk.grey command} end reading #{seqno}"
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

execute = (meta, command, conf, cb) ->
  console.log "-> execute #{command} for #{meta.header.from[0]}"
  setup =
    remote: conf.exec.remote
    cmd: conf.exec.cmd
    args: conf.exec.args
#    priority: 'immediately'
  Exec.run setup, (err, exec) ->
    # check if email should be send
    return cb() unless conf.email
    return cb() if not conf.email.onlyOnError and exec.result.code
    console.log chalk.grey '   sending mail response'
    # configure email
    debug chalk.grey "#{chalk.grey command}: building email"
    email = object.clone conf.email
    email.to = meta.header.from
    email.subject = "Re: #{meta.header.subject[0]}"
    email.inReplyTo = meta.header['message-id'][0]
    email.references = meta.header['message-id']
    context =
      name: command
      conf: conf
      date: new Date()
      process: exec.process
      result: exec.result
    context.result.stdout = exec.stdout()
    context.result.stderr = exec.stderr()
    mail.send email, context, cb
