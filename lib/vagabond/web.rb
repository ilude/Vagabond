module Vagabond
	class Web

    require 'webrick'
    include WEBrick

    class FileServlet < WEBrick::HTTPServlet::AbstractServlet       
      def initialize(server,localfile, box)
        super(server)
        @server=server
        @localfile=localfile
        @box = box
      end

			def do_GET(request,response)
				response['Content-Type']='text/plain'
				response.status = 200
				puts "Serving file #{@localfile}"
				response.body=Vagabond::ErbProcessor.process(@localfile, @box)
				#If we shut too fast it might not get the complete file
				sleep 2
				@server.shutdown
			end
		end 

    def self.wait_for_request(options, box)  
      @box = 
      s= HTTPServer.new( :Port => box.env.port )
      s.mount("/#{options[:filename]}", FileServlet, File.join(options[:web_dir] || "",options[:filename]), box)
      trap("INT"){
				s.shutdown
				puts "Stopping webserver"
				exit
      }
      s.start
    end
  end
end