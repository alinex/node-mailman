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
Report = require 'alinex-report'
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
  daemon: false # runs in daemon mode?

imap = null # imap connection
numJobs = 0 # number of jobs in progress

exports.init = (setup) ->
  mode = setup


# Run Mailman
# -------------------------------------------------
exports.run = (cb) ->
  numJobs = 0
  console.log "check for commands on mailbox"
  debug "connect to mailserver..."
  setup = config.get '/mailman/mailcheck'
  imap = new Imap setup
  imap.once 'ready', -> openBox (err, box) ->
    return cb err if err
    processMails box, (err) ->
      imap.end()
      cb err
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
  return cb() unless conf.variables
  body = unless body.html
    body.text.trim()
  else
    require('html2plaintext') body.html
  return cb() unless body
  # use only the code till the first empty line
  lines = []
#  for l in string.toList body
  for l in body.split /\n/
    break unless l.trim()
    lines.push l
  # parse ini format
  ini = require 'ini'
  try
    obj = ini.decode lines.join '\n'
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
#  obj = object.lcKeys obj
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
  if command is 'help'
    return help meta, conf, cb
  # check for max execution
  max = if meta.daemon then config.get '/mailman/daemon/maxJobs' else 20
  unless numJobs < max
    console.error "skipping for this round (max #{max} jobs per round)"
    return cb()
  # check authentications
  if conf.filter?.from
    from = meta.header.from.toLowerCase()
    valid = false
    for test in conf.filter?.from
      valid = ~from.indexOf test
      break if valid
    unless valid
      console.error "skipping invalid sender #{from}"
      return cb()
  # parse Options
  console.log "-> execute #{command} for #{meta.header.from}"
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
    console.log "   with", variables if variables
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
      return cb() unless not conf.email.onlyOnError or exec.result.code
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

help = (meta, conf, cb) ->
  report = new Report()
  report.h2 "General Use"
  report.p "To run one of the possible commands from Mailman you have to send an
  simple email to it's address under #{meta.header.to}."
  report.h3 "Authentification"
  report.p "This is done based on your email address. So you can only request what
  is available for xour mail address. See the following list of possibilities for
  you."
  report.h3 "Selection of Report"
  report.h3 "Variables"
  report.h3 "Response"
  report.h3 "Examples"
  # search for allowed commands
  report.h2 "Available Commands"
  for name, cmd of config.get '/mailman/command'
    # check for valid command
    valid = cmd.filter?.from?.filter (e) -> ~meta.header.from.toLowerCase().indexOf e
    continue if cmd.filter?.from and not valid.length
    # create report entry
    report.h3 cmd.title
    report.p cmd.description
    report.code "Subject: #{cmd.filter.subject}"
    if cmd.variables
      report.p "This reports supports/needs some variables to be set within the contents:"
      report.ul Object.keys(cmd.variables).map (key) ->
        v = cmd.variables[key]
        msg = "`#{key}`"
        msg += " - **#{v.title}**" if v.title
        msg += " (optional)" if v.optional and not v.default
        msg += " (default: #{v.default})" if v.default
        msg += "\\\n#{v.description}" if v.description
        msg += "\\\nType: " + switch v.type
          when 'array'
            "List of #{v.entries?.type ? 'entries'}"
          else
            v.type
        if v.delimiter
          del = v.delimiter.toString()
          if match = del.match /^\/(.*)\/([gim]+)?$/
            del = match[1].replace /\\[srt ]\*/g, ''
            .replace /\\s\+?/g, ' '
            .replace /\\t\+?/g, 'TAB'
            .split /|/
            .join "', '"
          msg += " (use '#{del}' as delimiter)"
        msg
# list delimiter format optimized

  # configure email
  email = object.clone conf.email ? {base: 'default'}
  email.to = [meta.header.from]
  email.subject = "Re: #{meta.header.subject}"
  email.inReplyTo = meta.header['message-id']
  email.references = [meta.header['message-id']]
  # send help email
  mail.send email,
    name: 'help'
    conf: conf
    date: new Date()
    help: report.toString()
  , cb
