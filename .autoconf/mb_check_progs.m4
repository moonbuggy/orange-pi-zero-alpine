# MB_VAR_APPEND_UNIQUE(var, string, [sep])
# ----------------------------------------
#
m4_define([MB_VAR_APPEND_UNIQUE], [[]dnl
AS_IF([test -z "$@"], AC_MSG_ERROR(mb_var_append_unique requires arguments))
AS_IF([test ! -z "$3"], [AS_VAR_SET([sep], [$3])], [AS_VAR_SET([sep], [,])])
AS_CASE([$AS_TR_SH($1)], [*"$2"*], [true], [AS_VAR_APPEND($1, ["$2$sep"])])
])[]dnl	# MB_VAR_APPEND_UNIQUE

# MB_MISSING_DISPLAY_TABLE(table)
# -------------------------------
#
m4_define([MB_MISSING_DISPLAY_TABLE], [[]dnl
AS_VAR_SET_IF([mb_missing_string_$1],
	[AS_VAR_COPY([this_list], [mb_missing_string_$1])
	AS_ECHO; AS_ECHO("At least one $1 dependency is missing")
	printf -v table_header "%24s    %s" "dependency" "source hint"
	AS_ECHO; AS_ECHO("$table_header")
	AS_ECHO([-----------------------------------------------------])
	echo $this_list | tr '!' '\n' | while read this_pair
	do
	AS_IF([test ! -z "$this_pair"], [[]dnl
		printf -v table_line "%24s    %s" "$(echo $this_pair | cut -d ',' -f 1)" "$(echo $this_pair | cut -d ',' -f 2)"
		AS_ECHO("$table_line")])[]dnl
	done; AS_ECHO])[]dnl
])[]dnl	# MB_MISSING_DISPLAY_TABLE

# MB_MISSING_DISPLAY([tables])
# ----------------------------
#
m4_define([MB_MISSING_DISPLAY], [[]dnl
AS_IF([test -z "$@"], [AS_VAR_SET([tables], [$mb_missing_strings])], [AS_VAR_SET([tables], [$@])])
echo "$tables" | tr ',' '\n' | while read this_table
do
	AS_IF([test ! -z "$this_table"], MB_MISSING_DISPLAY_TABLE([$this_table])); done
])[]dnl	# MB_MISSING_DISPLAY

# MB_MISSING_IF([types])
# ----------------------
#
m4_define([MB_MISSING_IF], [[]dnl
AS_VAR_SET([these_types], ["$@"])
AS_VAR_SET([mb_missing], [])
AS_IF([test -z "$these_types"], [AS_IF([test ! -z "$mb_missing_strings"], [AS_VAR_SET([mb_missing], 1)])],
	[echo "$these_types" | tr ',' '\n' | while read this_type
	do
		AS_CASE($mb_missing_strings, [*"$this_type"*], [AS_EXIT(1)]); done
	AS_IF([test $? = 1], [AS_VAR_SET([mb_missing], [true])])
])	])[]dnl # MB_MISSING_IF

# MB_MISSING_IF_EXIT([types])
# ---------------------------
#
m4_define([MB_MISSING_IF_EXIT], [[]dnl
AS_VAR_SET([these_types], ["$@"])
MB_MISSING_IF($these_types)
AS_IF([test ! -z "$mb_missing"],
	[MB_MISSING_DISPLAY($these_types)
	AC_MSG_ERROR([cannot continue without dependencies])])[]dnl
])[]dnl # MB_MISSING_IF_EXIT

# MB_MISSING_FLAG(type, program, [hint], [fatal])
# -----------------------------------------------
#
m4_define([MB_MISSING_FLAG], [[]dnl
AS_CASE(${mb_missing_string_$1}, [*"$2"*], [true], [
	MB_VAR_APPEND_UNIQUE([mb_missing_string_$1], [$2,$3], [!])
	MB_VAR_APPEND_UNIQUE([mb_missing_strings], [$1])
	AS_IF([test ! -z "$4"],
		[AC_MSG_NOTICE([FATAL: $2 is immediately required to proceed])
		MB_MISSING_IF_EXIT])[]dnl
]) ])[]dnl	# MB_MISSING_FLAG

