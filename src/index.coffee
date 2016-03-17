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
MailParser = require('mailparser').MailParser
# include alinex modules
config = require 'alinex-config'
Exec = require 'alinex-exec'
{object} = require 'alinex-util'
async = require 'alinex-async'
mail = require 'alinex-mail'
validator = require 'alinex-validator'
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
        bodies: ['HEADER', 'TEXT']
        markSeen: true
      f.on 'message', (msg, seqno) ->
        debug "#{chalk.grey command} read message ##{seqno}"
        mailparser = new MailParser()
        mailparser.on 'end', (obj) ->
          execute
            header: obj.headers
            body:
              html: obj.html
              text: obj.text
          , command, setup, (err) ->
            return cb err if err
            count--
#        attrs = null
        msg.on 'body', (stream) ->
          stream.on 'data', (chunk) ->
            mailparser.write chunk.toString 'utf8'
#        msg.once 'attributes', (data) ->
#          attrs = data
#          debug "#{chalk.grey command + ' #' + seqno} attributes: #{util.inspect attrs}"
        msg.once 'end', ->
          debug "#{chalk.grey command} end reading #{seqno}"
          mailparser.end()
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

bodyVariables = (conf, body, cb) ->
  return cb null, {} unless conf.variables
  body = unless body.html
    body.text.trim()
  else
    require('html2plaintext') body.html
  return cb() unless body
  # parse ini format
  ini = require 'ini'
  try
    obj = ini.decode body
  catch error
    return cb new Error "ini parser: #{error.message}"
  # detect failed parsing
  if not obj?
    return cb new Error "ini parser: could not parse any result"
  if obj['{']
    return cb new Error "ini parser: Unexpected token { at start"
  for k, v of obj
    if v is true and k.match /:/
      return cb new Error "ini parser: Unexpected key name containing
      ':' with value true"
  # validate variables
  obj = object.lcKeys obj
  delete obj[key] unless conf.variables[key] for key of obj
  validator.check
    name: 'emailBody'
    value: obj
    schema:
      type: 'object'
      allowedKeys: true
      mandatoryKeys: true
      keys: conf.variables
  , cb

execute = (meta, command, conf, cb) ->
  console.log "-> execute #{command} for #{meta.header.from}"
  # parse Options
  bodyVariables conf, meta.body, (err, variables) ->
    # configure email
    email = object.clone conf.email ? {base: 'default'}
    email.to = [meta.header.from]
    email.subject = "Re: #{meta.header.subject}"
    email.inReplyTo = meta.header['message-id']
    email.references = [meta.header['message-id']]
    # send error email
    if err
      return mail.send email,
        name: command
        conf: conf
        date: new Date()
        result:
          code: 1
          error: err.message
      , cb
    console.log "   with", variables
    # add variables to command
    variables ?= {}
    variables._mail =
      header:
        from: meta.header.from
    variables._json = JSON.stringify variables
    setup =
      remote: conf.exec.remote
      cmd: conf.exec.cmd
      args: conf.exec.args.map (e) -> e variables
  #    priority: 'immediately'
    Exec.run setup, (err, exec) ->
      # check if email should be send
      return cb() unless conf.email
      return cb() if not conf.email.onlyOnError and exec.result.code
      # send email
      console.log chalk.grey '   sending mail response'
      context =
        name: command
        conf: conf
        date: new Date()
        process: exec.process
        result: exec.result
      context.result.stdout = exec.stdout()
      context.result.stderr = exec.stderr()
      mail.send email, context, cb
