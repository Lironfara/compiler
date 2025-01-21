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
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2016:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2030:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2042:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2057:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2073:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2091:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2106:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2116:
	db T_integer	; 0
	dq 0
	; L_constants + 2125:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2159:
	db T_interned_symbol	; +
	dq L_constants + 2106
	; L_constants + 2168:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2209:
	db T_integer	; 1
	dq 1
	; L_constants + 2218:
	db T_integer	; 2
	dq 2
free_var_0:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2106

free_var_1:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_2:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_3:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_4:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_5:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2125

free_var_6:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_7:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2042

free_var_8:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2091

free_var_9:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_10:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_11:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_12:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_13:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_14:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_15:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_16:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_17:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_18:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_19:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_20:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_21:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_22:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_23:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_24:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_25:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_26:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_27:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_28:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_29:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_30:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_31:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_32:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_33:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_34:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_35:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_36:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_37:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_38:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_39:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_40:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_41:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_42:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2073

free_var_43:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_44:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_45:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_46:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_47:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_48:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_49:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_50:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2030

free_var_51:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_52:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_53:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2016

free_var_54:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_55:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_56:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_57:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2057


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_52
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_54
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_56
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_44
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_40
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for car
	mov rdi, free_var_24
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_39
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_45
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_43
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_46
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_4
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_2
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_1
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_3
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_41
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_6
	mov rsi, L_code_ptr_integer_to_fraction
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
.L_lambda_simple_env_loop_0001:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0001
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0001
.L_lambda_simple_env_end_0001:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0001:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0001
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0001
.L_lambda_simple_params_end_0001:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0001
	jmp .L_lambda_simple_end_0001
.L_lambda_simple_code_0001:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0001
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0001:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0001
.L_tc_recycle_frame_loop_0001:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0001
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0001
.L_tc_recycle_frame_done_0001:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0001:	; new closure is in rax
	mov qword [free_var_16], rax
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
.L_lambda_simple_env_loop_0002:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0002
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0002
.L_lambda_simple_env_end_0002:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0002:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0002
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0002
.L_lambda_simple_params_end_0002:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0002
	jmp .L_lambda_simple_end_0002
.L_lambda_simple_code_0002:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0002
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0002:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0002
.L_tc_recycle_frame_loop_0002:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0002
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0002
.L_tc_recycle_frame_done_0002:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0002:	; new closure is in rax
	mov qword [free_var_23], rax
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
.L_lambda_simple_env_loop_0003:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0003
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0003
.L_lambda_simple_env_end_0003:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0003:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0003
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0003
.L_lambda_simple_params_end_0003:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0003
	jmp .L_lambda_simple_end_0003
.L_lambda_simple_code_0003:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0003
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0003:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0003
.L_tc_recycle_frame_loop_0003:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0003
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0003
.L_tc_recycle_frame_done_0003:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0003:	; new closure is in rax
	mov qword [free_var_31], rax
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
.L_lambda_simple_env_loop_0004:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0004
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0004
.L_lambda_simple_env_end_0004:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0004:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0004
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0004
.L_lambda_simple_params_end_0004:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0004
	jmp .L_lambda_simple_end_0004
.L_lambda_simple_code_0004:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0004
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0004:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0004
.L_tc_recycle_frame_loop_0004:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0004
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0004
.L_tc_recycle_frame_done_0004:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0004:	; new closure is in rax
	mov qword [free_var_38], rax
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
.L_lambda_simple_env_loop_0005:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0005
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0005
.L_lambda_simple_env_end_0005:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0005:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0005
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0005
.L_lambda_simple_params_end_0005:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0005
	jmp .L_lambda_simple_end_0005
.L_lambda_simple_code_0005:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0005
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0005:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0005
.L_tc_recycle_frame_loop_0005:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0005
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0005
.L_tc_recycle_frame_done_0005:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0005:	; new closure is in rax
	mov qword [free_var_12], rax
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
.L_lambda_simple_env_loop_0006:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0006
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0006
.L_lambda_simple_env_end_0006:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0006:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0006
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0006
.L_lambda_simple_params_end_0006:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0006
	jmp .L_lambda_simple_end_0006
.L_lambda_simple_code_0006:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0006
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0006:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0006
.L_tc_recycle_frame_loop_0006:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0006
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0006
.L_tc_recycle_frame_done_0006:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0006:	; new closure is in rax
	mov qword [free_var_15], rax
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
.L_lambda_simple_env_loop_0007:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0007
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0007
.L_lambda_simple_env_end_0007:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0007:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0007
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0007
.L_lambda_simple_params_end_0007:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0007
	jmp .L_lambda_simple_end_0007
.L_lambda_simple_code_0007:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0007
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0007:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0007
.L_tc_recycle_frame_loop_0007:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0007
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0007
.L_tc_recycle_frame_done_0007:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0007:	; new closure is in rax
	mov qword [free_var_19], rax
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
.L_lambda_simple_env_loop_0008:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0008
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0008
.L_lambda_simple_env_end_0008:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0008:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0008
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0008
.L_lambda_simple_params_end_0008:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0008
	jmp .L_lambda_simple_end_0008
