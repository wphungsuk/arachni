=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'xmlrpc/client'
require 'openssl'

module Arachni
module RPC
module XML
module Client

#
# XMLRPC client for remote instances spawned by a remote dispatcher
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Instance

    attr_reader :opts
    attr_reader :framework
    attr_reader :modules
    attr_reader :plugins
    attr_reader :service

    #
    # Maps the methods of remote objects to local ones
    #
    class Mapper

        def initialize( server, remote )
            @server = server
            @remote = remote
        end

        private
        #
        # Used to provide the illusion of locality for remote methods
        #
        def method_missing( sym, *args, &block )
            call = "#{@remote}.#{sym.to_s}"
            @server.call( call, *args )
        end

    end

    #
    # Used to make remote option attributes look like setter methods
    #
    class OptsMapper < Mapper

        def method_missing( sym, *args, &block )
            return super( sym, *args, &block ) if sym == :set

            call = "#{@remote}.#{sym.to_s}="
            @server.call( call, *args )
        end

    end

    def initialize( opts, url )

        @opts = opts

        # start the XMLRPC client
        @server = ::XMLRPC::Client.new2( url )

        # there'll be a HELL of lot of output so things might get..laggy.
        # a big timeout is required to avoid Timeout exceptions...
        @server.timeout = 9999999


        if @opts.ssl_ca
            @server.instance_variable_get( :@http ).instance_variable_set( :@ca_file, @opts.ssl_ca )
            @server.instance_variable_get( :@http ).instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_PEER )
        else
            @server.instance_variable_get( :@http ). instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )
        end

        @opts      = OptsMapper.new( @server, 'opts' )
        @framework = Mapper.new( @server, 'framework' )
        @modules   = Mapper.new( @server, 'modules' )
        @plugins   = Mapper.new( @server, 'plugins' )
        @service   = Mapper.new( @server, 'service' )
    end

    #
    # Used to make old school XMLRPC calls
    #
    def call( method, *args )
        @server.call( method, *args )
    end

end

end
end
end
end
