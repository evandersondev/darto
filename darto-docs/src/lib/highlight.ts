// Lightweight Dart syntax highlighter (regex-based, returns HTML)
const KEYWORDS = [
  'final', 'var', 'void', 'late', 'const', 'import', 'as', 'class', 'extends',
  'implements', 'with', 'return', 'if', 'else', 'for', 'while', 'try', 'catch',
  'on', 'throw', 'async', 'await', 'true', 'false', 'null', 'new', 'this',
  'Future', 'FutureOr', 'List', 'Map', 'String', 'int', 'double', 'bool',
  'DateTime', 'RegExp', 'typedef', 'enum', 'switch', 'case', 'default',
];

function escapeHtml(s: string) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export function highlightDart(code: string): string {
  const re = new RegExp(
    [
      `(?<comment>\\/\\/[^\\n]*|\\/\\*[\\s\\S]*?\\*\\/)`,
      `(?<string>'(?:\\\\.|[^'\\\\\\n])*'|"(?:\\\\.|[^"\\\\\\n])*")`,
      `(?<number>\\b\\d+(?:\\.\\d+)?\\b)`,
      `(?<kw>\\b(?:${KEYWORDS.join('|')})\\b)`,
      `(?<fn>\\b[a-zA-Z_$][\\w$]*(?=\\s*\\())`,
      `(?<prop>\\.[a-zA-Z_$][\\w$]*)`,
      `(?<punct>[{}()\\[\\];,:=<>!?+\\-*/&|])`,
    ].join('|'),
    'g'
  );

  let out = '';
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(code)) !== null) {
    if (m.index > last) out += escapeHtml(code.slice(last, m.index));
    const g = m.groups || {};
    const raw = escapeHtml(m[0]);
    if (g.comment) out += `<span class="tok-comment">${raw}</span>`;
    else if (g.string) out += `<span class="tok-string">${raw}</span>`;
    else if (g.number) out += `<span class="tok-number">${raw}</span>`;
    else if (g.kw) out += `<span class="tok-keyword">${raw}</span>`;
    else if (g.fn) out += `<span class="tok-fn">${raw}</span>`;
    else if (g.prop) out += `<span class="tok-prop">${raw}</span>`;
    else if (g.punct) out += `<span class="tok-punct">${raw}</span>`;
    else out += raw;
    last = m.index + m[0].length;
  }
  if (last < code.length) out += escapeHtml(code.slice(last));
  return out;
}

export function highlightSh(code: string): string {
  const re = /(#[^\n]*)|(--?[\w-]+)|('(?:[^'\\]|\\.)*')|("(?:[^"\\]|\\.)*")/g;
  let out = '';
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(code)) !== null) {
    if (m.index > last) out += escapeHtml(code.slice(last, m.index));
    const [full, comment, flag, sq, dq] = m;
    if (comment) out += `<span class="tok-comment">${escapeHtml(full)}</span>`;
    else if (flag) out += `<span class="tok-fn">${escapeHtml(full)}</span>`;
    else if (sq || dq) out += `<span class="tok-string">${escapeHtml(full)}</span>`;
    last = m.index + full.length;
  }
  if (last < code.length) out += escapeHtml(code.slice(last));
  return out;
}

export function highlightYaml(code: string): string {
  return code.split('\n').map(line => {
    if (/^\s*#/.test(line)) return `<span class="tok-comment">${escapeHtml(line)}</span>`;
    const m = line.match(/^(\s*)([\w.-]+)(\s*:\s*)(.*)$/);
    if (m) {
      const [, ws, key, sep, val] = m;
      const eVal = escapeHtml(val);
      const colored = eVal
        ? /^["']/.test(eVal) || /^\d/.test(eVal) || eVal === 'true' || eVal === 'false' || eVal === 'null'
          ? `<span class="tok-number">${eVal}</span>`
          : `<span class="tok-string">${eVal}</span>`
        : '';
      return `${ws}<span class="tok-prop">${escapeHtml(key)}</span>${escapeHtml(sep)}${colored}`;
    }
    return escapeHtml(line);
  }).join('\n');
}