.L_lambda_simple_code_0008:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0008
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0008:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0008
.L_tc_recycle_frame_loop_0008:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0008
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0008
.L_tc_recycle_frame_done_0008:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0008:	; new closure is in rax
	mov qword [free_var_22], rax
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
.L_lambda_simple_env_loop_0009:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0009
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0009
.L_lambda_simple_env_end_0009:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0009:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0009
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0009
.L_lambda_simple_params_end_0009:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0009
	jmp .L_lambda_simple_end_0009
.L_lambda_simple_code_0009:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0009
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0009:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0009
.L_tc_recycle_frame_loop_0009:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0009
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0009
.L_tc_recycle_frame_done_0009:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0009:	; new closure is in rax
	mov qword [free_var_27], rax
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
.L_lambda_simple_env_loop_000a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000a
.L_lambda_simple_env_end_000a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000a
.L_lambda_simple_params_end_000a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000a
	jmp .L_lambda_simple_end_000a
.L_lambda_simple_code_000a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000a
.L_tc_recycle_frame_loop_000a:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000a
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000a
.L_tc_recycle_frame_done_000a:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000a:	; new closure is in rax
	mov qword [free_var_30], rax
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
.L_lambda_simple_env_loop_000b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000b
.L_lambda_simple_env_end_000b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000b
.L_lambda_simple_params_end_000b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000b
	jmp .L_lambda_simple_end_000b
.L_lambda_simple_code_000b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000b
.L_tc_recycle_frame_loop_000b:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000b
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000b
.L_tc_recycle_frame_done_000b:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000b:	; new closure is in rax
	mov qword [free_var_34], rax
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
.L_lambda_simple_env_loop_000c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000c
.L_lambda_simple_env_end_000c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000c
.L_lambda_simple_params_end_000c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000c
	jmp .L_lambda_simple_end_000c
.L_lambda_simple_code_000c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000c
.L_tc_recycle_frame_loop_000c:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000c
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000c
.L_tc_recycle_frame_done_000c:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000c:	; new closure is in rax
	mov qword [free_var_37], rax
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
.L_lambda_simple_env_loop_000d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000d
.L_lambda_simple_env_end_000d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000d
.L_lambda_simple_params_end_000d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000d
	jmp .L_lambda_simple_end_000d
.L_lambda_simple_code_000d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000d
.L_tc_recycle_frame_loop_000d:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000d
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000d
.L_tc_recycle_frame_done_000d:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000d:	; new closure is in rax
	mov qword [free_var_10], rax
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
.L_lambda_simple_env_loop_000e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000e
.L_lambda_simple_env_end_000e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000e
.L_lambda_simple_params_end_000e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000e
	jmp .L_lambda_simple_end_000e
.L_lambda_simple_code_000e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000e
.L_tc_recycle_frame_loop_000e:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000e
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000e
.L_tc_recycle_frame_done_000e:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000e:	; new closure is in rax
	mov qword [free_var_11], rax
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
.L_lambda_simple_env_loop_000f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000f
.L_lambda_simple_env_end_000f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000f
.L_lambda_simple_params_end_000f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000f
	jmp .L_lambda_simple_end_000f
.L_lambda_simple_code_000f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_000f
.L_tc_recycle_frame_loop_000f:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_000f
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_000f
.L_tc_recycle_frame_done_000f:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000f:	; new closure is in rax
	mov qword [free_var_13], rax
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
.L_lambda_simple_env_loop_0010:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0010
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0010
.L_lambda_simple_env_end_0010:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0010:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0010
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0010
.L_lambda_simple_params_end_0010:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0010
	jmp .L_lambda_simple_end_0010
.L_lambda_simple_code_0010:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0010
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0010:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0010
.L_tc_recycle_frame_loop_0010:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0010
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0010
.L_tc_recycle_frame_done_0010:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0010:	; new closure is in rax
	mov qword [free_var_14], rax
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
.L_lambda_simple_env_loop_0011:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0011
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0011
.L_lambda_simple_env_end_0011:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0011:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0011
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0011
.L_lambda_simple_params_end_0011:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0011
	jmp .L_lambda_simple_end_0011
.L_lambda_simple_code_0011:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0011
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0011:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0011
.L_tc_recycle_frame_loop_0011:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0011
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0011
.L_tc_recycle_frame_done_0011:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0011:	; new closure is in rax
	mov qword [free_var_17], rax
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
.L_lambda_simple_env_loop_0012:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0012
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0012
.L_lambda_simple_env_end_0012:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0012:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0012
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0012
.L_lambda_simple_params_end_0012:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0012
	jmp .L_lambda_simple_end_0012
.L_lambda_simple_code_0012:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0012
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0012:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0012
.L_tc_recycle_frame_loop_0012:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0012
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0012
.L_tc_recycle_frame_done_0012:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0012:	; new closure is in rax
	mov qword [free_var_18], rax
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
.L_lambda_simple_env_loop_0013:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0013
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0013
.L_lambda_simple_env_end_0013:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0013:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0013
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0013
.L_lambda_simple_params_end_0013:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0013
	jmp .L_lambda_simple_end_0013
.L_lambda_simple_code_0013:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0013
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0013:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0013
.L_tc_recycle_frame_loop_0013:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0013
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0013
.L_tc_recycle_frame_done_0013:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0013:	; new closure is in rax
	mov qword [free_var_20], rax
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
.L_lambda_simple_env_loop_0014:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0014
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0014
.L_lambda_simple_env_end_0014:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0014:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0014
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0014
.L_lambda_simple_params_end_0014:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0014
	jmp .L_lambda_simple_end_0014
