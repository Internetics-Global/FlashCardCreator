
#import "UIImageView+Extensions.h"
#import <objc/runtime.h>

@implementation UIImageView (Extensions)

@dynamic hitTestEdgeInsets;
@dynamic bypassTransparentColor;

static const NSString *KEY_HIT_TEST_EDGE_INSETS = @"HitTestEdgeInsets";

static char const * const KEY_HIT_TEST_BYPASS_TRANSPARENT_COLOR = "BypassTransparentColor";

- (void)setBypassTransparentColor:(BOOL)bypassTransparentColor {
    NSNumber *number = [NSNumber numberWithBool: bypassTransparentColor];
    objc_setAssociatedObject(self, KEY_HIT_TEST_BYPASS_TRANSPARENT_COLOR, number , OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bypassTransparentColor {
    
    NSNumber *number = objc_getAssociatedObject(self, KEY_HIT_TEST_BYPASS_TRANSPARENT_COLOR);
    return [number boolValue];
    
}


-(void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = [NSValue value:&hitTestEdgeInsets withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS);
    if(value) {
        UIEdgeInsets edgeInsets; [value getValue:&edgeInsets]; return edgeInsets;
    }else {
        return UIEdgeInsetsZero;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (self.bypassTransparentColor) {
        
        BOOL transparent = [self transparentAtPoint:point];
        
        if (transparent == YES) {
            return false;
        }
    }
    
    if(UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || self.hidden) {
        return [super pointInside:point withEvent:event];
    }
    
    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);
    
    return CGRectContainsPoint(hitFrame, point);
}



/**
 *  Special in this project, we ignore those image location with alpha value = 0
 */
- (BOOL) transparentAtPoint:(CGPoint)point
{
    unsigned char pixel[4] = {0};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [self.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    //NSLog(@"pixel: %d %d %d %d", pixel[0], pixel[1], pixel[2], pixel[3]);
    
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
    
    return pixel[3] <0.01;
}

@end
