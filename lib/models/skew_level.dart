enum SkewLevel {
  none('None', 'Roughly uniform across keys'),
  mild('Mild', 'Top 20% of keys carry ~50% of volume'),
  heavy('Heavy', 'Top 1% of keys carry >50% of volume');

  const SkewLevel(this.label, this.description);
  final String label;
  final String description;
}
