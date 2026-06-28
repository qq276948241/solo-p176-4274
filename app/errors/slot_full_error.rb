class SlotFullError < ApiError
  def initialize(message = '该时段已约满')
    super(message, status: 409, code: 'slot_full')
  end
end
