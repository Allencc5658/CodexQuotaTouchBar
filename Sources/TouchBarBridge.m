#import <AppKit/AppKit.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <objc/message.h>

typedef void (*ControlStripPresence)(NSString *, BOOL);

static ControlStripPresence presenceFunction(void) {
    static ControlStripPresence function = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *framework = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation",
                                 RTLD_LAZY | RTLD_LOCAL);
        if (framework) {
            function = (ControlStripPresence)dlsym(framework,
                "DFRElementSetControlStripPresenceForIdentifier");
        }
    });
    return function;
}

static SEL showSelector(void) {
    SEL modern = sel_registerName("presentSystemModalTouchBar:systemTrayItemIdentifier:");
    if ([NSTouchBar respondsToSelector:modern]) return modern;
    SEL legacy = sel_registerName("presentSystemModalFunctionBar:systemTrayItemIdentifier:");
    return [NSTouchBar respondsToSelector:legacy] ? legacy : NULL;
}

bool CQTouchBarAvailable(void) {
    return showSelector() != NULL &&
        presenceFunction() != NULL &&
        [NSTouchBarItem respondsToSelector:sel_registerName("addSystemTrayItem:")];
}

bool CQAddTrayItem(NSTouchBarItem *item) {
    SEL selector = sel_registerName("addSystemTrayItem:");
    if (![NSTouchBarItem respondsToSelector:selector]) return false;
    ((void (*)(id, SEL, id))objc_msgSend)(NSTouchBarItem.class, selector, item);
    ControlStripPresence presence = presenceFunction();
    if (presence) presence(item.identifier, YES);
    return true;
}

bool CQPresentTouchBar(NSTouchBar *bar, NSString *trayIdentifier) {
    SEL selector = showSelector();
    if (!selector) return false;
    ((void (*)(id, SEL, id, id))objc_msgSend)(NSTouchBar.class, selector, bar, trayIdentifier);
    return true;
}

void CQDismissTouchBar(NSTouchBar *bar) {
    SEL selector = sel_registerName("dismissSystemModalTouchBar:");
    if (![NSTouchBar respondsToSelector:selector]) {
        selector = sel_registerName("dismissSystemModalFunctionBar:");
    }
    if ([NSTouchBar respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(NSTouchBar.class, selector, bar);
    }
}

void CQRemoveTrayItem(NSTouchBarItem *item) {
    ControlStripPresence presence = presenceFunction();
    if (presence) presence(item.identifier, NO);
    SEL selector = sel_registerName("removeSystemTrayItem:");
    if ([NSTouchBarItem respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(NSTouchBarItem.class, selector, item);
    }
}
