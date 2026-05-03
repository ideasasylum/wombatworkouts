require "securerandom"

module Garmin
  module FitEncoder
    class TooManyStepsError < StandardError
      attr_reader :step_count

      def initialize(step_count)
        @step_count = step_count
        super("Garmin Connect supports at most #{MAX_STEPS} steps per workout (got #{step_count})")
      end
    end

    # FIT epoch: 1989-12-31 00:00:00 UTC.
    FIT_EPOCH = Time.utc(1989, 12, 31).to_i

    # Garmin Connect importer rejects workouts with more than 50 steps.
    MAX_STEPS = 50

    # FIT base types — id is what gets written into the definition record.
    BASE_TYPE = {
      enum: {id: 0x00, size: 1, pack: "C"},
      uint8: {id: 0x02, size: 1, pack: "C"},
      string: {id: 0x07, size: 1, pack: nil},
      uint16: {id: 0x84, size: 2, pack: "v"},
      uint32: {id: 0x86, size: 4, pack: "V"},
      uint32z: {id: 0x8C, size: 4, pack: "V"}
    }.freeze

    # Global message numbers.
    MESG = {file_id: 0, workout: 26, workout_step: 27, exercise_title: 264}.freeze

    # Local message type slots (4 bits each, 0..15).
    LOCAL = {file_id: 0, workout: 1, workout_step: 2, exercise_title: 3}.freeze

    # Field layout per message: [field_def_num, size_in_bytes, base_type_key].
    # The order written here is the byte order in the data record.
    # Field numbers verified against @garmin/fitsdk 21.202 profile.js.
    FIELDS = {
      file_id: [
        [0, 1, :enum],   # type
        [1, 2, :uint16], # manufacturer
        [2, 2, :uint16], # product
        [3, 4, :uint32z], # serial_number
        [4, 4, :uint32]  # time_created
      ],
      workout: [
        [254, 2, :uint16], # message_index
        [4, 1, :enum],   # sport
        [5, 4, :uint32z], # capabilities
        [6, 2, :uint16], # num_valid_steps
        [11, 1, :enum]    # sub_sport
        # wkt_name (field 8) is appended dynamically because string size varies.
      ],
      workout_step: [
        [254, 2, :uint16], # message_index
        [1, 1, :enum],   # duration_type
        [2, 4, :uint32], # duration_value
        [3, 1, :enum],   # target_type
        [7, 1, :enum],   # intensity
        [10, 2, :uint16], # exercise_category
        [11, 2, :uint16]  # exercise_name
        # wkt_step_name (field 0) is appended dynamically.
      ],
      exercise_title: [
        [254, 2, :uint16], # message_index
        [0, 2, :uint16], # exercise_category
        [1, 2, :uint16] # exercise_name
        # wkt_step_name (field 2) is appended dynamically.
      ]
    }.freeze

    # Wkt name and step name fields are strings whose size depends on the input.
    # We pad each to a fixed budget per record to keep definitions stable.
    WKT_NAME_SIZE = 32
    STEP_NAME_SIZE = 32
    EXERCISE_TITLE_SIZE = 64

    # Enum values.
    SPORT_TRAINING = 10
    SUB_SPORT_STRENGTH = 20
    DURATION_REPS = 29
    TARGET_OPEN = 2
    INTENSITY_ACTIVE = 0
    FILE_TYPE_WORKOUT = 5
    MANUFACTURER_DEVELOPMENT = 255
    EXERCISE_CATEGORY_UNKNOWN = 65534

    module_function

    def encode_program(program)
      step_count = program.exercises.sum(&:repeat_count)
      raise TooManyStepsError.new(step_count) if step_count > MAX_STEPS

      body = String.new(encoding: Encoding::ASCII_8BIT)

      body << definition_record(:file_id, FIELDS[:file_id])
      body << data_record(:file_id, FIELDS[:file_id], file_id_values)

      workout_fields = FIELDS[:workout] + [[8, WKT_NAME_SIZE, :string]]
      body << definition_record(:workout, workout_fields)
      body << data_record(:workout, workout_fields, workout_values(program, step_count))

      step_fields = FIELDS[:workout_step] + [[0, STEP_NAME_SIZE, :string]]
      body << definition_record(:workout_step, step_fields)

      title_fields = FIELDS[:exercise_title] + [[2, EXERCISE_TITLE_SIZE, :string]]
      title_def_emitted = false

      step_index = 0
      program.exercises.order(:position).each do |exercise|
        category, name = ExerciseMapping.lookup(exercise.name)

        if category == EXERCISE_CATEGORY_UNKNOWN
          unless title_def_emitted
            body << definition_record(:exercise_title, title_fields)
            title_def_emitted = true
          end
          name = step_index # synthetic exercise_name id, scoped to category=unknown
          body << data_record(:exercise_title, title_fields, exercise_title_values(name, exercise.name))
        end

        exercise.repeat_count.times do |set_idx|
          step_name = "#{exercise.name} #{set_idx + 1}/#{exercise.repeat_count}"
          values = workout_step_values(step_index, step_name, exercise.reps, category, name)
          body << data_record(:workout_step, step_fields, values)
          step_index += 1
        end
      end

      header = file_header(body.bytesize)
      payload = header + body
      crc = Crc16.compute(payload)
      payload + [crc].pack("v")
    end

    # 14-byte FIT header: size, protocol_version, profile_version (uint16 LE),
    # data_size (uint32 LE), ".FIT" (4 bytes), header CRC (uint16 LE).
    def file_header(data_size)
      profile_version = 21 * 1000 + 202
      bytes = String.new(encoding: Encoding::ASCII_8BIT)
      bytes << [14, 0x02, profile_version].pack("CCv")
      bytes << [data_size].pack("V")
      bytes << ".FIT".b
      header_crc = Crc16.compute(bytes)
      bytes << [header_crc].pack("v")
      bytes
    end

    # Definition record: 0x40|local_msg_type, reserved, architecture(LE=0),
    # global_msg_num (uint16 LE), num_fields, then num_fields × (field_num, size, base_type_id).
    def definition_record(kind, fields)
      out = String.new(encoding: Encoding::ASCII_8BIT)
      out << [0x40 | LOCAL.fetch(kind), 0, 0, MESG.fetch(kind), fields.size].pack("CCCvC")
      fields.each do |fdn, size, base_key|
        out << [fdn, size, BASE_TYPE.fetch(base_key)[:id]].pack("CCC")
      end
      out
    end

    # Data record: local_msg_type (no MSB, no def bit), then field bytes in definition order.
    def data_record(kind, fields, values)
      out = String.new(encoding: Encoding::ASCII_8BIT)
      out << [LOCAL.fetch(kind)].pack("C")
      fields.each do |fdn, size, base_key|
        v = values.fetch(fdn)
        out << if base_key == :string
          str = v.to_s.b
          str = str[0, size - 1] if str.bytesize >= size
          str + ("\x00".b * (size - str.bytesize))
        else
          [v].pack(BASE_TYPE.fetch(base_key)[:pack])
        end
      end
      out
    end

    def file_id_values
      {
        0 => FILE_TYPE_WORKOUT,
        1 => MANUFACTURER_DEVELOPMENT,
        2 => 0,
        3 => SecureRandom.random_number(0xFFFFFFFE) + 1,
        4 => Time.now.to_i - FIT_EPOCH
      }
    end

    def workout_values(program, num_valid_steps)
      {
        254 => 0,
        4 => SPORT_TRAINING,
        5 => 0,
        6 => num_valid_steps,
        11 => SUB_SPORT_STRENGTH,
        8 => program.title.to_s
      }
    end

    def workout_step_values(message_index, name, reps, exercise_category, exercise_name)
      {
        254 => message_index,
        1 => DURATION_REPS,
        2 => reps,
        3 => TARGET_OPEN,
        7 => INTENSITY_ACTIVE,
        10 => exercise_category,
        11 => exercise_name,
        0 => name.to_s
      }
    end

    def exercise_title_values(name_id, title)
      {
        254 => name_id,
        0 => EXERCISE_CATEGORY_UNKNOWN,
        1 => name_id,
        2 => title.to_s
      }
    end
  end
end
