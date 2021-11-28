/* this file gets included into each file created by scc1 */

#ifndef SCC_CORE_H
#define SCC_CORE_H

#include <M2/gc-include.h>
#include <stdio.h>

#if defined(__cplusplus)
  extern "C" {
#endif
    extern void fatal(const char *s,...);

    extern void invalidTypeTag(int,const char*,int,int);
    extern void invalidNullPointer(const char*,int,int);
    extern void fatalarraylen(int,const char*,int,int);
    extern void fatalarrayindex(int,int,const char*,int,int);
    extern void outofmem2(size_t);
    #if 0
       /* GC_check_annotated_obj is no longer globally defined */
    #ifndef NDEBUG
      #include <assert.h>
      void *GC_check_annotated_obj(void *);
      #define GC_CHECK_CLOBBER(p) assert((p) == 0 || 0 == GC_check_annotated_obj(GC_base((void *)(p))))
    #else
      #define GC_CHECK_CLOBBER(p)
    #endif
    #else
      #define GC_CHECK_CLOBBER(p)
    #endif

    extern FILE* alloc_log_file;
    extern void log_frees(void* obj, void*);
    #define log_alloc(obj,type)                                           \
      do{                                                                 \
        if(alloc_log_file){                                               \
          fprintf(alloc_log_file,"A %p %s\n",(obj),(type));               \
          GC_REGISTER_FINALIZER_NO_ORDER((obj),log_frees,NULL,NULL,NULL); \
        }                                                                 \
      }while(0)

#if defined(__cplusplus)
  }
#endif


#endif

/*
# Local Variables:
# compile-command: "make -C $M2BUILDDIR/Macaulay2/c "
# End:
*/
