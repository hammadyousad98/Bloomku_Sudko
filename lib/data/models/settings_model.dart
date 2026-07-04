import 'package:objectbox/objectbox.dart';

@Entity()
class SettingsModel {
  @Id()
  int id = 0;

  double musicVolume = 0.8;
  double sfxVolume = 0.8;

  /// Selected theme index (0=Blossom, 1=Ocean, 2=Forest, 3=Cosmos, 4=Peach)
  int selectedThemeIndex = 0;

  bool vibrationEnabled = true;
}
