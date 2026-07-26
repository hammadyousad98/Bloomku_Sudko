import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TutorialSlide extends Equatable {
  final String title;
  final String body;
  final String? illustrationAsset;

  const TutorialSlide({
    required this.title,
    required this.body,
    this.illustrationAsset,
  });

  @override
  List<Object?> get props => [title, body, illustrationAsset];
}

class TutorialState extends Equatable {
  final int currentSlide;
  final int totalSlides;
  final List<TutorialSlide> slides;

  const TutorialState({
    required this.currentSlide,
    required this.totalSlides,
    required this.slides,
  });

  @override
  List<Object?> get props => [currentSlide, totalSlides, slides];
}

class TutorialCubit extends Cubit<TutorialState> {
  final void Function()? onComplete;

  TutorialCubit({
    required List<TutorialSlide> slides,
    this.onComplete,
  }) : super(TutorialState(
          currentSlide: 0,
          totalSlides: slides.length,
          slides: slides,
        ));

  void nextSlide() {
    if (state.currentSlide < state.totalSlides - 1) {
      emit(TutorialState(
        currentSlide: state.currentSlide + 1,
        totalSlides: state.totalSlides,
        slides: state.slides,
      ));
    } else {
      onComplete?.call();
    }
  }

  void prevSlide() {
    if (state.currentSlide > 0) {
      emit(TutorialState(
        currentSlide: state.currentSlide - 1,
        totalSlides: state.totalSlides,
        slides: state.slides,
      ));
    }
  }

  void skip() {
    onComplete?.call();
  }

  /// TYPE A - Main Tutorial Slides
  static List<TutorialSlide> getMainSlides() {
    return const [
      TutorialSlide(
        title: "Welcome to Zenduko",
        body:
            "A mindful logic puzzle. Place one [objectName] in every row, column, and color region.",
      ),
      TutorialSlide(
        title: "Tap once to mark",
        body:
            "Tap a cell once to mark it with ×. Tap the marker again to unmark it.",
      ),
      TutorialSlide(
        title: "Double-tap to place",
        body:
            "Double-tap any empty or marked cell to place your [objectName] there. Double-tap a placed [objectName] to remove it.",
      ),
      TutorialSlide(
        title: "Rows, columns, regions",
        body:
            "Every row, every column, and every color region must contain exactly one [objectName].",
      ),
      TutorialSlide(
        title: "No touching",
        body:
            "No [objectName] can touch another, even diagonally. Leave every surrounding cell clear.",
      ),
    ];
  }

  /// TYPE B - Rule Tutorial Slides
  static TutorialSlide getFullDiagonalRule() {
    return const TutorialSlide(
      title: "New Rule Unlocked!",
      body:
          "No two [objectName]s may share any diagonal line — not just neighbors, but across the entire board.",
    );
  }

  static TutorialSlide getMinDistanceRule(int distance) {
    return TutorialSlide(
      title: "Spread Them Out!",
      body:
          "On Ultra Hard, every [objectName] must be at least $distance cells from every other — measured in steps across rows and columns combined.",
    );
  }

  static TutorialSlide getKnightsMoveRule() {
    return const TutorialSlide(
      title: "The Knight Awakens!",
      body:
          "From level 80, each [objectName] also blocks the cells a chess knight can jump to. The L-shaped move adds a surprising new layer to every puzzle.",
    );
  }

  static TutorialSlide getMineRule() {
    return const TutorialSlide(
      title: "Watch Your Step!",
      body:
          "Ultra Hard boards can hide landmines. Stepping on one costs extra lives — you won't know where they are until it's too late, so place carefully.",
    );
  }

  static TutorialSlide getRowColumnRule() {
    return const TutorialSlide(
      title: "Row & Column Rule",
      body: "Only one [objectName] per row, and only one per column.",
    );
  }

  static TutorialSlide getColorRegionRule() {
    return const TutorialSlide(
      title: "Color Region Rule",
      body: "Only one [objectName] per colored region.",
    );
  }

  static TutorialSlide getNoTouchRule() {
    return const TutorialSlide(
      title: "No Touching Rule",
      body: "Flowers can't touch each other — not even diagonally.",
    );
  }
}
