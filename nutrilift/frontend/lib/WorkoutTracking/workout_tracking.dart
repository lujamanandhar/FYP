import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/nutrilift_header.dart';
import '../screens/workout_history_screen.dart';
import '../screens/new_workout_screen.dart';
import '../screens/exercise_library_screen.dart';
import '../screens/personal_records_screen.dart';
import '../screens/guided_workout_player_screen.dart';
import '../screens/guided_workout_plans.dart';
import '../screens/workout_detail_screen.dart';
import '../providers/workout_history_provider.dart';
import '../providers/personal_records_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../providers/repository_providers.dart';
import '../services/dashboard_service.dart';
import '../services/streak_service.dart';
import '../services/dashboard_refresh_service.dart';
import '../widgets/streak_overview_widget.dart';
import 'dart:async';
import '../models/workout_log.dart';
import '../models/workout_models.dart' show CreateWorkoutLogRequest, ExerciseSetRequest, WorkoutSetRequest;
import '../models/personal_record.dart';
import '../models/exercise.dart';

const Color _kRed = Color(0xFFE53935);

enum _WorkoutView { today, all, favourites }

// ── Warmup & Stretch static data ──────────────────────────────────────────────
const _kWarmupPlan = GuidedPlan(
  id: 'warmup',
  name: '5-Min Warmup',
  description: 'Dynamic warmup to prepare your body.',
  difficulty: 'Beginner',
  category: 'Full Body',
  estimatedMinutes: 5,
  emoji: '🔥',
  exercises: [
    GuidedExercise(name: 'Arm Circles', muscleGroup: 'Shoulders', durationSeconds: 30, restSeconds: 5, instruction: 'Rotate arms in large circles forward then backward.'),
    GuidedExercise(name: 'Leg Swings', muscleGroup: 'Hips', durationSeconds: 30, restSeconds: 5, instruction: 'Hold wall, swing each leg forward and back.'),
    GuidedExercise(name: 'Hip Circles', muscleGroup: 'Hips', durationSeconds: 30, restSeconds: 5, instruction: 'Hands on hips, rotate in large circles each direction.'),
    GuidedExercise(name: 'Jumping Jacks', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 10, instruction: 'Jump feet wide while raising arms overhead.'),
    GuidedExercise(name: 'High Knees', muscleGroup: 'Cardio', durationSeconds: 30, restSeconds: 10, instruction: 'Run in place, driving knees up to hip height.'),
  ],
);

const _kWarmupIntensePlan = GuidedPlan(
  id: 'warmup_intense',
  name: '10-Min Power Warmup',
  description: 'High-intensity warmup for heavy training days.',
  difficulty: 'Intermediate',
  category: 'Full Body',
  estimatedMinutes: 10,
  emoji: '⚡',
  exercises: [
    GuidedExercise(name: 'Jumping Jacks', muscleGroup: 'Full Body', durationSeconds: 45, restSeconds: 10, instruction: 'Jump feet wide while raising arms overhead.'),
    GuidedExercise(name: 'Butt Kicks', muscleGroup: 'Hamstrings', durationSeconds: 40, restSeconds: 10, instruction: 'Jog in place, kicking heels up to your glutes.'),
    GuidedExercise(name: 'Inchworm', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 10, instruction: 'Bend forward, walk hands out to plank, walk back up.'),
    GuidedExercise(name: 'World\'s Greatest Stretch', muscleGroup: 'Full Body', durationSeconds: 45, restSeconds: 10, instruction: 'Lunge forward, rotate torso, reach arm to sky. Alternate sides.'),
    GuidedExercise(name: 'Bear Crawl', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 10, instruction: 'On hands and feet, crawl forward keeping knees low.'),
    GuidedExercise(name: 'Lateral Shuffles', muscleGroup: 'Legs', durationSeconds: 40, restSeconds: 10, instruction: 'Shuffle side to side in athletic stance.'),
    GuidedExercise(name: 'Mountain Climbers', muscleGroup: 'Core', durationSeconds: 40, restSeconds: 15, instruction: 'In plank, drive knees alternately toward chest rapidly.'),
  ],
);

const _kMorningWarmupPlan = GuidedPlan(
  id: 'warmup_morning',
  name: 'Morning Wake-Up',
  description: 'Gentle morning routine to wake up your body.',
  difficulty: 'Beginner',
  category: 'Full Body',
  estimatedMinutes: 7,
  emoji: '🌅',
  exercises: [
    GuidedExercise(name: 'Neck Rolls', muscleGroup: 'Neck', durationSeconds: 30, restSeconds: 5, instruction: 'Slowly roll neck in full circles each direction.'),
    GuidedExercise(name: 'Shoulder Rolls', muscleGroup: 'Shoulders', durationSeconds: 30, restSeconds: 5, instruction: 'Roll shoulders forward and backward in large circles.'),
    GuidedExercise(name: 'Torso Twists', muscleGroup: 'Core', durationSeconds: 30, restSeconds: 5, instruction: 'Stand feet apart, twist torso left and right with arms extended.'),
    GuidedExercise(name: 'Cat-Cow Stretch', muscleGroup: 'Back', durationSeconds: 40, restSeconds: 5, instruction: 'On hands and knees, arch back up then drop belly down.'),
    GuidedExercise(name: 'Hip Flexor Stretch', muscleGroup: 'Hips', durationSeconds: 30, restSeconds: 5, instruction: 'Lunge forward, lower back knee, push hips forward.'),
    GuidedExercise(name: 'Ankle Circles', muscleGroup: 'Ankles', durationSeconds: 30, restSeconds: 5, instruction: 'Rotate each ankle in full circles both directions.'),
  ],
);

