module Vagabond
	class Web
    require 'net/http'
    require 'webrick'
    require 'progressbar'

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

    def self.download(url, file, limit=3)

      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      uri = URI.parse(url)

      Net::HTTP.start(uri.host,uri.port) {|http|
        req = Net::HTTP::Get.new(uri.path, nil)
        alreadyDL = 0
        http.request(req) { |response|
          # handle 301/302 redirects
          if(response['location'])
            self.download(response['location'], file, limit - 1)
          else
            size = response.content_length

            pBar = ProgressBar.new("Downloading",size)
            pBar.file_transfer_mode
            File.open(file,'wb') {|file|
              response.read_body {|segment|
                alreadyDL += segment.length
                if(alreadyDL != 0)
                  pBar.set(alreadyDL)
                end
                file.write(segment)
              }
              pBar.finish
            }
          end          
        }
      }
    end

  end
end