module Urushiol
  class Varnish
    def initialize (name)
      @varnish_string = "\n# Start a varnish instance called \"#{name}\"\n"
      @varnish_string << "varnish #{name}"
    end

    def args(args_string)
      @varnish_string << " -arg \"#{args_string}\""
    end

    def vcl_file(file_path)
      args "-f #{file_path}"
    end

    def server_address(ip_adress,port)
      args "-a #{ip_adress}:#{port}"
    end

    def mock_server_address
      server_address("127.0.0.1","8080")
    end

    def vcl(vcl_string)
      @varnish_string << " -vcl {\n#{vcl_string}\n}"
    end

    def vcl_backend(vcl_backend_string)
      @varnish_string << " -vcl+backend {\n#{vcl_backend_string}\n}"
    end

    def start
      @varnish_string << " -start"
    end

    def varnish_source
      if @varnish_string.end_with?(" -start")
        @varnish_string
      else
        start
        @varnish_string
      end

    end
  end
end
