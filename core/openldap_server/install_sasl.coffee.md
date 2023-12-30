
# OpenLDAP SASL

SASL definition file to be used conjointly with SASLAuthd.

Note:

* dont know wich permission to give to "/run/saslauthd/mux" socket
* `ldapsearch -x -H ldapi:/// -b "" -LLL -s base supportedSASLMechanisms`
  possible values: PLAIN, GSSAPI, ANONYMOUS, CRAM-MD5, DIGEST-MD5, PLAIN, OTP, EXTERNAL
* the "slapd.conf" file is for now hardcoded

    export default header: 'OpenLDAP Server SASL', handler: ({options}) ->
    
      return unless options.saslauthd
      @file
        header: 'Conf'
        target: '/etc/sasl2/slapd.conf'
        content: """
        pwcheck_method: saslauthd
        mech_list: plain login external
        saslauthd_path: /run/saslauthd/mux
        """
      @service.restart
        header: 'Restart'
        if: -> @status()
        name: 'slapd'
