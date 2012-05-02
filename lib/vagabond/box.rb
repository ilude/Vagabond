require 'fileutils'

module Vagabond
  class Box
    attr_reader :name, :build_path, :env
    attr_accessor :template, :settings

    def initialize(name, env)
      @name = name
      @env = env
      @build_path = File.join(env.builds_path, name)
    end

    def template=(value)
      @template = value
    end

    def template
      @template
    end

    #def self.find_or_create(name, env, &block)
    #  find(name, env) || create(name, env, &block)
    #end

    def self.find(name, env = Environment.new)
      box = Box.new(name, env)
      if(box.created?)
        #box.settings = Vagabond::BoxSettings.new File.join(env.builds_path, name, settings)
        return box
      else
        return nil
      end
    end
    
    def self.create(name, template, env, settings = 'settings.rb')
      puts "creating box #{name}"
      box = Box.new(name, env)
      
      raise Exception.new("Box #{name} already exist!") if(box.created?)

      box.template = template

      template = Template.new(box.template, env);

      raise Exception, "Template #{template} does not exist at #{template.path}!" unless(template.exists?)

      template.create(box)

      box.settings = Vagabond::BoxSettings.new File.join(env.builds_path, name, settings)
      
      box
    end

    def destroy 
      if(created?)
        Vagabond::VM::Commands.destroy(name)
        FileUtils.remove_dir(build_path)
      end
    end

    def build
      iso_file = File.join("iso", @settings[:iso_file])

      if(!File.exists? iso_file) 
        Vagabond::Web.download(@settings[:iso_src], iso_file)
      end

      raise "Please download #{@settings[:iso_file]} and place it at #{File.expand}" if(!File.exists? iso_file)

      Vagabond::VM::Commands.create(name, @settings[:os_type_id])
      Vagabond::VM::Commands.create_sata_controller(name)
      Vagabond::VM::Commands.create_disk(name, "#{name}.vdi", @settings[:disk_size])
      Vagabond::VM::Commands.attach_disk(name, "#{name}.vdi")
      Vagabond::VM::Commands.attach_iso(name, iso_file)
      Vagabond::VM::Commands.set_boot_order(name)
      Vagabond::VM::Commands.create_ssh_mapping(name)
      Vagabond::VM::Commands.start(name)

      puts "Waiting for #{name} to boot up..."
      sleep @settings[:boot_wait]

      puts "Sending boot parameters..."

      @settings[:boot_cmd_sequence].each { |s|  
        s.gsub!(/%IP%/, @env.host);
        s.gsub!(/%PORT%/, @env.port.to_s);
        s.gsub!(/%NAME%/, name);

        Vagabond::VM::Commands.send_sequence(name,s)
      }

      Vagabond::Web.wait_for_request({
        :filename => "preseed.cfg",
        :web_dir => build_path},
        self
      )

      Vagabond::Web.wait_for_request({
        :filename => "latecommand.sh",
        :web_dir => build_path},
        self
      )

      Vagabond::Web.wait_for_request({
        :filename => "postinstall.sh",
        :web_dir => build_path},
        self
      )

    end

    def start
      Vagabond::VM::Commands.start(name)
    end

    def created?
      return Dir.exists?(File.join(@env.builds_path, @name))
    end
    
    def get_binding
      binding
    end
  end
end