.L_lambda_simple_code_0014:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0014
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0014:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0014
.L_tc_recycle_frame_loop_0014:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0014
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0014
.L_tc_recycle_frame_done_0014:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0014:	; new closure is in rax
	mov qword [free_var_21], rax
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
.L_lambda_simple_env_loop_0015:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0015
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0015
.L_lambda_simple_env_end_0015:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0015:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0015
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0015
.L_lambda_simple_params_end_0015:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0015
	jmp .L_lambda_simple_end_0015
.L_lambda_simple_code_0015:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0015
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0015:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0015
.L_tc_recycle_frame_loop_0015:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0015
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0015
.L_tc_recycle_frame_done_0015:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0015:	; new closure is in rax
	mov qword [free_var_25], rax
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
.L_lambda_simple_env_loop_0016:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0016
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0016
.L_lambda_simple_env_end_0016:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0016:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0016
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0016
.L_lambda_simple_params_end_0016:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0016
	jmp .L_lambda_simple_end_0016
.L_lambda_simple_code_0016:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0016
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0016:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0016
.L_tc_recycle_frame_loop_0016:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0016
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0016
.L_tc_recycle_frame_done_0016:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0016:	; new closure is in rax
	mov qword [free_var_26], rax
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
.L_lambda_simple_env_loop_0017:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0017
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0017
.L_lambda_simple_env_end_0017:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0017:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0017
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0017
.L_lambda_simple_params_end_0017:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0017
	jmp .L_lambda_simple_end_0017
.L_lambda_simple_code_0017:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0017
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0017:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0017
.L_tc_recycle_frame_loop_0017:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0017
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0017
.L_tc_recycle_frame_done_0017:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0017:	; new closure is in rax
	mov qword [free_var_28], rax
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
.L_lambda_simple_env_loop_0018:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0018
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0018
.L_lambda_simple_env_end_0018:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0018:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0018
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0018
.L_lambda_simple_params_end_0018:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0018
	jmp .L_lambda_simple_end_0018
.L_lambda_simple_code_0018:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0018
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0018:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0018
.L_tc_recycle_frame_loop_0018:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0018
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0018
.L_tc_recycle_frame_done_0018:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0018:	; new closure is in rax
	mov qword [free_var_29], rax
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
.L_lambda_simple_env_loop_0019:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0019
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0019
.L_lambda_simple_env_end_0019:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0019:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0019
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0019
.L_lambda_simple_params_end_0019:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0019
	jmp .L_lambda_simple_end_0019
.L_lambda_simple_code_0019:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0019
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0019:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0019
.L_tc_recycle_frame_loop_0019:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0019
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0019
.L_tc_recycle_frame_done_0019:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0019:	; new closure is in rax
	mov qword [free_var_32], rax
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
.L_lambda_simple_env_loop_001a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001a
.L_lambda_simple_env_end_001a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001a
.L_lambda_simple_params_end_001a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001a
	jmp .L_lambda_simple_end_001a
.L_lambda_simple_code_001a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001a
.L_tc_recycle_frame_loop_001a:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001a
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001a
.L_tc_recycle_frame_done_001a:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001a:	; new closure is in rax
	mov qword [free_var_33], rax
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
.L_lambda_simple_env_loop_001b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001b
.L_lambda_simple_env_end_001b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001b
.L_lambda_simple_params_end_001b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001b
	jmp .L_lambda_simple_end_001b
.L_lambda_simple_code_001b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_31]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001b
.L_tc_recycle_frame_loop_001b:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001b
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001b
.L_tc_recycle_frame_done_001b:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001b:	; new closure is in rax
	mov qword [free_var_35], rax
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
.L_lambda_simple_env_loop_001c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001c
.L_lambda_simple_env_end_001c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001c
.L_lambda_simple_params_end_001c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001c
	jmp .L_lambda_simple_end_001c
.L_lambda_simple_code_001c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_38]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001c
.L_tc_recycle_frame_loop_001c:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001c
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001c
.L_tc_recycle_frame_done_001c:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001c:	; new closure is in rax
	mov qword [free_var_36], rax
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
.L_lambda_simple_env_loop_001d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001d
.L_lambda_simple_env_end_001d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001d
.L_lambda_simple_params_end_001d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001d
	jmp .L_lambda_simple_end_001d
.L_lambda_simple_code_001d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0001
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0001
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001d
.L_tc_recycle_frame_loop_001d:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001d
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001d
.L_tc_recycle_frame_done_001d:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0001
.L_if_else_0001:
	mov rax, L_constants + 2
.L_if_end_0001:
.L_or_end_0001:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001d:	; new closure is in rax
	mov qword [free_var_49], rax
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
.L_lambda_opt_env_loop_0001:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0001
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0001
.L_lambda_opt_env_end_0001:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0001:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0001
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0001
.L_lambda_opt_params_end_0001:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0001
	jmp .L_lambda_opt_end_0001
.L_lambda_opt_code_0001:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0001
	jg .L_lambda_opt_arity_check_more_0001
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0001:
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
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
	jmp .L_lambda_opt_end_0001	; new closure is in rax
.L_lambda_opt_arity_check_more_0001:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0001:
	cmp r8, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0001
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0001
.L_lambda_opt_stack_shrink_loop_exit_0001:
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
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0001:	; new closure is in rax
	mov qword [free_var_47], rax
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
.L_lambda_simple_env_loop_001e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001e
.L_lambda_simple_env_end_001e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001e
.L_lambda_simple_params_end_001e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001e
	jmp .L_lambda_simple_end_001e
