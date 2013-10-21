module Urushiol
  class Vtc

    def initialize(name)
      @vtc = ""
    end

    def mock_backends(vcl)
      if vcl != nil
        backends = vcl.scan(/^backend (\w*)\W+/).flatten

        #Mock servers in vtc-file
        backends.each do |backend|
          index = backends.index(backend)
          @vtc << "server s#{index} -repeat 10000 {
              # Receive a request
              rxreq
              # Send a standard response
              txresp -hdr \"Connection: close\" -body \"#{backend}\"
            } -start \n"

          #mock backends in vcl-file
          vcl.gsub!(/(?m)backend #{backend} \{(.*?)\}/,
                     "backend #{backend} {\n  .host = \"${s#{index}_addr}\";\n  .port = \"${s#{index}_port}\";\n}")
        end
        @test_vcl = vcl
      else
        puts("no vcl-file given")
      end
    end

    def append_config(tests)
      @vtc << tests
    end

    def mock_varnish
      @vtc << "# Start a varnish instance called \"v1\" from vcl and override backends with mock server adresses
              varnish v1 -arg \"-f /tmp/test.vcl\" -start \n"
    end

    def get_spec
      @vtc
    end
  end
end
