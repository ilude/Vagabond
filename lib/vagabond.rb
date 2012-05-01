require "vagabond/VM/commands"
require "vagabond/web"
require "vagabond/box"
require "vagabond/template"
require "vagabond/environment"
require "vagabond/erbprocessor"


module Vagabond
  VERSION = '0.0.1'
  DESCRIPTION = "Manage Virtualbox virtual machines from ISO images to running boxes"
  
  class Clouds
    def initialize()
      @boxs = {}
      @env = Vagabond::Environment.new
    end
    
    def box(name, &block)
      puts "locating or creating box #{name}"
      @boxs[name] = Vagabond::Box.find_or_create(name, @env, &block)
    end
    

    def build
      @boxs.each do |box|
        box.build
      end
    end
  end

  def self.run
    clouds = Clouds.new
    clouds.instance_eval( File.read("Cloudfile"), 'Cloudfile')
    clouds.build
  end  
end

