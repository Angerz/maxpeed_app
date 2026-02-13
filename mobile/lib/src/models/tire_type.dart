enum TireType {
  radial('Radial'),
  carga('Carga'),
  milimetrica('Milimétrica'),
  convencional('Convencional');

  const TireType(this.label);
  final String label;

  bool get requiresProfile {
    return this == TireType.radial || this == TireType.milimetrica;
  }
}
