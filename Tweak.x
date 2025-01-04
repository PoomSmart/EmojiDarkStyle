#define CHECK_TARGET
#import <EmojiLibrary/Header.h>
#import <UIKit/UIImage+Private.h>
#import <PSHeader/PS.h>
#import <dlfcn.h>
#import <substrate.h>
#import <version.h>

static BOOL iOS91Up;

static void prepareForDisplay(UIKeyboardEmojiCategoryBar *self) {
    Class UIKeyboardEmojiCategoryClass = %c(UIKeyboardEmojiCategory);
    NSMutableArray *categories = [UIKeyboardEmojiCategoryClass categories];
    NSUInteger count = iOS91Up ? [UIKeyboardEmojiCategoryClass enabledCategoryIndexes].count : categories.count;
    NSMutableArray <UIKBTree *> *array = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger idx = 0; idx < count; ++idx) {
        UIKBTree *tree = [[UIKBTree alloc] initWithType:8];
        NSUInteger realIdx = iOS91Up ? [UIKeyboardEmojiCategoryClass categoryTypeForCategoryIndex:idx] : idx;
        tree.displayString = [%c(UIKeyboardEmojiGraphics) emojiCategoryImagePath:categories[realIdx] forRenderConfig:self.renderConfig];
        [array addObject:tree];
    }
    UIKBTree *tree = [self valueForKey:@"m_key"];
    tree.subtrees = array;
}

static NSString *emojiCategoryImagePath(Class UIKeyboardEmojiGraphics, UIKeyboardEmojiCategory *category, UIKBRenderConfig *renderConfig) {
    if (renderConfig.lightKeyboard)
        return [UIKeyboardEmojiGraphics emojiCategoryImagePath:category];
    PSEmojiCategory categoryType = category.categoryType;
    NSString *name = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch"
    switch (categoryType) {
#pragma clang diagnostic pop
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
    return name ? name : [UIKeyboardEmojiGraphics emojiCategoryImagePath:category];
}

%hook UIKeyboardEmojiGraphics

%new(@@:@@)
+ (NSString *)emojiCategoryImagePath:(UIKeyboardEmojiCategory *)category forRenderConfig:(UIKBRenderConfig *)renderConfig {
    return emojiCategoryImagePath(self, category, renderConfig);
}

%end

%hook UIKeyboardEmojiSplitCategoryPicker

- (NSString *)symbolForRow:(NSInteger)row {
    PSEmojiCategory categoryType = iOS91Up ? [%c(UIKeyboardEmojiCategory) categoryTypeForCategoryIndex:row] : row;
    return [%c(UIKeyboardEmojiGraphics) emojiCategoryImagePath:[%c(UIKeyboardEmojiCategory) categoryForType:categoryType] forRenderConfig:self.renderConfig];
}

%end

%hook UIKeyboardEmojiCategoryBar

- (void)setNeedsDisplay {
    %orig;
    prepareForDisplay(self);
}

%end

%group preiOS83

%hook UIKeyboardEmojiGraphics

%new(@@:@)
+ (NSString *)emojiCategoryImagePath:(UIKeyboardEmojiCategory *)category {
    PSEmojiCategory categoryType = category.categoryType;
    NSString *name = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch"
    switch (categoryType) {
#pragma clang diagnostic pop
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

static NSArray *_darkIcons;
static NSMutableArray <NSString *> *darkIcons() {
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

extern UIImage *_UIImageWithName(NSString *name);
%hookf(UIImage *, _UIImageWithName, NSString *name) {
    if (name && [name hasPrefix:@"emoji_"] && [_darkIcons containsObject:name])
        return [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:[UIApplication class]]];
    return %orig;
}

%ctor {
    if (isTarget(TargetTypeApps | TargetTypeGenericExtensions)) {
        iOS91Up = IS_IOS_OR_NEWER(iOS_9_1);
#if TARGET_OS_SIMULATOR
        if (!iOS91Up)
            dlopen("/opt/simject/EmojiResources.dylib", RTLD_LAZY | RTLD_GLOBAL);
#else
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiResources.dylib", RTLD_LAZY);
#endif
        if (!IS_IOS_OR_NEWER(iOS_8_3)) {
            %init(preiOS83);
        }
        _darkIcons = darkIcons();
        %init;
    }
}
