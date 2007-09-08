class Judge::Client::DiffChecker
  
  def normalize(text)
    text.strip.gsub("\r", '').split("\n").collect do |line|
      line.gsub(/\s+/, ' ').strip
    end.join("\n")
  end

  def check(test, input_path, output_path, wdir, invoker, vfs)

    answer_path = vfs.get(test.answer_file)
    
    otext = File.open(output_path, 'r') { |f| f.read }
    atext = File.open(answer_path, 'r') { |f| f.read }
    
    otext = normalize(otext)
    atext = normalize(atext)
    
    r = Judge::Client::CheckingResult.new
    r.status = :ok
    r.outcome = if otext == atext then :ok else :wa end
    r.comment = ""
    return r
  end
end
