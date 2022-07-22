
require 'logger'
require './rdparse.rb'
require './src.rb'


class BeanStormParser

  attr_reader :parser

  def initialize
    @parser = Parser.new("Bean Storm") do |parser|

      token(/\n/) {|_| :end_of_line}

      token(/#.*/) # comment

      token(/( |\t)+/) # whitespace

      token(/\d+\.\d+/) {|t| t.to_f} # float literal

      token(/\d+/) {|t| t.to_i} # int literal

      token(/True/) {|t| :true}   # bool literal
      token(/False/) {|t| :false} # bool literal

      token(/"[^\"]*"/)  {|t| t} # "string" literal
      token(/'[^\']*'/)  {|t| t} # 'string' literal

      token(/(^int$|^float$|^bool$|^string$|^list$|^auto$)/) {|t| t} # types

      token(/(^load$|^print$|^if$|^elif$|^else$|^while$|^for$)/) {|t| t} # keywords
      token(/(^break$|^continue$|^return$|^class$|^input$)/) {|t| t}
      token(/(^insert$|^delete$)/) {|t| t}

      token(/\/\/=/) {|t| t} # operators
      token(/(\+\+|--|\/\/|==|!=|>=|<=|&&|\|\|)/) {|t| t} 
      token(/(\+=|-=|\*=|\/=|%=|<<|>>)/) {|t| t}  
      token(/(=|\+|-|\*|\/|%|&|!|<|>)/) {|t| t} 

      token(/(\[|\]|\(|\)|\{|\}|,|\.|:)/) {|t| t} # () [] {} , . :

      token(/[^(load)].*\.bean/) {|t| t}  # file name

      token(/\w+/) {|t| t} # names

      token(/.+/) {|t| t} # error


      ########################################
      #              PROGRAM                 #
      ########################################

      start :program do
        match(:stmts) {|stmts| stmts.eval}
      end

      rule :stmts do
        match(:stmt, :eol, :stmts) {|stmt,_,stmts| Stmts.new(stmt, stmts)}
        match(:eol, :stmts)        {|stmt,stmts| Stmts.new(stmt, stmts)}
        match(:stmt, :eol)         {|stmt,_| Stmts.new(stmt, nil)}
        match(:eol)                {|stmt| Stmts.new(stmt, nil)}
      end

      rule :stmt do
        match(:class_def)
        match(:func_def)
        match(:nested_stmt)
      end

      rule :nested_stmt do
        match("load", /.+/)      {|_,file| Load.new(parser,file)} 
        match("print", :or_cond) {|_,value| Print.new(value)}
        match(:loop_stmt)
        match(:if_stmt)
        match(:declare_stmt)
        match(:assign_stmt)
        match(:list_func)
        match(:or_cond)
        match(:error)
      end

      rule :eol do
        match(:end_of_line)
      end

      rule :error do
        match(:error, :error_token) {|error,token| Error.new(token,error)}  
        match(:error_token)         {|token| Error.new(token)}   
      end

      rule :error_token do
        match(/^(?!^load$|^print$|^input$|^end_of_line$|^int$|^float$|^bool$|
                   ^string$|^list$|^auto$|^insert$|^delete$|^True$|^False$|^if$|
                   ^elif$|^else$|^while$|^for$|^break$|^continue$|^return$|^class$|
                   \(|\)|\{|\}|).+/x)
      end


      ########################################
      #              VARIABLES               #
      ########################################

      rule :name do
        match(/^(?!^load$|^print$|^input$|^end_of_line$|^int$|^float$|^bool$|
                   ^string$|^list$|^auto$|^insert$|^delete$|^if$|^elif$|^else$|
                   ^while$|^for$|^break$|^continue$|^return$|^class$)^[a-z]\w*/x)
      end

      rule :built_in_type do
        match("int")
        match("float")
        match("bool")
        match("string")
        match("list")
        match("auto")
      end

      rule :type do
        match(:built_in_type)
        match(:class_name)
      end

      rule :declare_stmt do
        match(:built_in_type, :name, "=", "&", :variable) do |type,name,_,_,value| 
          Declare_Variable.new(type,name,value,true)
        end
        match(:built_in_type, :name, "=", :or_cond) do |type,name,_,value| 
          Declare_Variable.new(type,name,value)
        end
        match(:built_in_type, :name) {|type,name| Declare_Variable.new(type,name)}

        match(:class_name, :name, "(", :func_args, ")") do |cls,name,_,args,_|
          Declare_Class_Variable.new(cls,name,args)
        end
        match(:class_name, :name, "(", ")") do |cls,name,_,_|
          Declare_Class_Variable.new(cls,name,"")
        end
        match(:class_name, :name, "=", "&", :class_variable) do |cls,name,_,_var|
          Declare_Class_Variable.new(cls,name,nil,var,true)
        end
        match(:class_name, :name, "=", :class_variable) do |cls,name,_,var|
          Declare_Class_Variable.new(cls,name,nil,var)
        end
        match(:class_name, :name) do |cls,name|
          Declare_Class_Variable.new(cls,name)
        end
      end

      rule :assign_stmt do
        match(:name, "=", "&", :variable) do |name,op,_,value| 
          Assign_Variable.new(name,op,value,true)
        end
        match(:name, :assign, :or_cond) do |name,op,value|
          Assign_Variable.new(name,op,value)
        end

        match(:name, :index, "=", :or_cond) do |name,index,_,value|
          List_Index.new(name,index,value)
        end

        match(:member_access, "=", "&", :variable) do |member,op,_,value|
          Member_Assign.new(member,value,op,true)
        end
        match(:member_access, :assign, :or_cond) do |member,op,value|
          Member_Assign.new(member,value,op)
        end
      end

      rule :assign do
        match("=")
        match("+=")
        match("-=")
        match("*=")
        match("/=")
        match("%=")
        match("//=")
      end

      rule :variable do
        match(:member_access)
        match(:func_call)
        match(:name)  {|name| Retrieve_Variable.new(name)}
      end

      rule :class_variable do
        match(:list_index)
        match(:variable)
      end


      ########################################
      #              CONDITION               #
      ########################################

      rule :or_cond do
        match(:or_cond, "||", :and_cond) {|lh,op,rh| Condition.new(lh,op,rh)}
        match(:and_cond)
      end

      rule :and_cond do
        match(:and_cond, "&&", :comp) {|lh,op,rh| Condition.new(lh,op,rh)}
        match(:comp)
      end

      rule :comp do
        match(:expr, :comp_opr, :expr) {|lh,op,rh| Condition.new(lh,op,rh)}
        match("!", :or_cond)           {|_,cond| Not.new(cond)}
        match(:expr)
      end

      rule :comp_opr do
        match("==")
        match("!=")
        match("<=")
        match(">=")
        match("<")
        match(">")
      end

      rule :expr do
        match(:expr, '+', :term) {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:expr, '-', :term) {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:term)
      end

      rule :term do
        match(:term, '*', :un_opr_pre)  {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:term, '/', :un_opr_pre)  {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:term, '%', :un_opr_pre)  {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:term, '//', :un_opr_pre) {|lh,op,rh| Binary_Expr.new(lh,op,rh)}
        match(:un_opr_pre) 
      end

      rule :un_opr_pre do
        match('-', :un_opr_post)  {|_,value| Unary_Expr.new(:-, value)}
        match('++', :un_opr_post) {|_,value| Unary_Expr.new(:pre_inc, value)}
        match('--', :un_opr_post) {|_,value| Unary_Expr.new(:pre_dec, value)}
        match(:un_opr_post)
      end

      rule :un_opr_post do
        match(:value, '++') {|value,_| Unary_Expr.new(:post_inc, value)}  
        match(:value, '--') {|value,_| Unary_Expr.new(:post_dec, value)}
        match(:value)
      end

      rule :value do
        match("input") {|_| Input.new}
        match(:literal)
        match(:list_index)
        match(:variable)
        match("(", :or_cond, ")") {|_,cond,_| cond}
      end

      rule :literal do
        match(:int)
        match(:float)
        match(:bool)
        match(:string)
        match(:list)
      end


      ########################################
      #                TYPES                 #
      ########################################

      rule :int do
        match(Integer) {|int| Data_Obj.new("int", int)}
      end

      rule :float do
        match(Float) do |float|
          billion = 1000000000.0
          Data_Obj.new("float", (float*billion).round / billion)
        end
      end

      rule :bool do
        match(:true)  {|_| Data_Obj.new("bool", true)}
        match(:false) {|_| Data_Obj.new("bool", false)}
      end

      rule :string do
        match(/^"[^\"]*"$/)  {|str| Data_Obj.new("string", str[1..-2].to_s)} 
        match(/^'[^\']*'$/)  {|str| Data_Obj.new("string", str[1..-2].to_s)} 
      end

      rule :list do
        match("[", :list_content, "]") {|_,cont,_| Data_Obj.new("list", cont)}
        match("[", "]")                {|_,_| Data_Obj.new("list", [])}
      end

      rule :list_content do
        match(:or_cond, ",", :list_content) {|value,_,cont| Nested_Objects.new(value,cont)}
        match(:or_cond)                     {|value| Nested_Objects.new(value,nil)}
      end

      rule :list_index do
        match(:name, :index) {|name,index| List_Index.new(name,index)}
      end

      rule :index do
        match( "[", :expr, "]", :index) {|_,expr,_,index| Nested_Objects.new(expr,index)}
        match("[", :expr, "]")          {|_,expr,_| Nested_Objects.new(expr,nil)}
      end


      rule :list_func do
        match(:expr, ".", "insert", "(", :expr, ",", :expr, ")") do |list,_,_,_,index,_,value,_|
          List_Func.new(list, :add, index, value)
        end
        match(:expr, ".", "delete", "(", :expr, ")") do |list,_,_,_,index,_|
          List_Func.new(list, :del, index)
        end
      end

      ########################################
      #                CONTROL               #
      ########################################

      rule :nested_stmts do
        match(:control_stmt, :eol, :nested_stmts) {|stmt,_,stmts| Nested_Stmts.new(stmt, stmts)}
        match(:eol, :nested_stmts)                {|stmt,stmts| Nested_Stmts.new(stmt, stmts)}
        match(:control_stmt, :eol)                {|stmt,_| Nested_Stmts.new(stmt, nil)}
        match(:control_stmt)                      {|stmt| Nested_Stmts.new(stmt, nil)}
        match(:eol)                               {|stmt| Nested_Stmts.new(stmt, nil)}
      end

      rule :control_stmt do
        match("return", :or_cond) {|stmt,value| Control_Stmt.new(stmt,value)}
        match("return")   {|stmt| Control_Stmt.new(stmt)}
        match("break")    {|stmt| Control_Stmt.new(stmt)} 
        match("continue") {|stmt| Control_Stmt.new(stmt)}
        match(:nested_stmt)
      end

      rule :stmt_block do
        match(:left_bracket, :nested_stmts, :right_bracket) {|_,stmts,_| stmts}  
      end

      rule :left_bracket do
        match("{")
        match(:eol, "{")
      end

      rule :right_bracket do
        match("}")
        match("}", :eol)
      end

      rule :if_stmt do
        match("if", "(", :or_cond, ")", :stmt_block, :elif_else) do |_,_,cond,_,stmts,elif|
          If.new(cond, stmts, elif)
        end  
        match("if", "(", :or_cond, ")", :stmt_block) do |_,_,cond,_,stmts|
          If.new(cond, stmts)
        end 
      end

      rule :elif_else do
        match(:elif, "(", :or_cond, ")", :stmt_block, :elif_else) do |_,_,cond,_,stmts,elif|
          If.new(cond, stmts, elif)
        end  
        match(:elif, "(", :or_cond, ")", :stmt_block) do |_,_,cond,_,stmts|
          If.new(cond, stmts)
        end
        match(:else, :stmt_block) {|_,stmts| If.new(Data_Obj.new("bool", true), stmts)}
      end

      rule :elif do
        match(:eol, "elif")
        match("elif")
      end

      rule :else do
        match(:eol, "else")
        match("else")
      end

      rule :loop_stmt do
        match("while", "(", :or_cond, ")", :stmt_block) do |_,_,cond,_,stmts| 
          While.new(cond,stmts)
        end

        match("for", "(", :for_expr, ")", :stmt_block) do |_,_,for_expr,_,stmts|
          For.new(for_expr, stmts)
        end
      end

      rule :for_expr do
        match(:for_lh, ":", :or_cond, ":", :for_rh) {|lh,_,cond,_,rh| [lh,cond,rh]}
        match(":", :or_cond, ":", :for_rh)          {|_,cond,_,rh| [nil,cond,rh]}
        match(:for_lh, ":", ":", :for_rh)           {|lh,_,_,rh| [lh,true,rh]}
        match(:for_lh, ":", :or_cond, ":")          {|lh,_,cond,_| [lh,cond,nil]}
        match(":", ":", :for_rh)                    {|_,_,rh| [nil,true,rh]}
        match(":", :or_cond, ":")                   {|_,cond,_| [nil,cond,nil]}
        match(:for_lh, ":", ":")                    {|lh,_,_| [lh,true,nil]}
        match(":", ":")                             {|_,_| [nil,true,nil]}
      end

      rule :for_lh do
        match(:declare_stmt)
        match(:variable)
      end

      rule :for_rh do
        match(:assign_stmt)
        match(:expr)
      end


      ########################################
      #                FUNCTION              #
      ########################################

      rule :func_def do
        match(:func_type, :name, "(", :params, ")", 
              :stmt_block) do |type,name,_,params,_,stmts| 
          Func_Def.new(type,name,params,stmts)
        end

        match(:func_type, :name, "(", ")", 
              :stmt_block) do |type,name,_,_,stmts| 
          Func_Def.new(type,name,nil,stmts)
        end
      end

      rule :func_type do
        match("void")
        match(:type)
      end

      rule :params do
        match(:type, :name, ",", :params) do |type,name,_,params|
          Func_Params.new(type,name,params)
        end
        match(:type, :name) {|type,name| Func_Params.new(type,name)} 
      end

      rule :func_call do
        match(:name, "(", :func_args, ")") {|name,_,args,_| Func_Call.new(name,args)}
        match(:name, "(", ")")             {|name,_,_| Func_Call.new(name,nil)}
        match(:class_name, "(", :func_args, ")") {|name,_,args,_| Func_Call.new(name,args)}
        match(:class_name, "(", ")")             {|name,_,_| Func_Call.new(name,nil)}
      end

      rule :func_args do
        match("&", :variable, ",", :func_args) {|_,value,_,args| Func_Args.new(value,args,true)}
        match(:or_cond, ",", :func_args)      {|value,_,args| Func_Args.new(value,args)}
        match("&", :variable)                  {|_,value| Func_Args.new(value,nil,true)}
        match(:or_cond)                       {|value| Func_Args.new(value)}
      end


      ########################################
      #                 CLASS                #
      ########################################

      rule :class_def do
        match("class", :class_name, "<", :class_name, :class_block) do |_,name,_,parent,stmts|
          Class_Def.new(name,stmts,parent)
        end
        match("class", :class_name, :class_block) {|_,name,stmts| Class_Def.new(name,stmts,nil)}
      end

      rule :class_name do
        match(/^(?!^True$|^False$)^[A-Z]\w*/)
      end

      rule :class_block do
        match(:left_bracket, :class_stmts, :right_bracket) {|_,stmts,_| stmts}
      end

      rule :class_stmts do
        match(:class_stmt, :eol, :class_stmts) {|stmt,_,stmts| Nested_Stmts.new(stmt, stmts)}
        match(:eol, :class_stmts)                {|stmt,stmts| Nested_Stmts.new(stmt, stmts)}
        match(:class_stmt, :eol)                 {|stmt,_| Nested_Stmts.new(stmt, nil)}
        match(:class_stmt)                       {|stmt| Nested_Stmts.new(stmt, nil)}
        match(:eol)                              {|stmt| Nested_Stmts.new(stmt, nil)}
      end

      rule :class_stmt do
        match(:func_def)
        match(:constructor)
        match(:class_declare_stmt)
      end

      rule :constructor do
          match(:class_name, "(", :params, ")", 
              :stmt_block) do |name,_,params,_,stmts| 
          Constructor.new(name,params,stmts)
        end
        match(:class_name, "(", ")", 
              :stmt_block) do |name,_,_,stmts| 
          Constructor.new(name,nil,stmts)
        end
      end

      rule :class_declare_stmt do
        match("static", :declare_stmt) {|_,stmt| Static_Variable.new(stmt)}
        match(:declare_stmt)
      end

      rule :member_access do
        match(:name, ".", :member_access) {|name,_,member| Member_Access.new(name,member)}
        match(:name, ".", :member)        {|name,_,member| Member_Access.new(name,member)}
      end

      rule :member do
        match(:func_call)
        match(:list_index)
        match(:name) {|name| Retrieve_Variable.new(name)}
      end

    end
  end
end