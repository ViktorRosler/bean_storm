class Data_Obj

	attr_accessor :value
	attr_reader :type

	def initialize(type, value)
		@type, @value = type, value
	end

	def to_string
		if @type == "list"
			out = "["
			for value in eval
				out += ", " if out != "["
				out += value.to_string
			end
			return out + "]"
		elsif @value == true
			return "True"
		elsif @value == false
			return "False"
		else
			return @value.to_s
		end
	end

	def truth_value
		return false if @type == "int" && @value == 0
		return false if @type == "float" && @value == 0.0
		return eval if @type == "bool"
		return false if @type == "string" && @value == ""
		return false if @type == "list" && (@value == [] || @value == nil)
		return false if @type == "void"
		return true
	end

	def get_obj
		return self
	end

	def eval
		@value = @value.eval if @value.class == Nested_Objects
		return @value
	end

end

class List_Index

	attr_reader :value

	def initialize(name, index, value = nil)
		@name, @index, @value = name, index, value
	end

	def to_string
		return get_obj.to_string
	end

	def truth_value
		return get_obj.truth_value
	end

	def get_obj
		obj = get_var_from_scope(@name)
		array = obj.eval
		index_array = @index.eval
		index_array.each_with_index do |value, i|
			index = value.eval
			if index < 0 || index > array.length - 1
				raise "#{@name}[#{index}] is out of index"
			end
			if i == index_array.length - 1 && @value != nil
				array[index] = @value.get_obj
			end
			obj = array[index]
			array = obj.eval
			raise "#{@name}[#{index}] is out of index" if obj == nil
		end
		return obj
	end

	def eval
		return get_obj.eval
	end
end

class Nested_Objects

	attr_reader :object, :nested

	def initialize(object, nested)
		@object, @nested = object, nested
	end

	def eval
		out = []
		object = @object
		nested = @nested
		while(true)
			out << object.get_obj.clone
			break if nested == nil
			object = nested.object
			nested = nested.nested
		end
		return out
	end
end