# MB_CHECK_PYTHON([fatal])
# ------------------------
#
m4_define([MB_CHECK_PYTHON], [[]dnl
AC_PATH_PROGS([PYTHON], [python3 python], [no])
AS_VAR_IF([PYTHON], [no], [MB_MISSING_FLAG([required], python, python3, $1)], [
	AS_VAR_SET([PYTHON_VER], [$([$PYTHON -c "import sys; print('python' + str(sys.version_info[0]) + '.' + str(sys.version_info[1]))"])])
	AC_CHECK_PROG(PYTHON_VER, $PYTHON_VER, $PYTHON_VER, $PYTHON)
	AC_CHECK_LIB($PYTHON_VER, main, PYTHON_LIB=$PYTHON_VER, PYTHON_LIB=no)
	AS_VAR_IF([PYTHON_LIB], [no], [AC_CHECK_LIB(${PYTHON_VER}m, main, PYTHON_LIB=${PYTHON_VER}m, PYTHON_LIB=no)])
	AS_VAR_IF([PYTHON_LIB], [no], [PYTHON_HEADER=no], [AS_VAR_SET([PYTHON_HEADER], [$([$PYTHON -c "from sysconfig import *; print(get_config_var('CONFINCLUDEPY'))"])])
])	])	])[]dnl	# MB_CHECK_PYTHON

# MB_CHECK_PYMOD(type, module, [fatal])
# -------------------------------------
#
m4_define([MB_CHECK_PYMOD], [[]dnl
AC_MSG_CHECKING(python module: $2)
AS_IF([AS_VAR_TEST_SET(PYTHON)], [], [AC_MSG_ERROR([no successful Python check, cannot check Python modules])])
AS_VAR_SET_IF(AS_TR_SH(HAVE_PYMOD_$2), [AS_ECHO_N("(cached) ")],
	[$PYTHON -c "import $2" 2>/dev/null
	AS_IF([test $? = 0], [AS_VAR_SET(AS_TR_SH(HAVE_PYMOD_$2), [yes])],
		[AS_VAR_SET(AS_TR_SH(HAVE_PYMOD_$2), [no])
		MB_MISSING_FLAG([$1], [$2], [python module], [$3])])])
AC_MSG_RESULT($AS_TR_SH(HAVE_PYMOD_$2))[]dnl
])[]dnl # MB_CHECK_PYMOD

# MB_CHECK_PYMOD_REQ(module, [fatal])
# -----------------------------------
#
m4_define([MB_CHECK_PYMOD_REQ], [MB_CHECK_PYMOD(required, [$1], [$2])])[]dnl	# MB_CHECK_PYMOD_REQ

# MB_CHECK_PYMOD_REC(module, [fatal])
# -----------------------------------
#
m4_define([MB_CHECK_PYMOD_REC], [MB_CHECK_PYMOD(recommended, [$1], [$2])])[]dnl	# MB_CHECK_PYMOD_REC

# MB_CHECK_PYMODS(modules)
# ------------------------
#
m4_define([MB_CHECK_PYMODS], [m4_map_args_w($@, [MB_CHECK_PYMOD(required, ], [)])])[]dnl	# MB_CHECK_PYMODS

# MB_PATH_PROGS(type, program, [hint], [fatal])
# ---------------------------------------------
#
m4_define([MB_PATH_PROGS], [
AC_PATH_PROGS(AS_TR_SH([have_$2]), [$2], [no])
AS_VAR_IF([AS_TR_SH([have_$2])], [no],
	[AS_VAR_SET([prog_name], [$(echo $2 | cut -d ' ' -f 1)])
	MB_MISSING_FLAG([$1], [$prog_name], [$3], [$4])
])	])[]dnl	# MB_PATH_PROGS

# MB_PATH_PROGS_REC(program, [hint], [fatal])
# -------------------------------------------
#
m4_define([MB_PATH_PROGS_REC], [MB_PATH_PROGS([recommended], [$1], [$2], [$3])])[]dnl	# MB_PATH_PROGS_REC

# MB_PATH_PROGS_REQ(program, [hint], [fatal])
# -------------------------------------------
#
m4_define([MB_PATH_PROGS_REQ], [MB_PATH_PROGS([required], [$1], [$2], [$3])])[]dnl	# MB_PATH_PROGS_REQ

# MB_CHECK_HEADERS(headers, [name], [hint], [type])
# -------------------------------------------------
#
m4_define([MB_CHECK_HEADERS], [[]dnl
AS_IF([test -z "$@"], AC_MSG_ERROR(mb_check_headers requires arguments))
AC_CHECK_HEADERS([$1], [AS_VAR_SET([this_missing], [no]); break], [AS_VAR_SET([this_missing], [yes])])
AS_VAR_IF([this_missing], [no], [], [MB_MISSING_FLAG([$4], [$2], [$3])])
])[]dnl	# MB_CHECK_HEADERS

# MB_CHECK_HEADERS_REC(headers, [name], [hint])
# ---------------------------------------------
#
m4_define([MB_CHECK_HEADERS_REC], [MB_CHECK_HEADERS([$1], [$2], [$3], [recommended])])[]dnl	# MB_CHECK_HEADERS_REC

# MB_CHECK_HEADERS_REQ(headers, [name], [hint])
# ---------------------------------------------
#
m4_define([MB_CHECK_HEADERS_REQ], [MB_CHECK_HEADERS([$1], [$2], [$3], [required])])[]dnl	# MB_CHECK_HEADERS_REQ