.L_lambda_simple_code_001e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001e:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_0002
	mov rax, L_constants + 2
	jmp .L_if_end_0002
.L_if_else_0002:
	mov rax, L_constants + 3
.L_if_end_0002:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001e:	; new closure is in rax
	mov qword [free_var_51], rax
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
.L_lambda_simple_env_loop_001f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001f
.L_lambda_simple_env_end_001f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001f
.L_lambda_simple_params_end_001f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001f
	jmp .L_lambda_simple_end_001f
.L_lambda_simple_code_001f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0002
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_44]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001e
.L_tc_recycle_frame_loop_001e:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001e
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001e
.L_tc_recycle_frame_done_001e:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0002:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001f:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0020:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0020
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0020
.L_lambda_simple_env_end_0020:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0020:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0020
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0020
.L_lambda_simple_params_end_0020:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0020
	jmp .L_lambda_simple_end_0020
.L_lambda_simple_code_0020:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0020
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0020:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0021:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0021
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0021
.L_lambda_simple_env_end_0021:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0021:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0021
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0021
.L_lambda_simple_params_end_0021:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0021
	jmp .L_lambda_simple_end_0021
.L_lambda_simple_code_0021:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0021
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0021:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0003
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_0003
.L_if_else_0003:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_001f
.L_tc_recycle_frame_loop_001f:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_001f
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_001f
.L_tc_recycle_frame_done_001f:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0003:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0021:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0002:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0002
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0002
.L_lambda_opt_env_end_0002:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0002:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0002
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0002
.L_lambda_opt_params_end_0002:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0002
	jmp .L_lambda_opt_end_0002
.L_lambda_opt_code_0002:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0002
	jg .L_lambda_opt_arity_check_more_0002
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0002:
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
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0021
.L_tc_recycle_frame_loop_0021:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0021
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0021
.L_tc_recycle_frame_done_0021:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_0002	; new closure is in rax
.L_lambda_opt_arity_check_more_0002:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0002:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_0002
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0002
.L_lambda_opt_stack_shrink_loop_exit_0002:
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
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0020
.L_tc_recycle_frame_loop_0020:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0020
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0020
.L_tc_recycle_frame_done_0020:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0002:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0020:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0022:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0022
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0022
.L_lambda_simple_env_end_0022:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0022:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0022
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0022
.L_lambda_simple_params_end_0022:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0022
	jmp .L_lambda_simple_end_0022
.L_lambda_simple_code_0022:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0022
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0022:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0023:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0023
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0023
.L_lambda_simple_env_end_0023:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0023:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0023
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0023
.L_lambda_simple_params_end_0023:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0023
	jmp .L_lambda_simple_end_0023
.L_lambda_simple_code_0023:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0023
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0023:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0004
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0022
.L_tc_recycle_frame_loop_0022:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0022
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0022
.L_tc_recycle_frame_done_0022:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0004
.L_if_else_0004:
	mov rax, PARAM(0)	; param a
.L_if_end_0004:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0023:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0003:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0003
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0003
.L_lambda_opt_env_end_0003:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0003:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0003
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0003
.L_lambda_opt_params_end_0003:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0003
	jmp .L_lambda_opt_end_0003
.L_lambda_opt_code_0003:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0003
	jg .L_lambda_opt_arity_check_more_0003
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0003:
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
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0024
.L_tc_recycle_frame_loop_0024:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0024
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0024
.L_tc_recycle_frame_done_0024:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_0003	; new closure is in rax
.L_lambda_opt_arity_check_more_0003:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0003:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_0003
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0003
.L_lambda_opt_stack_shrink_loop_exit_0003:
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
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0023
.L_tc_recycle_frame_loop_0023:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0023
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0023
.L_tc_recycle_frame_done_0023:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0003:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0022:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_9], rax
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
.L_lambda_opt_env_loop_0004:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0004
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0004
.L_lambda_opt_env_end_0004:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0004:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0004
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0004
.L_lambda_opt_params_end_0004:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0004
	jmp .L_lambda_opt_end_0004
.L_lambda_opt_code_0004:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0004
	jg .L_lambda_opt_arity_check_more_0004
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0004:
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
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0026:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0026
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0026
.L_lambda_simple_env_end_0026:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0026:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0026
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0026
.L_lambda_simple_params_end_0026:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0026
	jmp .L_lambda_simple_end_0026
.L_lambda_simple_code_0026:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0026
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0026:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

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
.L_lambda_simple_env_loop_0027:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0027
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0027
.L_lambda_simple_env_end_0027:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0027:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0027
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0027
.L_lambda_simple_params_end_0027:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0027
	jmp .L_lambda_simple_end_0027
.L_lambda_simple_code_0027:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0027
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0027:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0007
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0004
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0028
.L_tc_recycle_frame_loop_0028:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0028
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0028
.L_tc_recycle_frame_done_0028:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0004:
	jmp .L_if_end_0007
.L_if_else_0007:
	mov rax, L_constants + 2
.L_if_end_0007:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0027:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0008
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0029
.L_tc_recycle_frame_loop_0029:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0029
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0029
.L_tc_recycle_frame_done_0029:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0008
.L_if_else_0008:
	mov rax, L_constants + 2
