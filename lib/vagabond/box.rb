require 'fileutils'

module Vagabond
  class Box
    attr_reader :name, :build_path, :env
    attr_accessor :template

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

    def self.find_or_create(name, env, &block)
      find(name, env) || create(name, env, &block)
    end

    def self.find(name, env = Environment.new)
      box = Box.new(name, env)
      if(box.created?)
        return box
      else
        return nil
      end
    end
    
    def self.create(name, env, &block)
      puts "creating box #{name}"
      box = Box.new(name, env)

      raise Exception.new("Box #{name} already exist!") if(box.created?)

      box.instance_eval(&block)

      template = Template.new(box.template, env);

      raise Exception, "Template #{template} does not exist at #{template.path}!" unless(template.exists?)

      template.create(box)
      
      box
    end

    def destroy 
      if(created?)
        Vagabond::VM::Commands.destroy(name)
        FileUtils.remove_dir(build_path)
      end
    end

    def build
      Vagabond::VM::Commands.create(name, 'Ubuntu_64')
      Vagabond::VM::Commands.create_sata_controller(name)
      Vagabond::VM::Commands.create_disk(name, "#{name}.vdi", 10140)
      Vagabond::VM::Commands.attach_disk(name, "#{name}.vdi")
      Vagabond::VM::Commands.attach_iso(name, "iso/ubuntu-11.10-server-amd64.iso")
      Vagabond::VM::Commands.set_boot_order(name)
      Vagabond::VM::Commands.create_ssh_mapping(name)
      Vagabond::VM::Commands.start(name)

      sleep 10

      sequence = [
        '<Esc><Wait><Esc><Wait><Enter><Wait>',
        '/install/vmlinuz noapic preseed/url=http://%IP%:%PORT%/preseed.cfg ',
        'debian-installer=en_US auto locale=en_US kbd-chooser/method=us ',
        'hostname=%NAME% ',
        'fb=false debconf/frontend=noninteractive ',
        'keyboard-configuration/layout=USA keyboard-configuration/variant=USA console-setup/ask_detect=false ',
        'initrd=/install/initrd.gz -- <Enter>'
      ]  

      sequence.each { |s|  
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