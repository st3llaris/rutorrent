module Rutorrent
  class MessageCodeHandler
    attr_accessor :socket, :file_savers, :downloaded_pieces, :requested_pieces, :piece_availability, :mutex,
                  :download_complete

    def initialize(socket, file_savers, downloaded_pieces, download_complete)
      @socket = socket
      @file_savers = file_savers
      @downloaded_pieces = downloaded_pieces
      @requested_pieces = Set.new
      @piece_availability = Hash.new { |hash, key| hash[key] = 0 }
      @mutex = Mutex.new
      @download_complete = download_complete
    end

    def handle_choke(_payload)
      puts "Received choke"
      sleep(5)
      handle_interested(nil, sending: true)
    end

    def handle_unchoke(_payload)
      puts "Received unchoked"
      return if downloaded_pieces.size + 1 == file_savers.sum(&:total_pieces)

      handle_request(nil, sending: true)
    end

    def handle_interested(_payload, sending: false)
      if sending
        puts "Sending interested"
        length = "\0\0\0\1"
        message_id = "\2"
        socket.write(length + message_id)
        message = MessageReader.read_message(socket)
        if Constants::PEER_MESSAGES_MAPPING[message[0]] == "unchoke"
          handle_unchoke(nil)
        else
          puts "waiting for unchoke"
          handle_interested(nil, sending: sending)
        end
      else
        puts "Received interested"
      end
    end

    def handle_not_interested(payload); end

    def handle_have(payload)
      puts "Received have: #{payload.unpack1("B*")}"
    end

    def handle_bitfield(payload)
      puts "Received bitfield"
      @available_pieces = AvailablePiece.new(payload.unpack1("B*")).available_pieces
      handle_interested(nil, sending: true)
    end

    def handle_request(_payload, sending: false)
      if sending
        puts "Sending requests"
        @available_pieces.each do |_available_piece|
          request_info = next_request_piece
          break unless request_info

          piece_index = request_info[:piece_index]
          next if requested_pieces.include?(piece_index)

          begin_offset = request_info[:begin_offset]
          request_length = request_info[:request_length]

          length_prefix = [13].pack("N")
          message_id = [6].pack("C")
          payload = [piece_index, begin_offset, request_length].pack("N*")
          packet = length_prefix + message_id + payload

          socket.send(packet, 0)
          requested_pieces.add(piece_index)
          puts "Requested piece #{piece_index} from offset #{begin_offset} with length #{request_length}"
          if download_complete.true?
            puts "download completed"
            return
          end
        end
      else
        puts "Received request"
      end
    end

    def handle_piece(payload)
      puts "Received piece"
      piece_index, begin_offset = payload.unpack("N2")
      block_data = payload[8..]

      file_savers.each do |file_saver|
        file_saver.save_block(piece_index, begin_offset, block_data)
      end

      mutex.synchronize do
        downloaded_pieces.add(piece_index)
        requested_pieces.delete(piece_index)
      end

      return if downloaded_pieces.size + 1 == file_savers.sum(&:total_pieces)

      handle_request(nil, sending: true)
    end

    def handle_cancel(payload)
      puts "Received cancel: #{payload.unpack1("B*")}"
    end

    def next_request_piece
      piece_index = @available_pieces.find { |index| !requested_pieces.include?(index) }
      return nil unless piece_index

      begin_offset = 0
      request_length = 16_384

      { piece_index: piece_index, begin_offset: begin_offset, request_length: request_length }
    end
  end
end
