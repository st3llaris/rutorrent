module Rutorrent
  class AvailablePiece
    attr_accessor :payload

    def initialize(payload)
      @payload = payload.chars.map!(&:to_i)
    end

    def available_pieces
      payload.each_index.select { |i| payload[i] == 1 }
    end
  end
end
