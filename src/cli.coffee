# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
yargs = require 'yargs'
chalk = require 'chalk'
fspath = require 'path'
# include alinex modules
config = require 'alinex-config'
Exec = require 'alinex-exec'
mail = require 'alinex-mail'
alinex = require 'alinex-core'
# include classes and helpers
mailman = require './index'
schema = require './configSchema'

process.title = 'MailMan'
logo = alinex.logo 'Email Control Manager'


# Error management
# -------------------------------------------------
alinex.initExit()
process.on 'exit', ->
  console.log "Goodbye\n"

# Start argument parsing
# -------------------------------------------------
yargs
.usage "\nUsage: $0 [options]"
.env 'MAILMAN' # use environment arguments prefixed with SCRIPTER_
# examples
.example('$0', 'to simply run the manager once')
.example('$0 -d -C -v 2>&1 >/var/log/mailman.log', 'run continuously as a daemon')
# general options
.options
  help:
    alias: 'h',
    description: 'display help message'
  nocolors:
    alias: 'C'
    describe: 'turn of color output'
    type: 'boolean'
    global: true
  verbose:
    alias: 'v'
    describe: 'run in verbose mode (multiple makes more verbose)'
    count: true
    global: true
  try:
    alias: 't'
    describe: "try run which wont change the request emails"
    type: 'boolean'
    global: true
  daemon:
    alias: 't'
    describe: "run as a daemon"
    type: 'boolean'
    global: true
# general help
.help 'help'
.updateStrings
  'Options:': 'General Options:'
.epilogue """
  You may use environment variables prefixed with 'MAILMAN_' to set any of
  the options like 'MAILMAN_VERBOSE' to set the verbose level.

  For more information, look into the man page.
  """
# validation
.strict()
.fail (err) ->
  err = new Error "CLI #{err}"
  err.description = 'Specify --help for available options'
  alinex.exit 2, err
argv = yargs.argv
# parse data
argv.json = JSON.parse argv.json if argv.json
# implement some global switches
chalk.enabled = false if argv.nocolors


# Main routine
# -------------------------------------------------
console.log logo
console.log "Initializing..."
# init
mailman.init
  try: argv.try
  daemon: argv.daemon
mail.setup (err) ->
  alinex.exit err if err
  Exec.setup (err) ->
    alinex.exit err if err
    # add schema for module's configuration
    config.setSchema '/mailman', schema
    # set module search path
    config.register 'mailman', fspath.dirname __dirname
    mailman.init
      try: argv.try
    config.init (err) ->
      alinex.exit err if err
      # check mails
      if argv.daemon
        daemon()
      else
        mailman.run (err) ->
          alinex.exit err if err

daemon = ->
  setTimeout daemon, config.get '/mailman/daemon/interval'
  mailman.run (err) ->
    alinex.exit err if err
