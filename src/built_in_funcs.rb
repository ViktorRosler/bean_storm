
class Load

	attr_reader :path, :last_stmt

	def initialize(parser, path)
		@parser, @path = parser, path
	end

	def eval
		puts "\nLoading #{@path}...\n"
		begin
			file = File.new(@path) 
		rescue SystemCallError
			puts "Unable to open file #{@path}"
			return
		end
		@last_stmt = @parser.parse file.read + "\n"
		puts "#{path} loaded successfully!"
	end
end

class Print

	def initialize(value)
		@value = value
	end

	def eval
		puts @value.to_string
	end

end

class Input

	def truth_value
		return get_obj.truth_value
	end

	def get_obj
		input = $stdin.gets

		if input =~ /^-?\d+$/
			obj = Data_Obj.new("int", input.to_i)
		elsif input =~  /^-?\d+\.\d+$/
			obj = Data_Obj.new("float", input.to_f)
		elsif input =~ /^True$/
			obj = Data_Obj.new("bool", true)
		elsif input =~ /^False$/
			obj = Data_Obj.new("bool", false)
		else
			obj = Data_Obj.new("string", input)
		end

		return obj
	end

	def eval
		return get_obj.eval
	end

end


class List_Func

	def initialize(list, func, index, value = nil)
		@list, @func, @index, @value = list, func, index, value
	end

	def to_string
		return get_obj.to_string
	end

	def get_obj
		list = @list.get_obj
		array = Marshal.load(Marshal.dump(list.eval))
		raise "Invalid list function #{@func} call" if array.class != Array
		index = @index.eval
		raise "Invalid list function #{@func} call" if index.to_i != index
		if @func == :add
			array.insert(index, @value.get_obj)
		elsif @func == :del
			array.delete_at(index)
		end
		list.value = array
		return list
	end

	def eval
		return get_obj.eval
	end

end