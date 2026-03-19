## Plan: Improve statistics, streak, dark/light mode, and notifications

TL;DR: Nâng cấp hệ thống thống kê hiện có trong Habit Tracker bằng cách mở rộng model và provider, làm mới UI/Statistics/Home, thêm theme tùy chọn (light/dark) và tích hợp thông báo nhắc nhở với lưu cài đặt.

Steps
1. Data model enhancements (Habit class): longest streak, average streak, success rate timeline, monthly goal.
2. Habit statistics utilities: create class / methods for overall metrics (total habits, completed count, average completion, best/longest streak, monthly summary) in `lib/services/habit_statistics_service.dart` / `habit_provider`.
3. Statistics screen improvements:
   - Add metric cards (overall %, best streak, longest streak, today/completed rate, weekly target)
   - Add chart (Bar chart for 7-day completion or line chart), use custom/`charts_flutter`.
   - Add filter chips (7 days / 30 days / 12 weeks).
   - Make per-habit card colors themed via `Theme.of(context)`.
4. Home screen completion widget: x/y habits, circular + progress indicator, quick streak summary.
5. Dark/Light theme mode:
   - Add `ThemeMode` states in `lib/services/theme_provider.dart`.
   - Persist in SharedPreferences key `habit_tracker_theme_mode`.
   - In `main.dart` use `theme` and `darkTheme` with `themeMode` from provider.
   - Add icon button/toggle on `HomeScreen` AppBar or navigation drawer.
6. Notification reminders:
   - Add dependency `flutter_local_notifications` and native setup for each platform.
   - Add fields to Habit model: `reminderEnabled`, `reminderTime` (or separate `HabitReminder` model).
   - Initialize notification service in `main.dart` and in `HabitProvider` (on load and on add/update/delete).
   - Schedule a local notification for each enabled habit daily/weekly intake.
   - Cancel notifications when disable or delete.
7. Storage updates:
   - `HabitStorageService` store additional settings alongside habits (theme mode, notification token) in SharedPreferences.
   - Migration logic if old data lacks new keys.
8. Optional stats enhancements (if time): streak timeline view (calendar heatmap), habit-level analytics detail page.

Verification
1. Unit tests for model: `completionPercentage` and `currentStreak` and new `longestStreak`.
2. Run app, add habits, mark completions and verify statistics values and progress bars.
3. Switch light/dark toggle; restart app; verify persisted.
4. Create habit with reminder; check local notification appears in system (or simulation in emulator) at selected time.
5. Visual inspection: cards use 2-tone interactive layout, consistent dark theme.

Decisions
- Existing `completionPercentage` is 30-day / 12-week.
- Streak counts as consecutive completed days or weeks using `isCompletedOn`.
- Notifications are local, per-habit scheduled.

Further Considerations
1. App architecture: state management remains Provider (no refactor to Riverpod now).
2. If using charts package, add dependency to `pubspec.yaml` and test on all platforms.
3. If need remote sync later, design `Habit` model with optional `id` and share metadata, but not in this sprint.