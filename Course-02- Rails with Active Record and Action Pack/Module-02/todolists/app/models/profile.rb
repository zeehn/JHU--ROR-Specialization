class Profile < ActiveRecord::Base
  belongs_to :user

  validates :gender, inclusion: { in: ['male', 'female']}
  validate :names_null_check
  validate :gender_name_check

  def names_null_check
    if first_name.nil? && last_name.nil?
      errors.add(:first_name, "Both first name and last name can't be null.")
    end
  end

  def gender_name_check
    if first_name == 'Sue' && gender == 'male'
      errors.add(:first_name, "A male can't have a first name Sue.")
    end
  end

  def self.get_all_profiles(min, max)
    where('birth_year BETWEEN ? AND ?', min, max).order(:birth_year)
  end
end
