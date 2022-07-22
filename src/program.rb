

class Stmts


	def initialize(stmt, stmts)
		@stmt, @stmts = stmt, stmts
	end

	def eval

		if @stmt.class == Load
			@stmt.eval
			out = @stmt
		elsif @stmt == :end_of_line
			out = nil
		else 
			if @stmt.class.method_defined? :to_string
				out = @stmt.to_string
			else
				@stmt.eval
				out = nil
			end
		end

		if @stmts.class == Stmts 
		 	@stmts.eval 
		else
		  	return out
		end
	end
end

class Error

	attr_reader :token, :error

	def initialize(token, error = nil)
		@token, @error = token, error
	end

	def eval
		while(@error)
			@token += " " + @error.token.to_s
			@error = @error.error
		end

		raise "Invalid statement: #{@token}"
	end
end
