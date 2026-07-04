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
        title: "Welcome to Bloomku",
        body: "A mindful logic puzzle. Place one [objectName] in every row, column, and color region.",
      ),
      TutorialSlide(
        title: "Tap once — mark ×",
        body: "Tap a cell once to mark it with × — this cell cannot hold a [objectName].",
      ),
      TutorialSlide(
        title: "Tap twice — place",
        body: "Tap a marked cell again to place your [objectName] there.",
      ),
      TutorialSlide(
        title: "Tap again — clear",
        body: "A third tap clears the cell completely.",
      ),
      TutorialSlide(
        title: "One per row & column",
        body: "Every row and every column must contain exactly one [objectName].",
      ),
      TutorialSlide(
        title: "One per color region",
        body: "Each colored region on the grid must also contain exactly one [objectName].",
      ),
      TutorialSlide(
        title: "No touching!",
        body: "A [objectName] blocks all 8 cells directly surrounding it. Nothing can be placed there.",
      ),
    ];
  }

  /// TYPE B - Rule Tutorial Slides
  static TutorialSlide getFullDiagonalRule() {
    return const TutorialSlide(
      title: "New Rule Unlocked!",
      body: "No two [objectName]s may share any diagonal line — not just neighbors, but across the entire board.",
    );
  }

  static TutorialSlide getMinDistanceRule(int distance) {
    return TutorialSlide(
      title: "Spread Them Out!",
      body: "On Ultra Hard, every [objectName] must be at least $distance cells from every other — measured in steps across rows and columns combined.",
    );
  }

  static TutorialSlide getKnightsMoveRule() {
    return const TutorialSlide(
      title: "The Knight Awakens!",
      body: "From level 80, each [objectName] also blocks the cells a chess knight can jump to. The L-shaped move adds a surprising new layer to every puzzle.",
    );
  }
}
