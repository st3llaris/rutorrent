require "digest"
require "pry"
class FileSaver
  attr_reader :expected_hashes, :total_pieces, :piece_length, :file_path, :file, :pieces, :received_sizes, :downloaded,
              :length

  def initialize(file_path, piece_length, total_pieces, expected_hashes, length)
    @file_path = file_path
    @file = File.open(file_path, "wb+")
    @piece_length = piece_length
    @total_pieces = total_pieces
    @expected_hashes = expected_hashes
    @received_sizes = Array.new(total_pieces, 0)
    @count = 0
    @downloaded = false
    @length = length
  end

  def save_block(piece_index, _begin_offset, _block_data, pieces)
    return unless piece_complete?(piece_index, pieces)

    verify_and_save_piece(piece_index, pieces)
  end

  def piece_complete?(piece_index, pieces)
    piece_size = piece_index == @total_pieces - 1 ? expected_final_piece_size : @piece_length
    pieces[piece_index]&.blocks&.sum { |block| block[:block_data].size } == piece_size
  end

  def verify_and_save_piece(piece_index, pieces)
    piece_data = pieces[piece_index]
    piece_data.blocks.each do |block_hash|
      if @file.size >= length
        @file.close
        @downloaded = true
        break
      end

      hash = Digest::SHA1.digest(block_hash[:block_data])

      if hash.size == @expected_hashes[piece_index].size
        @file.seek(@count * block_hash[:block_data].size)
        @count += piece_index
        @file.write(block_hash[:block_data])
        puts "Verified and saved piece #{piece_index}, offset #{block_hash[:begin_offset]}"
      else
        puts "Piece #{piece_index} failed hash check"
      end
    end
  end

  def expected_final_piece_size
    total_length = (@piece_length * (@total_pieces - 1)) + @expected_hashes.last.size
    total_length - (@piece_length * (@total_pieces - 1))
  end

  def close
    file.close
  end
end
