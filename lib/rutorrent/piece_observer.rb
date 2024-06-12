module Rutorrent
  class PieceObserver
    attr_reader :piece

    def initialize(piece)
      @piece = piece
      piece.add_observer(self)
    end

    def update
      # piece.update_buffer
    end
  end
end