.L_if_end_0008:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0026:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002a
.L_tc_recycle_frame_loop_002a:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002a
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002a
.L_tc_recycle_frame_done_002a:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_0004	; new closure is in rax
.L_lambda_opt_arity_check_more_0004:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0004:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_0004
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0004
.L_lambda_opt_stack_shrink_loop_exit_0004:
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
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0024:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0024
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0024
.L_lambda_simple_env_end_0024:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0024:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0024
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0024
.L_lambda_simple_params_end_0024:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0024
	jmp .L_lambda_simple_end_0024
.L_lambda_simple_code_0024:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0024
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0024:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

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
.L_lambda_simple_env_loop_0025:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0025
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0025
.L_lambda_simple_env_end_0025:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0025:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0025
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0025
.L_lambda_simple_params_end_0025:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0025
	jmp .L_lambda_simple_end_0025
.L_lambda_simple_code_0025:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0025
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0025:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0005
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0003
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0025
.L_tc_recycle_frame_loop_0025:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0025
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0025
.L_tc_recycle_frame_done_0025:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0003:
	jmp .L_if_end_0005
.L_if_else_0005:
	mov rax, L_constants + 2
.L_if_end_0005:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0025:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0006
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0026
.L_tc_recycle_frame_loop_0026:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0026
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0026
.L_tc_recycle_frame_done_0026:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0006
.L_if_else_0006:
	mov rax, L_constants + 2
.L_if_end_0006:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0024:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0027
.L_tc_recycle_frame_loop_0027:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0027
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0027
.L_tc_recycle_frame_done_0027:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0004:	; new closure is in rax
	mov qword [free_var_53], rax
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
.L_lambda_opt_env_loop_0005:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0005
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0005
.L_lambda_opt_env_end_0005:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0005:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0005
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0005
.L_lambda_opt_params_end_0005:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0005
	jmp .L_lambda_opt_end_0005
.L_lambda_opt_code_0005:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0005
	jg .L_lambda_opt_arity_check_more_0005
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0005:
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
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_002a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_002a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002a
.L_lambda_simple_env_end_002a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_002a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002a
.L_lambda_simple_params_end_002a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002a
	jmp .L_lambda_simple_end_002a
.L_lambda_simple_code_002a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002a:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

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
.L_lambda_simple_env_loop_002b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_002b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002b
.L_lambda_simple_env_end_002b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_002b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002b
.L_lambda_simple_params_end_002b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002b
	jmp .L_lambda_simple_end_002b
.L_lambda_simple_code_002b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002b:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0007
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000b
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002e
.L_tc_recycle_frame_loop_002e:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002e
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002e
.L_tc_recycle_frame_done_002e:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_000b
.L_if_else_000b:
	mov rax, L_constants + 2
.L_if_end_000b:
.L_or_end_0007:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002b:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0008
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000c
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002f
.L_tc_recycle_frame_loop_002f:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002f
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002f
.L_tc_recycle_frame_done_002f:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_000c
.L_if_else_000c:
	mov rax, L_constants + 2
.L_if_end_000c:
.L_or_end_0008:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0030
.L_tc_recycle_frame_loop_0030:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0030
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0030
.L_tc_recycle_frame_done_0030:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_0005	; new closure is in rax
.L_lambda_opt_arity_check_more_0005:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0005:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_0005
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0005
.L_lambda_opt_stack_shrink_loop_exit_0005:
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
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0028:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0028
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0028
.L_lambda_simple_env_end_0028:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0028:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0028
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0028
.L_lambda_simple_params_end_0028:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0028
	jmp .L_lambda_simple_end_0028
.L_lambda_simple_code_0028:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0028
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0028:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

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
.L_lambda_simple_env_loop_0029:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0029
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0029
.L_lambda_simple_env_end_0029:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0029:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0029
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0029
.L_lambda_simple_params_end_0029:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0029
	jmp .L_lambda_simple_end_0029
.L_lambda_simple_code_0029:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0029
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0029:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0005
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0009
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002b
.L_tc_recycle_frame_loop_002b:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002b
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002b
.L_tc_recycle_frame_done_002b:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0009
.L_if_else_0009:
	mov rax, L_constants + 2
.L_if_end_0009:
.L_or_end_0005:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0029:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0006
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000a
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002c
.L_tc_recycle_frame_loop_002c:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002c
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002c
.L_tc_recycle_frame_done_002c:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_000a
.L_if_else_000a:
	mov rax, L_constants + 2
.L_if_end_000a:
.L_or_end_0006:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0028:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_002d
.L_tc_recycle_frame_loop_002d:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_002d
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_002d
.L_tc_recycle_frame_done_002d:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0005:	; new closure is in rax
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
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
.L_lambda_simple_env_loop_002c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002c
.L_lambda_simple_env_end_002c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002c
.L_lambda_simple_params_end_002c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002c
	jmp .L_lambda_simple_end_002c
