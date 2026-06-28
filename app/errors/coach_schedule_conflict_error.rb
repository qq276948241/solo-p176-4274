class CoachScheduleConflictError < ApiError
  def initialize(message = '该时段教练已有排班')
    super(message, status: 409, code: 'coach_schedule_conflict')
  end
end
