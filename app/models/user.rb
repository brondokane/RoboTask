# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  session_token   :string           not null
#  bio             :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  fname           :string           not null
#  lname           :string           not null
#

class User < ActiveRecord::Base
  validates :password_digest, :session_token, :fname, :lname, presence: true
  validates :email, uniqueness: true
  validate :email_valid
  validates :password, length: { minimum: 6, allow_nil: true }

  attr_reader :password

  has_many(:created_tasks,
    class_name: "Task",
    foreign_key: :creator_id,
    primary_key: :id
  )

  has_many(:worked_tasks,
    class_name: "Task",
    foreign_key: :worker_id,
    primary_key: :id
  )

  has_many(:work_times)

  after_initialize :ensure_session_token!

  def self.find_by_credentials(email, password)
    @user = User.find_by_email(email)
    @user && @user.valid_password?(password) ? @user : nil
  end

  def self.workers
    User.joins(:time_slices).group(:id)
  end

  def valid_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def password=(password)
    @password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def reset_session_token!
    self.session_token = SecureRandom.urlsafe_base64(16)
    self.save!
    self.session_token
  end

  def workable_tasks(tasks)
    schedule = WorkTime.schedule_hash(self.work_times)
    tasks.to_a.select { |task| task.is_workable?(schedule) }
  end

  def nickname
    "#{fname} #{lname[0]}."
  end

  private

  def ensure_session_token!
    self.session_token ||= SecureRandom.urlsafe_base64(16)
  end

  def email_valid
    unless email.match(/\w+@\w+(\.\w+)+/)
      errors.add(:email, "Please provide a valid email address.")
    end
  end
end
