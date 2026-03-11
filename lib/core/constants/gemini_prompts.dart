/// Prompt base per Gemini
class GeminiPrompts {
  GeminiPrompts._();

  static String buildCategoryPrompt(List<String> categoryDescriptions) {
    final categoriesText = categoryDescriptions
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
    return '''
Analizza questa immagine e scegli UNA sola categoria che meglio descrive il contenuto.
Categorie disponibili (con parole chiave per il riconoscimento):
$categoriesText

Rispondi SOLO con un JSON valido nel formato:
{"category_id":"id_categoria","confidence":0.0-1.0,"description":"breve descrizione in italiano"}
Se nessuna categoria è appropriata usa category_id "altro" e description con una breve descrizione.
''';
  }
}
