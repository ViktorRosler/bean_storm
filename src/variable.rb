
def type_check(type, value)
	if type == "int" 
		if value.class != Integer
			raise "Invalid Type: #{value} is not an integer"
		end
	elsif type == "float" 
		if value.class != Integer && value.class != Float 
			raise "Invalid Type: #{value} is not a float"
		end
	elsif type == "number" 
		if value.class != Integer && value.class != Float 
			raise "Invalid Type: #{value} is not a number"
		end
	elsif type == "bool" 
		if value != true and value != false
			raise "Invalid Type: #{value} is not a bool"
		end
	elsif type == "string"
		if value.class != String
			raise "Invalid Type: #{value} is not a string"
		end
	elsif type == "list" 
		if value.class != Array
			raise "Invalid Type: #{value} is not a list"
		end
	elsif type == "void"
		raise "Invalid Type: #{value} is set to void"
	elsif type != value
		raise "Invalid type: #{value} is not a(n) #{type}"
	end
end

def assign(lh, op, rh)
	if lh.class == Data_Obj && rh.class == Data_Obj
		if op == "="
			lh.value = rh.value
			return
		else
			begin
				lh.value = Binary_Expr.new(lh, op[0..-2], rh).eval
				return
			rescue 
				raise "Invalid assignment #{lh.type} #{op} #{rh.type}"
			end
		end	
	elsif lh.class == Class_Obj && rh.class == Class_Obj
		if op == "=" && lh.type == rh.type
			lh.instantiate
			lh.scope = Marshal.load(Marshal.dump(rh.scope))
			return
		end
	end

	raise "Invalid assignment #{lh.type} #{op} #{rh.type}"
end

class Declare_Variable

	attr_reader :type, :name

	def initialize(type, name, object = nil, reference = false)
		@type, @name, @object, @reference = type, name, object, reference
	end

	def default_object
		case @type
		when "int"
			return Data_Obj.new(@type, 0)
		when "float"
			return Data_Obj.new(@type, 0.0)
		when "bool"
			return Data_Obj.new(@type, false)
		when "string"
			return Data_Obj.new(@type, "")
		when "list"
			return Data_Obj.new(@type, [])
		when "auto"
			raise "Variable #{@name} is not assigned a value."
		end	
	end

	def eval(to_scope = true)
		@object == nil ? obj = default_object : obj = @object.get_obj
		obj.eval if @type == "list"
		@type = obj.type if @type == "auto"
		type_check(@type, obj.value)
		obj = Data_Obj.new(@type, obj.eval) if !@reference
		add_var_to_scope(@name, obj) if to_scope
		return obj
	end

end


class Assign_Variable

	def initialize(name, op, object, reference = false)
		@name, @op, @object, @reference = name, op, object, reference
	end

	def eval
		obj = @object.get_obj
		var = get_var_from_scope(@name)
		type_check(var.type, obj.eval)
		@reference ? set_var_in_scope(@name, obj) : assign(var, @op, obj)	
	end
end

class Retrieve_Variable

	attr_reader :name

	def initialize(name)
		@name = name
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def get_obj
		return get_var_from_scope(@name)
	end

	def eval
		return get_obj.eval
	end
end