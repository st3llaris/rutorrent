require "digest/sha1"

class FileSaver
  attr_reader :expected_hashes, :pieces, :total_pieces, :piece_length, :file_path, :file

  def initialize(file_path, piece_length, total_pieces, expected_hashes)
    @file_path = file_path
    @file = File.open(file_path, "wb")
    @piece_length = piece_length
    @total_pieces = total_pieces
    @expected_hashes = expected_hashes
    @pieces = Array.new(total_pieces) { "" }
  end

  def save_block(piece_index, begin_offset, block_data)
    @pieces[piece_index] ||= ""
    @pieces[piece_index][begin_offset, block_data.length] = block_data

    @file.seek(piece_index * @piece_length)
    @file.write(@pieces[piece_index])
    verify_piece(piece_index)
    @pieces[piece_index] = nil
  end

  def save_piece_to_file(piece_index)
    @file.seek(piece_index * piece_length)
    @file.write(pieces[piece_index])
    puts "Verified and saved piece #{piece_index}"
  end

  def expected_final_piece_size
    @total_length - (@piece_length * (@total_pieces - 1))
  end

  def verify_piece(piece_index)
    piece_data = @pieces[piece_index]
    piece_hash = Digest::SHA1.digest(piece_data)
    expected_hash = @expected_hashes[piece_index]

    return save_piece_to_file(piece_index)
  end

  def close
    file.close
  end
end
