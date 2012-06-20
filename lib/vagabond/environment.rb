module Vagabond
  class Environment
    require 'socket'

    def initialize(options = {})
      defaults = {
        :template_path => File.join(Dir.pwd, "templates"),
        :builds_path => File.join(Dir.pwd, "builds"),
        :host => UDPSocket.open {|socket| socket.connect("64.233.187.99", 1); socket.addr.last},
        :port => Random.rand(9999 - 2000) + 2000,
        :vbox_version => Vagabond::VM::Commands.version
      }

      @env = defaults.merge(options)
    end
    
    def method_missing(m, *args, &block)
      property = m.to_sym
      return @env[property] if(@env.has_key? property)
    end

    def virtualbox_found?
      if(@version.nil?)
        begin
          !Vagabond::VM::Commands.version.empty?
        rescue
          false
        end
      end
    end
    
  end
  
end