/* 
  Custom Markdown Style for Darto
  --------------------------------
  This CSS file provides a minimalist and modern look for Markdown-rendered templates in Darto.
  It is inspired by GitHub Flavored Markdown and the style found on pub.dev and is applicable to all Markdown templates
  used within Darto (e.g., those with the "md" engine).

  Markdown Type: GitHub Flavored Markdown / Minimalist Markdown Style
*/

/* Base style for the body */
const customStyle = '''
<style>
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      "Helvetica Neue", Arial, sans-serif;
    background-color: #ffffff;
    color: #24292e;
    line-height: 1.6;
    padding: 20px;
    margin: 0;
  }
  
  /* Headings */
  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    border-bottom: 1px solid #eaecef;
    font-weight: 600;
    margin-top: 24px;
    margin-bottom: 16px;
    line-height: 1.25;
  }
  
  h1 {
    font-size: 2em;
  }
  
  h2 {
    font-size: 1.5em;
  }
  
  /* Paragraphs */
  p {
    margin-top: 0;
    margin-bottom: 16px;
  }
  
  /* Blockquotes */
  blockquote {
    padding: 0 1em;
    color: #6a737d;
    border-left: 0.25em solid #dfe2e5;
    margin: 0 0 16px;
  }
  
  /* Inline Code */
  p code,
  li code {
    background-color: rgba(27, 31, 35, 0.05);
    padding: 0.2em 0.4em;
    margin: 0;
    font-size: 85%;
    border-radius: 3px;
  }
  
  /* Code Blocks (Multiline) */
  pre {
    background-color: #f6f8fa;
    padding: 16px;
    overflow: auto;
    border-radius: 3px;
    margin-bottom: 16px;
  }
  
  /* Code and pre tags for inline monospace font */
  pre,
  code {
    font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, Courier,
      monospace;
  }
  
  /* Links */
  a {
    color: #0366d6;
    text-decoration: none;
  }
  a:hover {
    text-decoration: underline;
  }
  
  /* Lists */
  ul,
  ol {
    padding-left: 2em;
    margin-top: 0;
    margin-bottom: 16px;
  }
  
  /* Tables */
  table {
    border-collapse: collapse;
    display: block;
    width: 100%;
    overflow: auto;
    margin-bottom: 16px;
  }
  th,
  td {
    border: 1px solid #dfe2e5;
    padding: 6px 13px;
  }
  thead {
    background-color: #f6f8fa;
  }
  
  /* Horizontal Rules */
  hr {
    height: 0.25em;
    padding: 0;
    margin: 24px 0;
    background-color: #eaecef;
    border: 0;
  }
  
  /* Images */
  img {
    max-width: 100%;
    border-radius: 3px;
  }
</style>
''';
