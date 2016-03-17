# Configuration Schema
# =================================================

email = require('alinex-mail/lib/configSchema.js').email


# Complete Schema Definition
# -------------------------------------------------
command =
  title: "Command Setup"
  description: "the definition of a single command to execute"
  type: 'object'
  allowedKeys: true
  keys:
    title:
      title: "Title"
      description: "the short title of the job to be used in display"
      type: 'string'
    description:
      title: "Description"
      description: "a short abstract of what this job will retrieve"
      type: 'string'
    filter:
      title: "Filter Conditions"
      description: "the conditions to filter mails which are seen as linked to
      this command"
      type: 'object'
      allowedKeys: true
      keys:
        subject:
          title: "Subject"
          description: "the case insenitive part of the subject which must be there"
          type: 'string'
        from:
          title: "Allowed Sender"
          description: "the list of allowed users by name part of the email address"
          type: 'array'
          toArray: true
          entries:
            type: 'string'
    variables:
      type: 'object'
      entries: [
        type: 'object'
        mandatoryKeys: ['type']
        keys:
          type:
            type: 'string'
      ]
    exec:
      title: "Commandline"
      description: "the real call on commandline"
      type: 'object'
      allowedKeys: true
      mandatoryKeys: ['cmd']
      keys:
        cmd:
          title: "Executable"
          description: "the executable to run"
          type: 'string'
        args:
          title: "Parameters"
          description: "the parameters to send"
          type: 'array'
          toArray: true
          entries:
            type: 'handlebars'
    email: email

# Complete Schema Definition
# -------------------------------------------------

module.exports =
  title: "Mailman Setup"
  description: "the configuration for the mail manager system"
  type: 'object'
  allowedKeys: true
  keys:
    mailcheck:
      title: "IMAP Setup"
      description: "the mailserver on which to check for new commands"
      type: 'object'
      allowedKeys: true
      keys:
        user:
          title: "Username"
          description: "the username to log into server"
          type: 'string'
        password:
          title: "Password"
          description: "the password for login"
          type: 'string'
        host:
          title: "Hostname or IP"
          description: "the imap host"
          type: 'hostname'
        port:
          title: "Port"
          description: "the port number to use for connection"
          type: 'port'
          optional: true
        tls:
          title: "Secure Login"
          description: "a flag to use secure login over TLS"
          type: 'boolean'
          default: false
        autotls:
          title: "TLS Upgrade"
          description: "the value decides when to upgrade to a secure session"
          type: 'string'
          values: ['always', 'required', 'never']
          default: 'never'
        connTimeout:
          title: "Connection Timeout"
          description: "the time in milliseconds to wait to establish connection"
          type: 'interval'
          min: 100
          default: 10000
        authTimeout:
          title: "Authentication Timeout"
          description: "the time in milliseconds to wait to authenticate user"
          type: 'interval'
          min: 100
          default: 5000
    command:
      title: "Command Setup"
      description: "the configuration for the calling command"
      type: 'object'
      allowedKeys: true
      entries: [command]
    email:
      title: "Email Templates"
      description: "the possible templates used for sending emails"
      type: 'object'
      entries: [email]
    interval:
      title: "Check Interval"
      description: "the time to recheck for new emails in daemon mode"
      type: 'interval'
      default: 300000
