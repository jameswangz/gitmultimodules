
module ResultAnalyzer
	
	def analyze_multiple_commits(raw_data)
		raw_data = %Q{
commit e089627dea996a74aac73943694e7a40636d2968
Author: James Wang <jameswangz81@gmail.com>
Date:   Tue Mar 27 17:34:41 2012 +0800

    change 4

commit 0ca0a733e1471319e70ff37dc91f9445130a4e51
Author: James Wang <jameswangz81@gmail.com>
Date:   Tue Mar 27 17:34:35 2012 +0800

    change 3
		}	

		array = raw_data.scan(/commit\s+(.*)\s*Author:\s+(.*)\s*Date:\s+(.*)\s*(.*)/)
		array.each { |e| puts "#{e}" }
		array
	end	
end

class Tester

		include ResultAnalyzer

end


if __FILE__ == $0
	
		Tester.new.analyze_multiple_commits ''

end		

