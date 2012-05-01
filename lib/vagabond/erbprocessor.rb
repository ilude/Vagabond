require "erb"

module Vagabond
  class ErbProcessor
    def self.process(filename, box)
      return ERB.new(File.read(filename)).result(box.get_binding)
    end
  end
end