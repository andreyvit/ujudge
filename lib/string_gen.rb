
class String
  def self.random_string(len)
    result = ""
    len.times { result << (?a + rand(26)).chr }
    return result
  end
  
  def self.desimilarity(a, b)
    # TODO: replace with a dynamic O(N^2) algortihm
    return 100 unless a.size == b.size
    changes = 0
    0.upto(a.size-1) { |i| changes += 1 if a[i] != b[i] }
    return changes
  end
end
