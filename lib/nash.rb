# Simulate a 2 player Nash game
require 'bigdecimal'
require 'bigdecimal/math'

include BigMath

class NashUtility
  attr_accessor :dev
  
  def initialize(q_A, q_B, n, t, dev)
    @q_A = BigDecimal.new(q_A.to_f.to_s)
    @q_B = BigDecimal.new(q_B.to_f.to_s)
    @n = BigDecimal.new(n.to_f.to_s)
    @t = BigDecimal.new(t.to_f.to_s)
    @dev = BigDecimal.new(dev.to_f.to_s)
  end
  
  def utility(p_i, p_j)
    p_i, p_j = BigDecimal.new(p_i.to_f.to_s), BigDecimal.new(p_j.to_f.to_s)
    @q_A * @n * (p_i)/(p_i+p_j) * log((p_i+p_j)*@t, 30) + @q_B * @n * (1-p_i)/(2-p_i-p_j) * log((2-p_i-p_j)*@t, 30)
  end
  
  def deviate(p_i, p_j)
    if utility(p_i+@dev, p_j) > utility(p_i, p_j)
      return :increase
    elsif utility(p_i-@dev, p_j) > utility(p_i, p_j)
      return :decrease
    else
      return :no_change
    end
  end
  
end

# Attempt to maximize utilities of u1 and u2 (social welfare max)
# Very very slow
def max_utilities(u1, u2)
  # puts u1.utility(0.62, 0.62) + u2.utility(0.62, 0.62)
  max_p_i, max_p_j, max_val = 0.0, 0.0, BigDecimal.new("0.0")
  maxy, dev = 1.0, 0.001
  p_i, p_j = 0.001, 0.001
  while p_i <= maxy
    p_j = 0.001
    while p_j <= maxy
      new_u = u1.utility(p_i, p_j) + u2.utility(p_j, p_i)
      if new_u > max_val
        max_val = new_u
        max_p_i, max_p_j = p_i, p_j
      end
      p_j += dev
    end
    p_i += dev
  end
  [max_p_i, max_p_j, max_val]
end

if __FILE__ == $0
  
  p_i, p_j = 0.428571, 0.428571
  q_A, q_B = 0.3, 0.4
  
  dev = 0.001
  
  a = NashUtility.new(q_A, q_B, 100, 100, dev)
  b = NashUtility.new(q_A, q_B, 100, 100, dev)
  
  # puts a.utility(0.4132892437, 0.4132892437)  + b.utility(0.4132892437, 0.4132892437)
  # puts a.utility(0.428571, 0.428571)  + b.utility(0.428571, 0.428571)
  
  #puts max_utilities(a, b)
  
  10000.times do
    dev_reduce, dev_reduce2 = false, false
    
    case a.deviate(p_i, p_j)
    when :increase
      p_i += dev if p_i+dev <= 1.0
    when :decrease
      p_i -= dev if p_i-dev >= 0.0
    when :no_change
      dev_reduce = true
    end
    
    case a.deviate(p_j, p_i)
    when :increase
      p_j += dev if p_j+dev <= 1.0
    when :decrease
      p_j -= dev if p_j-dev >= 0.0
    when :no_change
      dev_reduce2 = true
    end
    
    if dev_reduce && dev_reduce2
      dev /= 10.0
      a.dev /= BigDecimal.new('10.0')
      b.dev /= BigDecimal.new('10.0')
    end
    
    puts "a: %.10f, b: %.10f" % [p_i, p_j]
    
  end
  
end