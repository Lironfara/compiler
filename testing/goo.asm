;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 1514:
	db T_integer	; 0
	dq 0
	; L_constants + 1523:
	db T_string	; "crazy-ack"
	dq 9
	db 0x63, 0x72, 0x61, 0x7A, 0x79, 0x2D, 0x61, 0x63
	db 0x6B
	; L_constants + 1541:
	db T_integer	; 1
	dq 1
	; L_constants + 1550:
	db T_integer	; 7
	dq 7
	; L_constants + 1559:
	db T_integer	; 2
	dq 2
	; L_constants + 1568:
	db T_integer	; 61
	dq 61
	; L_constants + 1577:
	db T_integer	; 3
	dq 3
	; L_constants + 1586:
	db T_integer	; 316
	dq 316
	; L_constants + 1595:
	db T_integer	; 5
	dq 5
	; L_constants + 1604:
	db T_integer	; 636
	dq 636
	; L_constants + 1613:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1630:
	db T_interned_symbol	; whatever
	dq L_constants + 1613
free_var_0:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_1:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_2:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_3:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_4:	; location of crazy-ack
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1523

free_var_5:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_6:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for zero?
	mov rdi, free_var_6
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_1
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_0
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_3
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_2
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_00d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00d8
.L_lambda_simple_env_end_00d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00d8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_00d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00d8
.L_lambda_simple_params_end_00d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00d8
	jmp .L_lambda_simple_end_00d8
.L_lambda_simple_code_00d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00d8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, PARAM(1)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_013f:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_013f
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_013f
.L_tc_recycle_frame_done_013f:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00d8:	; new closure is in rax
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_00d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00d9
.L_lambda_simple_env_end_00d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00d9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_00d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00d9
.L_lambda_simple_params_end_00d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00d9
	jmp .L_lambda_simple_end_00d9
.L_lambda_simple_code_00d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d9:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1514
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0140:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0140
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0140
.L_tc_recycle_frame_done_0140:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00d9:	; new closure is in rax
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1630
	push rax
	mov rax, L_constants + 1630
	push rax
	mov rax, L_constants + 1630
	push rax
	mov rax, L_constants + 1630
	push rax
	push 4	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_00da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00da
.L_lambda_simple_env_end_00da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00da:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_00da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00da
.L_lambda_simple_params_end_00da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00da
	jmp .L_lambda_simple_end_00da
