
class Control_Stmt

	attr_reader :stmt, :return_obj

	def initialize(stmt, value = nil)
		@stmt, @value = stmt, value
	end

	def eval
		@return_obj = @value.get_obj if @value != nil
		return self
	end

end

class Nested_Stmts

	attr_reader :stmt, :stmts

	def initialize(stmt, stmts)
		@stmt, @stmts = stmt, stmts
	end

	def to_array
		array = [@stmt]
		stmts = @stmts
		while(stmts)
			array << stmts.stmt
			stmts = stmts.stmts
		end

		return array
	end

	def eval
		result = @stmt.eval if @stmt != :end_of_line
		return result if result.class == Control_Stmt
		@stmts.eval if @stmts
	end

end

class If

	def initialize(condition, stmts, elif_else = nil)
		@condition, @stmts, @elif_else = condition, stmts, elif_else
	end

	def eval
		if @condition.truth_value
			$scopes << {:@scope_type => :control}
			result = @stmts.eval
			$scopes.delete_at(-1)
			return result
		elsif @elif_else
			@elif_else.eval
		end
	end

end

class While

	def initialize(condition, stmts)
		@condition, @stmts = condition, stmts
	end

	def eval
		while @condition.truth_value
			$scopes << {:@scope_type => :control}
			result = @stmts.eval
			$scopes.delete_at(-1)
			break if result.class == Control_Stmt && result.stmt == "break"
		end
		return result
	end

end

class For

	def initialize(for_expr, stmts)
		@var, @condition, @expr = for_expr[0], for_expr[1], for_expr[2]
		@stmts = stmts
	end

	def eval

		@var.class == Declare_Variable ? obj = @var.eval(false) : obj = nil

		while true
			$scopes << {:@scope_type => :control}
			add_var_to_scope(@var.name, obj) if obj != nil
			break if !@condition.truth_value
			result = @stmts.eval
			break if result.class == Control_Stmt && result.stmt == "break"
			@expr.eval if @expr != nil
			$scopes.delete_at(-1)
		end
		$scopes.delete_at(-1)
		return result
	end

end