AC_PREREQ([2.69])
AC_INIT([orange-pi-zero-alpine], [3.11.3], [])

m4_define([mb_include], [m4_include][([$1])])dnl

mb_include(.autoconf/ax_require_defined.m4)
mb_include(.autoconf/ax_with_curses.m4)
mb_include(.autoconf/ax_python.m4)
mb_include(.autoconf/mb_check_progs.m4)
mb_include(.autoconf/pkg.m4)

PKG_PROG_PKG_CONFIG

AC_USE_SYSTEM_EXTENSIONS

### START manual block

AC_PROG_AWK
AS_VAR_IF([AWK], [:], [MB_MISSING_FLAG(required, awk)])

AC_PROG_CC
AS_VAR_IF([CC], [:], [MB_MISSING_FLAG(required, cc, c compiler)])

AC_PROG_CPP

AC_PROG_CXX
AS_VAR_IF([CXX], [:], [MB_MISSING_FLAG(required, cxx, c++ compiler)])

AX_WITH_CURSES
AS_VAR_IF([ax_cv_ncurses], [yes], [], [
	MB_MISSING_FLAG(required, ncurses libs, libncurses5-dev)
])

AC_PROG_LEX
AS_VAR_IF([LEX], [:], [MB_MISSING_FLAG(required, lex, flex)], 
	[AS_VAR_IF([LEX], [flex], [],
		[AC_SUBST([LEX_OUTPUT_ROOT], [lex.yy])
		AC_SUBST([LEXLIB], [''])])[]dnl
])[]dnl

AC_PROG_LN_S
AS_VAR_IF([LN_S], [:], [MB_MISSING_FLAG(recommended, ln -s, soft links)])

AC_PROG_RANLIB
AS_VAR_IF([RANLIB], [:], [MB_MISSING_FLAG(recommended, ranlib)])

AC_PROG_YACC
AC_PATH_PROG(YACC_INST, $YACC, no)
AS_VAR_IF([YACC_INST], [no], [
	MB_MISSING_FLAG(required, yacc, bison)
])

MB_PATH_PROGS_REQ(arm-linux-gnueabihf-gcc, gcc-arm-linux-gnueabihf)
MB_PATH_PROGS_REQ(dtc, device-tree-compiler)
MB_PATH_PROGS_REQ(git)
MB_PATH_PROGS_REQ(mkimage, u-boot-tools)
MB_PATH_PROGS_REQ(mksquashfs, squashfs-tools)
MB_PATH_PROGS_REQ(swig)

MB_CHECK_PYTHON(1)
MB_CHECK_PYMOD_REQ(distutils.core)

MB_CHECK_HEADERS_REQ([Python.h python/Python.h $PYTHON_HEADER/Python.h], [python headers], [python3-dev])
MB_CHECK_HEADERS_REQ([openssl/bio.h], [openssl headers], [libssl-dev])

### START autoscan block

# Checks for header files.
AC_FUNC_ALLOCA
AC_CHECK_HEADERS([arpa/inet.h fcntl.h fenv.h float.h inttypes.h libintl.h limits.h locale.h malloc.h memory.h mntent.h netdb.h netinet/in.h stddef.h stdint.h stdlib.h string.h strings.h sys/file.h sys/ioctl.h sys/mount.h sys/param.h sys/socket.h sys/statfs.h sys/statvfs.h sys/time.h sys/timeb.h sys/vfs.h syslog.h termios.h unistd.h utime.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL
AC_TYPE_UID_T
AC_C_INLINE
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_INT8_T
AC_TYPE_MODE_T
AC_TYPE_OFF_T
AC_TYPE_PID_T
AC_C_RESTRICT
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_CHECK_MEMBERS([struct stat.st_blksize])
AC_STRUCT_ST_BLOCKS
AC_CHECK_MEMBERS([struct stat.st_rdev])
AC_STRUCT_TIMEZONE
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T
AC_CHECK_TYPES([ptrdiff_t])

# Checks for library functions.
AC_FUNC_CHOWN
AC_FUNC_ERROR_AT_LINE
AC_FUNC_FORK
AC_FUNC_FSEEKO
AC_FUNC_GETMNTENT
AC_FUNC_LSTAT_FOLLOWS_SLASHED_SYMLINK
AC_HEADER_MAJOR
AC_FUNC_MALLOC
AC_FUNC_MKTIME
AC_FUNC_MMAP
AC_FUNC_REALLOC
AC_FUNC_STRERROR_R
#AC_FUNC_STRNLEN
AC_FUNC_STRTOD
AC_CHECK_FUNCS([alarm atexit bzero clock_gettime dup2 euidaccess fdatasync floor ftime ftruncate getcwd gethostname getmntent getpagesize gettimeofday hasmntopt inet_ntoa isascii localtime_r memchr memmove memset mkdir munmap pathconf pow putenv realpath regcomp rmdir select setenv setlocale socket sqrt strcasecmp strchr strcspn strdup strerror strncasecmp strndup strpbrk strrchr strspn strstr strtol strtoul strtoull strtoumax uname])

MB_MISSING_IF_EXIT
