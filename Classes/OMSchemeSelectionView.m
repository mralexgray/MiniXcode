/**  OMSchemeSelectionView.m	 OMMiniXcode	 Created by Ole Zorn on 10.09.12.  */

#import "OMSchemeSelectionView.h"

@implementation OMSchemeSelectionView
@synthesize 	 popUpButton=_popUpButton, spinner=_spinner,	tag=_tag;

-      (id)             initWithFrame:(NSRect)frame			{
	if (self != [super initWithFrame:frame]) return nil;
	[self addSubview:_popUpButton = [NSPopUpButton.alloc initWithFrame:NSMakeRect(0, 0, frame.size.width - 20, 20)]];
	[_popUpButton.cell setControlSize: NSSmallControlSize];
	_popUpButton.autoresizingMask = NSViewWidthSizable;
	_popUpButton.bezelStyle 		= NSTexturedRoundedBezelStyle;
	_popUpButton.font					= [NSFont systemFontOfSize:11.0];
	[self addSubview:	_spinner 	= [NSProgressIndicator.alloc initWithFrame:NSMakeRect(NSMaxX(self.bounds) - 16, 2, 16, 16)]];
	_spinner.controlSize 			= NSSmallControlSize;
	_spinner.autoresizingMask 		= NSViewMinXMargin;
	_spinner.style						= NSProgressIndicatorSpinningStyle;
	_spinner.displayedWhenStopped = NO;
    return self;
}
-    (void) resizeSubviewsWithOldSize:(NSSize)oldBoundsSize	{

	[super resizeSubviewsWithOldSize:oldBoundsSize];
	self.popUpButton.frame 	= NSMakeRect(0, 0, self.bounds.size.width - 20, self.bounds.size.height);
	self.spinner.frame 		= NSMakeRect(self.bounds.size.width - 16, 2, 16, 16);
}
- (NSView*) 					   hitTest:(NSPoint)aPoint			{

	//Ignore mouse events for the spinner...
	return [self.popUpButton hitTest:[self convertPoint:aPoint fromView:self.superview]];
}
-    (BOOL) isOpaque														{	return NO;	}
-    (void) dealloc														{	[_popUpButton release];	[_spinner release];	[super dealloc];	}

@end
