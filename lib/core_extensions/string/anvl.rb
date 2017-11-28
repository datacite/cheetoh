module CoreExtensions
  module String
    module Anvl
      def from_anvl
        self.split("\n").reduce({}) do |sum, line|
          k, v = line.split(": ", 2)
          sum[k.to_s.kanvlunesc] = v.to_s.anvlunesc
          sum
        end
      end

      def kanvlesc
        self.anvlesc.gsub(/:/, "%3A")
      end

      def anvlesc
        self.gsub(/%/, "%25").gsub(/\n/, "%0A").gsub(/\r/, "%0D")
      end

      def kanvlunesc
        self.gsub(/%3A/, ":").anvlunesc
      end

      def anvlunesc
        self.gsub(/%25/, "%").gsub(/%0A/, "\n").gsub(/%0D/, "\r")
      end
    end
  end
end
