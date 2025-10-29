# Interactive Guide & Training System

## Overview

FlutterPOS now includes a comprehensive interactive guide and training system designed to help new users and staff learn the system through step-by-step tutorials and practice environments.

## Components

### 1. GuideService (`lib/services/guide_service.dart`)

**Purpose**: Manages guide completion tracking and provides predefined guide workflows.

**Key Features**:
- Singleton pattern for global access
- Persistent completion tracking via `shared_preferences`
- Prevents duplicate guide overlays
- Predefined workflow definitions for common tasks

**API**:
```dart
// Initialize (called in main.dart)
await GuideService.instance.init();

// Check if user completed a guide
bool completed = await GuideService.instance.hasCompletedGuide('retail_pos_intro');

// Mark a guide as completed
await GuideService.instance.markGuideCompleted('retail_pos_intro');

// Get guide steps for a workflow
List<GuideStep> steps = PredefinedGuides.getGuideSteps('retail_pos_intro');
```

**Available Guides**:
- `retail_pos_intro` - Introduction to Retail Mode POS
- `retail_first_sale` - Step-by-step first sale walkthrough
- `cafe_pos_intro` - Introduction to Cafe Mode with order numbers
- `restaurant_pos_intro` - Introduction to Restaurant Mode with tables
- `categories_setup` - How to create and manage categories
- `items_setup` - How to create and manage items

### 2. Guide Widgets (`lib/widgets/guide_widgets.dart`)

#### GuideSpotlight
Highlights UI elements with pulsing animation and help bubble.

**Usage**:
```dart
GuideSpotlight(
  targetKey: GlobalKey(), // Key of widget to highlight
  message: 'Tap here to add items to cart',
  highlightColor: Color(0xFF2563EB),
  tooltipPosition: TooltipPosition.below,
)
```

#### InteractiveGuideOverlay
Full-screen overlay with step-by-step guide progression.

**Usage**:
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => InteractiveGuideOverlay(
    guideName: 'Retail POS Introduction',
    steps: PredefinedGuides.getGuideSteps('retail_pos_intro'),
    onComplete: () {
      GuideService.instance.markGuideCompleted('retail_pos_intro');
      Navigator.pop(context);
    },
    onSkip: () => Navigator.pop(context),
  ),
);
```

**Features**:
- Progress indicator (step X of Y)
- Previous/Next navigation
- Skip option
- Action hints for each step
- Icon-based visual guidance

#### FloatingGuideButton
FAB-style button to trigger guides.

**Usage**:
```dart
FloatingActionButton(
  onPressed: () { /* show guide */ },
  tooltip: 'Show Guide',
)
```

### 3. Training Data Generator (`lib/services/training_data_generator.dart`)

**Purpose**: Populate database with sample data for training and practice.

**API**:
```dart
// Load sample categories and items
await TrainingDataGenerator.instance.generateSampleCategories();
await TrainingDataGenerator.instance.generateSampleItems();

// Clear all training data
await TrainingDataGenerator.instance.clearTrainingData();
```

**Sample Data Included**:
- **Categories**: Beverages, Food, Desserts, Merchandise
- **Items**: 
  - Beverages: Espresso, Cappuccino, Iced Latte, Orange Juice
  - Food: Croissant, Sandwich, Salad Bowl
  - Desserts: Chocolate Cake, Cheesecake, Cookie
  - Merchandise: Coffee Mug, T-Shirt

## Integration Points

### POS Screens

All three POS screens now have FloatingGuideButton:
- `retail_pos_screen.dart` - Shows `retail_pos_intro` guide
- `cafe_pos_screen.dart` - Shows `cafe_pos_intro` guide
- `pos_order_screen.dart` - Shows `restaurant_pos_intro` guide

### Settings Screens

#### Categories Management
- FloatingGuideButton in bottom app bar
- Shows `categories_setup` guide

#### Training Mode Dialog (Settings Screen)
New training data management buttons:
- **Load Sample Data**: Adds sample categories and items
- **Clear All Data**: Removes all categories and items (with confirmation)

## User Workflows

### New User Onboarding

1. **First Launch**: Existing tutorial overlay shows on mode selection screen
2. **Choose Mode**: User selects Retail/Cafe/Restaurant mode
3. **Guide Trigger**: Blue help button (?) appears in bottom-right corner
4. **Interactive Tutorial**: Step-by-step guide walks through:
   - Product browsing and selection
   - Adding items to cart
   - Adjusting quantities
   - Processing checkout
   - Understanding tax and service charges

### Staff Training

1. **Enable Training Mode**: Settings → Training Mode → Enable toggle
2. **Load Sample Data**: Settings → Training Mode → Load Sample Data button
3. **Practice Transactions**: Use sample products for realistic training
4. **Access Guides**: Help buttons available on all screens
5. **Clear When Done**: Settings → Training Mode → Clear All Data

### Guide Persistence

- Guide completion tracked per device (shared_preferences)
- Guides can be re-triggered anytime via help button
- No automatic guide showing after first completion

## Technical Details

### GuideStep Data Model

```dart
class GuideStep {
  final String title;           // Short step title
  final String description;     // Detailed instructions
  final IconData icon;          // Visual icon for step
  final GlobalKey? targetKey;   // For spotlight highlighting
  final TooltipPosition? tooltipPosition;
  final List<String>? actionHints; // Bullet points of tips
}
```

### Completion Tracking

- Stored in `shared_preferences` with key pattern: `guide_completed_{guideId}`
- Boolean flag: `true` = completed, `false` or absent = not completed
- Per-device tracking (does not sync across devices)

### Preventing Duplicate Overlays

GuideService maintains `_currentlyShowingGuides` set to prevent multiple instances of the same guide.

```dart
// Check before showing
if (!GuideService.instance.canShowGuide('retail_pos_intro')) {
  return; // Already showing
}
```

## Customization Guide

### Adding a New Guide

1. **Define Guide ID** in `PredefinedGuides`:
```dart
static const String myNewGuide = 'my_new_guide';
```

2. **Create Step List**:
```dart
static final List<GuideStep> _myNewGuideSteps = [
  GuideStep(
    title: 'Step 1',
    description: 'Do this...',
    icon: Icons.star,
    actionHints: ['Hint 1', 'Hint 2'],
  ),
  // More steps...
];
```

3. **Add to getGuideSteps** method:
```dart
case 'my_new_guide':
  return _myNewGuideSteps;