.L_lambda_simple_code_00da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_00da
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00da:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rbx, qword [rbp + 8 * (4 + 1)]
	mov qword [rbx], rax

	mov rbx, qword [rbp + 8 * (4 + 2)]
	mov qword [rbx], rax

	mov rbx, qword [rbp + 8 * (4 + 3)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_00db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00db
.L_lambda_simple_env_end_00db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00db:	; copy params
	cmp rsi, 4
	je .L_lambda_simple_params_end_00db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00db
.L_lambda_simple_params_end_00db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00db
	jmp .L_lambda_simple_end_00db
.L_lambda_simple_code_00db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00db
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00db:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00af
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00af
.L_if_else_00af:
	mov rax, L_constants + 2
.L_if_end_00af:
	cmp rax, sob_boolean_false
	je .L_if_else_00b7
	; preparing a tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0141:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0141
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0141
.L_tc_recycle_frame_done_0141:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b7
.L_if_else_00b7:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b0
.L_if_else_00b0:
	mov rax, L_constants + 2
.L_if_end_00b0:
	cmp rax, sob_boolean_false
	je .L_if_else_00b6
	; preparing a tail-call
	mov rax, L_constants + 1541
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1514
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0142:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0142
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0142
.L_tc_recycle_frame_done_0142:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b6
.L_if_else_00b6:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b5
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, L_constants + 1514
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1514
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0143:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0143
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0143
.L_tc_recycle_frame_done_0143:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b5
.L_if_else_00b5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b1
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b1
.L_if_else_00b1:
	mov rax, L_constants + 2
.L_if_end_00b1:
	cmp rax, sob_boolean_false
	je .L_if_else_00b4
	; preparing a tail-call
	mov rax, L_constants + 1514
	push rax
	mov rax, L_constants + 1541
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0144:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0144
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0144
.L_tc_recycle_frame_done_0144:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b4
.L_if_else_00b4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b3
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1514
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1541
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0145:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0145
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0145
.L_tc_recycle_frame_done_0145:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b3
.L_if_else_00b3:
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b2
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0146:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0146
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0146
.L_tc_recycle_frame_done_0146:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b2
.L_if_else_00b2:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0147:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0147
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0147
.L_tc_recycle_frame_done_0147:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_00b2:
.L_if_end_00b3:
.L_if_end_00b4:
.L_if_end_00b5:
.L_if_end_00b6:
.L_if_end_00b7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00db:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param ack3
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_001f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_001f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_001f
.L_lambda_opt_env_end_001f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_001f:	; copy params
	cmp rsi, 4
	je .L_lambda_opt_params_end_001f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_001f
.L_lambda_opt_params_end_001f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_001f
	jmp .L_lambda_opt_end_001f
.L_lambda_opt_code_001f:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_001f
	jg .L_lambda_opt_arity_check_more_001f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_001f:
	sub rsp, 8
	mov rax, qword[rsp + 8 *1]
	mov qword[rsp], rax  
	mov rax, qword[rsp + 8 *2] ;rax now holds env 
	mov qword[rsp + 8 * 1], rax
	mov rax, 2
	mov qword[rsp + 8 *2], rax
	mov rax, qword[rsp + 8 * (4 + 0)]
	mov qword[rsp + 8 * (3 + 0)], rax
	mov rax, sob_nil
	mov qword[rsp + 8 * (3 + 1)], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00dd
.L_lambda_simple_env_end_00dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00dd:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_00dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00dd
.L_lambda_simple_params_end_00dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00dd
	jmp .L_lambda_simple_end_00dd
.L_lambda_simple_code_00dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00dd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00dd:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param c
	push rax
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014a:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014a
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014a
.L_tc_recycle_frame_done_014a:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00dd:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param bcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014b:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014b
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014b
.L_tc_recycle_frame_done_014b:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_001f	; new closure is in rax
.L_lambda_opt_arity_check_more_001f:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_001f:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_001f
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_001f
.L_lambda_opt_stack_shrink_loop_exit_001f:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, 2
	sub rax, rdi
	mov rdi, rax
	imul rax,8
	add rsp, rax
	mov rax, rsp
	mov r8, rdi
	imul r8, 8
	sub rax, r8
	mov r10, rax	; holds the original ret in the stack
	add r10, 8*3
	add rax, 2* 8	; rax holds arg count [rsp+ 2*8] in the original 
	mov r8, qword[rax] ;arg count = r8
	imul r8,8
	add rax, r8
	mov qword[rax] ,r9
 	mov r8, r10
	add r8, 8 * 0
	mov r9,qword[r8]
	mov qword [r8 + rdi * 8], r9
	sub r10, 8*3
	mov qword [rsp+2*8], 2
	mov rax, qword[r10 + 1 * 8]
	mov qword[rsp + 1*8] ,rax
	mov rax, qword[r10]
	mov qword[rsp], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00dc
.L_lambda_simple_env_end_00dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00dc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_00dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00dc
.L_lambda_simple_params_end_00dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00dc
	jmp .L_lambda_simple_end_00dc
.L_lambda_simple_code_00dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00dc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00dc:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param c
	push rax
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0148:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0148
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0148
.L_tc_recycle_frame_done_0148:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00dc:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param bcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0149:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0149
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0149
.L_tc_recycle_frame_done_0149:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_001f:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param ack-x
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0020:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0020
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0020
.L_lambda_opt_env_end_0020:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0020:	; copy params
	cmp rsi, 4
	je .L_lambda_opt_params_end_0020
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0020
.L_lambda_opt_params_end_0020:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0020
	jmp .L_lambda_opt_end_0020
.L_lambda_opt_code_0020:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_0020
	jg .L_lambda_opt_arity_check_more_0020
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0020:
	sub rsp, 8
	mov rax, qword[rsp + 8 *1]
	mov qword[rsp], rax  
	mov rax, qword[rsp + 8 *2] ;rax now holds env 
	mov qword[rsp + 8 * 1], rax
	mov rax, 3
	mov qword[rsp + 8 *2], rax
	mov rax, qword[rsp + 8 * (4 + 0)]
	mov qword[rsp + 8 * (3 + 0)], rax
	mov rax, qword[rsp + 8 * (4 + 1)]
	mov qword[rsp + 8 * (3 + 1)], rax
	mov rax, sob_nil
	mov qword[rsp + 8 * (3 + 2)], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00df
.L_lambda_simple_env_end_00df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00df:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_00df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00df
.L_lambda_simple_params_end_00df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00df
	jmp .L_lambda_simple_end_00df
.L_lambda_simple_code_00df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00df
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00df:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param c
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014e:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014e
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014e
.L_tc_recycle_frame_done_014e:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00df:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param cs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014f:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014f
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014f
.L_tc_recycle_frame_done_014f:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
	jmp .L_lambda_opt_end_0020	; new closure is in rax
.L_lambda_opt_arity_check_more_0020:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0020:
	cmp r8, 2
	je .L_lambda_opt_stack_shrink_loop_exit_0020
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0020
.L_lambda_opt_stack_shrink_loop_exit_0020:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, 3
	sub rax, rdi
	mov rdi, rax
	imul rax,8
	add rsp, rax
	mov rax, rsp
	mov r8, rdi
	imul r8, 8
	sub rax, r8
	mov r10, rax	; holds the original ret in the stack
	add r10, 8*3
	add rax, 2* 8	; rax holds arg count [rsp+ 2*8] in the original 
	mov r8, qword[rax] ;arg count = r8
	imul r8,8
	add rax, r8
	mov qword[rax] ,r9
 	mov r8, r10
	add r8, 8 * 1
	mov r9,qword[r8]
	mov qword [r8 + rdi * 8], r9
	mov r8, r10
	add r8, 8 * 0
	mov r9,qword[r8]
	mov qword [r8 + rdi * 8], r9
	sub r10, 8*3
	mov qword [rsp+2*8], 3
	mov rax, qword[r10 + 1 * 8]
	mov qword[rsp + 1*8] ,rax
	mov rax, qword[r10]
	mov qword[rsp], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00de
.L_lambda_simple_env_end_00de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00de:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_00de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00de
.L_lambda_simple_params_end_00de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00de
	jmp .L_lambda_simple_end_00de
.L_lambda_simple_code_00de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00de:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param c
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014c:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014c
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014c
.L_tc_recycle_frame_done_014c:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00de:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param cs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_014d:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_014d
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_014d
.L_tc_recycle_frame_done_014d:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0020:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param ack-y
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0021:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0021
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0021
.L_lambda_opt_env_end_0021:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0021:	; copy params
	cmp rsi, 4
	je .L_lambda_opt_params_end_0021
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0021
.L_lambda_opt_params_end_0021:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0021
	jmp .L_lambda_opt_end_0021
.L_lambda_opt_code_0021:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0021
	jg .L_lambda_opt_arity_check_more_0021
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0021:
	sub rsp, 8
	mov rax, qword[rsp + 8 *1]
	mov qword[rsp], rax  
	mov rax, qword[rsp + 8 *2] ;rax now holds env 
	mov qword[rsp + 8 * 1], rax
	mov rax, 1
	mov qword[rsp + 8 *2], rax
	mov rax, sob_nil
	mov qword[rsp + 8 * (3 + 0)], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00e1
.L_lambda_simple_env_end_00e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00e1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_00e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00e1
.L_lambda_simple_params_end_00e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00e1
	jmp .L_lambda_simple_end_00e1
.L_lambda_simple_code_00e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00e1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e1:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param c
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0152:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0152
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0152
.L_tc_recycle_frame_done_0152:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00e1:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param abcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0153:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0153
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0153
.L_tc_recycle_frame_done_0153:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
	jmp .L_lambda_opt_end_0021	; new closure is in rax
.L_lambda_opt_arity_check_more_0021:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0021:
	cmp r8, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0021
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0021
.L_lambda_opt_stack_shrink_loop_exit_0021:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, 1
	sub rax, rdi
	mov rdi, rax
	imul rax,8
	add rsp, rax
	mov rax, rsp
	mov r8, rdi
	imul r8, 8
	sub rax, r8
	mov r10, rax	; holds the original ret in the stack
	add r10, 8*3
	add rax, 2* 8	; rax holds arg count [rsp+ 2*8] in the original 
	mov r8, qword[rax] ;arg count = r8
	imul r8,8
	add rax, r8
	mov qword[rax] ,r9
 	sub r10, 8*3
	mov qword [rsp+2*8], 1
	mov rax, qword[r10 + 1 * 8]
	mov qword[rsp + 1*8] ,rax
	mov rax, qword[r10]
	mov qword[rsp], rax
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_00e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00e0
.L_lambda_simple_env_end_00e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00e0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_00e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00e0
.L_lambda_simple_params_end_00e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00e0
	jmp .L_lambda_simple_end_00e0
.L_lambda_simple_code_00e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00e0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e0:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param c
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0150:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0150
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0150
.L_tc_recycle_frame_done_0150:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00e0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param abcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0151:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0151
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0151
.L_tc_recycle_frame_done_0151:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0021:	; new closure is in rax
	push rax
	mov rax, PARAM(3)	; param ack-z
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_00e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_00e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_00e2
.L_lambda_simple_env_end_00e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_00e2:	; copy params
	cmp rsi, 4
	je .L_lambda_simple_params_end_00e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_00e2
.L_lambda_simple_params_end_00e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_00e2
	jmp .L_lambda_simple_end_00e2
.L_lambda_simple_code_00e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00e2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e2:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1559
	push rax
	mov rax, L_constants + 1559
	push rax
	mov rax, L_constants + 1514
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1550
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00ba
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1577
	push rax
	mov rax, L_constants + 1577
	push rax
	mov rax, L_constants + 1514
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1568
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b9
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1595
	push rax
	mov rax, L_constants + 1541
	push rax
	mov rax, L_constants + 1541
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1586
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_00b8
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1541
	push rax
	mov rax, L_constants + 1514
	push rax
	mov rax, L_constants + 1559
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 1604
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov r15, rbp	 ;will hold the rbp we need to overwrite
 	mov r14, qword[r15 + 3*8]	 ;r14 holding the param count of h
	add r14, 3 	 ;adding so we will get to the params 
	shl r14, 3 	 ;multiplie r14 by 8
	add r15, r14 	 ;now r15 points to the top of the rbp, An-1 
	mov r8, rsp 	; r8 now holds the lower of the stack
	mov r9, qword[rsp + 3*8] 	 ;r9 is holding the arg count of h
	add r9, 3 	 ;for getting to the params
	shl r9, 3 	 ;multiplie by 8 
	add r8, r9 	 ;now r8 is holding the top of rsp
.L_tc_recycle_frame_loop_0154:
	cmp r8,rsp	 ;if we reached the end of the stack
	je .L_tc_recycle_frame_done_0154
	mov rbx, qword[r8]	 ;rbx holds the value of the stack
	mov qword[r15], rbx	 ;move the value to the top of the stack
	sub r15, 8	 ;move the top of the stack one down
	sub r8, 8	 ;move the top of the stack one down
	jmp .L_tc_recycle_frame_loop_0154
.L_tc_recycle_frame_done_0154:
	pop rbp	 ;rbp now holding the old rbp of f
	lea rsp, [r15 + 8 *1]	 ;move the old rbp of f to the top of the stack
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_00b8
.L_if_else_00b8:
	mov rax, L_constants + 2
.L_if_end_00b8:
	jmp .L_if_end_00b9
.L_if_else_00b9:
	mov rax, L_constants + 2
.L_if_end_00b9:
	jmp .L_if_end_00ba
.L_if_else_00ba:
	mov rax, L_constants + 2
.L_if_end_00ba:
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00e2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_00da:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_4]	; free var crazy-ack
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        enter 0,0
        ;assuming we have 2 params - f and list to apply f on it
        cmp COUNT, 2
        jl L_error_arg_count_2    ; f and list
        mov r8, qword[rbp]      ;backup rbp  
        mov r9, qword[rbp +8]   ;backup ret addr
        mov r15, PARAM(1)         ;get list
        mov rax, PARAM(0)         ;get f

        assert_closure(rax)        ; Count elements in the list
        mov r10, 0                ;counter
        mov r11, r15 ; Is the list pointer
       
        
