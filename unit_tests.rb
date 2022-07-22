
require 'test/unit'
require './parser.rb'


class Test_Bean_Storm < Test::Unit::TestCase

	def test_declare_retrieve_variable
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# INT
		parser.parse("int i = 6\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 6)

		# FLOAT
		parser.parse("float f = 6.45\n")
		f = parser.parse("f\n")
		assert_equal(f.to_f, 6.45)

		parser.parse("int h = 9\n")
		parser.parse("f = h\n")
		f = parser.parse("f\n")
		assert_equal(f.to_f, 9)

		# BOOL
		parser.parse("bool b = True\n")
		b = parser.parse("b\n")
		assert_equal(b, "True")

		# STRING
		parser.parse("string s = 'Hello Bean!'\n")
		s = parser.parse("s\n")
		assert_equal(s, 'Hello Bean!')

		# LIST
		parser.parse("list l = [1, 4, 'asdf']\n")
		l = parser.parse("l\n")
		assert_equal(l[1..-2].split(", "), ["1","4","asdf"])

		# LIST INDEXING
		parser.parse("list l3 = [1, 2.3, 'asdf', True]\n")
		l2 = parser.parse("l3[1]\n")
		assert_equal(l2.to_f, 2.3)

		parser.parse("int k = 99\n")
		parser.parse("list l2 = [k, 4.5, k]\n")
		l3 = parser.parse("l2[0]\n")
		assert_equal(l3.to_i, 99)
	end

	def test_assign_variable
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# INT
		parser.parse("int i = 6\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 6)

		parser.parse("i = 7\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 7)

		parser.parse("int j = i\n")
		j = parser.parse("j\n")
		assert_equal(j, i)
		parser.parse("j = 8\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 7)

		# FLOAT
		parser.parse("float f = 6.45\n")
		f = parser.parse("f\n")
		assert_equal(f.to_f, 6.45)

		parser.parse("f = 7.04\n")
		f = parser.parse("f\n")
		assert_equal(f.to_f, 7.04)

		parser.parse("float g = f\n")
		g = parser.parse("g\n")
		assert_equal(g, f)
		parser.parse("g = 9.99\n")
		f = parser.parse("f\n")
		assert_equal(f.to_f, 7.04) 

		parser.parse("float h = 4\n")
		parser.parse("h = 4.5\n")
		h = parser.parse("h\n")
		assert_equal(h.to_f, 4.5)

		# BOOL
		parser.parse("bool b = False\n")
		b = parser.parse("b\n")
		assert_equal(b, "False")

		parser.parse("b = True\n")
		b = parser.parse("b\n")
		assert_equal(b, "True")

		parser.parse("bool c = b\n")
		c = parser.parse("c\n")
		assert_equal(c, b)
		parser.parse("c = False\n")
		b = parser.parse("b\n")
		assert_equal(b, "True")


		# STRING
		parser.parse("string s = 'Hello Bean!'\n")
		s = parser.parse("s\n")
		assert_equal(s, "Hello Bean!")

		parser.parse("s = 'How have you Bean?'\n")
		s = parser.parse("s\n")
		assert_equal(s, "How have you Bean?")

		parser.parse("string t = s\n")
		t = parser.parse("t\n")
		assert_equal(t, s)
		parser.parse("t = 'BeanyBoy'\n")
		s = parser.parse("s\n")
		assert_equal(s, "How have you Bean?")


		# LIST
		parser.parse("list l = [1, 2.3, 'asdf', True]\n")
		l = parser.parse("l\n")
		ans = "[1, 2.3, asdf, True]"
		assert_equal(l, ans)

		parser.parse("l = [2, True, False]\n")
		l = parser.parse("l\n")
		ans = "[2, True, False]"
		assert_equal(l, ans)

		parser.parse("list m = l\n")
		m = parser.parse("m\n")
		assert_equal(m, ans)

		parser.parse("m = [3,4,5.5]\n")	
		m = parser.parse("m\n")
		ans = "[3, 4, 5.5]"	
		assert_equal(m, ans)

		# LIST INDEXING
		parser.parse("list l2 = [1, 2.3, 'asdf', True]\n")
		parser.parse("l2[1] = 4\n")
		li = parser.parse("l2[1]\n")
		assert_equal(li.to_i, 4)

		# VARIABLE IN LIST
		parser.parse("int var = 55\n")
		parser.parse("list l3 = [var, var, var]\n")
		li = parser.parse("l3[1]\n") 
		assert_equal(li.to_i, 55)

		parser.parse("var = 44\n")
		li = parser.parse("l3[1]\n") 
		assert_equal(li.to_i, 55)

		# AUTO
		parser.parse("auto a = 4\n")
		a = parser.parse("a\n")
		assert_equal(a.to_i, 4)
		parser.parse("a = 8\n")
		a = parser.parse("a\n")
		assert_equal(a.to_i, 8)

		parser.parse("auto a2 = ++5\n")
		a2 = parser.parse("a2\n")
		assert_equal(a2.to_i, 6)

		parser.parse("string u = 'hej'\n")
		parser.parse("auto a3 = u\n")
		a3 = parser.parse("a3\n")
		assert_equal(a3, "hej")
	end

	def test_list_functions
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# TEST INSERT
		parser.parse("list l = [1,2,3,4]\n")
		parser.parse("l.insert(3, 'asdf')\n")
		a = parser.parse("l[3]\n")
		assert_equal(a, "asdf")

		b = parser.parse("[1,2,3].insert(0,0)\n")
		assert_equal(b, "[0, 1, 2, 3]")

		parser.parse("l = [1, [2,3]]\n")
		c = parser.parse("l[1].insert(2,4)\n")
		assert_equal(c, "[2, 3, 4]")

		parser.parse("list f() {return []}\n")
		d = parser.parse("f().insert(0, True)\n")
		assert_equal(d, "[True]")

		parser.parse("class E {list l = [1, '2']}\n")
		parser.parse("E e\n")
		e = parser.parse("e.l.insert(1, 1.5)\n")
		assert_equal(e, "[1, 1.5, 2]")

		# TEST DELETE
		parser.parse("list ll = [1,2,3,4]\n")
		parser.parse("ll.delete(3)\n")
		a = parser.parse("ll\n")
		assert_equal(a, "[1, 2, 3]")

		b = parser.parse("[1,2,3].delete(0)\n")
		assert_equal(b, "[2, 3]")

		parser.parse("ll = [1, [2,3]]\n")
		c = parser.parse("ll[1].delete(0)\n")
		assert_equal(c, "[3]")

		parser.parse("list g() {return [4,5,6]}\n")
		d = parser.parse("g().delete(0)\n")
		assert_equal(d, "[5, 6]")

		parser.parse("E ee\n")
		e = parser.parse("ee.l.delete(1)\n")
		assert_equal(e, "[1]")
	end

	def test_expression
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# LITERALS
		i = parser.parse("2\n")
		assert_equal(i.to_i, 2)

		f = parser.parse("3.4\n")
		assert_equal(f.to_f, 3.4)

		# PARANTHESES
		i = parser.parse("(2)\n")
		assert_equal(i.to_i, 2)

		f = parser.parse("(3.4)\n")
		assert_equal(f.to_f, 3.4)

		# UNARY OPERATOR -
		n = parser.parse("-4\n")
		assert_equal(n.to_i, -4)

		n = parser.parse("-12.4\n")
		assert_equal(n.to_f, -12.4)

		# UNARY OPERATOR ++
		u = parser.parse("++7\n")
		assert_equal(u.to_i, 8)

		u = parser.parse("5++\n")
		assert_equal(u.to_i, 5)

		u = parser.parse("++6.7\n")
		assert_equal(u.to_f, 7.7)

		u = parser.parse("12.2++\n")
		assert_equal(u.to_f, 12.2)

		parser.parse("int i = 9\n")
		u = parser.parse("++i\n")
		assert_equal(u.to_i, 10)
		u = parser.parse("i\n")
		assert_equal(u.to_i, 10)

		parser.parse("int j = 7\n")
		u = parser.parse("j++\n")
		assert_equal(u.to_i, 7)
		u = parser.parse("j\n")
		assert_equal(u.to_i, 8)

		# UNARY OPERATOR --
		u = parser.parse("--7\n")
		assert_equal(u.to_i, 6)

		u = parser.parse("5--\n")
		assert_equal(u.to_i, 5)

		u = parser.parse("--6.7\n")
		assert_equal(u.to_f, 5.7)

		u = parser.parse("12.2--\n")
		assert_equal(u.to_f, 12.2)

		parser.parse("int k = 9\n")
		u = parser.parse("--k\n")
		assert_equal(u.to_i, 8)
		u = parser.parse("k\n")
		assert_equal(u.to_i, 8)

		parser.parse("int l = 7\n")
		u = parser.parse("l--\n")
		assert_equal(u.to_i, 7)
		u = parser.parse("l\n")
		assert_equal(u.to_i, 6)
	
		# BINARY OPERATOR *
		m = parser.parse("4 * 4\n") 
		assert_equal(m.to_i, 16)

		m = parser.parse("4.4 * 5\n") 
		assert_equal(m.to_i, 22)

		m = parser.parse("4 * 5.2\n") 
		assert_equal(m.to_f, 20.8)

		m = parser.parse("4.3 * 5.2\n") 
		assert_equal(m.to_f, 22.36)

		# BINARY OPERATOR /
		d = parser.parse("8/4\n") 
		assert_equal(d.to_f, 2)

		d = parser.parse("8.5/4\n") 
		assert_equal(d.to_f, 2.125)

		d = parser.parse("8/4.8\n") 
		assert_equal(d.to_f, 1.666666667)

		d = parser.parse("7.5/3.3\n") 
		assert_equal(d.to_f, 2.272727273)

		# BINARY OPERATOR // 
		d = parser.parse("8//3\n") 
		assert_equal(d.to_i, 2)

		 d = parser.parse("8.9//3\n") 
		assert_equal(d.to_i, 2)

		d = parser.parse("12//3.3\n") 
		assert_equal(d.to_i, 3)

		d = parser.parse("14.4//4.8\n") 
		assert_equal(d.to_i, 3)

		# BINARY OPERATOR %
		m = parser.parse("8 % 2\n")
		assert_equal(m.to_i, 0)

		m = parser.parse("8.8 % 2\n")
		assert_equal(m.to_f, 0.8)  

		m = parser.parse("8 % 3.5\n")
		assert_equal(m.to_i, 1) 

		m = parser.parse("8.8 % 2.2\n")
		assert_equal(m.to_i, 0)  

		# BINARY OPERATOR + 
		a = parser.parse("2 + 1\n")
		assert_equal(a.to_i, 3)

		a = parser.parse("2.2 + 6\n")
		assert_equal(a.to_f, 8.2)

		a = parser.parse("5 + 8.9\n")
		assert_equal(a.to_f, 13.9)	

		a = parser.parse("0.5 + 5.9\n")
		assert_equal(a.to_f, 6.4)	 

		# BINARY OPERATOR -
		d = parser.parse("7-9\n")
		assert_equal(d.to_i, -2)

		d = parser.parse("7.8-9\n")
		assert_equal(d.to_f, -1.2)

		d = parser.parse("10-5.59\n")
		assert_equal(d.to_f, 4.41)

		d = parser.parse("8.7-6.4\n")
		assert_equal(d.to_f, 2.3)

		# COMPOSITE EXPRESSIONS
		e = parser.parse("2*1.1*4+(3*-5)\n")
		assert_equal(e.to_f, -6.2)

		e = parser.parse("-5/(8*8)+23-8\n")
		assert_equal(e.to_f, 14.921875)

		e = parser.parse("(++6 % 3) * 6.4 // 2\n")
		assert_equal(e.to_i, 3)

		# STRING CONCAT
		f = parser.parse("'as' + 'df'\n")
		assert_equal(f, "asdf")

		# LIST CONCAT
		parser.parse("list g = [1,'2'] + [3,4]\n")
		g = parser.parse("g\n")
		ans = "[1, 2, 3, 4]"
		assert_equal(g, ans)
	end

	def test_expr_assign_operators
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# +=
		parser.parse("int i\n")
		parser.parse("i += 22\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 22)

		parser.parse("string s = 'as'\n")
		parser.parse("s += 'df'\n")
		s = parser.parse("s\n")
		assert_equal(s, "asdf")

		parser.parse("list l = [1,2]\n")
		parser.parse("l += [3,4]\n")
		l = parser.parse("l[2]\n")
		assert_equal(l.to_i, 3)

		# -= 
		parser.parse("int j = 55\n")
		parser.parse("list ll = [44]\n")
		parser.parse("j -= ll[0]\n")
		j = parser.parse("j\n")
		assert_equal(j.to_i, 11)

		# *=
		parser.parse("float f = 4\n")
		parser.parse("int g() {return -2}\n")
		parser.parse("f *= g()\n")
		f = parser.parse("f\n")
		assert_equal(f.to_i, -8)

		# /=
		parser.parse("float h = 45.1\n")
		parser.parse("h /= 11\n")
		h = parser.parse("h\n")
		assert_equal(h.to_f, 4.1)

		# %=
		parser.parse("int k = 12\n")
		parser.parse("class D {int i = 7}\n")
		parser.parse("D c\n")
		parser.parse("k %= c.i\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 5)

		# //=
		parser.parse("float m = 33.3\n")
		parser.parse("m //= 8\n")
		m = parser.parse("m\n")
		assert_equal(m.to_f, 4)
	end



	def test_if_statemnt
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# IF
		parser.parse("int i = 0\n")
		parser.parse("if (True) {i = 1}\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 1)

		parser.parse("if (False) {i = 2}\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 1)

		# ELSE
		parser.parse("int j = 0\n")
		parser.parse("if (True) {j = 1} else {j = 2}\n")
		j = parser.parse("j\n")
		assert_equal(j.to_i, 1)

		parser.parse("if (False) {j = 3} else {j = 4}\n")
		j = parser.parse("j\n")
		assert_equal(j.to_i, 4)

		# ELSE IF
		parser.parse("int k = 0\n")
		parser.parse("if (False) {k = 1} elif (True) {k = 2} else {k = 3}\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 2)

		parser.parse("if (False) {k = 4} elif (True) {k = 5}\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 5)

		parser.parse("if (False) {k = 6} elif (False) {k = 7} else {k = 8}\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 8)
		
		parser.parse("if (True) {k = 9} elif (True) {k = 10} else {k = 11}\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 9)
	end

	def test_condition
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# LITERALS
		parser.parse("int i = 0\n")
		parser.parse("if (True) {i = 2}\n")
		c = parser.parse("i\n")
		assert_equal(c.to_i, 2)

		parser.parse("int j = 0\n")
		parser.parse("if (False) {j = 2}\n")
		c = parser.parse("j\n")
		assert_equal(c.to_i, 0)

		# NOT
		parser.parse("int m = 0\n")
		parser.parse("if (!True) {m = 2}\n")
		c = parser.parse("m\n")
		assert_equal(c.to_i, 0)

		parser.parse("int n = 0\n")
		parser.parse("if (!False) {n = 2}\n")
		c = parser.parse("n\n")
		assert_equal(c.to_i, 2)

		parser.parse("int o = 0\n")
		parser.parse("if (!True) {o = 2}\n")
		c = parser.parse("o\n")
		assert_equal(c.to_i, 0)

		parser.parse("int p = 0\n")
		parser.parse("if (!0) {p = 2}\n")
		c = parser.parse("p\n")
		assert_equal(c.to_i, 2)

		# VARIABLES
		parser.parse("int q = 0\n")
		parser.parse("bool b = True\n")
		parser.parse("if (b) {q = 2}\n")
		c = parser.parse("q\n")
		assert_equal(c.to_i, 2)

		parser.parse("if (!b) {q = 4}\n")
		c = parser.parse("q\n")
		assert_equal(c.to_i, 2)

		parser.parse("int r = 0\n")
		parser.parse("bool b2 = False\n")
		parser.parse("if (b2) {r = 2}\n")
		c = parser.parse("r\n")
		assert_equal(c.to_i, 0)

		parser.parse("if (!b2) {r = 4}\n")
		c = parser.parse("r\n")
		assert_equal(c.to_i, 4)

		parser.parse("int s = 0\n")
		parser.parse("int i2 = 5\n")
		parser.parse("if (i2) {s = 2}\n")
		c = parser.parse("s\n")
		assert_equal(c.to_i, 2)

		parser.parse("if (!i2) {s = 4}\n")
		c = parser.parse("s\n")
		assert_equal(c.to_i, 2)

		parser.parse("int t = 0\n")
		parser.parse("string s2 = ''\n")
		parser.parse("if (s2) {t = 2}\n")
		c = parser.parse("t\n")
		assert_equal(c.to_i, 0)

		parser.parse("if (!s2) {t = 4}\n")
		c = parser.parse("t\n")
		assert_equal(c.to_i, 4)

		# AND
		parser.parse("int u = 0\n")
		parser.parse("if (True && False) {u = 2} else {u = 4}\n")
		c = parser.parse("u\n")
		assert_equal(c.to_i, 4)

		parser.parse("int u2 = 0\n")
		parser.parse("if (True && True) {u2 = 2} else {u2 = 4}\n")
		c = parser.parse("u2\n")
		assert_equal(c.to_i, 2)

		# OR
		parser.parse("int v = 0\n")
		parser.parse("if (True || False) {v = 2} else {v = 4}\n")
		c = parser.parse("v\n")
		assert_equal(c.to_i, 2)

		parser.parse("int v2 = 0\n")
		parser.parse("if (False || False) {v2 = 2} else {v2 = 4}\n")
		c = parser.parse("v2\n")
		assert_equal(c.to_i, 4)


		# COMPARATOR ==
		parser.parse("int w = 0\n")
		parser.parse("if (5 == 5.0) {w = 2} else {w = 4}\n")
		c = parser.parse("w\n")
		assert_equal(c.to_i, 2)

		# COMPARATOR !=
		parser.parse("int x = 0\n")
		parser.parse("if ('True' != True) {x = 2} else {x = 4}\n")
		c = parser.parse("x\n")
		assert_equal(c.to_i, 2)
		
		# COMPARATOR >
		parser.parse("int y = 0\n")
		parser.parse("if (5 > 4.0) {y = 2} else {y = 4}\n")
		c = parser.parse("y\n")
		assert_equal(c.to_i, 2)
		
		parser.parse("int y2 = 0\n")
		parser.parse("if (5 > 6.0) {y2 = 2} else {y2 = 4}\n")
		c = parser.parse("y2\n")
		assert_equal(c.to_i, 4)
		
		# COMPARATOR <
		parser.parse("int z = 0\n")
		parser.parse("if (5 < 4.0) {z = 2} else {z = 4}\n")
		c = parser.parse("z\n")
		assert_equal(c.to_i, 4)
		
		parser.parse("int z2 = 0\n")
		parser.parse("if (5 < 6.0) {z2 = 2} else {z2 = 4}\n")
		c = parser.parse("z2\n")
		assert_equal(c.to_i, 2)
		
		# COMPARATOR >=
		parser.parse("int aa = 0\n")
		parser.parse("if (5 >= 4.0) {aa = 2} else {aa = 4}\n")
		c = parser.parse("aa\n")
		assert_equal(c.to_i, 2)
		
		parser.parse("int aa2 = 0\n")
		parser.parse("if (5 >= 6.0) {aa2 = 2} else {aa2 = 4}\n")
		c = parser.parse("aa2\n")
		assert_equal(c.to_i, 4)
		
		parser.parse("int aa3 = 0\n")
		parser.parse("if (5 >= 5.0) {aa3 = 2} else {aa3 = 4}\n")
		c = parser.parse("aa3\n")
		assert_equal(c.to_i, 2)
		
		# COMPARATOR <=
		parser.parse("int ab = 0\n")
		parser.parse("if (5 <= 4.0) {ab = 2} else {ab = 4}\n")
		c = parser.parse("ab\n")
		assert_equal(c.to_i, 4)
		
		c = parser.parse("int ab2 = 0\n")
		parser.parse("if (5 <= 6.0) {ab2 = 2} else {ab2 = 4}\n")
		c = parser.parse("ab2\n")
		assert_equal(c.to_i, 2)
		
		c = parser.parse("int ab3 = 0\n")
		parser.parse("if (5 <= 5.0) {ab3 = 2} else {ab3 = 4}\n")
		c = parser.parse("ab3\n")
		assert_equal(c.to_i, 2)
	end

	def test_type_truth_value
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# INT
		parser.parse("int i = 0\n")
		parser.parse("if (1) {i=1} else {i=2}\n")
		c = parser.parse("i\n")
		assert_equal(c.to_i, 1)

		parser.parse("int j = 0\n")
		parser.parse("if (0) {j=1} else {j=2}\n")
		c = parser.parse("j\n")
		assert_equal(c.to_i, 2)

		# FLOAT
		parser.parse("int k = 0\n")
		parser.parse("if (1.0) {k=1} else {k=2}\n")
		c = parser.parse("k\n")
		assert_equal(c.to_i, 1)

		parser.parse("int l = 0\n")
		parser.parse("if (0.0) {l=1} else {l=2}\n")
		c = parser.parse("l\n")
		assert_equal(c.to_i, 2)

		# STRING
		parser.parse("int m = 0\n")
		parser.parse("if ('asdf') {m=1} else {m=2}\n")
		c = parser.parse("m\n")
		assert_equal(c.to_i, 1)

		parser.parse("int n = 0\n")
		parser.parse("if ('') {n=1} else {n=2}\n")
		c = parser.parse("n\n")
		assert_equal(c.to_i, 2)

		# LIST
		parser.parse("int o = 0\n")
		parser.parse("if ([1,6]) {o=1} else {o=2}\n")
		c = parser.parse("o\n")
		assert_equal(c.to_i, 1)

		parser.parse("int p = 0\n")
		parser.parse("if ([]) {p=1} else {p=2}\n")
		c = parser.parse("p\n")
		assert_equal(c.to_i, 2)
	end

	def test_while_loop
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# WHILE
		parser.parse("int i = 0\n")
		parser.parse("while (i != 5) {++i}\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 5)

		parser.parse("int j = 0\n")
		str = "while (j != 9)\n" \
		      "{\n"\
		      	"j = j + 2\n"\
		      	"j = j - 1\n" \
		      	"bool b\n" \
		      "}\n"

		parser.parse(str)
		j = parser.parse("j\n")
		assert_equal(j.to_i, 9)


		# BREAK
		parser.parse("int k = 0\n")
		str = "while (True)\n" \
		      "{\n" \
		      	"break\n" \
		      	"k = 99\n" \
		      "}\n"
		parser.parse(str)
		k = parser.parse("k\n")
		assert_equal(k.to_i, 0)

		parser.parse("int l = 0\n")
		str = "while (True)\n" \
		      "{\n" \
		      	"l = l + 1\n" \
		      	"if (l == 11) {break}\n" \
		      "}\n"

		parser.parse(str)
		l = parser.parse("l\n")
		assert_equal(l.to_i, 11)

		# CONTINUE
		parser.parse("int m = 0\n")
		str = "while (m != 5)\n" \
		      "{\n" \
                "m = m + 1\n" \
		      	"continue\n" \
		      	"m = 99\n" \
		      "}\n"
		parser.parse(str)
		m = parser.parse("m\n")
		assert_equal(m.to_i, 5)
	end

	def test_function
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]	

		# DEFINE & CALL FUNCTION
		parser.parse("int func() {return 55}\n")
		parser.parse("int i = func()\n")
		i = parser.parse("i\n")
		assert_equal(i.to_i, 55)

		# DEFINE FUNCTION WITH ONE PARAMETER
		parser.parse("int func2(int i) {return i}\n")
		parser.parse("int j = func2(22)\n")
		j = parser.parse("j\n")
		assert_equal(j.to_i, 22)

		# DEFINE & CALL FUNCTION WITH MULTIPLE PARAMETERS
		parser.parse("int func3(int a, int b) {return a+b}\n")
		parser.parse("int k = func3(22,11)\n")
		k = parser.parse("k\n")
		assert_equal(k.to_i, 33)

		# DEFINE & CALL TWO DIFFERENT FUNCTIONS WITH SAME NAME
		parser.parse("int func4() {return 0}\n")
		parser.parse("int func4(int i) {return i}\n")
		parser.parse("int l = func4()\n")
		l = parser.parse("l\n")
		assert_equal(l.to_i, 0)
		parser.parse("l = func4(11)\n")
		l = parser.parse("l\n")
		assert_equal(l.to_i, 11)

		# FUNCTION RETURNING DEFAULT RETURN VALUE
		parser.parse("int func6() {return}\n")
		parser.parse("int m = func6()\n")
		m = parser.parse("m\n")
		assert_equal(m.to_i, 0)

		# TYPECHECK RETURN VALUE
		parser.parse("int func8() {return 'asdf'}\n")
		assert_raise(RuntimeError) {parser.parse("func8()\n")}
	end

	def test_scope
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]	

		# IF STATEMENT SCOPE
        parser.parse("int i = 0\n")
        parser.parse("if (True) {int i = 4}\n")
        s = parser.parse("i\n")
        assert_equal(s.to_i, 0)

        # MULTIPLE NESTED SCOPES
        str = "int a = 56\n" \
			  "float b = a\n" \
			  "int x\n" \
			  "if (a == b)\n" \
              "{\n" \
				  "int a = 5\n" \
				  "if (True)\n" \
				  "{\n" \
				      "int a = 9\n" \
					  "x = a\n" \
				  "}\n" \
				  "b = a\n" \
				  "float c = 5.8\n" \
              "}\n"
        parser.parse(str)
        s = parser.parse("a\n")
        assert_equal(s.to_i, 56)
        s = parser.parse("b\n")
        assert_equal(s.to_i, 5)
        assert_raise(RuntimeError) {parser.parse("c\n")}
        s = parser.parse("x\n")
        assert_equal(s.to_i, 9)

        # WHILE LOOP SCOPE
        parser.parse("int j = 0\n")
        str = "while (j != 13)\n" \
              "{\n" \
                  "++j\n" \
                  "j = j - 1\n" \
                  "bool b\n" \
                  "++j\n" \
              "}\n"
        parser.parse(str)
        s = parser.parse("j\n")
        assert_equal(s.to_i, 13)
	end 

	def test_error_handling
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# TYPE CHECK
		assert_raise {parser.parse("int i = 2.0\n")}
		assert_raise {parser.parse("float f = True\n")}
		assert_raise {parser.parse("bool b = 'True'\n")}
		assert_raise {parser.parse("string s = []\n")}
		assert_raise {parser.parse("list l = 1\n")}
		assert_raise {parser.parse("auto a\n")}
		assert_raise do
			parser.parse("void f() {return}\n")
			parser.parse("auto a2 = f()\n")
		end
		assert_raise do
			parser.parse("class A {int i}\n")
			parser.parse("class B {float f}\n")
			parser.parse("A a3\n")
			parser.parse("B b2 = a3\n")
		end

		# ASSIGN
		assert_raise {parser.parse("i += 'asd'\n")}
		assert_raise {parser.parse("'sad' -= 'd'\n")}
		assert_raise {parser.parse("[1,2] -= [1]\n")}
		assert_raise {parser.parse("[1,2] *= 2\n")}
		assert_raise do
			parser.parse("A aa\n")
			parser.parse("B bb\n")
			parser.parse("bb = aa\n")
		end

		# LIST INDEX
		parser.parse("list ll = [1,2,3,4,5]\n")
		assert_raise {parser.parse("ll[-1]\n")}
		assert_raise {parser.parse("ll[6]\n")}

		# LIST FUNCTIONS
		assert_raise {parser.parse("'asdf'.delete(1)\n")}
		assert_raise {parser.parse("124.insert(2,3)\n")}

		# CONDITION
		assert_raise {parser.parse("[1,2,3] <= 'asdf'\n")}
		assert_raise {parser.parse("True < False\n")}
		assert_raise {parser.parse("2 > '-1'\n")}
		assert_raise {parser.parse("[2] >= [1]\n")}

		# BINARY EXPRESSION
		assert_raise {parser.parse("'asd' + [1,2,3]\n")}
		assert_raise {parser.parse("[4] - 4\n")}
		assert_raise {parser.parse("[2] * 5\n")}
		assert_raise {parser.parse("[1,2,3] - [2]\n")}
		assert_raise {parser.parse("'23' - 5\n")}
		assert_raise {parser.parse("'as' - 's'\n")}

		# UNARY EXPRESSION
		assert_raise {parser.parse("++'asd'\n")}
		assert_raise {parser.parse("[2]++\n")}
		assert_raise {parser.parse("--True\n")}

		# CLASS
		assert_raise do
			parser.parse("A irt = 66\n")
		end
		assert_raise do
			parser.parse("A asd\n")
			parser.parse("asd.var\n")
		end
		assert_raise do
			parser.parse("A afd\n")
			parser.parse("afd.var = 33\n")
		end
		assert_raise do
			parser.parse("A ert\n")
			parser.parse("list lio = [1,ert,3]\n")
			parser.parse("lio.ert\n")
		end

		# SCOPE
		assert_raise {parser.parse("variable\n")}
		assert_raise do
			parser.parse("auto af = 2\n")
			parser.parse("auto af = 3\n")
		end
		assert_raise do 
			parser.parse("void ff() {return}\n")
			parser.parse("int ff() {return 5}\n")
		end
		assert_raise do
			parser.parse("int func(int a, int b) {return a+b}\n")
			parser.parse("func(2)\n")
		end
		assert_raise {parser.parse("func(3,2,1)\n")}
		assert_raise do 
			parser.parse("int add(int a, int a) {return a+a}\n")
			parser.parse("add(1,1)\n")
		end



	end

	def test_files
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]

		# IF STATEMENTS TEST
		a = parser.parse("load tests/if_tests.bean\n")
		assert_equal(a.last_stmt, "True")

		# WHILE STATEMENTS TESTS
		$scopes = [Hash.new]
		b = parser.parse("load tests/while_tests.bean\n")
		assert_equal(b.last_stmt, "True")

		# FUNCTION TESTS
		$scopes = [Hash.new]
		c = parser.parse("load tests/function_tests.bean\n")
		assert_equal(c.last_stmt, "True")

		# LISTS
		$scopes = [Hash.new]
		d = parser.parse("load tests/list_tests.bean\n")
		assert_equal(d.last_stmt, "True")
		
		# QUICK SORT
		$scopes = [Hash.new]
		q = parser.parse("load tests/quicksort.bean\n")
		assert_equal(q.last_stmt, "True")

		# FUNCTION OVERLOADING
		$scopes = [Hash.new]
		f = parser.parse("load tests/overloading_tests.bean\n")
		assert_equal(f.last_stmt, "True")
		
		# CLASSES
		$scopes = [Hash.new]
		g = parser.parse("load tests/class_tests.bean\n")
		assert_equal(g.last_stmt, "True")
	end

	def test_additional_files
		parser = BeanStormParser.new.parser
		parser.logger.level = Logger::WARN
		$scopes = [Hash.new]
		$classes = Hash.new

		a = parser.parse("load tests/variables_thorough_test.bean\n")
		assert_equal(a.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		b = parser.parse("load tests/expressions_thorough_test.bean\n")
		assert_equal(b.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		c = parser.parse("load tests/lists_thorough_test.bean\n")
		assert_equal(c.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		d = parser.parse("load tests/conditions_thorough_test.bean\n")
		assert_equal(d.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		e = parser.parse("load tests/loops_thorough_test.bean\n")
		assert_equal(e.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		f = parser.parse("load tests/functions_thorough_test.bean\n")
		assert_equal(f.last_stmt, "True")

		$scopes = [Hash.new]
		$classes = Hash.new
		g = parser.parse("load tests/classes_thorough_test.bean\n")
		assert_equal(g.last_stmt, "True")
	end

end 


