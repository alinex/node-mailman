# Main controlling class
# =================================================
# This is the real main class which can be called using it's API. Other modules
# like the cli may be used as bridges to this.


# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('mailman')
# include alinex modules
config = require 'alinex-config'
Exec = require 'alinex-exec'
{string} = require 'alinex-util'
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
  mail: null # alternative email to use

exports.init = (setup) ->
  mode = setup
