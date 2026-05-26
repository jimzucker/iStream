enum FieldType {
  stringType('string'),
  intType('int'),
  longType('long'),
  doubleType('double'),
  decimalType('decimal'),
  timestampType('timestamp'),
  booleanType('boolean'),
  bytesType('bytes');

  const FieldType(this.label);
  final String label;
}

class Field {
  Field({required this.name, required this.type});

  String name;
  FieldType type;
}
