module Urushiol
  class Vcl

    def initialize (vcl_file_ref)
      @vcl = ""
      parse(vcl_file_ref)
    end

    def parse (vcl_file_ref)
      file = File.open(vcl_file_ref)
      file.each do |line|
        @vcl << line
      end
    end

    def get_conf
      @vcl
    end

  end
end
