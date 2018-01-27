#define CHECK_TARGET
#define CHECK_EXCEPTIONS
#import "../EmojiLibrary/Header.h"
#import "../PS.h"
#import <UIKit/UIImage+Private.h>
#import <substrate.h>

static BOOL iOS91Up;

static void prepareForDisplay(UIKeyboardEmojiCategoryBar *self) {
    NSMutableArray *categories = [NSClassFromString(@"UIKeyboardEmojiCategory") categories];
    NSUInteger count = iOS91Up ? [NSClassFromString(@"UIKeyboardEmojiCategory") enabledCategoryIndexes].count : categories.count;
    NSMutableArray <UIKBTree *> *array = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger idx = 0; idx < count; idx++) {
        UIKBTree *tree = [[UIKBTree alloc] initWithType:8];
        NSUInteger realIdx = iOS91Up ? [NSClassFromString(@"UIKeyboardEmojiCategory") categoryTypeForCategoryIndex:idx] : idx;
        tree.displayString = [NSClassFromString(@"UIKeyboardEmojiGraphics") emojiCategoryImagePath:categories[realIdx] forRenderConfig:self.renderConfig];
        [array addObject:[tree autorelease]];
    }
    MSHookIvar<UIKBTree *>(self, "m_key").subtrees = array;
}

static NSString *emojiCategoryImagePath(UIKeyboardEmojiGraphics *self, UIKeyboardEmojiCategory *category, UIKBRenderConfig *renderConfig) {
    if (renderConfig.lightKeyboard)
        return [[self class] emojiCategoryImagePath:category];
    PSEmojiCategory categoryType = category.categoryType;
    NSString *name = nil;
    switch (categoryType) {
        case PSEmojiCategoryPeople:
            name = @"emoji_people_dark.png";
            break;
        case PSEmojiCategoryNature:
            name = @"emoji_nature_dark.png";
            break;
        case PSEmojiCategoryFoodAndDrink:
            name = @"emoji_food-and-drink_dark.png";
            break;
        case PSEmojiCategoryObjects:
        case IDXPSEmojiCategoryObjects: // == PSEmojiCategoryTravelAndPlaces
            if (!iOS91Up || (categoryType == PSEmojiCategoryObjects && iOS91Up)) {
                name = @"emoji_objects_dark.png";
                break;
            }
        case IDXPSEmojiCategoryTravelAndPlaces: // == PSEmojiCategoryActivity
            if (!iOS91Up || (categoryType == PSEmojiCategoryTravelAndPlaces && iOS91Up)) {
                name = @"emoji_travel-and-places_dark.png";
                break;
            }
        case IDXPSEmojiCategoryActivity:
            name = @"emoji_activity_dark.png";
            break;
        case PSEmojiCategorySymbols:
        case PSEmojiCategoryFlags:
            if (!iOS91Up || (categoryType == PSEmojiCategorySymbols && iOS91Up))
                break;
        case IDXPSEmojiCategoryFlags:
            name = @"emoji_flags_dark.png";
            break;
    }
    return name ? name : [[self class] emojiCategoryImagePath:category];
}

%hook UIKeyboardEmojiGraphics

%new
+ (NSString *)emojiCategoryImagePath: (UIKeyboardEmojiCategory *)category forRenderConfig: (UIKBRenderConfig *)renderConfig {
    return emojiCategoryImagePath(self, category, renderConfig);
}

%end

%hook UIKeyboardEmojiSplitCategoryPicker

- (NSString *)symbolForRow: (NSInteger)row {
    PSEmojiCategory categoryType = isiOS91Up ? [NSClassFromString(@"UIKeyboardEmojiCategory") categoryTypeForCategoryIndex:row] : row;
    return [NSClassFromString(@"UIKeyboardEmojiGraphics") emojiCategoryImagePath:[NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:categoryType] forRenderConfig:self.renderConfig];
}

%end

%group iOS9Up

%hook UIKeyboardEmojiCategoryBar

- (void)prepareForDisplay {
    %orig;
    prepareForDisplay(self);
}

%end

%end

%group preiOS83

%hook UIKeyboardEmojiGraphics

%new
+ (NSString *)emojiCategoryImagePath: (UIKeyboardEmojiCategory *)category {
    PSEmojiCategory categoryType = category.categoryType;
    NSString *name = nil;
    switch (categoryType) {
        case IDXPSEmojiCategoryRecent:
            name = @"emoji_recents.png";
            break;
        case IDXPSEmojiCategoryPeople:
            name = @"emoji_people.png";
            break;
        case IDXPSEmojiCategoryNature:
            name = @"emoji_nature.png";
            break;
        case IDXPSEmojiCategoryFoodAndDrink:
            name = @"emoji_food-and-drink.png";
            break;
        case IDXPSEmojiCategoryActivity:
            name = @"emoji_activity.png";
            break;
        case IDXPSEmojiCategoryTravelAndPlaces:
            name = @"emoji_travel-and-places.png";
            break;
        case IDXPSEmojiCategoryObjects:
            name = @"emoji_objects.png";
            break;
        case IDXPSEmojiCategorySymbols:
            name = @"emoji_objects-and-symbols.png";
            break;
        case IDXPSEmojiCategoryFlags:
            name = @"emoji_flags.png";
            break;
    }
    return name;
}

%end

%end

%group preiOS9

%hook UIKeyboardEmojiCategoryBar

- (void)setNeedsDisplay {
    %orig;
    prepareForDisplay(self);
}

%end

%end

%group iOS91Up

static NSArray *_darkIcons;
static NSMutableArray *darkIcons() {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:7];
    [array addObject:@"emoji_people_dark.png"];
    [array addObject:@"emoji_nature_dark.png"];
    [array addObject:@"emoji_food-and-drink_dark.png"];
    [array addObject:@"emoji_activity_dark.png"];
    [array addObject:@"emoji_travel-and-places_dark.png"];
    [array addObject:@"emoji_objects_dark.png"];
    [array addObject:@"emoji_flags_dark.png"];
    return array;
}

extern "C" UIImage *_UIImageWithName(NSString *name);
%hookf(UIImage *, _UIImageWithName, NSString *name) {
    if (name && [name hasPrefix:@"emoji_"] && [_darkIcons containsObject:name])
        return [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:[UIApplication class]]];
    return %orig;
}

%end

%ctor {
    if (_isTarget(TargetTypeGUINoExtension, @[@"com.apple.mobilesms.compose", @"com.apple.MobileSMS.MessagesNotificationExtension"])) {
        iOS91Up = isiOS91Up;
#if TARGET_OS_SIMULATOR
        if (!iOS91Up)
            dlopen("/opt/simject/EmojiResources.dylib", RTLD_LAZY);
#else
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiResources.dylib", RTLD_LAZY);
#endif
        if (isiOS9Up) {
            %init(iOS9Up);
            if (iOS91Up) {
                _darkIcons = [darkIcons() retain];
                %init(iOS91Up);
            }
        } else {
            %init(preiOS9);
            if (!isiOS83Up) {
                %init(preiOS83);
            }
        }
        %init;
    }
}