.count_loop:
        cmp r11, sob_nil ;checking if we done, it's a proper list
        je .write_over_frame
        inc r10                   ; Increment list element count
        mov r11, SOB_PAIR_CDR(r11) ;getting the next element in s if error might be here
        jmp .count_loop

        ;r10 list length

.write_over_frame:
        mov r11, r10 ;
        sub r11, 2 ;how much to increase rbp for list argumetns
        shl r11, 3 ;multiply by 8
        sub rbp, r11 ;making space for list arguemtns

.mov_env_rbp:
        mov qword[rbp], r8 ;restore old rbp ;now rbp points to the right position
        mov qword[rbp + 8], r9 ;restore old ret addr
        mov rbx, SOB_CLOSURE_ENV(rax)
        mov qword[rbp + 8*2], rbx ;save the env in the new frame
        mov qword[rbp+ 8*3], r10 ;save the number of params in the new frame
        mov r11, 0;
        ;r10 is the originl list length
.copy_list_arguments:
        cmp r11, r10 ;reached to the end of the list
        je .done_copy_list_arguments;
        mov r12, SOB_PAIR_CAR(r15) ;get the car of the list
        mov qword PARAM(r11), r12 ;copy the car to the new frame
        mov r15, SOB_PAIR_CDR(r15) ;get the cdr of the list
        inc r11
        jmp .copy_list_arguments
        ;;;rsp now points to the old ret?
        ;;;rbp now points to the older rbp?
.done_copy_list_arguments:
        lea rsp, [rbp + 8*1]
        jmp SOB_CLOSURE_CODE(rax) ;jump to the code of the closure


L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`
