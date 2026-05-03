module Garmin
  module FitEncoder
    module Crc16
      TABLE = [
        0x0000, 0xCC01, 0xD801, 0x1400,
        0xF001, 0x3C00, 0x2800, 0xE401,
        0xA001, 0x6C00, 0x7800, 0xB401,
        0x5000, 0x9C01, 0x8801, 0x4400
      ].freeze

      module_function

      def compute(bytes)
        crc = 0
        bytes.each_byte do |b|
          tmp = TABLE[crc & 0xF]
          crc = (crc >> 4) & 0x0FFF
          crc = (crc ^ tmp ^ TABLE[b & 0xF]) & 0xFFFF

          tmp = TABLE[crc & 0xF]
          crc = (crc >> 4) & 0x0FFF
          crc = (crc ^ tmp ^ TABLE[(b >> 4) & 0xF]) & 0xFFFF
        end
        crc
      end
    end
  end
end
