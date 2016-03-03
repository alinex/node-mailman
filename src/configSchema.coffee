# Configuration Schema
# =================================================


# Email Action
# -------------------------------------------------
email =
  title: "Email Action"
  description: "the setup for an individual email action"
  type: 'object'
  allowedKeys: true
  keys:
    base:
      title: "Base Template"
      type: 'string'
      description: "the template used as base for this"
      list: '<<<context:///email>>>'
    transport:
      title: "Service Connection"
      description: "the service connection to send mails through"
      type: 'or'
      or: [
        type: 'string'
      ,
        type: 'object'
      ]
    from:
      title: "From"
      description: "the address emails are send from"
      type: 'string'
    replyTo:
      title: "Reply To"
      description: "the address to send answers to"
      type: 'string'
      optional: true
    to:
      title: "To"
      description: "the address emails are send to"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    cc:
      title: "Cc"
      description: "the carbon copy addresses"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    bcc:
      title: "Bcc"
      description: "the blind carbon copy addresses"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    locale:
      title: "Locale Setting"
      description: "the locale setting for subject and body dates"
      type: 'string'
      minLength: 2
      maxLength: 5
      lowerCase: true
      match: /^[a-z]{2}(-[a-z]{2})?$/
    subject:
      title: "Subject"
      description: "the subject line of the generated email"
      type: 'handlebars'
    body:
      title: "Content"
      description: "the body content of the generated email"
      type: 'handlebars'
    onlyOnError:
      title: "Send Only on Error"
      description: "the response mail will only be send on error of the executed
      command"
      type: 'boolean'
      default: false
  optional: true

# Complete Schema Definition
# -------------------------------------------------
command =
  title: "Command"
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
      type: 'object'
      allowedKeys: true
      keys:
        subject:
          type: 'string'
        from:
          type: 'array'
          toArray: true
          entries:
            type: 'string'
    data:
      type: 'object'
    exec:
      type: 'object'
      #############################
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
