
$classes = Hash.new

class Class_Def

	def initialize(name, stmts, parent = nil)
		@name, @stmts, @parent = name, stmts, parent
	end

	def eval
		raise "class #{@name} is defined twice" if $classes[@name] != nil

		if @parent != nil
			if $classes[@parent] == nil
				raise "#{@name}'s parent #{@parent} is not defined" 
			end
			class_scope, instance_stmts, constructors = $classes[@parent].clone
		else
			class_scope = {:@scope_type => :class_func}
			instance_stmts = []
			constructors = []
		end

		for stmt in @stmts.to_array
			if stmt.class == Func_Def 
				func = stmt.eval(false)	
				class_scope[func[2]] = Hash.new if class_scope[func[2]] == nil
				class_scope[func[2]][func[1]] = func[0]
			elsif stmt.class == Static_Variable
				var = stmt.eval
				class_scope[var[0]] = var[1] 
			elsif stmt.class == Constructor
				if stmt.name != @name
					raise "invalid constructor name #{stmt.name} in class #{@name}"
				end
				constructors << stmt
			elsif stmt.class == Declare_Variable || stmt.class == Declare_Class_Variable
				instance_stmts << stmt
			end
		end

		$classes[@name] = [class_scope, instance_stmts, constructors]
		
	end

end

class Declare_Class_Variable

	attr_reader :name

	def initialize(type, name, args = nil, value = nil, reference = false)
		@type, @name, @args, @value, @reference = type, name, args, value, reference
	end

	def eval(to_scope = true)

		if @value != nil
			value = @value.get_obj
			if value.class == Class_Obj
				type_check(@type, value.type)
				if @reference
					obj = value
				else
					obj = Marshal.load(Marshal.dump(value))
				end
			else
				raise "invalid declaration: #{@type} #{@name} = #{value.type}"
			end
		else
			obj = Class_Obj.new(@type)
			if @args == ""
				obj.construct(nil)
			elsif @args != nil
				obj.construct(@args)
			end
		end

		add_var_to_scope(@name, obj) if to_scope
		return obj
	end
end

class Class_Obj

	attr_reader :type
	attr_accessor :scope

	def initialize(type)
		@type = type
		@instantiated = false
		@scope = {:@scope_type => :class}
	end

	def instantiate
		return if @instantiated
		instance_stmts = $classes[@type][1]
		for stmt in instance_stmts
			obj = stmt.eval(false)
			@scope[stmt.name] = obj
		end
		@instantiated = true
	end

	def construct(args)
		instantiate
		$scopes << @scope
		$scopes << $classes[@type][0]
		$scopes << {:@scope_type => :class_func}
		constructors = $classes[@type][2]
		for stmt in constructors
			func_def = stmt.eval
			$scopes[-1][func_def[2]] = Hash.new if $scopes[-1][func_def[2]] == nil
			$scopes[-1][func_def[2]][func_def[1]] = func_def[0]
		end
		Func_Call.new(@type, args).eval
		$scopes = $scopes[0..-4]
 	end

 	def get_member(name)
 		return @scope[name] if @scope[name] != nil
 		raise "Invalid member access #{@type}.#{name}"
 	end

 	def set_member(name, obj, op, reference = false)
 		instantiate
 		if @scope[name] != nil
 			type_check(@scope[name].type, obj.eval)
 			if reference
 				@scope[name] = obj
 			else
 				assign(@scope[name], op, obj)
 			end
 		elsif $classes[@type][0][name] != nil && $classes[@type][0][name].class != Hash
 			type_check($classes[@type][0][name].type, obj.eval)
 			if reference
 				$classes[@type][0][name] = obj
 			else
 				assign($classes[@type][0][name], op, obj)
 			end
 		else
 			raise "Invalid member access #{@type}.#{name}"
 		end
	end

	def to_string
		return @type
	end

	def truth_value
		return @instantiated
	end

	def get_obj
		instantiate
		return self
	end

	def eval
		return @type
	end

	def get_obj_with_instance_scope(stmt)
		instantiate
		$scopes << @scope
		$scopes << $classes[@type][0]
		obj = stmt.get_obj
		$scopes = $scopes[0..-3]
		return obj
	end

end

class Constructor

	attr_reader :name

	def initialize(name, params, stmts)
		@name = name
		@constructor = Func_Def.new("void", name, params, stmts)
	end

	def eval
		return @constructor.eval(false)
	end
end

class Static_Variable

	attr_reader :name

	def initialize(stmt)
		@stmt = stmt
	end

	def eval
		return [@stmt.name, @stmt.eval(false)]
	end
end


class Member_Access

	attr_reader :name, :member

	def initialize(name, member)
		@name, @member = name, member
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def type_check(obj)
		if obj.class != Class_Obj
			raise "Invalid member access #{@name}.#{@member.name}"
		end 
	end

	def get_obj(get_class_obj = false)
		class_obj = get_var_from_scope(@name)
		type_check(class_obj)
		class_obj.instantiate
		member = @member
		name = @member.name if get_class_obj
		while (member.class == Member_Access)
			class_obj = class_obj.get_member(member.name)
			type_check(class_obj)
			class_obj.instantiate
			member = member.member
			name = member.name if get_class_obj
		end
		if get_class_obj
			return [class_obj, name]
		else
			return class_obj.get_obj_with_instance_scope(member)
		end
	end

	def eval
		return get_obj.eval
	end
end

class Member_Assign

	attr_reader :object

	def initialize(member_access, object, op, reference = false)
		@member_access, @object = member_access, object
		@op, @reference = op, reference
	end

	def eval
		class_obj, name = @member_access.get_obj(true)
		class_obj.set_member(name, @object.get_obj, @op, @reference)
	end

end
