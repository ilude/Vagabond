module Vagabond
  class BoxSettings < Hash
    def initialize(path)
      instance_eval IO.read(path)
    end
    
    def method_missing(meth, *args, &blk)
      self[meth.to_sym] = args[0]
    end
  end
end