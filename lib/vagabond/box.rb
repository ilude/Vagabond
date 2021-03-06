require 'fileutils'
require 'json_builder'
require 'ip'

module Vagabond
  class Box
    attr_reader :name, :build_path, :env
    attr_accessor :template, :settings

    def initialize(name, env)
      @name = name
      @env = env
      @build_path = File.join(env.builds_path, name)
    end

    def self.find(name, env = Environment.new)
      box = Box.new(name, env)
      if(box.created?)
        #box.settings = Vagabond::BoxSettings.new File.join(env.builds_path, name, settings)
        return box
      else
        return nil
      end
    end
    
    def self.create(name, options = {:template => 'ubuntu-12.04-server-amd64', :address => :dhcp}, env)
      puts "creating box #{name} from #{options[:template]}"
      box = Box.new(name, env)
      
      raise Exception.new("Box #{name} already exist!") if(box.created?)

      template_path = File.join(env.template_path, options[:template])
      raise Exception.new("Template #{options[:template]} does not exist at #{template_path}!") unless Dir.exists?(template_path)

      box.template = options[:template]

      settings = Vagabond::BoxSettings.new(File.join(template_path, 'settings.rb'))

      # clean out empty options
      box.settings = settings.merge(options.delete_if {|key,value| value.nil?})
      
      box
    end

    def build
      iso_file = File.join("iso", @settings[:iso_file])

      if(!File.exists?(iso_file) &&  @settings[:iso_src])
        puts "#{File.expand_path(iso_file)} not found!"
        puts "Please wait while the file is downloaded..."

        start_time = Time.now

        Vagabond::Web.download(@settings[:iso_src], iso_file)

        puts "Download completed in #{Time.at(Time.now - start_time).gmtime.strftime("%H:%M:%S")}"
      end

      raise "Please download #{@settings[:iso_file]} and place it at #{File.expand_path(iso_file)}" if(!File.exists? iso_file)

      Vagabond::VM::Commands.create(name, @settings)
      sata_name = Vagabond::VM::Commands.create_sata_controller(name, @settings)
      disk_name = Vagabond::VM::Commands.create_disk(name, name, @settings)
      Vagabond::VM::Commands.attach_disk(name, sata_name, disk_name)
      Vagabond::VM::Commands.attach_iso(name, sata_name, iso_file)
      Vagabond::VM::Commands.set_boot_order(name)
      Vagabond::VM::Commands.create_inetface(name, @settings)
      Vagabond::VM::Commands.start(name)

      puts "Waiting for #{name} to boot up..."
      sleep @settings[:boot_wait]

      if(@settings[:boot_cmd_sequence]) 
        puts "Sending boot parameters..."

        @settings[:boot_cmd_sequence].each { |s|  
          s.gsub!(/%IP%/, @env.host);
          s.gsub!(/%PORT%/, @env.port.to_s);
          s.gsub!(/%NAME%/, name);

          Vagabond::VM::Commands.send_sequence(name,s)
        }
      end

      if(@settings[:install_files]) 
        @settings[:install_files].each do |file|
          Vagabond::Web.wait_for_request({
            :filename => file,
            :web_dir => File.join(env.template_path, @template)},
            self
          )
        end
      end
    end

    def start(type = :normal)
      Vagabond::VM::Commands.start(name, type)
    end

    def stop(type = :normal)
      Vagabond::VM::Commands.stop(name, type)
    end

    def created?
      return Dir.exists?(File.join(@env.builds_path, @name))
    end

    def destroy 
      if(created?)
        Vagabond::VM::Commands.destroy(name)
      end
      if(Dir.exists? build_path)
        FileUtils.remove_dir(build_path)
      end
    end

    def node_json
      ip = IP.new(address) rescue nil
      return JSONBuilder::Compiler.generate(:pretty => true) do
        user do
          name 'vagabond'
        end
        if ip 
          network do
            static true
            ip ip.to_addr
            netmask ip.netmask.to_s
            network ip.network.to_addr
            broadcast ip.broadcast.to_addr
            gateway ip.network(1).to_addr
          end
        end
        run_list ["recipe[default]", "recipe[default::interfaces]"] 
      end
    end
    
    def get_binding
      binding
    end
  end
end