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
argv = yargs
.usage("""
  #{logo}
  Usage: $0 [-vCcltd]
  """)
# examples
.example('$0', 'to simply run the manager once')
.example('$0 -d -C >/dev/null', 'run continuously as a daemon')
# general options
.alias('C', 'nocolors')
.describe('C', 'turn of color output')
.boolean('C')
.alias('v', 'verbose')
.describe('v', 'run in verbose mode (multiple makes more verbose)')
.count('verbose')
# controller run
.alias('t', 'try')
.describe('t', 'try run which wont change the emails')
.boolean('t')
# daemon
.alias('d', 'daemon')
.describe('d', 'run as a daemon')
.boolean('d')
# general help
.help('h')
.alias('h', 'help')
.epilogue("For more information, look into the man page.")
.showHelpOnFail(false, "Specify --help for available options")
.strict()
.fail (err) ->
  err = new Error "CLI #{err}"
  err.description = 'Specify --help for available options'
  alinex.exit 2, err
.argv
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
