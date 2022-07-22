
$scopes = [Hash.new]

$scope_stack = []

def access_scope(name, obj = nil, param_key = nil)
	i = $scopes.length-1
	only_class_or_global = false
	while (i >= 0)
		if only_class_or_global && i > 0 && $scopes[i][:@scope_type] != :class &&
		   $scopes[i][:@scope_type] != :class_func
			i -= 1
		elsif $scopes[i][name] != nil && $scopes[i][name].class != Hash
			if obj != nil
				$scopes[i][name] = obj
				return
			else
				return $scopes[i][name]
			end
		elsif $scopes[i][name].class == Hash && param_key != nil
			  if $scopes[i][name][param_key] != nil
			  	return $scopes[i][name][param_key]
			  end
			  i -= 1
		elsif $scopes[i][:@scope_type] == :func
			only_class_or_global = true
			i -= 1
		else
			i -= 1
		end
	end
	raise "#{name} is not defined"
end

def add_var_to_scope(name, obj)
	if $scopes[-1][name] == nil
		$scopes[-1][name] = obj
	else
		raise "#{name} is already defined"
	end
end

def get_var_from_scope(name)
	return access_scope(name)
end

def set_var_in_scope(name, obj)
	access_scope(name, obj)
end

def add_func_to_scope(name, param_key, func_def)
	if $scopes[0][name] == nil
		$scopes[0][name] = Hash.new 
	elsif $scopes[0][name].class != Hash
		raise "#{name} is already defined"
	end

	if $scopes[0][name][param_key] == nil
		$scopes[0][name][param_key] = func_def
	else
		raise "Function #{name}(#{param_key}) is already defined"
	end

end

def get_func_from_scope(name, param_key)
	return access_scope(name,nil,param_key)
end

def create_func_call_scope(func_name,params,args)
	scope = {:@scope_type => :func}
	for arg in args.to_array
		raise "Invalid number of arguments to #{func_name}" if params == nil
		obj = arg.get_obj
		type, name = params.type, params.name
		params = params.params

		type_check(type, obj.eval)
		if scope[name] == nil
			scope[name] = obj
		else
			raise "#{func_name} has multiple parameters named #{name}"
		end
	end
	raise "Invalid number of arguments to #{func_name}" if params != nil
	$scopes << scope
end