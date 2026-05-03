# == Schema Information
#
# Table name: library_exercises
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  video_url   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
class LibraryExercise < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :video_url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL"}, allow_blank: true

  scope :alphabetical, -> { order(Arel.sql("LOWER(name) ASC")) }

  def attributes_for_exercise
    slice("name", "video_url", "description")
  end
end
