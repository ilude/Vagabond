module Vagabond
  module VM
    class Commands
      @virtualbox_command = 'vboxmanage'
      @interfaces = []
      @host_ifaces = []

      def self.virtualbox_command
        @virtualbox_command
      end

      def self.virtualbox_command=(value)
        @virtualbox_command = value
      end

      def self.version
        if(@version.nil?)
          @version = (execute "-v").gsub(/r\d+/, '')
        end

       @version
      end

      def self.create(boxname, options = {})
        options = {:memory => "384", :cpus => "1"}.merge(options)
        execute "createvm --name \"#{boxname}\" --ostype #{options[:os_type]} --register --basefolder \"#{File.expand_path("builds/")}/\""
        execute "modifyvm \"#{boxname}\" --cpus #{options[:cpus]} --memory #{options[:memory]}"
      end

      def self.create_sata_controller(boxname, options = {}, sata_name = "SATA Controller")
        options = {:sataportcount => "4", :hostiocache => "off", :bootable => "on"}.merge(options)
        command = "storagectl \"#{boxname}\" --name \"#{sata_name}\" --add sata"
        command << " --sataportcount #{options[:sataportcount]}"
        command << " --hostiocache #{options[:hostiocache]}"
        command << " --bootable #{options[:bootable]}"
        execute command
        sata_name
      end

      def self.create_disk(boxname, disk_name, options = {})
        options = {:disk_size => "10140", :disk_format => "VDI"}.merge(options)
        disk_name = "#{disk_name}.#{options[:disk_format]}"
        location = File.join("builds", boxname, disk_name)

        command = "createhd --filename \"#{location}\""
        command << " --size #{options[:disk_size]}" 
        command << " --format #{options[:disk_format]}"
        execute command

        disk_name
      end

      def self.attach_disk(boxname, sata_name, location)
        execute "storageattach \"#{boxname}\" --storagectl \"#{sata_name}\" --port 0 --device 0 --type hdd --medium \"builds/#{boxname}/#{location}\""
      end

      def self.attach_iso(boxname, sata_name, location)
        execute "storageattach \"#{boxname}\" --storagectl \"#{sata_name}\" --port 1 --device 0 --type dvddrive --medium \"#{location}\""
      end

      def self.destroy(boxname)
        begin
          execute "unregistervm \"#{boxname}\" --delete"
        rescue

        end
      end

      def self.create_ssh_mapping(boxname, hostport=7222, guestport=22)
        execute "modifyvm \"#{boxname}\" --natpf1 'guestssh,tcp,,#{hostport},,#{guestport}'"
      end

      def self.create_inetface(boxname, options = {})
        if(options[:ip])
          execute "modifyvm \"#{boxname}\" --nic1 bridged --nictype1 virtio --bridgeadapter1 \"#{get_bridging_interfaces[0][:name]}\""
          #execute "modifyvm \"#{boxname}\" --nic2 hostonly --hostonlyadapter2 \"#{get_host_interfaces[0][:name]}\""
        else
          #create_ssh_mapping(boxname)
        end
      end

      def self.set_boot_order(boxname)
        execute "modifyvm \"#{boxname}\" --boot1 disk"
        execute "modifyvm \"#{boxname}\" --boot2 dvd"
        execute "modifyvm \"#{boxname}\" --boot3 none"
        execute "modifyvm \"#{boxname}\" --boot4 none"
      end

      def self.start(boxname, type = :normal)
        type_switch = (type == :headless) ? "--type headless" : ''
        execute "startvm \"#{boxname}\" #{type_switch}"
      end

      def self.stop(boxname, type = :normal)
        type_switch = (type == :force) ? "poweroff" : "acpipowerbutton"
        execute "controlvm \"#{boxname}\" #{type_switch}"
      end

      def self.list(state = :all)
        state_switch = (state == :all) ? "vms" : "runningvms"
        execute "-q list #{state_switch}"
      end

      def self.get_bridging_interfaces
        if(@interfaces.length == 0)
          output = (execute "list bridgedifs").split(/\r?\n/)
          output.each do |line|
            key, value = line.split(':').map {|item| item.strip }
            if(line.start_with?("Name:")) 
              @interfaces << {:name => value}
            elsif !key.nil? 
              @interfaces.last[key.downcase.to_sym] = value
            end
          end 
        end

        @interfaces
      end

      def self.get_host_interfaces
        if(@host_ifaces.length == 0)
          output = (execute "list hostonlyifs").split(/\r?\n/)
          output.each do |line|
            key, value = line.split(':').map {|item| item.strip }
            if(line.start_with?("Name:")) 
              @host_ifaces << {:name => value}
            elsif !key.nil? 
              @host_ifaces.last[key.downcase.to_sym] = value
            end
          end 
        end

        @host_ifaces
      end

      def self.send_sequence(boxname,s)
        keycodes=string_to_keycode(s)

        # VBox seems to have issues with sending the scancodes as one big
        # .join()-ed string. It seems to get them out or order or ignore some.
        # A workaround is to send the scancodes one-by-one.
        keycodes.each { |keycode|
          if keycode=="wait"
            sleep 1
            next         
          end

          execute "controlvm \"#{boxname}\" keyboardputscancode #{keycode}"
          #puts "controlvm \"#{boxname}\" keyboardputscancode #{keycode}"
          sleep 0.01 
        }
      end

      def self.string_to_keycode(thestring)
    
        #http://www.win.tue.nl/~aeb/linux/kbd/scancodes-1.html
    
        k=Hash.new
        k['1'] = '02 82'; k['2'] = '03 83'; k['3'] = '04 84'; k['4'] = '05 85' ;
        k['5'] = '06 86'; k['6'] = '07 87'; k['7'] = '08 88'; k['8'] = '09 89'; k['9'] = '0a 8a';
        k['0'] = '0b 8b'; k['-'] = '0c 8c'; k['='] = '0d 8d';
        k['Tab'] = '0f 8f'; 
        k['q'] = '10 90'; k['w'] = '11 91'; k['e'] = '12 92';  
        k['r'] = '13 93'; k['t'] = '14 94'; k['y'] = '15 95';   
        k['u'] = '16 96'; k['i'] = '17 97'; k['o'] = '18 98'; k['p'] = '19 99' ; 
       
        k['Q']  = '2a 10 aa' ; k['W']  = '2a 11 aa' ; k['E']  = '2a 12 aa'; k['R'] = '2a 13 aa' ; k['T'] = '2a 14 aa' ; k['Y'] = '2a 15 aa'; k['U']= '2a 16 aa' ; k['I']='2a 17 aa'; k['O'] = '2a 18 aa' ; k['P'] = '2a 19 aa' ;

        k['a'] = '1e 9e'; k['s']  = '1f 9f' ; k['d']  = '20 a0' ; k['f']  = '21 a1'; k['g'] = '22 a2' ; k['h'] = '23 a3' ; k['j'] = '24 a4'; 
        k['k']= '25 a5' ; k['l']='26 a6';
        k['A'] = '2a 1e aa 9e'; k['S']  = '2a 1f aa 9f' ; k['D']  = '2a 20 aa a0' ; k['F']  = '2a 21 aa a1';
        k['G'] = '2a 22 aa a2' ; k['H'] = '2a 23 aa a3' ; k['J'] = '2a 24 aa a4'; k['K']= '2a 25 aa a5' ; k['L']='2a 26 aa a6'; 
        
        k[';'] = '27 a7' ;k['"']='2a 28 aa a8';k['\'']='28 a8';

        k['\\'] = '2b ab';   k['|'] = '2a 2b aa 8b';

        k['[']='1a 9a'; k[']']='1b 9b';
        k['<']='2a 33 aa b3'; k['>']='2a 34 aa b4'; k['?']='2a 35 aa b5';
        k['$']='2a 05 aa 85';
        k['+']='2a 0d aa 8d';

        k['z'] = '2c ac'; k['x']  = '2d ad' ; k['c']  = '2e ae' ; k['v']  = '2f af'; k['b'] = '30 b0' ; k['n'] = '31 b1' ;
        k['m'] = '32 b2';
        k['Z'] = '2a 2c aa ac'; k['X']  = '2a 2d aa ad' ; k['C']  = '2a 2e aa ae' ; k['V']  = '2a 2f aa af';
        k['B'] = '2a 30 aa b0' ; k['N'] = '2a 31 aa b1' ; k['M'] = '2a 32 aa b2';
        
        k[',']= '33 b3' ; k['.']='34 b4'; k['/'] = '35 b5' ;k[':'] = '2a 27 aa a7';
        k['%'] = '2a 06 aa 86';  k['_'] = '2a 0c aa 8c';
        k['&'] = '2a 08 aa 88';
        k['('] = '2a 0a aa 8a';
        k[')'] = '2a 0b aa 8b';
              

        special=Hash.new;
        special['<Enter>'] = '1c 9c';
        special['<Backspace>'] = '0e 8e';
        special['<Spacebar>'] = '39 b9';
        special['<Return>'] = '1c 9c'
        special['<Esc>'] = '01 81';
        special['<Tab>'] = '0f 8f';
        special['<KillX>'] = '1d 38 0e';
        special['<Wait>'] = 'wait';

        special['<Up>'] = '48 c8';
        special['<Down>'] = '50 d0';
        special['<PageUp>'] = '49 c9';
        special['<PageDown>'] = '51 d1';
        special['<End>'] = '4f cf';
        special['<Insert>'] = '52 d2';
        special['<Delete>'] = '53 d3';
        special['<Left>'] = '4b cb';
        special['<Right>'] = '4d cd';
        special['<Home>'] = '47 c7';

        special['<F1>'] = '3b';
        special['<F2>'] = '3c';
        special['<F3>'] = '3d';
        special['<F4>'] = '3e';
        special['<F5>'] = '3f';
        special['<F6>'] = '40';
        special['<F7>'] = '41';
        special['<F8>'] = '42';
        special['<F9>'] = '43';
        special['<F10>'] = '44';

        keycodes= Array.new
        thestring.gsub!(/ /,"<Spacebar>")

        until thestring.length == 0
          nospecial=true;
          special.keys.each { |key|
            if thestring.start_with?(key)
              #take thestring
              #check if it starts with a special key + pop special string
              keycodes << special[key]
              thestring=thestring.slice(key.length,thestring.length-key.length)
              nospecial=false;
              break;
            end
          }
          if nospecial
            code=k[thestring.slice(0,1)]
            if !code.nil?
              keycodes << code
            else
              puts "no scan code for #{thestring.slice(0,1)}"
            end
            #pop one
            thestring=thestring.slice(1,thestring.length-1)
          end
        end

        return keycodes
      end

      def self.execute(args)
        output = ''

        #puts "#{@virtualbox_command} #{args}"

        output, e, s = Open3.capture3("#{@virtualbox_command} #{args}")

        if(s.exitstatus != 0)
          raise "executing #{@virtualbox_command} #{args} => #{e}"
        end

        output
      end
    end
  end
end