const _kStretchPlan = GuidedPlan(
  id: 'stretch',
  name: '5-Min Cool Down',
  description: 'Static stretches to recover and relax.',
  difficulty: 'Beginner',
  category: 'Full Body',
  estimatedMinutes: 5,
  emoji: '🧘',
  exercises: [
    GuidedExercise(name: 'Standing Quad Stretch', muscleGroup: 'Quads', durationSeconds: 30, restSeconds: 5, instruction: 'Stand on one leg, pull other foot to glutes. Hold.'),
    GuidedExercise(name: 'Hamstring Stretch', muscleGroup: 'Hamstrings', durationSeconds: 30, restSeconds: 5, instruction: 'Sit on floor, legs straight, reach for toes.'),
    GuidedExercise(name: 'Chest Opener', muscleGroup: 'Chest', durationSeconds: 30, restSeconds: 5, instruction: 'Clasp hands behind back, open chest upward.'),
    GuidedExercise(name: 'Child\'s Pose', muscleGroup: 'Back', durationSeconds: 40, restSeconds: 5, instruction: 'Kneel, sit back on heels, arms extended forward.'),
    GuidedExercise(name: 'Pigeon Pose', muscleGroup: 'Hips', durationSeconds: 40, restSeconds: 5, instruction: 'One leg forward bent, other extended back. Hold each side.'),
  ],
);

const _kStretchDeepPlan = GuidedPlan(
  id: 'stretch_deep',
  name: '10-Min Deep Stretch',
  description: 'Full body deep stretch for flexibility and recovery.',
  difficulty: 'Intermediate',
  category: 'Full Body',
  estimatedMinutes: 10,
  emoji: '🌿',
  exercises: [
    GuidedExercise(name: 'Seated Forward Fold', muscleGroup: 'Hamstrings', durationSeconds: 45, restSeconds: 5, instruction: 'Sit with legs straight, fold forward reaching for feet.'),
    GuidedExercise(name: 'Butterfly Stretch', muscleGroup: 'Hips', durationSeconds: 45, restSeconds: 5, instruction: 'Sit with soles together, press knees toward floor.'),
    GuidedExercise(name: 'Spinal Twist', muscleGroup: 'Back', durationSeconds: 40, restSeconds: 5, instruction: 'Sit, cross one leg over, twist toward bent knee. Each side.'),
    GuidedExercise(name: 'Doorway Chest Stretch', muscleGroup: 'Chest', durationSeconds: 40, restSeconds: 5, instruction: 'Arms at 90°, press forearms on wall, lean forward.'),
    GuidedExercise(name: 'Lying Hip Flexor', muscleGroup: 'Hips', durationSeconds: 45, restSeconds: 5, instruction: 'Lie on back, pull one knee to chest, extend other leg.'),
    GuidedExercise(name: 'Thread the Needle', muscleGroup: 'Shoulders', durationSeconds: 40, restSeconds: 5, instruction: 'On all fours, slide one arm under body, rest shoulder on floor.'),
    GuidedExercise(name: 'Supine Twist', muscleGroup: 'Back', durationSeconds: 45, restSeconds: 5, instruction: 'Lie on back, drop knees to one side, arms out. Each side.'),
  ],
);

const _kYogaStretchPlan = GuidedPlan(
  id: 'stretch_yoga',
  name: 'Yoga Flow',
  description: 'Yoga-inspired stretches for mind and body.',
  difficulty: 'Beginner',
  category: 'Full Body',
  estimatedMinutes: 8,
  emoji: '🕉️',
  exercises: [
    GuidedExercise(name: 'Mountain Pose', muscleGroup: 'Full Body', durationSeconds: 30, restSeconds: 5, instruction: 'Stand tall, feet together, arms at sides. Breathe deeply.'),
    GuidedExercise(name: 'Downward Dog', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 5, instruction: 'Inverted V shape, hands and feet on floor, hips high.'),
    GuidedExercise(name: 'Warrior I', muscleGroup: 'Legs', durationSeconds: 40, restSeconds: 5, instruction: 'Lunge forward, back foot at 45°, arms overhead. Each side.'),
    GuidedExercise(name: 'Warrior II', muscleGroup: 'Legs', durationSeconds: 40, restSeconds: 5, instruction: 'Wide stance, front knee bent, arms parallel to floor.'),
    GuidedExercise(name: 'Triangle Pose', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 5, instruction: 'Wide stance, reach down to front foot, other arm up.'),
    GuidedExercise(name: 'Cobra Pose', muscleGroup: 'Back', durationSeconds: 35, restSeconds: 5, instruction: 'Lie face down, press up with arms, arch back gently.'),
    GuidedExercise(name: 'Corpse Pose', muscleGroup: 'Full Body', durationSeconds: 60, restSeconds: 0, instruction: 'Lie flat on back, arms at sides, completely relax.'),
  ],
);

