

class Condition

	def initialize(lh, op, rh)
		@lh, @op, @rh = lh, op, rh
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return eval
	end

	def get_obj
		if @op == "&&"
			value = @lh.truth_value && @rh.truth_value
		elsif @op == "||"
			value = @lh.truth_value || @rh.truth_value
		else
			begin
				value = @lh.eval == @rh.eval if @op == "=="
				value = @lh.eval != @rh.eval if @op == "!="
				value = @lh.eval <= @rh.eval if @op == "<="
				value = @lh.eval >= @rh.eval if @op == ">="
				value = @lh.eval < @rh.eval if @op == "<"
				value = @lh.eval > @rh.eval if @op == ">"
			rescue
				raise "#{@lh.get_obj.type} #{@op} #{@rh.get_obj.type} is an invalid condition"
			end
		end
		return Data_Obj.new("bool", value)
	end

	def eval
		return get_obj.eval
	end

end

class Not

	def initialize(condition)
		@condition = condition
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return eval
	end

	def get_obj
		value = @condition.truth_value
		return Data_Obj.new("bool", !value)
	end

	def eval
		return get_obj.eval
	end
end

class Binary_Expr

	def initialize(lh, op, rh)
		@lh, @op, @rh = lh, op, rh
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def get_obj
		lh = @lh.get_obj
		rh = @rh.get_obj
		if (lh.type == "int" || lh.type == "float") && (rh.type == "int" || rh.type == "float")
			if @op == '//'
				value = instance_eval("#{lh.eval.to_f}/#{rh.eval}").truncate
				return Data_Obj.new("int", value)
			else
				billion = 1000000000.0
				value = (instance_eval("#{lh.eval.to_f}#{@op}#{rh.eval}")*billion).round / billion
				if lh.type == "int" && rh.type == "int" && value == value.to_i
					return Data_Obj.new("int", value.to_i) 
				end
				return Data_Obj.new("float", value)
			end
		elsif lh.type == "string" && rh.type == "string" && @op == '+'
			value = lh.eval + rh.eval
			return Data_Obj.new("string", value)
		elsif lh.type == "list" && rh.type == "list" && @op == '+'
			value = lh.eval + rh.eval
			return Data_Obj.new("list", value)
		else
			raise "Invalid expression: #{lh.type} #{@op} #{rh.type}"
		end	
	end

	def eval
		return get_obj.eval
	end

end

class Unary_Expr

	def initialize(op, object)
		@op, @object = op, object
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def round_float(value)
		billion = 1000000000.0
		value = (value*billion).round / billion if value != value.to_i
		return value
	end

	def get_obj
		obj = @object.get_obj
		type_check("number", obj.eval)
		
		if @op == :-
			copy = obj.clone
			copy.value *= -1
		elsif @op == :pre_dec
			obj.value -= 1
			obj.value = round_float(obj.value)
			copy = obj.clone
		elsif @op == :post_dec
			copy = obj.clone
			obj.value -= 1
			obj.value = round_float(obj.value)
		elsif @op == :pre_inc
			obj.value += 1
			obj.value = round_float(obj.value)
			copy = obj.clone
		elsif @op == :post_inc
			copy = obj.clone
			obj.value += 1
			obj.value = round_float(obj.value)
		end

		return copy
	end

	def eval
		return get_obj.eval
	end
end