```

4. **Trigger in UI**:
```dart
FloatingGuideButton(
  onPressed: () async {
    final steps = PredefinedGuides.getGuideSteps('my_new_guide');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractiveGuideOverlay(
        guideName: 'My New Guide',
        steps: steps,
        onComplete: () {
          GuideService.instance.markGuideCompleted('my_new_guide');
          Navigator.pop(context);
        },
        onSkip: () => Navigator.pop(context),
      ),
    );
  },
)
```

### Adding More Training Data

Edit `TrainingDataGenerator._getSampleItems()` to add more products:

```dart
Item(
  id: 'training_item_${_random.nextInt(100000)}',
  name: 'New Product',
  description: 'Product description',
  categoryId: categoryId,
  price: 9.99,
  cost: 3.00,
  sku: 'SKU-001',
  icon: Icons.shopping_bag,
  color: Color(0xFF4361EE),
  stock: 50,
  isAvailable: true,
  isFeatured: false,
  trackStock: true,
  sortOrder: 1,
),
```

## Best Practices

### For Developers

- **Always initialize GuideService** in main.dart before app runs
- **Use unique guide IDs** to avoid conflicts
- **Provide clear action hints** for each step
- **Test guides** on small screens for overflow safety
- **Mark guides complete** only when user finishes all steps

### For Trainers

- **Enable Training Mode** before practicing
- **Load sample data** for realistic practice
- **Complete guides in order**: 
  1. Mode introduction (retail/cafe/restaurant)
  2. First sale walkthrough
  3. Settings management (categories, items)
- **Clear data** after training sessions
- **Re-trigger guides** for refresher training

### For Users

- **Don't skip guides** on first use - they contain important information
- **Use help buttons** anytime you need assistance
- **Practice in Training Mode** before real transactions
- **Refer back to guides** if you forget a process

## Future Enhancements

Potential additions to the guide system:

- [ ] **Video tutorials**: Embedded video guides for complex workflows
- [ ] **Achievement system**: Gamification with badges for completed guides
- [ ] **Multi-language support**: Translate guide content
- [ ] **Contextual help**: Auto-trigger guides based on user actions
- [ ] **Progress dashboard**: Visual progress tracking for all guides
- [ ] **Custom guide builder**: UI for creating custom guides without coding
- [ ] **Guide analytics**: Track which steps users struggle with
- [ ] **Interactive simulations**: Practice mode with validation
- [ ] **Voice-over guides**: Audio narration option
- [ ] **AR overlays**: Augmented reality guide markers

## Troubleshooting

### Guide not showing
- Check GuideService is initialized in main.dart
- Verify guide ID exists in PredefinedGuides
- Ensure context is valid when showing dialog

### Guide appears multiple times
- Use `canShowGuide()` check before showing
- Ensure `barrierDismissible: false` in showDialog

### Training data not loading
- Check database connection
- Verify TrainingDataGenerator import
- Ensure async/await properly handled
- Check for existing data conflicts (unique constraints)

### Completion not persisting
- Verify shared_preferences is initialized
- Check GuideService.init() is awaited
- Ensure markGuideCompleted() is called on completion

## Performance Considerations

- **Initialization**: GuideService.init() is async - ensure awaited in main()
- **Spotlight animation**: Uses SingleTickerProviderStateMixin - properly disposed
- **Data generation**: TrainingDataGenerator operations are async - show loading indicators
- **Persistence**: shared_preferences I/O is async - don't block UI thread

## Accessibility

- All guide widgets support screen readers
- High contrast colors for visibility
- Large touch targets (48x48dp minimum)
- Clear text hierarchy and sizing
- Keyboard navigation support (web/desktop)

## Testing

```bash
# Run analyzer
flutter analyze

# Run tests
flutter test

# Test on Windows
flutter run -d windows
```

All guide components pass analyzer checks and tests successfully.

---

**Last Updated**: 2024
**Version**: 1.0.0
**Author**: FlutterPOS Development Team
