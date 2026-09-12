enum BlockType {
  paragraph('paragraph', 'Text', 'Plain text paragraph'),
  heading1('heading1', 'Heading 1', 'Large section heading'),
  heading2('heading2', 'Heading 2', 'Medium section heading'),
  heading3('heading3', 'Heading 3', 'Small subsection heading'),
  bulletList('bulletList', 'Bulleted List', 'Simple bulleted list'),
  numberedList('numberedList', 'Numbered List', 'Ordered numbered list'),
  checklist('checklist', 'To-do List', 'Track tasks with checkboxes'),
  quote('quote', 'Quote', 'Capture a quote or key insight'),
  callout('callout', 'Callout', 'Highlight important information'),
  code('code', 'Code Block', 'Code snippet with language badge'),
  divider('divider', 'Divider', 'Visual dividing line'),
  image('image', 'Image', 'Embed image with caption');

  final String key;
  final String label;
  final String description;

  const BlockType(this.key, this.label, this.description);

  static BlockType fromKey(String key) {
    for (final val in BlockType.values) {
      if (val.key == key) return val;
    }
    return BlockType.paragraph;
  }
}
