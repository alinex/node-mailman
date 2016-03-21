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
# include classes and helpers
logo = require('alinex-core').logo 'Email Control Manager'
mailman = require './index'
schema = require './configSchema'

process.title = 'MailMan'

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
  console.error """
    #{logo}
    #{chalk.red.bold 'CLI Parameter Failure:'} #{chalk.red err}

    """
  process.exit 1
.argv
# parse data
argv.json = JSON.parse argv.json if argv.json
# implement some global switches
chalk.enabled = false if argv.nocolors


# Error management
# -------------------------------------------------
exit = (code = 0, err) ->
  # exit without error
  process.exit code unless err
  # exit with error
  console.error chalk.red.bold "FAILED: #{err.message}"
  console.error err.description if err.description
  process.exit code unless argv.daemon
  argv.daemon = false
  setTimeout ->
    process.exit code
  , 2000

process.on 'SIGINT', -> exit 130, new Error "Got SIGINT signal"
process.on 'SIGTERM', -> exit 143, new Error "Got SIGTERM signal"
process.on 'SIGHUP', -> exit 129, new Error "Got SIGHUP signal"
process.on 'SIGQUIT', -> exit 131, new Error "Got SIGQUIT signal"
process.on 'SIGABRT', -> exit 134, new Error "Got SIGABRT signal"
process.on 'exit', ->
  console.log "Goodbye\n"

# Main routine
# -------------------------------------------------
console.log logo
console.log "Initializing..."
# init
mailman.init
  try: argv.try
  daemon: argv.daemon
mail.setup (err) ->
  exit 1, err if err
  Exec.setup (err) ->
    exit 1, err if err
    # add schema for module's configuration
    config.setSchema '/mailman', schema
    # set module search path
    config.register 'mailman', fspath.dirname __dirname
    mailman.init
      try: argv.try
    config.init (err) ->
      exit 1, err if err
      # check mails
      if argv.daemon
        daemon()
      else
        mailman.run (err) ->
          exit 1, err if err

daemon = ->
  setTimeout daemon, config.get '/mailman/daemon/interval'
  mailman.run (err) ->
    exit 1, err if err