// ── Body focus filter data ─────────────────────────────────────────────────────
const _kBodyFocusFilters = [
  {'label': 'Abs', 'value': 'CORE'},
  {'label': 'Arms', 'value': 'ARMS'},
  {'label': 'Chest', 'value': 'CHEST'},
  {'label': 'Legs', 'value': 'LEGS'},
  {'label': 'Shoulders', 'value': 'SHOULDERS'},
  {'label': 'Back', 'value': 'BACK'},
  {'label': 'Glutes', 'value': 'GLUTES'},
  {'label': 'Cardio', 'value': 'CARDIO'},
  {'label': 'Full Body', 'value': 'FULL_BODY'},
];

class WorkoutTracking extends StatelessWidget {
  const WorkoutTracking({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const WorkoutTrackingHome();
}

class WorkoutTrackingHome extends ConsumerStatefulWidget {
  const WorkoutTrackingHome({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutTrackingHome> createState() => _WorkoutTrackingHomeState();
}

class _WorkoutTrackingHomeState extends ConsumerState<WorkoutTrackingHome> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  String? _selectedMuscleGroup; // null = nothing selected
  int _currentStreak = 0;
  AllStreaks _allStreaks = const AllStreaks();
  final StreakService _streakService = StreakService();
  StreamSubscription<void>? _refreshSubscription;

  // My Workouts filter state
  _WorkoutView _workoutView = _WorkoutView.today;
  DateTimeRange? _dateFilter;
  Set<String> _favouriteWorkoutNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) _refreshData();
    });
    _loadStreak();
    _loadFavourites();
    _refreshSubscription = DashboardRefreshService().refreshStream.listen((_) {
      if (mounted) _loadStreak();
    });
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favourite_workouts') ?? [];
    if (mounted) setState(() => _favouriteWorkoutNames = favs.toSet());
  }

  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favourite_workouts', _favouriteWorkoutNames.toList());
  }

  void _toggleFavourite(String name) {
    setState(() {
      if (_favouriteWorkoutNames.contains(name)) {
        _favouriteWorkoutNames.remove(name);
      } else {
        _favouriteWorkoutNames.add(name);
      }
    });
    _saveFavourites();
  }

  void _refreshData() {
    ref.read(exerciseLibraryProvider.notifier).loadExercises();
    ref.read(workoutHistoryProvider.notifier).refresh();
    ref.read(personalRecordsProvider.notifier).refresh();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final streaks = await _streakService.fetchAllStreaks();
      if (mounted) {
        setState(() {
          _allStreaks = streaks;
          _currentStreak = streaks.workout.currentStreak;
        });
      }
    } catch (e) {
      print('Error loading streak: $e');
    }
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final aLocal = a.toLocal();
    final bLocal = b.toLocal();
    return aLocal.year == bLocal.year && aLocal.month == bLocal.month && aLocal.day == bLocal.day;
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final prsAsync = ref.watch(personalRecordsProvider);
    final exercisesAsync = ref.watch(exerciseLibraryProvider);

    final today = DateTime.now();

    final todayWorkouts = historyAsync.maybeWhen(
      data: (list) => list.where((w) => _isSameDay(w.date, today)).toList(),
      orElse: () => <WorkoutLog>[],
    );

    final todayPRs = prsAsync.maybeWhen(
      data: (list) => list.where((pr) => _isSameDay(pr.achievedDate, today)).toList(),
      orElse: () => <PersonalRecord>[],
    );

    // Dates that have workouts (for calendar dots)
    final workoutDates = historyAsync.maybeWhen(
      data: (list) => list.map((w) => DateTime(w.date.year, w.date.month, w.date.day)).toSet(),
      orElse: () => <DateTime>{},
    );

    // All exercises
    final allExercises = exercisesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Exercise>[],
    );

    return NutriLiftScaffold(
      streakCount: _currentStreak,
      onStreakTap: () => showStreakOverview(context, _allStreaks),
      title: 'Workout',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Today's stats (3 cards) ────────────────────────
            _buildTodayStats(context, todayWorkouts, todayPRs, workoutDates, historyAsync),
            const SizedBox(height: 24),

            // ── 2. Warmup & Stretch ───────────────────────────────
            _buildSectionHeader('Warmup & Stretch'),
            const SizedBox(height: 10),
            _buildWarmupStretchRow(context),
            const SizedBox(height: 24),

            // ── 3. Body Focus ─────────────────────────────────────
            _buildSectionHeader('Body Focus'),
            const SizedBox(height: 10),
            _buildBodyFocusChips(context, allExercises),
            if (_selectedMuscleGroup != null) ...[
              const SizedBox(height: 14),
              _buildDifficultyCards(context, allExercises),
            ],
            const SizedBox(height: 24),

            // ── 4. Custom Workout ─────────────────────────────────
            _buildSectionHeader('Custom Workout'),
            const SizedBox(height: 10),
            _buildCreateCustomWorkoutButton(context),
            const SizedBox(height: 24),

            // ── 5. My Saved Workouts ──────────────────────────────
            _buildSectionHeader('My Workouts'),
            const SizedBox(height: 4),
            Text(
              'Tap any past workout to repeat it',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 10),
            _buildMyWorkouts(context, historyAsync),
          ],
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Color(0xFF212121),
      ),
    );
  }

  // ── Today's stats (3 cards) ───────────────────────────────────────────────
  Widget _buildTodayStats(
    BuildContext context,
    List<WorkoutLog> todayWorkouts,
    List<PersonalRecord> todayPRs,
    Set<DateTime> workoutDates,
    AsyncValue<List<WorkoutLog>> historyAsync,
  ) {
    return Row(children: [
      _TodayStatCard(
        icon: Icons.fitness_center_rounded,
        label: "Today's\nWorkouts",
        value: '${todayWorkouts.length}',
        color: _kRed,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen(todayOnly: true)),
        ),
      ),
      const SizedBox(width: 10),
      _TodayStatCard(
        icon: Icons.emoji_events_rounded,
        label: "Today's\nPRs",
        value: '${todayPRs.length}',
        color: const Color(0xFFFFC107),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
        ),
      ),
      const SizedBox(width: 10),
      _TodayStatCard(
        icon: Icons.calendar_month_rounded,
        label: 'Workout\nHistory',
        value: '${historyAsync.maybeWhen(data: (l) => l.length, orElse: () => 0)}',
        color: const Color(0xFF42A5F5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutHistoryCalendarScreen(
              workoutDates: workoutDates,
              allWorkouts: historyAsync.maybeWhen(data: (l) => l, orElse: () => []),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Warmup & Stretch row ───────────────────────────────────────────────────
  Widget _buildWarmupStretchRow(BuildContext context) {
    final warmupPlans = [_kWarmupPlan, _kWarmupIntensePlan, _kMorningWarmupPlan];
    final stretchPlans = [_kStretchPlan, _kStretchDeepPlan, _kYogaStretchPlan];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warmup section
        Text('Warmup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: warmupPlans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(
              width: 160,
              child: _QuickPlanCard(
                plan: warmupPlans[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuidedWorkoutPlayerScreen(plan: warmupPlans[i]),
                )),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Stretch section
        Text('Cool Down & Stretch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stretchPlans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(
              width: 160,
              child: _QuickPlanCard(
                plan: stretchPlans[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuidedWorkoutPlayerScreen(plan: stretchPlans[i]),
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Body focus chips — highlight selected, show difficulty inline ─────────
  Widget _buildBodyFocusChips(BuildContext context, List<Exercise> allExercises) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kBodyFocusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _kBodyFocusFilters[i];
          final label = f['label'] as String;
          final value = f['value'] as String;
          final selected = _selectedMuscleGroup == value;

          return GestureDetector(
            onTap: () => setState(() {
              if (_selectedMuscleGroup == value) {
                _selectedMuscleGroup = null;
              } else {
                _selectedMuscleGroup = value;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _kRed : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? _kRed : Colors.grey[300]!,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: _kRed.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Difficulty cards: navigate to exercise list on tap ────────────────────
  Widget _buildDifficultyCards(BuildContext context, List<Exercise> allExercises) {
    final mg = _kBodyFocusFilters.firstWhere((f) => f['value'] == _selectedMuscleGroup);
    final muscleLabel = mg['label'] as String;
    final muscleValue = mg['value'] as String;
    final exercises = allExercises.where((e) => e.muscleGroup == muscleValue).toList();

    const difficulties = [
      {'label': 'Beginner', 'value': 'BEGINNER', 'color': Color(0xFF4CAF50), 'desc': 'Perfect for getting started'},
      {'label': 'Intermediate', 'value': 'INTERMEDIATE', 'color': Color(0xFFFF9800), 'desc': 'Build on your foundation'},
      {'label': 'Advanced', 'value': 'ADVANCED', 'color': Color(0xFFE53935), 'desc': 'Push your limits'},
    ];

    return Column(
      children: difficulties.map((d) {
        final diffValue = d['value'] as String;
        final diffLabel = d['label'] as String;
        final color = d['color'] as Color;
        final desc = d['desc'] as String;
        final count = exercises.where((e) => e.difficulty == diffValue).length;
        final diffExercises = exercises.where((e) => e.difficulty == diffValue).toList();

        return GestureDetector(
          onTap: count == 0 ? null : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BodyFocusExercisesScreen(
                title: '$muscleLabel $diffLabel',
                exercises: diffExercises,
                difficulty: diffLabel,
                difficultyColor: color,
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: count == 0 ? Colors.grey[50] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: count == 0 ? Colors.grey[200]! : color.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: count == 0 ? [] : [
                BoxShadow(color: color.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: count == 0 ? Colors.grey[300] : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$muscleLabel · $diffLabel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: count == 0 ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0 ? 'No exercises available' : '$count exercises · $desc',
                      style: TextStyle(
                        color: count == 0 ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── My Workouts (today by default, filterable, favouritable) ─────────────
  Widget _buildMyWorkouts(BuildContext context, AsyncValue<List<WorkoutLog>> historyAsync) {
    return historyAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_kRed)),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Could not load workouts', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
      data: (allWorkouts) {
        // ── Filter bar ──────────────────────────────────────────
        final filterBar = Row(
          children: [
            _ViewChip(label: 'Today',     selected: _workoutView == _WorkoutView.today,      onTap: () => setState(() { _workoutView = _WorkoutView.today;      _dateFilter = null; })),
            const SizedBox(width: 6),
            _ViewChip(label: 'All',       selected: _workoutView == _WorkoutView.all,        onTap: () => setState(() { _workoutView = _WorkoutView.all;        _dateFilter = null; })),
            const SizedBox(width: 6),
            _ViewChip(label: 'Favourites', icon: Icons.bookmark_rounded, selected: _workoutView == _WorkoutView.favourites, onTap: () => setState(() { _workoutView = _WorkoutView.favourites; _dateFilter = null; })),
            const Spacer(),
            // Date filter icon
            GestureDetector(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateFilter,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kRed)),
                    child: child!,
                  ),
                );
                if (range != null) setState(() { _dateFilter = range; _workoutView = _WorkoutView.all; });
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _dateFilter != null ? _kRed.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _dateFilter != null ? _kRed.withOpacity(0.3) : Colors.grey[200]!),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.date_range_rounded, size: 16, color: _dateFilter != null ? _kRed : Colors.grey[500]),
                  if (_dateFilter != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _dateFilter = null),
                      child: const Icon(Icons.close, size: 13, color: _kRed),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        );

        // ── Apply filters ────────────────────────────────────────
        List<WorkoutLog> filtered = allWorkouts;

        if (_dateFilter != null) {
          filtered = filtered.where((w) {
            final d = w.date.toLocal();
            return !d.isBefore(_dateFilter!.start) && !d.isAfter(_dateFilter!.end.add(const Duration(days: 1)));
          }).toList();
        } else if (_workoutView == _WorkoutView.today) {
          final today = DateTime.now();
          filtered = filtered.where((w) => _isSameDay(w.date, today)).toList();
        } else if (_workoutView == _WorkoutView.favourites) {
          filtered = filtered.where((w) => _favouriteWorkoutNames.contains(w.workoutName ?? 'Workout')).toList();
        }

        // Deduplicate by name (keep most recent) unless showing today or date-filtered
        if (_dateFilter == null && _workoutView != _WorkoutView.today) {
          final seen = <String>{};
          final unique = <WorkoutLog>[];
          for (final w in filtered) {
            final name = w.workoutName ?? 'Workout';
            if (!seen.contains(name)) { seen.add(name); unique.add(w); }
            if (unique.length >= 10) break;
          }
          filtered = unique;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            filterBar,
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(children: [
                  Icon(
                    _workoutView == _WorkoutView.favourites ? Icons.bookmark_border_rounded : Icons.history_rounded,
                    color: Colors.grey[400], size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _workoutView == _WorkoutView.today
                        ? 'No workouts logged today'
                        : _workoutView == _WorkoutView.favourites
                            ? 'No favourites yet — bookmark a workout!'
                            : 'No workouts found',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ]),
              )
            else
              ...filtered.map((w) => _MyWorkoutTile(
                workout: w,
                isFavourite: _favouriteWorkoutNames.contains(w.workoutName ?? 'Workout'),
                onToggleFavourite: () => _toggleFavourite(w.workoutName ?? 'Workout'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NewWorkoutScreen(repeatFrom: w)),
                ),
              )),
          ],
        );
      },
    );
  }

  // ── Create custom workout button ───────────────────────────────────────────
  Widget _buildCreateCustomWorkoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewWorkoutScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kRed.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Custom Workout',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Build your own workout plan',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
        ]),
      ),
    );
  }
}

// ── Today stat card ────────────────────────────────────────────────────────────
class _TodayStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TodayStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 26)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 11, height: 1.3)),
              const SizedBox(height: 6),
              Row(children: [
                Text('View all',
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 10),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Workout Calendar ───────────────────────────────────────────────────────────
class _WorkoutCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> workoutDates;
  final ValueChanged<DateTime> onDateSelected;

  const _WorkoutCalendar({
    required this.selectedDate,
    required this.workoutDates,
    required this.onDateSelected,
  });

  @override
  State<_WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<_WorkoutCalendar> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _prevMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      });

  bool _hasWorkout(DateTime d) =>
      widget.workoutDates.contains(DateTime(d.year, d.month, d.day));

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _prevMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 22,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_viewMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _nextMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 22,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) return const SizedBox();
            final day = index - startWeekday + 1;
            final date = DateTime(_viewMonth.year, _viewMonth.month, day);
            final isSelected = date.year == widget.selectedDate.year &&
                date.month == widget.selectedDate.month &&
                date.day == widget.selectedDate.day;
            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;
            final hasWorkout = _hasWorkout(date);

            return GestureDetector(
              onTap: () => widget.onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kRed
                      : isToday
                          ? _kRed.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? _kRed
                                : Colors.grey[800],
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (hasWorkout)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white70 : _kRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── Workout summary tile ───────────────────────────────────────────────────────
class _WorkoutSummaryTile extends StatelessWidget {
  final WorkoutLog workout;
  final VoidCallback onTap;

  const _WorkoutSummaryTile({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: _kRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.workoutName ?? 'Workout',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '${workout.duration} min · ${workout.caloriesBurned.toStringAsFixed(0)} cal',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          if (workout.hasNewPrs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('PR',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
        ]),
      ),
    );
  }
}

// ── Quick plan card (warmup/stretch) ──────────────────────────────────────────
class _QuickPlanCard extends StatelessWidget {
  final GuidedPlan plan;
  final VoidCallback onTap;

  const _QuickPlanCard({required this.plan, required this.onTap});

  // Curated workout background images — varied per plan
  static const _planImages = {
    'warmup': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
    'warmup_intense': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&q=80',
    'warmup_morning': 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400&q=80',
    'stretch': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80',
    'stretch_deep': 'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=400&q=80',
    'stretch_yoga': 'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=400&q=80',
  };

  @override
  Widget build(BuildContext context) {
    final imageUrl = _planImages[plan.id] ?? _planImages['warmup']!;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background photo
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            // Gradient fade from bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white70, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${plan.estimatedMinutes} min',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.fitness_center, color: Colors.white70, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${plan.totalExercises} exercises',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Play button top-right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFE53935), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Workout Tile ────────────────────────────────────────────────────────────
class _MyWorkoutTile extends StatelessWidget {
  final WorkoutLog workout;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback onToggleFavourite;

  const _MyWorkoutTile({
    required this.workout,
    required this.onTap,
    required this.isFavourite,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = workout.exercises.length;
    final localDate = workout.date.toLocal();
    final dateStr = DateFormat('MMM d, yyyy').format(localDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isFavourite ? _kRed.withOpacity(0.25) : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.replay_rounded, color: _kRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName ?? 'Workout',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'} · ${workout.duration} min · $dateStr',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          // Bookmark icon
          GestureDetector(
            onTap: onToggleFavourite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                isFavourite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isFavourite ? _kRed : Colors.grey[400],
                size: 22,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Repeat', style: TextStyle(color: _kRed, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ── View chip helper ──────────────────────────────────────────────────────────
class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _ViewChip({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kRed : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kRed : Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : Colors.grey[500]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workout History Calendar Screen ───────────────────────────────────────────
class WorkoutHistoryCalendarScreen extends StatefulWidget {
  final Set<DateTime> workoutDates;
  final List<WorkoutLog> allWorkouts;

  const WorkoutHistoryCalendarScreen({
    Key? key,
    required this.workoutDates,
    required this.allWorkouts,
  }) : super(key: key);

  @override
  State<WorkoutHistoryCalendarScreen> createState() =>
      _WorkoutHistoryCalendarScreenState();
}

class _WorkoutHistoryCalendarScreenState
    extends State<WorkoutHistoryCalendarScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final aLocal = a.toLocal();
    final bLocal = b.toLocal();
    return aLocal.year == bLocal.year && aLocal.month == bLocal.month && aLocal.day == bLocal.day;
  }

  List<WorkoutLog> get _selectedWorkouts => widget.allWorkouts
      .where((w) => _isSameDay(w.date, _selectedDate))
      .toList();

  @override
  Widget build(BuildContext context) {
    final label = _isSameDay(_selectedDate, DateTime.now())
        ? 'Today'
        : DateFormat('MMM d, yyyy').format(_selectedDate);

    return NutriLiftScaffold(
      title: 'Workout History',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            _WorkoutCalendar(
              selectedDate: _selectedDate,
              workoutDates: widget.workoutDates,
              onDateSelected: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),

            // Selected date label
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 10),

            // Workouts on selected date
            if (_selectedWorkouts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(children: [
                  Icon(Icons.event_busy_rounded, color: Colors.grey[400], size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No workout done on $label',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewWorkoutScreen()),
                    ),
                    child: Text(
                      'Log a workout',
                      style: TextStyle(
                        color: _kRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              )
            else
              ..._selectedWorkouts.map((w) => _WorkoutSummaryTile(
                workout: w,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(workout: w),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Body Focus: Difficulty selection screen ────────────────────────────────────
class BodyFocusDifficultyScreen extends StatelessWidget {
  final String muscleLabel;
  final String muscleValue;
  final String emoji;
  final List<Exercise> exercises;

  const BodyFocusDifficultyScreen({
    Key? key,
    required this.muscleLabel,
    required this.muscleValue,
    required this.emoji,
    required this.exercises,
  }) : super(key: key);

  static const _difficulties = [
    {'label': 'Beginner', 'value': 'BEGINNER', 'color': Color(0xFF4CAF50), 'desc': 'Perfect for getting started'},
    {'label': 'Intermediate', 'value': 'INTERMEDIATE', 'color': Color(0xFFFF9800), 'desc': 'Build on your foundation'},
    {'label': 'Advanced', 'value': 'ADVANCED', 'color': Color(0xFFE53935), 'desc': 'Push your limits'},
  ];

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: '$emoji $muscleLabel',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your level',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ..._difficulties.map((d) {
              final diffValue = d['value'] as String;
              final diffLabel = d['label'] as String;
              final color = d['color'] as Color;
              final desc = d['desc'] as String;
              final count = exercises.where((e) => e.difficulty == diffValue).length;

              return GestureDetector(
                onTap: count == 0 ? null : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BodyFocusExercisesScreen(
                      title: '$muscleLabel $diffLabel',
                      exercises: exercises.where((e) => e.difficulty == diffValue).toList(),
                      difficulty: diffLabel,
                      difficultyColor: color,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: count == 0 ? Colors.grey[100] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: count == 0 ? Colors.grey[300]! : color.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: count == 0 ? [] : [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(Icons.fitness_center, color: color, size: 26),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$muscleLabel $diffLabel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: count == 0 ? Colors.grey[400] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            count == 0 ? 'No exercises available' : '$count exercises',
                            style: TextStyle(
                              color: count == 0 ? Colors.grey[400] : color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (count > 0)
                      Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Body Focus: Exercises list screen with Start Workout button ────────────────
class BodyFocusExercisesScreen extends StatelessWidget {
  final String title;
  final List<Exercise> exercises;
  final String difficulty;
  final Color difficultyColor;

  const BodyFocusExercisesScreen({
    Key? key,
    required this.title,
    required this.exercises,
    required this.difficulty,
    required this.difficultyColor,
  }) : super(key: key);

  Color _diffColor(String d) {
    switch (d.toUpperCase()) {
      case 'BEGINNER': return Colors.green;
      case 'INTERMEDIATE': return Colors.orange;
      default: return _kRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: title,
      showBackButton: true,
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: exercises.length,
            itemBuilder: (context, i) {
              final ex = exercises[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ex.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(ex.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.fitness_center, color: difficultyColor)),
                          )
                        : Icon(Icons.fitness_center, color: difficultyColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(ex.muscleGroup,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        if (ex.instructions.isNotEmpty)
                          Text(
                            ex.instructions.split('\n').first,
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _diffColor(ex.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ex.difficulty,
                      style: TextStyle(
                          color: _diffColor(ex.difficulty),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
              );
            },
          ),

          // Floating Start Workout button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: () => _showModeDialog(context),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Start Workout (${exercises.length} exercises)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: difficultyColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How do you want to track?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Choose your workout tracking mode',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),

            // Manual option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualWorkoutPlayerScreen(
                      title: title,
                      exercises: exercises,
                      difficultyColor: difficultyColor,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kRed.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.touch_app_rounded, color: _kRed, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manual Tracking',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Press buttons to track reps & sets',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: _kRed, size: 16),
                ]),
              ),
            ),

            // Camera option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera tracking coming soon — requires ML Kit setup'),
                    backgroundColor: Color(0xFF1A1A2E),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.grey[600], size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('Camera Tracking',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Soon',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        Text('AI counts reps via camera pose detection',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Manual Workout Player Screen ───────────────────────────────────────────────
class ManualWorkoutPlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Exercise> exercises;
  final Color difficultyColor;

  const ManualWorkoutPlayerScreen({
    Key? key,
    required this.title,
    required this.exercises,
    required this.difficultyColor,
  }) : super(key: key);

  @override
  ConsumerState<ManualWorkoutPlayerScreen> createState() =>
      _ManualWorkoutPlayerScreenState();
}

class _ManualWorkoutPlayerScreenState
    extends ConsumerState<ManualWorkoutPlayerScreen> {
  int _currentIndex = 0;
  int _currentSet = 1;
  int _totalSets = 3;
  int _reps = 10;
  bool _paused = false;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Exercise get _current => widget.exercises[_currentIndex];
  bool get _isLast => _currentIndex == widget.exercises.length - 1;
  bool get _isLastSet => _currentSet >= _totalSets;

  void _nextSet() {
    if (_isLastSet) {
      _nextExercise();
    } else {
      setState(() => _currentSet++);
    }
  }

  void _nextExercise() {
    if (_isLast) {
      _finish();
    } else {
      setState(() {
        _currentIndex++;
        _currentSet = 1;
      });
    }
  }

  void _prevExercise() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentSet = 1;
      });
    }
  }

  void _finish() {
    final seconds = _stopwatch.elapsed.inSeconds;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCompletionScreen(
          title: widget.title,
          exercises: widget.exercises,
          durationSeconds: seconds,
          difficultyColor: widget.difficultyColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = _current;
    final progress = (_currentIndex + (_currentSet - 1) / _totalSets) /
        widget.exercises.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => _showQuitDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey[700], size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    Text(
                      '${_currentIndex + 1} / ${widget.exercises.length}',
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                'Set $_currentSet / $_totalSets',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ]),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    widget.difficultyColor),
              ),
            ),
          ),

          const Spacer(),

          // Exercise name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              ex.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 28),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.difficultyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.difficultyColor.withOpacity(0.3)),
            ),
            child: Text(ex.muscleGroup,
                style: TextStyle(
                    color: widget.difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),

          // Reps counter
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '$_reps',
              style: TextStyle(
                  color: widget.difficultyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 80),
            ),
            Text('REPS',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: () => setState(() => _reps = (_reps - 1).clamp(1, 100)),
                icon: Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.grey[600], size: 32),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => _reps = (_reps + 1).clamp(1, 100)),
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: Colors.grey[600], size: 32),
              ),
            ]),
          ]),

          const SizedBox(height: 16),

          // Instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              ex.instructions.split('\n').take(2).join(' '),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 12, height: 1.5),
            ),
          ),

          const Spacer(),

          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(children: [
              // Set done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.difficultyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _isLastSet && _isLast
                        ? 'Finish Workout'
                        : _isLastSet
                            ? 'Next Exercise'
                            : 'Set Done',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _currentIndex > 0 ? _prevExercise : null,
                    icon: const Icon(Icons.skip_previous_rounded, size: 18),
                    label: const Text('Prev'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _paused = !_paused),
                    icon: Icon(
                        _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 18),
                    label: Text(_paused ? 'Resume' : 'Pause'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                  TextButton.icon(
                    onPressed: _isLast ? null : _nextExercise,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Skip'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                ],
              ),
            ]),
          ),

          // Next exercise preview
          if (!_isLast)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(children: [
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text('Next: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  widget.exercises[_currentIndex + 1].name,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

// ── Workout Completion Screen ──────────────────────────────────────────────────
class WorkoutCompletionScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Exercise> exercises;
  final int durationSeconds;
  final Color difficultyColor;

  const WorkoutCompletionScreen({
    Key? key,
    required this.title,
    required this.exercises,
    required this.durationSeconds,
    required this.difficultyColor,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState
    extends ConsumerState<WorkoutCompletionScreen> {
  bool _saving = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveWorkout();
  }

  int get _estimatedCalories {
    final minutes = widget.durationSeconds / 60;
    // ~8 cal/min average for strength training
    return (minutes * 8).round().clamp(10, 9999);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  Future<void> _saveWorkout() async {
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final durationMinutes = (widget.durationSeconds / 60).ceil().clamp(1, 600);

      print('DEBUG: Creating exercise requests for ${widget.exercises.length} exercises');
      
      final exerciseRequests = widget.exercises.asMap().entries.map((entry) {
        print('DEBUG: Exercise ${entry.key}: id=${entry.value.id}, name=${entry.value.name}');
        return ExerciseSetRequest(
          exerciseId: '${entry.value.id}',
          order: entry.key,
          sets: [
            WorkoutSetRequest(
              setNumber: 1,
              reps: 10,
              weight: 0.5, // minimum valid weight (bodyweight exercises)
              completed: true,
            ),
          ],
          notes: entry.value.name,
        );
      }).toList();

      print('DEBUG: Created ${exerciseRequests.length} exercise requests');

      final request = CreateWorkoutLogRequest(
        workoutName: widget.title,
        durationMinutes: durationMinutes,
        caloriesBurned: _estimatedCalories.toDouble(),
        exercises: exerciseRequests,
      );

      print('DEBUG: Submitting workout: ${request.workoutName}');
      await repo.logWorkout(request);
      print('DEBUG: Workout saved successfully');
      
      ref.read(workoutHistoryProvider.notifier).refresh();

      // Wait for backend PR detection (now synchronous in serializer), then refresh PRs
      await Future.delayed(const Duration(milliseconds: 800));
      await ref.read(personalRecordsProvider.notifier).refresh();

      // Refresh streak and notify dashboard
      try {
        await StreakService().fetchAllStreaks();
        DashboardRefreshService().notifyRefresh();
        print('DEBUG: Streak refreshed after workout save');
      } catch (_) {}

      if (mounted) setState(() { _saving = false; _saved = true; });
    } catch (e, stackTrace) {
      print('WorkoutCompletionScreen save error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) setState(() { _saving = false; _saved = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Workout Complete!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
              const SizedBox(height: 6),
              Text(widget.title,
                  style: const TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 10),

              // Save status
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_saving) ...[
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white38)),
                  const SizedBox(width: 8),
                  const Text('Saving to history...',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ] else if (_saved) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 6),
                  const Text('Saved to workout history',
                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                ] else ...[
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  const Text('Could not save — check connection',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 32),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CompletionStat(
                    icon: Icons.timer_rounded,
                    label: 'Duration',
                    value: _formatDuration(widget.durationSeconds),
                    color: widget.difficultyColor,
                  ),
                  _CompletionStat(
                    icon: Icons.fitness_center_rounded,
                    label: 'Exercises',
                    value: '${widget.exercises.length}',
                    color: Colors.orange,
                  ),
                  _CompletionStat(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Est. Calories',
                    value: '$_estimatedCalories kcal',
                    color: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exercise summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exercises Completed',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    ...widget.exercises.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(Icons.check_circle_rounded,
                            color: widget.difficultyColor, size: 14),
                        const SizedBox(width: 8),
                        Text(e.name,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ]),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Invalidate providers to force fresh data load
                    ref.invalidate(workoutHistoryProvider);
                    ref.invalidate(personalRecordsProvider);
                    
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.difficultyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompletionStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}