.L_lambda_simple_code_002c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002c:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rbx, qword [rbp + 8 * (4 + 1)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_002d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_002d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002d
.L_lambda_simple_env_end_002d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_002d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002d
.L_lambda_simple_params_end_002d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002d
	jmp .L_lambda_simple_end_002d
.L_lambda_simple_code_002d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000d
	mov rax, L_constants + 1
	jmp .L_if_end_000d
.L_if_else_000d:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0031
.L_tc_recycle_frame_loop_0031:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0031
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0031
.L_tc_recycle_frame_done_0031:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_000d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002d:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_002e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_002e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002e
.L_lambda_simple_env_end_002e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_002e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002e
.L_lambda_simple_params_end_002e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002e
	jmp .L_lambda_simple_end_002e
.L_lambda_simple_code_002e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002e:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000e
	mov rax, L_constants + 1
	jmp .L_if_end_000e
.L_if_else_000e:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0032
.L_tc_recycle_frame_loop_0032:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0032
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0032
.L_tc_recycle_frame_done_0032:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_000e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002e:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0006:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0006
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0006
.L_lambda_opt_env_end_0006:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0006:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0006
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0006
.L_lambda_opt_params_end_0006:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0006
	jmp .L_lambda_opt_end_0006
.L_lambda_opt_code_0006:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0006
	jg .L_lambda_opt_arity_check_more_0006
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0006:
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
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0010
	mov rax, L_constants + 1
	jmp .L_if_end_0010
.L_if_else_0010:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0034
.L_tc_recycle_frame_loop_0034:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0034
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0034
.L_tc_recycle_frame_done_0034:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0010:
	leave
	ret AND_KILL_FRAME(2)
	jmp .L_lambda_opt_end_0006	; new closure is in rax
.L_lambda_opt_arity_check_more_0006:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0006:
	cmp r8, 1
	je .L_lambda_opt_stack_shrink_loop_exit_0006
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0006
.L_lambda_opt_stack_shrink_loop_exit_0006:
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
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_000f
	mov rax, L_constants + 1
	jmp .L_if_end_000f
.L_if_else_000f:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0033
.L_tc_recycle_frame_loop_0033:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0033
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0033
.L_tc_recycle_frame_done_0033:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_000f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0006:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_50], rax
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
.L_lambda_simple_env_loop_002f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002f
.L_lambda_simple_env_end_002f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002f
.L_lambda_simple_params_end_002f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002f
	jmp .L_lambda_simple_end_002f
.L_lambda_simple_code_002f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002f:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0030:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0030
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0030
.L_lambda_simple_env_end_0030:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0030:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0030
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0030
.L_lambda_simple_params_end_0030:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0030
	jmp .L_lambda_simple_end_0030
.L_lambda_simple_code_0030:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0030
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0030:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0035
.L_tc_recycle_frame_loop_0035:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0035
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0035
.L_tc_recycle_frame_done_0035:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0030:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_42]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0036
.L_tc_recycle_frame_loop_0036:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0036
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0036
.L_tc_recycle_frame_done_0036:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002f:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
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
.L_lambda_simple_env_loop_0031:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0031
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0031
.L_lambda_simple_env_end_0031:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0031:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0031
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0031
.L_lambda_simple_params_end_0031:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0031
	jmp .L_lambda_simple_end_0031
.L_lambda_simple_code_0031:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0031
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0031:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rbx, qword [rbp + 8 * (4 + 1)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0032:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0032
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0032
.L_lambda_simple_env_end_0032:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0032:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0032
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0032
.L_lambda_simple_params_end_0032:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0032
	jmp .L_lambda_simple_end_0032
.L_lambda_simple_code_0032:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0032
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0032:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0011
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_0011
.L_if_else_0011:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0037
.L_tc_recycle_frame_loop_0037:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0037
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0037
.L_tc_recycle_frame_done_0037:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0011:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0032:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0033:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0033
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0033
.L_lambda_simple_env_end_0033:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0033:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0033
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0033
.L_lambda_simple_params_end_0033:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0033
	jmp .L_lambda_simple_end_0033
.L_lambda_simple_code_0033:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0033
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0033:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0012
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_0012
.L_if_else_0012:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0038
.L_tc_recycle_frame_loop_0038:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0038
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0038
.L_tc_recycle_frame_done_0038:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0012:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0033:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0007:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0007
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0007
.L_lambda_opt_env_end_0007:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0007:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0007
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0007
.L_lambda_opt_params_end_0007:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0007
	jmp .L_lambda_opt_end_0007
.L_lambda_opt_code_0007:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0007
	jg .L_lambda_opt_arity_check_more_0007
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0007:
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
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0014
	mov rax, L_constants + 1
	jmp .L_if_end_0014
.L_if_else_0014:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003a
.L_tc_recycle_frame_loop_003a:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003a
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003a
.L_tc_recycle_frame_done_003a:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0014:
	leave
	ret AND_KILL_FRAME(1)
	jmp .L_lambda_opt_end_0007	; new closure is in rax
.L_lambda_opt_arity_check_more_0007:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0007:
	cmp r8, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0007
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0007
.L_lambda_opt_stack_shrink_loop_exit_0007:
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
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0013
	mov rax, L_constants + 1
	jmp .L_if_end_0013
.L_if_else_0013:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0039
.L_tc_recycle_frame_loop_0039:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0039
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0039
.L_tc_recycle_frame_done_0039:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0013:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0007:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0031:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0034:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0034
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0034
.L_lambda_simple_env_end_0034:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0034:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0034
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0034
.L_lambda_simple_params_end_0034:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0034
	jmp .L_lambda_simple_end_0034
.L_lambda_simple_code_0034:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0034
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0034:
	enter 0, 0
	mov rbx, qword [rbp + 8 * (4 + 0)]
	mov qword [rbx], rax

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0035:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0035
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0035
.L_lambda_simple_env_end_0035:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0035:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0035
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0035
.L_lambda_simple_params_end_0035:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0035
	jmp .L_lambda_simple_end_0035
.L_lambda_simple_code_0035:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0035
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0035:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_52]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0015
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0015
.L_if_else_0015:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_39]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_24]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, qword [free_var_9]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003b
.L_tc_recycle_frame_loop_003b:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003b
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003b
.L_tc_recycle_frame_done_003b:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0015:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0035:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0008:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0008
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0008
.L_lambda_opt_env_end_0008:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0008:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0008
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0008
.L_lambda_opt_params_end_0008:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0008
	jmp .L_lambda_opt_end_0008
