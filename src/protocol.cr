require "socket"

module Network
    module Protocol
        MAGIC       = 0xB007_u16
        VERSION     = 0x01_u8
        HEADER_SIZE = 16
        MAX_PAYLOAD = 1 << 20 # 1 MiB
        
        class ProtoError < Exception; end

        enum Opcode : UInt8
            Get         = 0x01
            Send        = 0x02
            GetReply    = 0xB1
            SendAck     = 0x82
        end

        enum Status : UInt8
            Ok                  = 0x00
            NotFound            = 0x01
            BadRequest          = 0x02
            PayloadTooLarge     = 0x03
            UnsupportedVersion  = 0x04
            UnknownOpcode       = 0x05
            Internal            = 0x06
        end

        record Message,
            opcode      : Opcode,
            status      : Status,
            request_id  : UInt32,
            payload     : Bytes

        record Response,
            opcode  : Opcode,
            status  : Status,
            payload : Bytes

        
        def self.read_message(io : IO) : Message?
            first = io.read_byte
            raise IO::EOFError.new if first.nil?

            rest = Bytes.new(HEADER_SIZE - 1)
            io.read_fully(rest)

            buf = IO::Memory.new(HEADER_SIZE)
            buf.write_byte(first)
            buf.write(rest)
            buf.rewind

            magic = buf.read_bytes(UInt16, IO::ByteFormat::BigEndian)
            raise ProtoError.new("bad MAGIC") unless magic === MAGIC

            version = buf.read_byte.not_nil!
            raise ProtoError.new("unsupported version #{version}") unless version === VERSION

            opcode_byte = buf.read_byte.not_nil!
            opcode = Opcode.from_value?(opcode_byte) ||
                raise ProtoError.new("unknown opcode")
            
            status_byte = buf.read_byte.not_nil!
            status = Status.from_value?(status_byte) || Status::Internal

            buf.skip(1)
            buf.skip(2)

            request_id = buf.read_bytes(UInt32, IO::ByteFormat::BigEndian)
            payload_len = buf.read_bytes(UInt32, IO::ByteFormat::BigEndian)

            if payload_len > MAX_PAYLOAD
                raise ProtoError.new("payload out of size: #{payload_len}")
            end

            payload = if payload_len == 0
                Bytes.empty
            else
                slice = Bytes.new(payload_len.to_i)
                io.read_fully(slice)
                slice
            end

            Message.new(opcode, status, request_id, payload)
        end

        def self.write_frame(io : IO,
                            opcode : Opcode,
                            request_id : UInt32,
                            payload : Bytes = Bytes.empty,
                            status : Status = Status::Ok) : Nil
            if payload.size > MAX_PAYLOAD
                raise ArgumentError.new("payload out of size: #{payload.size}")
            end

            io.write_bytes(MAGIC, IO::ByteFormat::BigEndian)
            io.write_byte(VERSION)
            io.write_byte(opcode.value)
            io.write_byte(status.value)
            io.write_byte(0_u8)
            io.write_bytes(0_u16, IO::ByteFormat::BigEndian)
            io.write_bytes(request_id, IO::ByteFormat::BigEndian)
            io.write_bytes(payload.size.to_u32, IO::ByteFormat::BigEndian)
            io.write(payload) unless payload.empty?
            
            io.flush
        end
    end
end