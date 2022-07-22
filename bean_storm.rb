
require './parser.rb'

class BeanStorm
	def initialize
		@parser = BeanStormParser.new.parser
		@parser.logger.level = Logger::WARN
	end

	def program
		for arg in ARGV
			@parser.parse "load #{arg}"
			puts "Loaded #{arg}"
		end

		puts if ARGV.length > 0

		puts "Welcome to Bean Storm!\nHow have you bean?"
		while true
			print ">> "
			str = $stdin.gets
			begin
				result = @parser.parse str
			rescue Exception => error
				puts "\n#{"-"*(error.to_s.length/2-2)}Error#{"-"*(error.to_s.length/2-2)}"
				puts error.to_s + "\n\n"
				result = nil
			end
				puts result if result && result.class != Load		
	    end
	end
end

BeanStorm.new.program