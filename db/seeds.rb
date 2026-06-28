puts '开始创建种子数据...'

unless Token.exists?
  token = Token.generate('初始测试Token', 365.days)
  puts "创建初始Token: #{token.token}"
  puts "请在请求头中使用: Authorization: Bearer #{token.token}"
end

Member.find_or_create_by!(phone: '13800138001') do |m|
  m.name = '张三'
  m.card_type = 'prepaid'
  m.remaining_sessions = 10
  m.status = 'active'
end
puts '创建次卡会员: 张三 (剩余10次)'

Member.find_or_create_by!(phone: '13800138002') do |m|
  m.name = '李四'
  m.card_type = 'monthly'
  m.monthly_start_date = Date.current
  m.monthly_end_date = Date.current + 1.month - 1.day
  m.status = 'active'
end
puts '创建月卡会员: 李四 (有效期内)'

Member.find_or_create_by!(phone: '13800138003') do |m|
  m.name = '王五'
  m.card_type = 'prepaid'
  m.remaining_sessions = 0
  m.status = 'active'
end
puts '创建次卡会员: 王五 (剩余0次)'

Member.find_or_create_by!(phone: '13800138004') do |m|
  m.name = '赵六'
  m.card_type = 'monthly'
  m.monthly_start_date = 2.months.ago.to_date
  m.monthly_end_date = 1.month.ago.to_date
  m.status = 'active'
end
puts '创建月卡会员: 赵六 (已过期)'

Coach.find_or_create_by!(phone: '13900139001') do |c|
  c.name = '王教练'
  c.specialty = '增肌、力量训练'
  c.status = 'active'
end
puts '创建教练: 王教练'

Coach.find_or_create_by!(phone: '13900139002') do |c|
  c.name = '李教练'
  c.specialty = '减脂、塑形'
  c.status = 'active'
end
puts '创建教练: 李教练'

Coach.find_or_create_by!(phone: '13900139003') do |c|
  c.name = '张教练'
  c.specialty = '康复、拉伸'
  c.status = 'inactive'
end
puts '创建教练: 张教练 (未激活)'

coaches = Coach.active.all
days = [0, 1, 2, 3, 4, 5, 6]
time_slots = [
  { start: '09:00', end: '10:00' },
  { start: '10:00', end: '11:00' },
  { start: '14:00', end: '15:00' },
  { start: '15:00', end: '16:00' },
  { start: '16:00', end: '17:00' },
  { start: '19:00', end: '20:00' },
  { start: '20:00', end: '21:00' }
]

coaches.each do |coach|
  week_start = Date.current.beginning_of_week

  days.each do |day_offset|
    next if rand > 0.7

    date = week_start + day_offset.days
    next if date < Date.current

    slots_for_day = time_slots.sample(rand(2..4))
    slots_for_day.each do |slot|
      CoachSchedule.find_or_create_by!(
        coach: coach,
        date: date,
        start_time: slot[:start],
        end_time: slot[:end]
      ) do |s|
        s.status = 'available'
        s.max_bookings = 1
      end
    end
  end
end
puts "为教练创建了 #{CoachSchedule.count} 个排班"

products_data = [
  { title: '可调节哑铃套装', description: '专业级可调节哑铃，2-24kg自由切换，适合家庭健身', category: '器材', condition: 'new', price: 599.00 },
  { title: '乳清蛋白粉', description: '高效增肌补剂，巧克力口味，每桶2.5kg', category: '补剂', condition: 'new', price: 299.00 },
  { title: '瑜伽垫', description: '加厚防滑瑜伽垫，6mm厚度，适合瑜伽和拉伸训练', category: '配件', condition: 'new', price: 89.00 },
  { title: '速干运动T恤', description: '透气速干面料，适合高强度训练', category: '服饰', condition: 'new', price: 129.00 },
  { title: '二手杠铃杆', description: '奥杠标准杠铃杆，20kg，轻微使用痕迹', category: '器材', condition: 'like_new', price: 450.00 },
  { title: 'BCAA支链氨基酸', description: '西瓜口味，训练中补充氨基酸防止肌肉流失', category: '补剂', condition: 'new', price: 159.00 },
  { title: '健身手套', description: '防滑透气健身手套，半指设计，保护手掌', category: '服饰', condition: 'good', price: 49.00 },
  { title: '弹力带套装', description: '5根不同阻力弹力带，适合拉伸和辅助训练', category: '配件', condition: 'new', price: 69.00 }
]

products_data.each do |attrs|
  Product.find_or_create_by!(title: attrs[:title]) do |p|
    p.description = attrs[:description]
    p.category = attrs[:category]
    p.condition = attrs[:condition]
    p.price = attrs[:price]
    p.status = 'active'
    p.published_at = rand(1..30).days.ago
  end
end
puts "创建了 #{Product.count} 个商品"

puts '种子数据创建完成!'
puts '=' * 50
puts '默认登录账号: admin / admin123'
puts '=' * 50
