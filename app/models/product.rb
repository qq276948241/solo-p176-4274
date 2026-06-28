class Product < ApplicationRecord
  CATEGORIES = %w[器材 补剂 服饰 配件 课程].freeze
  CONDITIONS = %w[new like_new good fair].freeze
  STATUSES = %w[active inactive].freeze

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :condition, presence: true, inclusion: { in: CONDITIONS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(status: 'active') }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_condition, ->(cond) { where(condition: cond) }
  scope :recent, -> { order(published_at: :desc) }
  scope :published, -> { where.not(published_at: nil) }

  before_create :set_published_at

  def active?
    status == 'active'
  end

  def published?
    published_at.present?
  end

  private

  def set_published_at
    self.published_at ||= Time.current if active?
  end
end
