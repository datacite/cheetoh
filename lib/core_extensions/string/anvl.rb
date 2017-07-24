module CoreExtensions
  module String
    module Anvl
      def from_anvl
        self.split("\n").reduce({}) do |sum, line|
          k, v = line.split(": ", 2)
          sum[k.to_s.anvlunesc] = v.to_s.anvlunesc
          sum
        end
      end

      def anvlesc
        self.gsub(/\n/, "%0A").gsub(/\r/, "%0D")
      end

      def anvlunesc
        self.gsub(/%0A/, "\n").gsub(/%0D/, "\r")
      end
    end
  end
end
