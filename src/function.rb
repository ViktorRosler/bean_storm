

class Func_Def

	attr_reader :name

	def initialize(type, name, params, stmts)
		@type, @name, @params, @stmts = type, name, params, stmts
	end

	def eval(to_scope = true)
		func_def = [@type, @params, @stmts]
		@params ? param_key = @params.get_param_key : param_key = ""
		if to_scope
			@params ? param_key = @params.get_param_key : param_key = ""
			add_func_to_scope(@name, param_key, func_def)
		else
			return [func_def, param_key, @name]
		end
	end

end

class Func_Params

	attr_reader :type, :name, :params

	def initialize(type, name, params = nil)
		@type, @name, @params = type, name, params
	end

	def get_param_key
		key = @type
		params = @params
		while(params)
			key += " " + params.type
			params = params.params
		end
		return key
	end
end


class Func_Call

	attr_reader :name

	def initialize(name, args = nil)
		@name, @args = name, args
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def get_obj
		@args != nil ? param_key = @args.get_param_keys : param_key = ""
		func_def = get_func_from_scope(@name, param_key)
		type, params, stmts = func_def[0], func_def[1], func_def[2]

		if params != nil
			create_func_call_scope(@name,params,@args)
		else
			$scopes << {:@scope_type => :func}
		end

		result = stmts.eval
		$scopes.delete_at(-1)
		

		if result.class == Control_Stmt && result.stmt == "return"
		   	if result.return_obj != nil
		   		type_check(func_def[0], result.return_obj.eval)
		   		return result.return_obj 
		   	end
		end

		return Data_Obj.new(type, 0) if type == "int"
		return Data_Obj.new(type, 0.0) if type == "float"
		return Data_Obj.new(type, false) if type == "bool"
		return Data_Obj.new(type, "") if type == "string"
		return Data_Obj.new(type, []) if type == "list"
		return Data_Obj.new(type, nil) if type == "void"
		return Class_Obj.new(type)
	end

	def eval
		return get_obj.eval
	end
end

class Func_Args

	attr_reader :object, :args

	def initialize(object, args = nil, reference = false)
		@object, @args, @reference = object, args, reference
		@array = nil
	end

	def add_obj_to_array(object)
		if @reference
			@array << object
		else
			if object.class == Class_Obj
				@array << Marshal.load(Marshal.dump(object))
			else
				@array << object.clone
			end
		end
	end

	def to_array
		return @array if @array != nil
		@array = []
		add_obj_to_array(@object.get_obj)
		args = @args
		while(args)
			add_obj_to_array(args.object.get_obj)
			args = args.args
		end
		return @array
	end

	def get_param_keys
		key = ""
		for arg in to_array
			key += " " if key != ""
			key += arg.type
		end
		@array = nil
		return key
	end

end