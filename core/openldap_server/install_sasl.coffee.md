
# OpenLDAP ACL

    module.exports = header: 'OpenLDAP Server SASL', handler: ->
      # Note:
      # * dont know wich permission to give to "/run/saslauthd/mux" socket
      # * `ldapsearch -x -H ldapi:/// -b "" -LLL -s base supportedSASLMechanisms`
      #   possible values: PLAIN, GSSAPI, ANONYMOUS, CRAM-MD5, DIGEST-MD5, PLAIN, OTP, EXTERNAL
      @file
        header: 'Conf'
        if: @has_service 'masson/core/saslauthd'
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
