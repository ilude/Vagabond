require 'FileUtils'

module Vagabond
  class Template
    attr_reader :name
    attr_reader :path
    def initialize(name, env)
      @name = name
      @env = env
      @path = env.template_path
    end
    
    def exists?
      Dir.exist?(path)
    end

    def create(box)
      source = Dir.glob(File.join(@env.template_path, @name, '*.*'))
      destination = File.join(@env.builds_path, box.name)

      Dir.mkdir(@env.builds_path) unless(Dir.exists?(@env.builds_path))
      Dir.mkdir(destination) unless(Dir.exists?(destination))

      FileUtils.cp_r source, destination
    end
    
  end
end