.L_lambda_opt_code_0008:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_0008
	jg .L_lambda_opt_arity_check_more_0008
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0008:
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
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003d
.L_tc_recycle_frame_loop_003d:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003d
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003d
.L_tc_recycle_frame_done_003d:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
	jmp .L_lambda_opt_end_0008	; new closure is in rax
.L_lambda_opt_arity_check_more_0008:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0008:
	cmp r8, 2
	je .L_lambda_opt_stack_shrink_loop_exit_0008
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0008
.L_lambda_opt_stack_shrink_loop_exit_0008:
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
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003c
.L_tc_recycle_frame_loop_003c:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003c
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003c
.L_tc_recycle_frame_done_003c:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0008:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0034:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0036:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0036
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0036
.L_lambda_simple_env_end_0036:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0036:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0036
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0036
.L_lambda_simple_params_end_0036:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0036
	jmp .L_lambda_simple_end_0036
.L_lambda_simple_code_0036:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0036
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0036:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2168
	push rax
	mov rax, L_constants + 2159
	push rax
	push 2	; arg count
	mov rax, qword [free_var_41]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003e
.L_tc_recycle_frame_loop_003e:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003e
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003e
.L_tc_recycle_frame_done_003e:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0036:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0037:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0037
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0037
.L_lambda_simple_env_end_0037:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0037:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0037
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0037
.L_lambda_simple_params_end_0037:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0037
	jmp .L_lambda_simple_end_0037
.L_lambda_simple_code_0037:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0037
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0037:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0038:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0038
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0038
.L_lambda_simple_env_end_0038:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0038:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0038
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0038
.L_lambda_simple_params_end_0038:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0038
	jmp .L_lambda_simple_end_0038
.L_lambda_simple_code_0038:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0038
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0038:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0021
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0018
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_003f
.L_tc_recycle_frame_loop_003f:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_003f
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_003f
.L_tc_recycle_frame_done_003f:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0018
.L_if_else_0018:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_44]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0017
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0040
.L_tc_recycle_frame_loop_0040:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0040
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0040
.L_tc_recycle_frame_done_0040:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0017
.L_if_else_0017:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0016
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_45]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0041
.L_tc_recycle_frame_loop_0041:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0041
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0041
.L_tc_recycle_frame_done_0041:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0016
.L_if_else_0016:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 0	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0042
.L_tc_recycle_frame_loop_0042:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0042
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0042
.L_tc_recycle_frame_done_0042:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0016:
.L_if_end_0017:
.L_if_end_0018:
	jmp .L_if_end_0021
.L_if_else_0021:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_44]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0020
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001b
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_5]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0043
.L_tc_recycle_frame_loop_0043:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0043
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0043
.L_tc_recycle_frame_done_0043:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_001b
.L_if_else_001b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_44]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001a
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0044
.L_tc_recycle_frame_loop_0044:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0044
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0044
.L_tc_recycle_frame_done_0044:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_001a
.L_if_else_001a:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0019
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_43]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0045
.L_tc_recycle_frame_loop_0045:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0045
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0045
.L_tc_recycle_frame_done_0045:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0019
.L_if_else_0019:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 0	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0046
.L_tc_recycle_frame_loop_0046:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0046
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0046
.L_tc_recycle_frame_done_0046:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0019:
.L_if_end_001a:
.L_if_end_001b:
	jmp .L_if_end_0020
.L_if_else_0020:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001e
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_45]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0047
.L_tc_recycle_frame_loop_0047:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0047
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0047
.L_tc_recycle_frame_done_0047:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_001e
.L_if_else_001e:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_44]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001d
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_43]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0048
.L_tc_recycle_frame_loop_0048:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0048
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0048
.L_tc_recycle_frame_done_0048:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_001d
.L_if_else_001d:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_001c
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 2	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_0049
.L_tc_recycle_frame_loop_0049:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_0049
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_0049
.L_tc_recycle_frame_done_0049:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_001c
.L_if_else_001c:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 0	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_004a
.L_tc_recycle_frame_loop_004a:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_004a
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_004a
.L_tc_recycle_frame_done_004a:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_001c:
.L_if_end_001d:
.L_if_end_001e:
	jmp .L_if_end_001f
.L_if_else_001f:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 0	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_004b
.L_tc_recycle_frame_loop_004b:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_004b
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_004b
.L_tc_recycle_frame_done_004b:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_001f:
.L_if_end_0020:
.L_if_end_0021:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0038:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0039:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0039
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0039
.L_lambda_simple_env_end_0039:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0039:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0039
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0039
.L_lambda_simple_params_end_0039:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0039
	jmp .L_lambda_simple_end_0039
