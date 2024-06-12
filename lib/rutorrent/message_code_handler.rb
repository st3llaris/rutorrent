module Rutorrent
  class MessageCodeHandler
    attr_accessor :socket, :file_savers, :downloaded_pieces, :requested_pieces, :mutex,
                  :download_complete, :piece_length

    def initialize(socket, file_savers, downloaded_pieces, download_complete, piece_length)
      @socket = socket
      @file_savers = file_savers
      @downloaded_pieces = downloaded_pieces
      @requested_pieces = Set.new
      @mutex = Mutex.new
      @download_complete = download_complete
      @piece_length = piece_length
      @received_pieces = []
      @pieces = []
    end

    def handle_choke(_payload)
      puts "Received choke"
      sleep(5)
      handle_interested(nil, sending: true)
    end

    def handle_unchoke(_payload)
      puts "Received unchoked"
      return if file_savers.all?(&:downloaded)

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
        @request_length = 16_384
        @available_pieces.each_with_index do |_available_piece, i|
          @offset = 0
          piece_index = i
          length_prefix = [13].pack("N")
          message_id = [6].pack("C")

          until @offset >= @piece_length
            payload = [piece_index, @offset, @request_length].pack("N*")
            packet = length_prefix + message_id + payload

            socket.send(packet, 0)

            puts "Requested piece #{piece_index} from offset #{@offset}"
            @offset += @request_length
          end

          requested_pieces.add(piece_index)
        end
      else
        puts "Received request"
      end
    end

    def handle_piece(payload)
      puts "Received piece"
      piece_index, begin_offset = payload.unpack("N2")
      block_data = payload[8..]
      existing_piece = @received_pieces.find { |piece| piece_index == piece&.piece_index }
      if existing_piece
        existing_piece.blocks = { begin_offset: begin_offset,
                                  block_data: block_data }
      else
        @received_pieces << Piece.new([{ begin_offset: begin_offset, block_data: block_data }], piece_index)
      end

      file_savers.each do |file_saver|
        file_saver.save_block(piece_index, begin_offset, block_data, @received_pieces)
      end

      mutex.synchronize do
        downloaded_pieces.add(piece_index)
      end
    end

    def handle_cancel(payload)
      puts "Received cancel: #{payload.unpack1("B*")}"
    end
  end
end
