require "test_helper"

class Garmin::FitEncoderTest < ActiveSupport::TestCase
  ExerciseStub = Struct.new(:name, :repeat_count, :reps, :position)

  class ProgramStub
    attr_reader :title, :exercises

    def initialize(title, exercises)
      @title = title
      @exercises = ExerciseRelation.new(exercises)
    end
  end

  class ExerciseRelation < SimpleDelegator
    def order(*) = self

    def sum(&block) = inject(0) { |acc, e| acc + block.call(e) }
  end

  def build_program(title:, exercises:)
    ProgramStub.new(title, exercises)
  end

  test "encodes a small strength program with valid CRC" do
    program = build_program(title: "Smoke", exercises: [
      ExerciseStub.new("Calf raises", 3, 10, 1)
    ])
    bytes = Garmin::FitEncoder.encode_program(program)

    assert_equal 0x0E, bytes.bytes[0], "header size should be 14"
    assert_equal 0x02, bytes.bytes[1], "protocol version should be 2"
    assert_equal ".FIT", bytes[8, 4]

    data_size = bytes[4, 4].unpack1("V")
    assert_equal bytes.bytesize - 14 - 2, data_size, "data_size matches body length"

    header_crc = bytes[12, 2].unpack1("v")
    assert_equal Garmin::FitEncoder::Crc16.compute(bytes[0, 12]), header_crc, "header CRC matches"

    file_crc = bytes[-2, 2].unpack1("v")
    assert_equal Garmin::FitEncoder::Crc16.compute(bytes[0..-3]), file_crc, "file CRC matches"
  end

  test "raises TooManyStepsError when total sets exceeds 50" do
    exercises = (1..6).map { |i| ExerciseStub.new("Exercise #{i}", 9, 10, i) } # 54 sets
    program = build_program(title: "Too big", exercises: exercises)
    err = assert_raises(Garmin::FitEncoder::TooManyStepsError) do
      Garmin::FitEncoder.encode_program(program)
    end
    assert_equal 54, err.step_count
  end

  test "boundary: exactly 50 steps is allowed" do
    exercises = [ExerciseStub.new("Squats", 50, 10, 1)]
    program = build_program(title: "Edge", exercises: exercises)
    bytes = Garmin::FitEncoder.encode_program(program)
    assert_operator bytes.bytesize, :>, 0
  end

  test "emits an exercise_title for every exercise, including mapped ones" do
    program = build_program(title: "Mixed", exercises: [
      ExerciseStub.new("Calf raises", 1, 10, 1),
      ExerciseStub.new("Mystery move", 1, 8, 2)
    ])
    bytes = Garmin::FitEncoder.encode_program(program)

    # exercise_title global msg num is 264 (uint16 LE = 0x08 0x01).
    title_def_marker = "\x00\x00\x08\x01".b
    assert_includes bytes, title_def_marker, "should emit exercise_title definition"

    # Both names should appear in the body as exercise_title text.
    assert_includes bytes, "Calf raises".b
    assert_includes bytes, "Mystery move".b
  end

  test "Crc16 matches reference vectors" do
    # Empty input → 0
    assert_equal 0, Garmin::FitEncoder::Crc16.compute("")
    # Self-consistency: header CRC should round-trip when re-computed with the appended CRC.
    sample = "abcdef".b
    crc = Garmin::FitEncoder::Crc16.compute(sample)
    assert_equal 0, Garmin::FitEncoder::Crc16.compute(sample + [crc].pack("v"))
  end
end

class Garmin::FitEncoder::ExerciseMappingTest < ActiveSupport::TestCase
  test "matches a known keyword" do
    category, _name = Garmin::FitEncoder::ExerciseMapping.lookup("Calf raises")
    assert_equal 1, category # calfRaise
  end

  test "case-insensitive substring match" do
    category, _name = Garmin::FitEncoder::ExerciseMapping.lookup("Heavy DEADLIFT day")
    assert_equal 8, category # deadlift
  end

  test "falls back to unknown for unmapped names" do
    category, name = Garmin::FitEncoder::ExerciseMapping.lookup("Mystery move")
    assert_equal Garmin::FitEncoder::EXERCISE_CATEGORY_UNKNOWN, category
    assert_equal 0, name
  end
end