.L_lambda_simple_code_0039:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0039
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0039:
	enter 0, 0
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
.L_lambda_opt_env_loop_0009:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0009
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0009
.L_lambda_opt_env_end_0009:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0009:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0009
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0009
.L_lambda_opt_params_end_0009:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0009
	jmp .L_lambda_opt_end_0009
.L_lambda_opt_code_0009:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0009
	jg .L_lambda_opt_arity_check_more_0009
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0009:
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
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2116
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_42]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_004d
.L_tc_recycle_frame_loop_004d:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_004d
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_004d
.L_tc_recycle_frame_done_004d:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
	jmp .L_lambda_opt_end_0009	; new closure is in rax
.L_lambda_opt_arity_check_more_0009:
	mov rax, qword[rsp + 2 * 8]
	mov rdi, rax
	mov r9, sob_nil
	mov r8, qword[rsp+2*8]
.L_lambda_opt_stack_shrink_loop_0009:
	cmp r8, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0009
	mov rbx, qword[rsp + 8 * (2 + r8)]
	mov rdi, 1+8+8	;for pair
	call malloc	 ;to create the pair in the stack
	mov byte [rax], T_pair	 ; to make it a pair
	mov qword[rax+1],rbx	 ;put the car in the last (not inside of the list yet) in the pair
 	mov qword[rax+1+8],r9
	mov r9 , rax	 ; for the recursion 
	dec r8
	jmp .L_lambda_opt_stack_shrink_loop_0009
.L_lambda_opt_stack_shrink_loop_exit_0009:
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
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2116
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_42]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 3	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_004c
.L_tc_recycle_frame_loop_004c:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_004c
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_004c
.L_tc_recycle_frame_done_004c:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0009:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0039:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword[rbp+ 8 * 1]	 ;old ret address of f
	push qword[rbp]
	mov rbx, qword[rsp+8*2]	 ;rbx holds the lexical enviroment of h
	mov qword[rbp + 8*2],rbx
	mov qword[rbp + 8*3], 1	 ;n turns to m
	mov rdi,0
	jmp .L_tc_recycle_frame_loop_004e
.L_tc_recycle_frame_loop_004e:
	cmp rdi, qword[rbp + 8*3]	 ;if rdi is equal to the number of parans - we donec
	je .L_tc_recycle_frame_done_004e
	mov rbx, qword[rsp + 8 * (4 + rdi)]
	mov qword[rbp + 8 * (4 + rdi)],rbx
	inc rdi
	jmp .L_tc_recycle_frame_loop_004e
.L_tc_recycle_frame_done_004e:
	mov rsp, rbp	; point to last argument
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0037:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 2218
	push rax
	mov rax, L_constants + 2209
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var +
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
        enter 0, 0
        cmp COUNT, 2
        jl L_error_arg_count_2    ; Need at least 2 arguments
        
        mov r8, COUNT             ; Save original argument count
        dec r8                    ; Last argument is the list
        mov r9, PARAM(r8)         ; Get the list (last argument)
        mov rbx, PARAM(0)         ; Get the function (first argument)
        ; Count elements in the list
        mov r10, 0                ; List element counter
        mov r11, r9               ; List pointer for counting

        
.count_loop:
        cmp byte [r11], T_nil
        je .prepare_stack
        assert_pair(r11)
        inc r10                   ; Increment list element count
        mov r11, SOB_PAIR_CDR(r11)
        jmp .count_loop

.prepare_stack:
        ; Calculate total arguments (direct args + list elements)
        mov r11, 0             ; Number of direct arguments
        add r11, r10            ; Add list elements count
        
        ; Allocate new frame
        mov rax, r11            ; Total argument count
        shl rax, 3              ; Multiply by 8 for byte count
        add rax, 8*4            ; Add space for ret, env, old rbp, arg count
        mov r12, rax            ; Save frame size
        
        sub rsp, r12            ; Allocate frame
        
        ; Copy direct arguments (excluding the list)
        mov rcx, r8              ; Number of direct arguments
        dec rcx                  ; Exclude the list
        mov rdx, 0              ; Destination offset

.copy_list:
        ; Copy list elements
        mov r13, r9             ; List pointer
.copy_list_loop:
        cmp byte [r13], T_nil
        je .finish_frame
        mov rax, SOB_PAIR_CAR(r13)    ; Get list element
        mov [rsp + 8*4 + rdx*8], rax  ; Store in frame
        inc rdx
        mov r13, SOB_PAIR_CDR(r13)
        jmp .copy_list_loop

.finish_frame:
        ; Set up frame
        mov rax, r11            ; Total argument count
        mov [rsp + 8*3], rax    ; Store argument count
        mov rax, [rbp + 8*2]    ; Get current env
        mov [rsp + 8*2], rax    ; Store env
        mov rax, [rbp + 8*1]    ; Get return address
        mov [rsp + 8*1], rax    ; Store return address
        mov rax, rbp            ; Get old rbp
        mov [rsp], rax          ; Store old rbp
        
        ; Get the function
        mov rax, rbx
        assert_closure(rax)
        
        ; Set up for call
        mov rbp, rsp            ; Set new frame pointer
        mov rsp, rbp            ; Align stack pointer
        
        ; Call the function
        push SOB_CLOSURE_ENV(rax)
        call SOB_CLOSURE_CODE(rax)
                
        leave
        ret AND_KILL_FRAME(2)
        
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
