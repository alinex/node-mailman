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
  # configure email
  email = object.clone conf.email ? {base: 'default'}
  email.to = [meta.header.from]
  email.subject = "Re: #{meta.header.subject}"
  email.inReplyTo = meta.header['message-id']
  email.references = [meta.header['message-id']]
  email = mail.resolve email
  # setup internationalization
  i18n = require 'i18n'
  i18n.configure
    # locales: ['en', 'de'] # not needed since v0.7 will be autodetected
    defaultLocale: 'en'
    directory: __dirname + '/../var/locales'
    objectNotation: true
  i18n.setLocale email.locale
  # create report
  report = new Report()
  report.toc()
  report.h2 i18n.__ "general.head:General Use"
  report.p i18n.__ "general.text:To run one of the possible commands from Mailman
  you have to send a simple email to it's address under %s.", meta.header.to
  report.h3 i18n.__ "auth.head:Authentification"
  report.p i18n.__ "auth.text:This is done based on your email address. So you can
  only request what is available for your mail address. See the following list of
  possibilities for you."
  report.h3 i18n.__ "select.head:Selection of Command"
  report.p i18n.__ "select.text:You may select from the below listed commands by
  to execute by using different subject lines in your email. The subject is case
  insensitive but have to be correctly spelled."
  report.h3 i18n.__ "var.head:Variables"
  report.p i18n.__ "var.text:Some of the commands need or allow variables to be used.
  They have to be given in the body of your email in ini format. This means that
  you have to write the name of the variable, an equal sign and it's value in one
  line. The first empty line marks the end of the variables, all information below
  will be ignored. See the Examples below."
  report.h3 i18n.__ "response.head:Response"
  report.p i18n.__ "response.text:The concrete response may vary for each command.
  It can send you an email with the result, the problems or just be quiet. Sometimes
  the called command will interact with you directly like DBReports will do."
  report.h3 i18n.__ "example.head:Examples"
  report.p i18n.__ "example.simple:A question to DBReports for an database analyzation
  may look like:"
  report.code "subject: last login\nbody: user_id = 52643"
  report.p i18n.__ "example.list:Or if you want to call it with multiple IDs (if possible):"
  report.code "subject: last login\nbody: user_id = 52643, 1285, 8854"
  report.code """
    subject: last login
    body: user_id[] = 52643
          user_id[] = 1285
          user_id[] = 8854
    """
  report.p i18n.__ "example.footer:What your command allows will be described in
  the command help below."
  # search for allowed commands
  report.h2 i18n.__ "command.head:Available Commands"
  for name, cmd of config.get '/mailman/command'
    # check for valid command
    valid = cmd.filter?.from?.filter (e) -> ~meta.header.from.toLowerCase().indexOf e
    continue if cmd.filter?.from and not valid.length
    # create report entry
    report.h3 cmd.title
    report.p cmd.description
    report.code "Subject: #{cmd.filter.subject}"
    if cmd.variables
      report.p i18n.__ "command.var:This command supports/needs some variables to be
      set within the contents:"
      report.ul Object.keys(cmd.variables).map (key) ->
        v = cmd.variables[key]
        msg = "`#{key}`"
        msg += " - **#{v.title}**" if v.title
        msg += " (#{i18n.__ 'optional'})" if v.optional and not v.default
        msg += " (#{i18n.__ 'default'}: #{v.default})" if v.default
        msg += "\\\n#{v.description}" if v.description
        msg += "\\\n#{i18n.__ 'Type'}: " + switch v.type
          when 'array'
            i18n.__ "command.list:List of %s", v.entries?.type ? i18n.__ 'entries'
          else
            v.type
        if v.delimiter
          del = v.delimiter.toString()
          if match = del.match /^\/(.*)\/([gim]+)?$/
            del = match[1].replace /\\[srt ]\*/g, ''
            .replace /\\t/g, '\t'
            .replace /\\s\+?/g, ' '
            .replace /^\[(.*?)\]$/g, (_, r) ->
              "#{r.split('').join '\', \''}"
            .replace /^\((.*?)\)$/g, (_, r) ->
              "#{r.split('|').join '\', \''}"
            .replace /\t\+?/g, 'TAB'
            .replace /\s\+?/g, 'SPACE'
          msg += " (" + i18n.__("use '%s' as delimiter", del) + ")"
        msg
  report.h2 i18n.__ "final.head:Further Help"
  report.p i18n.__ "final.text:If something goes wrong or you need further help
  send an email as reply to this."
  # send help email
  mail.send email,
    name: 'help'
    conf: conf
    date: new Date()
    help: report.toString()
  , cb
