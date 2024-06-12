require "observer"

module Rutorrent
  class Piece
    include Observable
    attr_reader :blocks, :piece_index, :buffer

    def initialize(blocks, piece_index)
      @blocks = blocks
      @piece_index = piece_index
      @piece_observer = PieceObserver.new(self)
    end

    def blocks=(new_element)
      blocks << new_element
      changed
      notify_observers
    end

    def update_buffer
      # buffer.write(blocks.last)
    end

    def buffer_content
      buffer.string
    end
  end
end
