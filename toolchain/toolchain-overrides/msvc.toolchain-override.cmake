# 4592 - symbol will be dynamically initialized (implementation limitation). More info: http://stackoverflow.com/a/34027257
# 4996 - usage of deprecated function
set( TNUN_disabled_warnings -wd4592 -wd4996 )

set( TNUN_default_warnings               -W4 )

add_definitions(
  -DNOMINMAX
  -DWIN32_LEAN_AND_MEAN
  -D_USE_MATH_DEFINES
  -D_HAS_AUTO_PTR_ETC
)

# NOMINMAX - ensures that min and max are not defined as macros which could cause problems when std::min and std::max from STL are used
# WIN32_LEAN_AND_MEAN - reduces the size of the Win32 header files by excluding some of the less frequently used APIs
# _USE_MATH_DEFINES - allow math constant definitions in math.c/cmath (https://msdn.microsoft.com/en-us/library/4hwaceh6.aspx)
# _HAS_AUTO_PTR_ETC - do not remote deprecated STL classes like auto_ptr and binary_function
