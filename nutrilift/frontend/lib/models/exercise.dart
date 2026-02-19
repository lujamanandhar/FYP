import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required int id,
    required String name,
    required String category,
    @JsonKey(name: 'muscle_group') required String muscleGroup,
    required String equipment,
    required String difficulty,
    required String description,
    required String instructions,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}
