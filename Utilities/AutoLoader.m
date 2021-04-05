//
//  AutoLoader.m
//  Dynamo
//
//  Created by John Holdsworth on 16/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  Swizzles methods of new class versions loaded in a bundle onto original classes.
//  Include in ".ssp" bundle projects.
//

@import Foundation;

@import MachO.getsect;
@import ObjectiveC.runtime;
@import Darwin.POSIX.dlfcn;

@implementation NSObject(DynamoLoader)

+ (void)load {
    Dl_info info;
    static int sym;
    if ( !dladdr( &sym, &info ) )
        NSLog( @"Could not find load address" );

#ifndef __LP64__
    uint32_t size = 0;
    char *referencesSection = getsectdatafromheader((struct mach_header *)info.dli_fbase,
                                                    "__DATA", "__objc_classlist", &size );
#else
    uint64_t size = 0;
    char *referencesSection =
        getsectdatafromheader_64((struct mach_header_64 *)info.dli_fbase,
                                 "__DATA", "__objc_classlist", &size ) ?:
        getsectdatafromheader_64((struct mach_header_64 *)info.dli_fbase,
                                 "__DATA_CONST", "__objc_classlist", &size );
#endif

    if ( referencesSection )
        {
            Class *classReferences = (Class *)(void *)((char *)info.dli_fbase+(uint64_t)referencesSection);

            for ( unsigned long i=0 ; i<size/sizeof *classReferences ; i++ ) {
                Class newClass = classReferences[i];
                const char *className = class_getName(newClass);
                Class oldClass = objc_getClass(className);
                [newClass class];

                if  ( newClass != oldClass ) {
                    // replace Objective-C implementations for class and instance methods
                    [self swizzle:'+' className:className onto:object_getClass(oldClass) from:object_getClass(newClass)];
                    [self swizzle:'-' className:className onto:oldClass from:newClass];

                    // a little inside knowledge of Objective-C data structures for patching dispatch table ...
                    struct _in_objc_class {

                        Class meta, supr;
                        void *cache, *vtable;
                        struct _in_objc_ronly *internal;

                        // data new to swift
                        int f1, f2; // added for Beta5
                        int size, tos, mdsize, eight;

                        struct __swift_data {
                            unsigned long flags;
                            const char *className;
                            int fieldcount, flags2;
                            const char *ivarNames;
                            struct _swift_field **(*get_field_data)(void);
                        } *swiftData;

                        IMP dispatch[1];
                    };
                    
                    struct _in_objc_class *newclass = (__bridge struct _in_objc_class *)newClass;

                    // if swift language class, copy across dispatch vtable
                    if ( (uintptr_t)newclass->internal & 0x1 ) {
                        struct _in_objc_class *oldclass = (__bridge struct _in_objc_class *)oldClass;
                        size_t dispatchTableLength = oldclass->mdsize - offsetof(struct _in_objc_class, dispatch) - 2*sizeof(IMP);
                        memcpy( oldclass->dispatch, newclass->dispatch, dispatchTableLength );
                    }
                }
            }
        }
    else
        NSLog( @"Injection Error: Could not locate referencesSection" );
}

+ (void)swizzle:(char)which className:(const char *)className onto:(Class)oldClass from:(Class)newClass {
    unsigned i, mc = 0;
    Method *methods = class_copyMethodList(newClass, &mc);

    for( i=0; i<mc; i++ ) {
        SEL sel = method_getName(methods[i]);
        IMP newIMPL = method_getImplementation(methods[i]);
        const char *type = method_getTypeEncoding(methods[i]);

        NSLog( @"Swizzling: %c[%s %s] %s to: %p", which, className, sel_getName(sel), type, newIMPL );
        class_replaceMethod( oldClass, sel, newIMPL, type );
    }
    
    free(methods);
}

@end
