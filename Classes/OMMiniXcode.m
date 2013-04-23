
/**  OMMiniXcode.m   OMMiniXcode  Created by Ole Zorn on 09/07/12. */

#import "OMMiniXcode.h"
#import "OMSchemeSelectionView.h"

#define SCHEME_POPUP_BUTTON_CONTAINER_TAG	456
#define SCHEME_POPUP_BUTTON_TAG				457
#define BUILD_PROGRESS_SPINNER_TAG			458

#define kOMMiniXcodeDisableSchemeSelectionInTitleBar	@"OMMiniXcodeDisableSchemeSelectionInTitleBar"
#define NCNTR NSNotificationCenter.defaultCenter
#define UDEFS NSUserDefaults.standardUserDefaults
#define addSelfSelector(A,B) addObserver:self selector:@selector(A) name:B object:nil

//TODO: Use the actual headers from class-dump

@interface NSObject (IDEKit)
+   (id) workspaceWindowControllers;
-   (id)       activeRunDestination;
-   (id)  _bestDestinationForScheme:(id)arg1 previousDestination:(id)arg2;
- (void)        setActiveRunContext:(id)arg1   andRunDestination:(id)arg2;
@end

@implementation OMMiniXcode
-   (id)        						  init 														{

	if (self = [super init]) {
		[NCNTR addSelfSelector ( buildProductsLocationDidChange:, @"IDEWorkspaceBuildProductsLocationDidChangeNotification" )];
		[NCNTR addSelfSelector (             windowDidBecomeKey:, NSWindowDidBecomeKeyNotification								  )];
		[NCNTR addSelfSelector (     splitViewDidResizeSubviews:, NSSplitViewDidResizeSubviewsNotification						  )];
		[NCNTR addSelfSelector (         windowDidEndLiveResize:, NSWindowDidEndLiveResizeNotification							  )];
		[NCNTR addSelfSelector (			  		  buildWillStart:, @"IDEBuildOperationWillStartNotification"					  )];
		[NCNTR addSelfSelector (						 buildDidStop:, @"IDEBuildOperationDidStopNotification"						  )];

		NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
		if (viewMenuItem) {			[viewMenuItem.submenu addItem:NSMenuItem.separatorItem];
			NSMenuItem *toggleSchemeInTitleBarItem = [NSMenuItem.alloc initWithTitle:@"Scheme Selection in Title Bar"
																									action:@selector(toggleSchemeInTitleBar:)
																						  keyEquivalent:@""].autorelease;
			toggleSchemeInTitleBarItem.target = self;
			[viewMenuItem.submenu addItem:toggleSchemeInTitleBarItem];
		}

		[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
			unsigned short keyCode = [event keyCode];
			if ((keyCode == 26 || keyCode == 28) && [event modifierFlags] & NSControlKeyMask) {
				NSWindow *window 							= [NSApp keyWindow];
				OMSchemeSelectionView *schemeView 	= [self schemePopUpButtonContainerForWindow:window];
				NSPopUpButton *popUpButton 			= schemeView.popUpButton;
				BOOL toolbarVisible 						= window.toolbar.isVisible;
				if (schemeView && !toolbarVisible) {
					NSMenuItem *selectedItem 			= popUpButton.selectedItem;
					if (keyCode == 28) {
						for (NSMenuItem *item in popUpButton.menu.itemArray.reverseObjectEnumerator) {
							if (item.state == NSOnState) {
								selectedItem 				= item;
								break;
							}
						}
					}
					[popUpButton.menu popUpMenuPositioningItem:selectedItem atLocation:NSMakePoint(-14, 2) inView:popUpButton];
				} else if (popUpButton) {
					@try {
						NSToolbar *toolbar 					= window.toolbar;
						if (toolbar.items.count >= 3) {
							NSToolbarItem *schemeItem 		= [toolbar.items objectAtIndex:2];
							NSView *schemeView = schemeItem.view;
							if (schemeView.subviews.count > 0) {
								NSPathControl *pathControl = (NSPathControl *)[schemeView.subviews objectAtIndex:0];
								if ([pathControl isKindOfClass:[NSPathControl class]] && [pathControl isKindOfClass:NSClassFromString(@"IDEPathControl")]) {
									NSArray *componentCells = [pathControl pathComponentCells];
									if (componentCells.count > 1) {
										NSPathComponentCell *cell = [componentCells objectAtIndex:(keyCode == 26 ? 0 : 1)];
										if ([pathControl respondsToSelector:@selector(popUpMenuForComponentCell:)])
											[pathControl performSelector:@selector(popUpMenuForComponentCell:) withObject:cell];
									}
								}
							}
						}
					}
					@catch (NSException *exception) { }
				} else NSBeep();
				return nil;
			}
			return event;
		}];
	}
	return self;
}
+ (void)                  pluginDidLoad:(NSBundle*)plugin								{

	static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{		sharedPlugin = self.new;	});
}
- (void)              selectDestination:(id)sender											{

	id destination 			= [[sender representedObject] objectForKey:@"destination"];
	id context 					= [[sender representedObject] objectForKey:@"context"];
	@try {
		[[[NSApp keyWindow].windowController valueForKeyPath:@"_workspace.runContextManager"]
		 setActiveRunContext:context andRunDestination:destination];
	}
	@catch (NSException *exception) { }
}
- (void)               selectRunContext:(id)sender											{

	NSDictionary *info = [sender representedObject];
	id context = [info objectForKey:@"context"];
	@try {
		id runContextManager = [[NSApp keyWindow].windowController valueForKeyPath:@"_workspace.runContextManager"];
		id bestDestination = [runContextManager _bestDestinationForScheme:context previousDestination:[runContextManager activeRunDestination]];
		[runContextManager setActiveRunContext:context andRunDestination:bestDestination];
	}
	@catch (NSException *exception) { }
}
- (void)         toggleSchemeInTitleBar:(id)sender											{

	BOOL titleBarDisabled;
	[UDEFS setBool:titleBarDisabled = ![UDEFS boolForKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar] forKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar];

	@try {
		NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") workspaceWindowControllers];
		for (NSWindow *window in [workspaceWindowControllers valueForKey:@"window"]) {
			BOOL isVis = window.toolbar.isVisible;  NSLog(@"Minixode is currently:%@", isVis ? @"VISIBLE." : @"hidden.");
			isVis ? [[self schemePopUpButtonContainerForWindow:window] setHidden:(titleBarDisabled || isVis)] : nil;
			NSLog(@"Minixode is now %@", window.toolbar.isVisible ? @"still Visible!" : @"hidden.");
		}
	}
	@catch (NSException *exception) { }
}
- (BOOL)               validateMenuItem:(NSMenuItem*)menuItem							{

	if ([menuItem action] != @selector(toggleSchemeInTitleBar:)) return YES;
	BOOL toolbarVisible 	  = [NSApp keyWindow].toolbar.isVisible;
	BOOL disabled 			  = [UDEFS boolForKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar];
	menuItem.state 		  = disabled ? NSOffState : NSOnState;
	return toolbarVisible ? NO : YES;
}
- (void)                 buildWillStart:(NSNotification*)notification				{

	@try {
		NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") workspaceWindowControllers];
		for (NSWindow *window in [workspaceWindowControllers valueForKey:@"window"])
			if ([self schemePopUpButtonContainerForWindow:window]) [[self schemePopUpButtonContainerForWindow:window].spinner startAnimation:nil];
	}
	@catch (NSException *exception) { }
}
- (void)                   buildDidStop:(NSNotification*)notification				{

	@try {
		NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") workspaceWindowControllers];
		for (NSWindow *window in [workspaceWindowControllers valueForKey:@"window"]) {
			OMSchemeSelectionView *schemeView = [self schemePopUpButtonContainerForWindow:window];
			if (schemeView) {
				[schemeView.spinner stopAnimation:nil];
			}
		}
	}
	@catch (NSException *exception) { }
}
- (void)     splitViewDidResizeSubviews:(NSNotification*)notification				{

	NSSplitView *splitView = notification.object;
	//TODO: This is a bit fragile, is there a better way to detect the navigator split view?
	if (splitView.subviews.count != 3 || !splitView.isVertical) return;

	BOOL titleBarDisabled 	= [UDEFS boolForKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar];
	NSWindow *window 		 	= splitView.window;
	NSView *schemeView 	 	= [self schemePopUpButtonContainerForWindow:window];
	if (!schemeView)			return;

	BOOL toolbarVisible 		= window.toolbar.isVisible;
	schemeView.hidden 		= toolbarVisible || titleBarDisabled;
	NSView *leftMostView 	= splitView.subviews[0];
	CGFloat leftMostWidth 	= leftMostView.bounds.size.width;
	if (leftMostWidth == 0)	  leftMostWidth = 280.0; //use a default width if the navigator is hidden
	NSView *titleView 		= [self windowTitleViewForWindow:window];
	if (titleView) 			  leftMostWidth = MIN(leftMostWidth, titleView.frame.origin.x - 20);
	schemeView.frame 			= (NSRect) { schemeView.frame.origin.x, schemeView.frame.origin.y,
														leftMostWidth - 80 + 20, schemeView.frame.size.height};
}
- (void)         windowDidEndLiveResize:(NSNotification*)notification				{

	NSWindow *window 				= notification.object;
	NSView *schemeView 			= [self schemePopUpButtonContainerForWindow:window];
	if (schemeView)	return;
	double delayInSeconds 		= 0.0;
	dispatch_time_t popTime 	= dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		BOOL toolbarVisible 		= window.toolbar.isVisible;
		BOOL titleBarDisabled 	= [UDEFS boolForKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar];
		schemeView.hidden			= toolbarVisible || titleBarDisabled;
	});
}
- (void)             windowDidBecomeKey:(NSNotification*)notification				{

	NSWindow *window = notification.object;
	if ([window isKindOfClass:NSClassFromString(@"IDEWorkspaceWindow")])
		@try {
			NSWindowController *windowController = window.windowController;
			if ([windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
				id workspace = [windowController valueForKey:@"_workspace"];
				[self buildProductsLocationDidChange:[NSNotification notificationWithName:@"IDEWorkspaceBuildProductsLocationDidChangeNotification"
																										 object:workspace]];
			}
		}	@catch (NSException *exception) { }
}
- (void) buildProductsLocationDidChange:(NSNotification*)notification				{

	@try {
		id workspace = notification.object;
		if ([workspace isKindOfClass:NSClassFromString(@"IDEWorkspace")]) {
			for (NSWindowController *workspaceWindowController in [NSClassFromString(@"IDEWorkspaceWindowController") workspaceWindowControllers]) {
				id workspaceForWindowController = [workspaceWindowController valueForKey:@"_workspace"];
				if (workspace == workspaceForWindowController) {
					NSPopUpButton *popUpButton = [self schemePopUpButtonForWindow:workspaceWindowController.window];
					NSMenu *menu 					= NSMenu.alloc.init.autorelease;
					menu.font						= [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
					
					id runContextManager = [workspace 			valueForKey:@"runContextManager"];
					id activeDestination = [runContextManager valueForKey:@"_activeRunDestination"];
					id activeScheme 		= [runContextManager valueForKey:@"_activeRunContext"];
					NSArray *runContexts = [runContextManager performSelector:@selector(runContexts)];
					for (id scheme in runContexts) {
						NSMenuItem *schemeItem = [NSMenuItem.alloc initWithTitle:[scheme valueForKey:@"name"]
															action:@selector(selectRunContext:) keyEquivalent:@""].autorelease;
						schemeItem.representedObject = @{ @"context" : scheme };
						if (scheme == activeScheme) {
							schemeItem.state 	= NSOnState;
							schemeItem.title	= [NSString stringWithFormat:@"%@ | %@", [scheme name], [activeDestination displayName]];
						} else
							[schemeItem setState:NSOffState];
						NSArray *destinations = [scheme valueForKey:@"availableRunDestinations"];
						if (destinations.count > 0) {
							NSMenu *submenu = [NSMenu.alloc initWithTitle:@""].autorelease;
							schemeItem.submenu = submenu;
							for (id destination in destinations) {
								NSMenuItem *destinationItem = [NSMenuItem.alloc initWithTitle:[destination valueForKey:@"fullDisplayName"]
																				action:@selector(selectDestination:) keyEquivalent:@""].autorelease;
								destinationItem.representedObject = @{@"destination":destination,@"context":scheme};
								destinationItem.				target = self;
								destinationItem.				 state = destination == activeDestination ? NSOnState : NSOffState;
								[submenu addItem:destinationItem];
							}
						}
						schemeItem.target	= self;
						[menu addItem:schemeItem];
					}
					[menu addItem:NSMenuItem.separatorItem];
					for (id destination in [activeScheme valueForKey:@"availableRunDestinations"]) {
						NSMenuItem *destinationItem = [NSMenuItem.alloc initWithTitle:[destination valueForKey:@"fullDisplayName"]
																								 action:@selector(selectDestination:)
																					 	keyEquivalent:@""].autorelease;
						destinationItem.representedObject = @{	@"destination": destination, @"context":activeScheme };
						destinationItem.				 state = destination == activeDestination ? NSOnState : NSOffState;
						destinationItem.				target = self;
						[menu addItem:destinationItem];
					}
					[popUpButton setMenu:menu];
				}
			}
		}
	}
	@catch (NSException *exception) {	}
}
-                (NSView*) 			  windowTitleViewForWindow:(NSWindow*)window	{

	for (NSView *view in [window.contentView superview].subviews)
		if ([view isKindOfClass:NSClassFromString(@"DVTDualProxyWindowTitleView")]) return view;
	return nil;
}
-         (NSPopUpButton*)				schemePopUpButtonForWindow:(NSWindow*)window	{	return [self schemePopUpButtonContainerForWindow:window].popUpButton;	}
- (OMSchemeSelectionView*) schemePopUpButtonContainerForWindow:(NSWindow*)window	{
	if ([window isKindOfClass:NSClassFromString(@"IDEWorkspaceWindow")]) {
		NSView *windowFrameView = [window.contentView superview];
		OMSchemeSelectionView *popUpContainerView = [windowFrameView viewWithTag:SCHEME_POPUP_BUTTON_CONTAINER_TAG];
		if (!popUpContainerView) {
			
			CGFloat buttonWidth 			= 200.0;
			NSView   *titleView 			= [self windowTitleViewForWindow:window];
			if (titleView)	buttonWidth = MIN(buttonWidth, titleView.frame.origin.x - 10 - 80);
			popUpContainerView 			= [OMSchemeSelectionView.alloc initWithFrame:(NSRect){	80, windowFrameView.bounds.size.height - 22,
																															buttonWidth + 20, 20 }	].autorelease;
			popUpContainerView.tag 		= SCHEME_POPUP_BUTTON_CONTAINER_TAG;
			popUpContainerView.autoresizingMask = NSViewMinYMargin;
			BOOL   toolbarVisible		= window.toolbar.isVisible;
			BOOL titleBarDisabled 		= [UDEFS boolForKey:kOMMiniXcodeDisableSchemeSelectionInTitleBar];
			[popUpContainerView setHidden:toolbarVisible || titleBarDisabled];
			[windowFrameView addSubview:popUpContainerView];
			
		}
		return popUpContainerView;
	}
	return nil;
}
- (void)dealloc																						{	[NCNTR removeObserver:self];	[super dealloc];	}
@end









